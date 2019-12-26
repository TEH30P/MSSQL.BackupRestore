New-Alias -Name Restore-MSSQLDB -Value '~MSSQLBR~DBRstSmart~Do' -Force;

# Nice and sweet database restore.
function ~MSSQLBR~DBRstSmart~Do
{	[CmdletBinding()]param
	(	[parameter(Mandatory=1, position=0)]
			[Uri[]]$iaRepoPath
	,	[parameter(Mandatory=1, position=1)]
			[string]$iSrvInstSrc
	,   [parameter(Mandatory=1, position=2)]
			[String]$iDBNameSrc
	,	[parameter(Mandatory=1, position=3)]
			[Object]$iSrvInst
	,   [parameter(Mandatory=1, position=4)]
			[String]$iDBName
	,   [parameter(Mandatory=0, position=5)]
			[DateTime]$iTimeTrg = [DateTime]::MaxValue
	,   [parameter(Mandatory=0)]
			[Byte]$iPriority = 0
	,   [parameter(Mandatory=0)]
			[ValidateSet('', 'f', 'df', 'fd', 'fl', 'lf', 'dfl', 'fdl', 'ldf', 'd', 'l', 'dl', 'ld')]
			[String]$iOperAllow = 'fd'
	,   [parameter(Mandatory=0)]
			[switch]$fStandby
	,	[parameter(Mandatory=0)]
			[switch]$fNoRecovery
	,	[parameter(Mandatory=0)]
			[switch]$fReplace
	,	[parameter(Mandatory=0)]
			[switch]$fPointInTime
	,   [parameter(Mandatory=0)]
			[switch]$fAsShJob
	,	[parameter(Mandatory=0)]
			[String]$iConfPath = [string]::Empty
	,	[parameter(Mandatory = 0, ValueFromPipeline = 1)]
			[psobject[]]$iaDBFileReloc
	
	)
begin
{	[datetime]$LogDate = [datetime]::Now;
	[System.Collections.Generic.List[NMSSQL.MBkpRst.CDBFileReloc]]$DBFRelocCll = @();
	[String[]]$ParamMsgCll = m~RstAttr~LogMsg~Gen $iaRepoPath $iSrvInst $iDBName $iSrvInstSrc $iDBNameSrc;
}
process
{	if ($null -ne $iaDBFileReloc)
	{	$iaDBFileReloc | % {[Void]$DBFRelocCll.Add($_)}}
}
end
{	try 
	{	# Some Relocation management.
		
		[NMSSQL.MBkpRst.CDBFileReloc[]]$DBFRelocCll = `
			for([Int32]$k = $DBFRelocCll.Count; ($k--);)
			{	$DBFRelocCll[$k]}
		;
		
		Write-Verbose 'Connect to sql server.';
		[Microsoft.SqlServer.Management.Common.ServerConnection]$SMOCnn = $null;
		[Microsoft.SqlServer.Management.Smo.Server]$SMOSrv = $null;
		. m~SMOSrv~Init~d; # << $iSrvInst

		if ($fReplace)
		{	[Nullable[Decimal]]$LsnLast = $null}
		else 
		{	[Nullable[Decimal]]$LsnLast = m~RstDB~RedoLsn~Get $SMOCnn $iDBName}
		
		[Nullable[DateTime]]$AtLast = $null;

		#
		Write-Verbose 'Collecting required data backup files.';
		#

		[Collections.ArrayList]$BkpFullInfoCll = @();
		[Collections.ArrayList]$BkpDiffInfoCll = @();
		[Collections.ArrayList]$BkpRowsInfoCll = $null;
		
		foreach ($BkpJobType in 'DBFull', 'DBDiff')
		{	if ($BkpJobType -eq 'DBFull')
			{	if ($iOperAllow.Contains('f'))
				{	$BkpRowsInfoCll = $BkpFullInfoCll}
				else 
				{	continue}
			}
			
			if ($BkpJobType -eq 'DBDiff')
			{	if ($iOperAllow.Contains('d'))
				{	$BkpRowsInfoCll = $BkpDiffInfoCll}
				else 
				{	continue}
			}

			foreach($BkpInfo in m~BkpFileData~Get $iaRepoPath $iSrvInstSrc $iDBNameSrc -iFltLast 1 -iFltBkpJobType $BkpJobType -iFltCopyOnly $false -iFltAtMin $AtLast -iFltAtMax $iTimeTrg)
			{	[Void]$BkpRowsInfoCll.Add($BkpInfo);
				$AtLast = $BkpInfo.PSAt;
			}
		}

		if ($null -eq $LsnLast)
		{	if (-not $BkpFullInfoCll.Count)
			{	throw [IO.FileNotFoundException]::new('Full database backup is not found.')}
		}
		else
		{	foreach ($BkpJobType in 'DBFull', 'DBDiff')
			{	if ($BkpJobType -eq 'DBFull')
				{	if ($iOperAllow.Contains('f'))
					{	$BkpRowsInfoCll = $BkpFullInfoCll}
					else 
					{	continue}
				}
				
				if ($BkpJobType -eq 'DBDiff')
				{	if ($iOperAllow.Contains('d'))
					{	$BkpRowsInfoCll = $BkpDiffInfoCll}
					else 
					{	continue}
				}
	
				if (-not $BkpRowsInfoCll.Count)
				{	continue}

				[psobject]$BkpLastHdr = m~BkpFile~SQLHdr~Get $SMOSrv ($BkpRowsInfoCll.PSFilePath);

				if ($BkpLastHdr.PSLastLSN -eq $LsnLast)
				{	if ($BkpJobType -eq 'DBDiff')
					{	$BkpFullInfoCll.Clear()}
					
					$BkpRowsInfoCll.Clear();
				}
				elseif ($BkpLastHdr.PSLastLSN -gt $LsnLast)
				{	$LsnLast = $BkpLastHdr.PSLastLSN}
				else 
				{	$BkpRowsInfoCll.Clear()}
			}
		}

		#
		Write-Verbose 'Collecting required tlog backup files';
		#

		[System.Collections.ArrayList]$BkpTLogInfoCll = @();
		
		if (-not $iOperAllow.Contains('l'))
		{	if ($null -eq $AtLast)
			{	throw [IO.FileNotFoundException]::new('Full/Diff database backup is not found.')}
			
			[DateTime]$BkpAt = $AtLast;
		}
		else
		{	if ($null -eq $LsnLast)
			{	if ($BkpDiffInfoCll.Count)
				{	[psobject]$BkpLastHdr = m~BkpFile~SQLHdr~Get $SMOSrv ($BkpDiffInfoCll[0].PSFilePath)}
				elseif ($BkpFullInfoCll.Count)
				{	[psobject]$BkpLastHdr = m~BkpFile~SQLHdr~Get $SMOSrv ($BkpFullInfoCll[0].PSFilePath)}
				else 
				{	throw [IO.FileNotFoundException]::new('Full/Diff database backup is not found.')}

				$LsnLast = $BkpLastHdr.PSLastLSN;
			}
						
			[Boolean]$TLogChained = $false;
			[psobject]$BkpTLogLastHdr = $null;
			
			foreach ($BkpInfo in m~BkpFileTLog~Get $iaRepoPath $iSrvInstSrc $iDBNameSrc -iFltLast $null -iFltCopyOnly $false -iFltAtMax $iTimeTrg)
			{	if (-not $TLogChained)
				{	if ($BkpInfo.PSLSNLast -ge $LsnLast)
					{	$BkpTLogLastHdr = m~BkpFile~SQLHdr~Get $SMOSrv ($BkpInfo.PSFilePath);
						
						if ($BkpTLogLastHdr.PSFirstLSN -le $LsnLast)
						{	$TLogChained = $true;
							$AtLast = $BkpInfo.PSAt;
							[Void]$BkpTLogInfoCll.Add($BkpInfo);
						}
						else 
						{	break}
					}
				}
				else 
				{	$AtLast = $BkpInfo.PSAt;
					[Void]$BkpTLogInfoCll.Add($BkpInfo);
				}
			}

			if (-not $fPointInTime)
			{	foreach ($BkpInfo in m~BkpFileTLog~Get $iaRepoPath $iSrvInstSrc $iDBNameSrc -iFltLast 1 -iFltAtMin $AtLast -iFltAtMax $iTimeTrg -iFltCopyOnly $true)
				{	[Void]$BkpTLogInfoCll.Add($BkpInfo)
					$AtLast = $BkpInfo.PSAt;
				}

				[DateTime]$BkpAt = $AtLast;
			}
			else
			{	[Boolean]$PointInTime = $false;
				
				foreach ($BkpInfo in m~BkpFileTLog~Get $iaRepoPath $iSrvInstSrc $iDBNameSrc -iFltAtMin $AtLast)
				{	if ($BkpInfo.PSAt -lt $iTimeTrg)
					{	continue}
					elseif (-not $PointInTime)
					{	$PointInTime = $true;						
						$AtLast = $BkpInfo.PSAt;
					}
					elseif ($AtLast -ne $BkpInfo.PSAt)
					{	break}

					[Void]$BkpTLogInfoCll.Add($BkpInfo)
				}
			
				if (-not $PointInTime)
				{	throw [IO.FileNotFoundException]::new('Can''t find the suitable t-log backup for Point-in-Time restore.')}
	
				[DateTime]$BkpAt = $iTimeTrg;
			}
		}
		
		#
		Write-Verbose 'Restoring db from collected backup files.';
		#
		
		[DateTime]$Now = [DateTime]::Now;
		[Int32]$BkpIdx = -2;
		[Int32]$BkpCnt = $BkpTLogInfoCll.Count;
		[Int32]$WaitDurationSec = 60;
		[Boolean]$RstNoRecovery = $true;
		[Boolean]$RstStandby = $false;
		[Boolean]$RstReplace = $fReplace;
		[Microsoft.SqlServer.Management.Smo.RestoreActionType]$RstAct = 'Database';

		if (-not $BkpCnt)
		{	if (-not $BkpDiffInfoCll.Count)
			{	$BkpCnt = -1}
		}

		<#!!!:INF: I loop thru all backups by index in "$BkpIdx".
			* -2: full backup
			* -1: diff backup (if it exist)
			* 0...: all tlog backups
		#>		

		[System.Collections.Generic.List[String]]$BkpFileCll = [System.Collections.Generic.List[String]]::new($BkpFullInfoCll.Count);
		
		if (-not $iOperAllow.Contains('l'))
		{	$Local:QIKeyJobType = 'Data'}
		
		if ($iSrvInst -is [String])
		{	[String]$Local:QIKeySrvInst = $iSrvInst}
		else
		{	[String]$Local:QIKeySrvInst = ' '}		
		
		Write-Verbose 'Create a queue item.';
		[String]$Local:QIKey = m~Queue~Rst~New $iaRepoPath $iPriority $Local:QIKeyJobType $Local:QIKeySrvInst $iDBName $iSrvInstSrc $iDBNameSrc $iConfPath;
		
		while (m~QueueItem~Exists $iaRepoPath $Local:QIKey 'New') 
		{	Start-Sleep 1}
	
		if (-not (m~QueueItem~Exists $iaRepoPath $Local:QIKey 'Act'))
		{	$Local:QIKey = [String]::Empty;
			throw [InvalidOperationException]::new('Queue lost.');
		}

		do 
		{	[void]$BkpFileCll.Clear();

			if ($BkpIdx -ge 0)
			{	if ($BkpIdx -eq 0)
				{	$RstAct = 'Log';
					$WaitDurationSec = 15;
				}
				
				[DateTime]$BkpCurrAt = $BkpTLogInfoCll[$BkpIdx].PSAt;
				[void]$BkpFileCll.Add($BkpTLogInfoCll[$BkpIdx].PSFilePath);

				while ((++$BkpIdx) -lt $BkpTLogInfoCll.Count)
				{	if ($BkpTLogInfoCll[$BkpIdx].PSAt -eq $BkpCurrAt)
					{	[void]$BkpFileCll.Add($BkpTLogInfoCll[$BkpIdx].PSFilePath)}
					else
					{	break}
				}
			}
			elseif ($BkpIdx -eq -2)
			{	$BkpIdx++;

				if (-not $BkpFullInfoCll.Count)
				{	continue}
				
				$BkpFullInfoCll | % {[void]$BkpFileCll.Add($_.PSFilePath)};
			}
			elseif ($BkpIdx -eq -1)
			{	$BkpIdx++;
				
				if (-not $BkpDiffInfoCll.Count)
				{	continue}
				
				$WaitDurationSec = 15;
				$BkpDiffInfoCll | % {[void]$BkpFileCll.Add($_.PSFilePath)};
			}
			
			if ($BkpIdx -eq $BkpCnt)
			{	$RstNoRecovery = $fNoRecovery;
				$RstStandby = $fStandby;
				
				if ($PointInTime)
				{	[DateTime]$DTPointInTime = $iTimeTrg}
			}
			
			[Microsoft.SqlServer.Management.Smo.Restore]$Local:SMORst = m~RstDB~Prep `
				$RstAct `
				$SMOSrv `
				($BkpFileCll.ToArray()) `
				$RstReplace `
				$RstNoRecovery `
				$RstStandby `
				$DBFRelocCll `
				$iSrvInstSrc `
				$iDBNameSrc `
				$iDBName `
				$Local:DTPointInTime `
				$BkpAt `
				$Now;
			
			
			Write-Verbose ">BkpFile: $(if ($RstReplace) {'RP'} else {'__'}) $(if ($RstNoRecovery) {'NR'} else {'__'}) ;$($BkpFileCll[0])";
			$RstReplace = $false;
			Write-Verbose 'Restore process started.';
			$SMORst.SqlRestoreAsync($SMOSrv);

			m~QueueItem~HeartBit $iaRepoPath $Local:QIKey;
			[datetime]$DTChk = [datetime]::Now.AddMinutes(1);
			
			Start-Sleep 1;

			while ($Local:SMORst.AsyncStatus.ExecutionStatus -eq 'InProgress')
			{	Start-Sleep $WaitDurationSec;
				
				if ($DTChk -le [datetime]::Now)
				{	m~QueueItem~HeartBit $iaRepoPath $Local:QIKey;
					$DTChk = [datetime]::Now.AddMinutes(1);
				}
			}
			
			Write-Verbose 'Restore process completed.';

			switch -Exact ($Local:SMORst.AsyncStatus.ExecutionStatus)
			{	'Failed'
				{	throw $Local:SMORst.AsyncStatus.LastException}
				'Succeeded'
				{	break}
				default
				{	throw [Exception]::new("Unknown SMO.Restore state. [$_]")}
			}

			$Local:SMORst = $null;
		} while($BkpIdx -lt $BkpCnt)
		
		Write-Verbose 'Release queue item.';
		m~QueueItem~StateSet $iaRepoPath $Local:QIKey 'Act' 'Fin'; $Local:QIKey = [String]::Empty;
	}
	catch 
	{	if ($fAsShJob)
		{	~SJLog~MsgException~New Err $LogDate $_ -iLogSrc ($MyInvocation.MyCommand);
			try {~SJLog~Msg~New Err $LogDate $ParamMsgCll -fAsKeyValue -iKey 'param' -iLogSrc ($MyInvocation.MyCommand)} catch {};
		}

		throw
	}
	finally
	{	if (-not [String]::IsNullOrEmpty($Local:QIKey))
		{	try {m~QueueItem~StateSet $iaRepoPath $Local:QIKey 'Nil' 'Err'} catch {}}

		if ($null -ne $Local:SMORst)
		{	try 
			{	if ($Local:SMORst.AsyncStatus.ExecutionStatus -eq 'InProgress')
				{	$Local:SMORst.Abort()}
			}
			catch {}
		}
	}
}
}
