function ~MSSQLBR~DBDataBkpSmart~Do
{	[CmdletBinding()]param
	(	[parameter(Mandatory=1, position=0)]
			[String]$iSrvInst
	,	[parameter(Mandatory=1, position=1)]
			[String]$iDBName
	,	[parameter(Mandatory=1, position=2)]
			[Uri[]]$iaRepoPath
	,	[parameter(Mandatory=1, position=3)]
			[DateTime]$iStartAt
	,	[parameter(Mandatory=1, position=4)]
			[TimeSpan]$iDuration
	,	[parameter(Mandatory=1)]
		[ValidateRange(0, 1)]
			[Double]$iDiffFullRatioMax
	,	[parameter(Mandatory=1)]
		[ValidateScript( {$_ -ge 1} )]
			[Double]$iDiffSizeFactor
	,	[parameter(Mandatory=0)]
		[ValidateScript( {$_ -gt 0} )]
			[Int64]$iTotalSizeMax = [Int64]::MaxValue
	,	[parameter(Mandatory=0)]
		[ValidateSet('', 'f', 'd', 'df', 'fd')]
			[String]$iOperAllow = [String]::Empty
	,	[parameter(Mandatory=0)]
			[Byte]$iArcLayer = 0
	,	[parameter(Mandatory=0)]
			[Byte]$iPriority = 0
	,	[parameter(Mandatory=0)]
			[switch]$fCompression
	,	[parameter(Mandatory=0)]
			[switch]$fAsShJob
	,	[parameter(Mandatory=0)]
			[String]$iConfPath = [string]::Empty
	);
try
{	[datetime]$LogDate = [datetime]::Now;
	[Collections.Generic.List[String]]$MsgCll = [Collections.Generic.List[String]]::new();
	[String[]]$ParamMsgCll = m~BkpAttr~LogMsg~Gen $iSrvInst $iDBName $iaRepoPath;
	
	[Boolean]$ModeDecision = $false;

	if ('df', 'fd', '' -contains $iOperAllow)
	{	$ModeDecision = $true;
		[Boolean]$BkpDiff = $true;
	}
	elseif ($iOperAllow -eq 'd') 
	{	[Boolean]$BkpDiff = $true}
	elseif ($iOperAllow -eq 'f') 
	{	[Boolean]$BkpDiff = $false}
	else 
	{	throw 'Main logic error!'}
	
	[NMSSQL.MBkpRst.EBkpJobType]$JobType = [NMSSQL.MBkpRst.EBkpJobType]::Data;
	
	Write-Verbose 'Create a queue item.';
	[String]$Local:QIKey = m~Queue~Bkp~New $iaRepoPath $iPriority $JobType $iSrvInst $iDBName $iConfPath;

	Write-Verbose 'Connect to sql server.';
	[Microsoft.SqlServer.Management.Smo.Server]$SMOSrv = $null;
	[Microsoft.SqlServer.Management.Common.ServerConnection]$SMOCnn = $null;
	. m~SMOSrv~Init~d; # << $iSrvInst
	
	[Collections.Generic.List[String]]$BkpOldFilePathCll = @();
	[Int64]$BkpFullSize = 0;
	[Int64]$BkpDiffSize = 0;
	
	Write-Verbose 'Calculate previous backups sizes.';

	foreach ($BkpInfo in m~BkpFileData~Get $iaRepoPath ($SMOCnn.TrueName) $iDBName -iFltLast 1 -iFltBkpJobType 'DBFull' -iFltCopyOnly $false)
	{	$BkpOldFilePathCll.Add($BkpInfo.PSFilePath);
		[datetime]$BkpFullAt = $BkpInfo.PSAt;
	}
	
	if ($BkpOldFilePathCll.Count)
	{	$BkpFullSize = m~BkpFile~SizeGet $BkpOldFilePathCll;
		$BkpOldFilePathCll.Clear()

		foreach ($BkpInfo in m~BkpFileData~Get $iaRepoPath ($SMOCnn.TrueName) $iDBName -iFltLast 1 -iFltAtMin $BkpFullAt -iFltBkpJobType 'DBDiff')
		{	$BkpOldFilePathCll.Add($BkpInfo.PSFilePath)}

		$BkpDiffSize = m~BkpFile~SizeGet $BkpOldFilePathCll;
	}
	
	Write-Verbose ">BkpFullSize = $BkpFullSize #$(m~DHex~ToString $BkpFullSize)";
	Write-Verbose ">BkpDiffSize = $BkpDiffSize #$(m~DHex~ToString $BkpDiffSize)";
	
	[hashtable]$BkpFileNamePara = 
    @{  iaRepoPath = $iaRepoPath
    ;   iSrvInst   = $SMOCnn.TrueName
    ;   iDBName    = $iDBName
	;	iArcLayer  = $iArcLayer
    #;   iAt        = [datetime]::Now #!!!REM: backup date will written to backup file name after backup process will done.
	};
	
	[Boolean]$RedoJob = $true;

	while ($ModeDecision)
	{	Write-Verbose 'I decide what type of backup will be done.';
		
		# OMG! No full backup. So... let fix it.
		if (-not $BkpFullSize)
		{	$BkpDiff = $false;
			break;
		}
		
		if ($BkpDiffSize -ge [Int64]($BkpFullSize * $iDiffFullRatioMax))
		{	$BkpDiff = $false;
			break;
		}

		if ([Int64]($BkpDiffSize * $iDiffSizeFactor) + $BkpFullSize -ge $iTotalSizeMax)
		{	$BkpDiff = $false;
			break;
		}

		$RedoJob = $false;

		break;
	}
	
	Write-Verbose 'Wait in queue.';

	while (m~QueueItem~Exists $iaRepoPath $Local:QIKey 'New') 
	{	Start-Sleep 1}

	Write-Verbose 'Wait finished.';

	while ($true)
	{	if ($BkpDiff) 
		{	Write-Verbose 'I will perform diff backup.';
			[NMSSQL.MBkpRst.EBkpJobType]$JobType = [NMSSQL.MBkpRst.EBkpJobType]::DBDiff;
		} 
		else 
		{	Write-Verbose 'I will perform full backup.';
			[NMSSQL.MBkpRst.EBkpJobType]$JobType = [NMSSQL.MBkpRst.EBkpJobType]::DBFull;
		}

		$BkpFileNamePara['iJobType'] = $JobType;
		
		[String[]]$BkpFilePathArr = m~BkpFilePath~Data~Gen @BkpFileNamePara;
		[Microsoft.SqlServer.Management.Smo.Backup]$Local:SMOBkp = m~BkpDBData~Prep $SMOSrv $iDBName $BkpFilePathArr $BkpDiff $fCompression;
				
		if (-not (m~QueueItem~Exists $iaRepoPath $Local:QIKey 'Act'))
		{	throw [InvalidOperationException]::new('Queue lost.')}

		m~QueueItem~Upd $iaRepoPath $Local:QIKey 'Act' @{'V-SrvInst' = $SMOCnn.TrueName; 'V-JobType' = $JobType};

		Write-Verbose 'Backup process started.';
		$Local:SMOBkp.SqlBackupAsync($SMOSrv);
		[datetime]$DTChk = [datetime]::Now.AddMinutes(1);

		if ($RedoJob)
		{	do
			{	Start-Sleep 15;
				
				if ($DTChk -le [datetime]::Now)
				{	m~QueueItem~HeartBit $iaRepoPath $Local:QIKey;
					$DTChk = [datetime]::Now.AddMinutes(1);
				}
			} while ($Local:SMOBkp.AsyncStatus.ExecutionStatus -eq 'InProgress');
		
			Write-Verbose 'Backup process completed.';
			m~QueueItem~HeartBit $iaRepoPath $Local:QIKey;
			break;
		}
		
		[Boolean]$BkpProcess = $true;

		while ($BkpProcess)
		{	Start-Sleep 15;
			
			if ($DTChk -le [datetime]::Now)
			{	m~QueueItem~HeartBit $iaRepoPath $Local:QIKey;
				$DTChk = [datetime]::Now.AddMinutes(1);
			}

			$BkpProcess = ($Local:SMOBkp.AsyncStatus.ExecutionStatus -eq 'InProgress');
			
			if (([Int64]$BkpSize = m~BkpFile~SizeGet $BkpFilePathArr))
			{	if (-not $BkpDiff)
				{	throw 'Main logic error!'}

				$BkpDiffSize = $BkpSize;
				#Write-Host ">BkpSize = $BkpSize #$(m~DHex~ToString $BkpSize)";

				if ($BkpDiffSize -ge [Int64]($BkpFullSize * $iDiffFullRatioMax) -or [Int64]($BkpDiffSize * $iDiffSizeFactor) + $BkpFullSize -ge $iTotalSizeMax)
				{	$Local:SMOBkp.Abort();
					$BkpProcess = $false;
					$RedoJob = $true;
					
					Write-Verbose 'Backup process aborted.';			
					break;
				}
			}
		}

		if (-not $RedoJob)
		{	Write-Verbose 'Backup process completed.';
			break;
		}

		$BkpDiff = $false;
		
		if ($Local:SMOBkp.AsyncStatus.ExecutionStatus -eq 'InProgress')
		{	$Local:SMOBkp.Wait();
			m~QueueItem~HeartBit $iaRepoPath $Local:QIKey;
		}
		
		foreach ($BkpFilePathIt in $BkpFilePathArr)
		{	if ([IO.File]::Exists($BkpFilePathIt))
			{	[IO.File]::Delete($BkpFilePathIt)}
		}

		$BkpFilePathArr = @();

		m~QueueItem~HeartBit $iaRepoPath $Local:QIKey;
	}

	switch -Exact ($Local:SMOBkp.AsyncStatus.ExecutionStatus)
	{	'Failed'
		{	throw $Local:SMOBkp.AsyncStatus.LastException}
		'Succeeded'
		{	break}
		default
		{	throw [Exception]::new("Unknown SMO.Backup state. [$_]")}
	}
	
	if ($BkpDiff)
	{	$BkpDiffSize = m~BkpFile~SizeGet $BkpFilePathArr}
	else
	{	$BkpDiffSize = 0;
		$BkpFullSize = m~BkpFile~SizeGet $BkpFilePathArr;
	}

	Write-Verbose ">BkpFullSize = $BkpFullSize #$(m~DHex~ToString $BkpFullSize)";
	Write-Verbose ">BkpDiffSize = $BkpDiffSize #$(m~DHex~ToString $BkpDiffSize)";

	if ($BkpDiff -and $BkpFullSize -eq 0)
	{	$MsgCll.Add('No full backup found.')}

	if ($BkpDiffSize -ge [Int64]($BkpFullSize * $iDiffFullRatioMax))
	{	$MsgCll.Add('Diff backup is too large.')}

	if ([Int64]($BkpDiffSize * $iDiffSizeFactor) + $BkpFullSize -ge $iTotalSizeMax)
	{	$MsgCll.Add('Total (diff+full) backup is too large.')}

	if ($iStartAt + $iDuration -lt [datetime]::now)
	{	$MsgCll.Add('Backup process is not fit into the time window.')}
	
	Write-Verbose 'Release queue item.';

	if ($MsgCll.Count)
	{	m~QueueItem~Upd $iaRepoPath $Local:QIKey 'Act' @{'L-Msg' = $MsgCll.ToArray()};
		$MsgCll.Clear();
		m~QueueItem~StateSet $iaRepoPath $Local:QIKey 'Act' 'Wrn';
	}
	else 
	{	m~QueueItem~StateSet $iaRepoPath $Local:QIKey 'Act' 'Fin'}
	
	$BkpInfo = m~BkpFile~SQLHdr~Get $SMOSrv $BkpFilePathArr;
	$BkpFileNamePara['iAt'] = $BkpInfo.PSBackupStartDate;
	[Int32]$Idx = -1;
	
	foreach($BkpFilePathIt in m~BkpFilePath~Data~Gen @BkpFileNamePara)
	{	$Idx++;
		[IO.File]::Move($BkpFilePathArr[$Idx], $BkpFilePathIt);
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
		
	if ($fAsShJob -and $null -ne $MsgCll -and $MsgCll.Count)
	{	~SJLog~Msg~New Wrn $LogDate ($MsgCll.ToArray()) -iLogSrc ($MyInvocation.MyCommand)}
	
	<#!!!REM: if this files exists better keep him.
	foreach ($BkpFilePathIt in $Local:BkpFilePathArr)
	{	if ([IO.File]::Exists($BkpFilePathIt))
		{	[IO.File]::Delete($BkpFilePathIt)}
	}
	#>
}}