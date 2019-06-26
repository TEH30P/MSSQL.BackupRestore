New-Alias -Name Backup-MSSQLDBData -Value '~MSSQLBR~DBDataBkp~Do' -Force;

# DB Data backup process.
function ~MSSQLBR~DBDataBkp~Do
{	param
	(   [parameter(Mandatory=1, position=0)]
			[Object]$iSrvInst
	,   [parameter(Mandatory=1, position=1)]
			[String]$iDBName
	,   [parameter(Mandatory=1, position=2)]
			[Uri[]]$iaRepoPath
	,   [parameter(Mandatory=0)]
			[Byte]$iArcLayer = 0
	,   [parameter(Mandatory=0)]
			[Byte]$iPriority = 0
	,   [parameter(Mandatory=0)]
			[switch]$fDiff
	,   [parameter(Mandatory=0)]
			[switch]$fCompression = $true
	,   [parameter(Mandatory=0)]
			[switch]$fCopyOnly
	,   [parameter(Mandatory=0)]
			[switch]$fRemoveDB
	,   [parameter(Mandatory=0)]
			[switch]$fAsShJob
	,   [parameter(Mandatory=0)]
			[String]$iConfPath = [string]::Empty
	);
try
{	#!!!TODO: When "-fRemoveDB" and "-fDiff" is set, function shoud check existence of Full backup.
	
	[datetime]$LogDate = [datetime]::Now;
	[Collections.Generic.List[String]]$MsgCll = [Collections.Generic.List[String]]::new();
	[String[]]$ParamMsgCll = m~BkpAttr~LogMsg~Gen $iSrvInst $iDBName $iaRepoPath;

	[NMSSQL.MBkpRst.EBkpJobType]$JobType = if ($fDiff) {[NMSSQL.MBkpRst.EBkpJobType]::DBDiff} else {[NMSSQL.MBkpRst.EBkpJobType]::DBFull};

	if ($iSrvInst -is [String])
	{	[String]$Local:QIKey = m~Queue~Bkp~New $iaRepoPath $iPriority $JobType $iSrvInst $iDBName $iConfPath}
	else 
	{	[String]$Local:QIKey = m~Queue~Bkp~New $iaRepoPath $iPriority $JobType '_'       $iDBName $iConfPath}

	
	[Microsoft.SqlServer.Management.Smo.Server]$SMOSrv = $null;
	[Microsoft.SqlServer.Management.Common.ServerConnection]$SMOCnn = $null;
	. m~SMOSrv~Init~d; # << $iSrvInst

	m~BkpDirData~Deactivate $SMOCnn.TrueName $iDBName $iaRepoPath | % {$MsgCll.Add($_)};

	[hashtable]$BkpFileNamePara = 
    @{  iaRepoPath = $iaRepoPath
    ;   iSrvInst   = $SMOCnn.TrueName
    ;   iDBName    = $iDBName
    ;   iJobType   = $JobType
    #;   iAt        = [datetime]::Now #!!!REM: backup date will written to backup file name after backup process will done.
	};
	
	[String[]]$Local:BkpFilePathArr = m~BkpFilePath~Data~Gen @BkpFileNamePara;
	[Microsoft.SqlServer.Management.Smo.Backup]$Local:SMOBkp = m~BkpDBData~Prep $SMOSrv $iDBName $Local:BkpFilePathArr $fDiff $fCompression $fCopyOnly;
	
	while (m~QueueItem~Exists $iaRepoPath $Local:QIKey 'New') 
	{	Start-Sleep 1}

	if (-not (m~QueueItem~Exists $iaRepoPath $Local:QIKey 'Act'))
	{	$Local:QIKey = [String]::Empty;
		throw [InvalidOperationException]::new('Queue lost.');
	}

	m~QueueItem~Upd $iaRepoPath $Local:QIKey 'Act' @{'V-SrvInst' = $SMOCnn.TrueName};
	#!!!INF: instruction "{$SMOSrv.Databases[$iDBName]}" will not throw exception if can not connect to sql but instruction below will do.
	[Microsoft.SqlServer.Management.Smo.Database]$SMODB = $SMOSrv.Databases | ? {$_.Name -eq $iDBName};
	
	if ($null -eq $Local:SMODB)
	{	throw [Microsoft.SqlServer.Management.Smo.MissingObjectException]::new("Database [$($iDBName.Replace(']', ']]'))] is not found.")}

	if ($fRemoveDB)
	{	if (-not $SMODB.ReadOnly)
		{	$SMODB.ReadOnly = $true;
			$SMODB.Alter([Microsoft.SqlServer.Management.Smo.TerminationClause]::RollbackTransactionsImmediately);
		}
	}
	
	$Local:SMOBkp.SqlBackupAsync($SMOSrv);
	[datetime]$DTChk = [datetime]::Now.AddMinutes(1);

	do 
	{	Start-Sleep 15;
		
		if ($DTChk -le [datetime]::Now)
		{	m~QueueItem~HeartBit $iaRepoPath $Local:QIKey;
			$DTChk = [datetime]::Now.AddMinutes(1);
		}
	}
	while ($Local:SMOBkp.AsyncStatus.ExecutionStatus -eq 'InProgress');

	m~QueueItem~HeartBit $iaRepoPath $Local:QIKey;

	switch -Exact ($Local:SMOBkp.AsyncStatus.ExecutionStatus)
	{	'Failed'
		{	throw $Local:SMOBkp.AsyncStatus.LastException}
		'Succeeded'
		{	break}
		default
		{	throw [Exception]::new("Unknown SMO.Backup state. [$_]")}
	}

	m~QueueItem~StateSet $iaRepoPath $Local:QIKey 'Act' 'Fin';
	
	$BkpInfo = m~BkpFile~SQLHdr~Get $SMOSrv $Local:BkpFilePathArr;
	$BkpFileNamePara['iAt'] = $BkpInfo.PSBackupFinishDate;

	if (-not $fCopyOnly)
	{   $BkpFileNamePara['iArcLayer'] = $iArcLayer}

	[Int32]$Idx = -1;
	
	foreach($BkpFilePathIt in m~BkpFilePath~Data~Gen @BkpFileNamePara)
	{	$Idx++;
		[IO.File]::Move($Local:BkpFilePathArr[$Idx], $BkpFilePathIt);
	}

	if ($fRemoveDB)
	{	$SMOSrv.KillDatabase($iDBName)		
		$SMODB = $null;
	}

	$Local:SMOBkp = $null;
	$Local:QIKey = [String]::Empty;
	$Local:BkpFilePathArr = @();
}
catch 
{	if ($fAsShJob)
	{	~SJLog~MsgException~New Err $LogDate $_ -iLogSrc ($MyInvocation.MyCommand);
		try {~SJLog~Msg~New Err $LogDate $ParamMsgCll -fAsKeyValue -iKey 'param' -iLogSrc ($MyInvocation.MyCommand)} catch {};
	}
	
	throw;
}
finally
{	if (-not [String]::IsNullOrEmpty($Local:QIKey))
	{	try {m~QueueItem~StateSet $iaRepoPath $Local:QIKey 'Nil' 'Err'} catch {}}

	if ($null -ne $Local:SMOBkp)
	{	try 
		{	if ($Local:SMOBkp.AsyncStatus.ExecutionStatus -eq 'InProgress')
			{	$Local:SMOBkp.Abort()}
		} 
		catch {}
	}
	
	<#!!!REM: if this files exists better keep him.
	foreach ($BkpFilePathIt in $Local:BkpFilePathArr)
	{	if ([IO.File]::Exists($BkpFilePathIt))
		{	[IO.File]::Delete($BkpFilePathIt)}
	}
	#>
}}