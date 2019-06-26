New-Alias -Name Backup-MSSQLDBTLog -Value '~MSSQLBR~TlogBkp~Do' -Force;

# DB TLog backup process.
function ~MSSQLBR~TlogBkp~Do
{	[CmdletBinding()]param 
	(	[parameter(Mandatory=1, position=0)]
			[Object]$iSrvInst
	,	[parameter(Mandatory=1, position=1)]
			[String]$iDBName
	,	[parameter(Mandatory=1, position=2)]
			[Uri[]]$iaRepoPath
	,   [parameter(Mandatory=0)]
			[Byte]$iPriority = 0
	,	[parameter(Mandatory=0)]
			[switch]$fCompression = $true
	,	[parameter(Mandatory=0)]
			[switch]$fCopyOnly
	,   [parameter(Mandatory=0)]
			[switch]$fAsShJob
	,   [parameter(Mandatory=0)]
			[String]$iConfPath = [string]::Empty
	);
try
{	[datetime]$LogDate = [datetime]::Now;
	[Collections.Generic.List[String]]$MsgCll = [Collections.Generic.List[String]]::new();
	[String[]]$ParamMsgCll = m~BkpAttr~LogMsg~Gen $iSrvInst $iDBName $iaRepoPath;

	[NMSSQL.MBkpRst.EBkpJobType]$JobType = [NMSSQL.MBkpRst.EBkpJobType]::TLog;

	if ($iSrvInst -is [String])
	{	[String]$Local:QIKey = m~Queue~Bkp~New $iaRepoPath $iPriority $JobType $iSrvInst $iDBName $iConfPath}
	else 
	{	[String]$Local:QIKey = m~Queue~Bkp~New $iaRepoPath $iPriority $JobType '_'       $iDBName $iConfPath}

	[Microsoft.SqlServer.Management.Smo.Server]$SMOSrv = $null;
	[Microsoft.SqlServer.Management.Common.ServerConnection]$SMOCnn = $null;
	. m~SMOSrv~Init~d; # << $iSrvInst
	
	m~BkpDirTLog~Deactivate $SMOCnn.TrueName $iDBName $iaRepoPath | % {$MsgCll.Add($_)};

	[hashtable]$BkpFileNamePara = 
	@{  iaRepoPath = $iaRepoPath
	;   iSrvInst   = $SMOCnn.TrueName
	;   iDBName    = $iDBName
	;	iLSNLast   = [Decimal]('9' * 25)
	#;   iAt        = [datetime]::Now #!!!REM: backup date will written to backup file name after backup process will done.
	};

	[String[]]$Local:BkpFilePathArr = m~BkpFilePath~TLog~Gen @BkpFileNamePara;
	[Microsoft.SqlServer.Management.Smo.Backup]$Local:SMOBkp = m~BkpTlog~Prep $SMOSrv $iDBName $Local:BkpFilePathArr $fCompression $fCopyOnly;
	
	while (m~QueueItem~Exists $iaRepoPath $Local:QIKey 'New') 
	{	Start-Sleep 1}

	if (-not (m~QueueItem~Exists $iaRepoPath $Local:QIKey 'Act'))
	{	$Local:QIKey = [String]::Empty;
		throw [InvalidOperationException]::new('Queue lost.');
	}

	m~QueueItem~Upd $iaRepoPath $Local:QIKey 'Act' @{'V-SrvInst' = $SMOCnn.TrueName};

	#!!!TODO: Move this block to dedicated function.
	$Local:SMOBkp.SqlBackupAsync($SMOSrv);
	[datetime]$DTChk = [datetime]::Now.AddMinutes(1);

	do 
	{	Start-Sleep 3;
		
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
	
	$Local:SMOBkp = $null;

	if ($MsgCll.Count)
	{	m~QueueItem~StateSet $iaRepoPath $Local:QIKey 'Act' 'Wrn'}
	else 
	{	m~QueueItem~StateSet $iaRepoPath $Local:QIKey 'Act' 'Fin'}

	$BkpInfo = m~BkpFile~SQLHdr~Get $SMOSrv $Local:BkpFilePathArr;
	$BkpFileNamePara['iAt'] = $BkpInfo.PSBackupFinishDate;

	if ($fCopyOnly)
	{	$BkpFileNamePara.Remove('iLSNLast')}
	else 
	{   $BkpFileNamePara['iLSNLast'] = $BkpInfo.PSLastLSN}
	
	[Int32]$Idx = -1;
	
	foreach($BkpFilePathIt in m~BkpFilePath~TLog~Gen @BkpFileNamePara)
	{	$Idx++;
		[IO.File]::Move($Local:BkpFilePathArr[$Idx], $BkpFilePathIt);
	}
	
	$Local:BkpFilePathArr = @();
	$Local:QIKey = [String]::Empty;
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
	
	foreach ($BkpFilePathIt in $Local:BkpFilePathArr)
	{	if ([IO.File]::Exists($BkpFilePathIt))
		{	[IO.File]::Delete($BkpFilePathIt)}
	}
}} 