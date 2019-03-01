# DB TLog backup process. Smart and tricky.
function ~MSSQLBR~TLogBkpSmart~Do
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
		[ValidateScript({$_ -ge 0})]
			[TimeSpan]$iDuration
	,	[parameter(Mandatory=0)]
		[ValidateScript({$_ -gt [timespan]::Zero})]
			[TimeSpan]$iAgeTrg = [timespan]::Zero
	,	[parameter(Mandatory=0)]
		[ValidateScript({$_ -ge 0})]
			[Int64]$iUsageMinTrg = 0
	,	[parameter(Mandatory=0)]
		[ValidateScript({$_ -gt 0})]
			[Int64]$iUsageMaxTrg = [Int64]::MaxValue
	,	[parameter(Mandatory=0)]
			[TimeSpan]$iChkPeriod = [timespan]::Zero
	,	[parameter(Mandatory=0)]
			[Byte]$iPriority = 0
	,	[parameter(Mandatory=0)]
			[switch]$fCompression
	,   [parameter(Mandatory=0)]
			[switch]$fAsShJob
	,	[parameter(Mandatory=0)]
			[String]$iConfPath = [string]::Empty
	);
try 
{	[datetime]$LogDate = [datetime]::Now;
	[Collections.Generic.SortedSet[String]]$ModeCll = [Collections.Generic.SortedSet[String]]::new();
	[Collections.Generic.List[String]]$MsgCll = [Collections.Generic.List[String]]::new();

	[String[]]$ParamMsgCll = m~BkpAttr~LogMsg~Gen $iSrvInst $iDBName $iaRepoPath;

	if ($iUsageMinTrg -gt 0)
	{	[Void]$ModeCll.Add('ChkUsedSpace');
		[Void]$ModeCll.Add('DoCopyOnlyBkp');
	}

	if ($iUsageMaxTrg -lt [Int64]::MaxValue)
	{	[Void]$ModeCll.Add('ChkUsedSpace');
		[Void]$ModeCll.Add('DoEarlyBkp');
	}

	if ($iAgeTrg -gt [TimeSpan]::Zero)
	{	[Void]$ModeCll.Add('ChkBkpAge')}

	if ($iChkPeriod -gt [TimeSpan]::Zero)
	{	if (-not $ModeCll.Contains('ChkUsedSpace'))
		{	throw [ArgumentException]::new('Parameter prohibited when "iUsageMaxTrg" and "iUsageMinTrg" is not passed.', 'iChkPeriod')}

		if ($iAgeTrg.Ticks % $iChkPeriod.Ticks)
		{	throw [ArgumentException]::new('The time periods which represents by "iChkPeriod" and "iAgeTrg" is not overlap.', 'iChkPeriod')}

		[timespan]$Period = $iChkPeriod;
	}
	else
	{	[timespan]$Period = $iAgeTrg
	
        if ($ModeCll.Contains('DoCopyOnlyBkp'))
		{	[Void]$ModeCll.Remove('ChkBkpAge')}   
		elseif ($ModeCll.Contains('ChkBkpAge') -and $ModeCll.Contains('DoEarlyBkp'))
		{	throw [ArgumentException]::new('Parameter required when "iUsageMinTrg", "iUsageMaxTrg" and "iAgeTrg" is passed.', 'iChkPeriod')}
    }
	
	if ($ModeCll.Count -eq 1)
	{	$ModeCll.Remove('ChkBkpAge')}
	
	[Boolean]$DoInit = $true;
	[Int32]$ErrCnt = 0;
	[Int32]$WrnCnt = 0;
	[NMSSQL.MBkpRst.EBkpJobType]$JobType = [NMSSQL.MBkpRst.EBkpJobType]::TLog;
	[datetime]$StartIt = $iStartAt;
	
	Write-Verbose 'Startind loop.';

	while ([datetime]::Now -lt $iStartAt + $iDuration)
	{	[Int32]$SleepSs = ($StartIt - [datetime]::Now).TotalSeconds + 0.5;

		if ($SleepSs -gt 0)
		{	Start-Sleep -Seconds $SleepSs}

		if ($DoInit)
		{	Write-Verbose 'Create a queue item.';

			[String]$Local:QIKey = m~Queue~Bkp~New $iaRepoPath $iPriority $JobType $iSrvInst $iDBName $iConfPath;
		
			[Microsoft.SqlServer.Management.Smo.Server]$SMOSrv = $null;
			[Microsoft.SqlServer.Management.Common.ServerConnection]$SMOCnn = $null;
			. m~SMOSrv~Init~d; # << $iSrvInst

			[String[]]$BkpFilePathArr = @();
			[Microsoft.SqlServer.Management.Smo.Backup]$Local:SMOBkp = $null;

			Write-Verbose 'Connect to sql server.';
			$SMOCnn.Connect();

			$BkpFilePathArr = m~BkpFileTLog~Get $iaRepoPath ($SMOCnn.TrueName) $iDBName -iFltLast 1 | % {$_.PSFilePath};
			
			if ($BkpFilePathArr.Count)
			{	$BkpInfoLast = m~BkpFile~SQLHdr~Get $SMOSrv $BkpFilePathArr}
			else 
			{	$BkpInfoLast = New-Object psobject -Property @{PSBackupStartDate = ([datetime]::Now - $iAgeTrg); PSLastLSN = ([decimal]::Zero)}}
		}
		
		try 
		{	if (-not $DoInit)
			{	Write-Verbose 'Create a queue item.';
				$Local:QIKey = m~Queue~Bkp~New $iaRepoPath $iPriority $JobType ($SMOCnn.TrueName) $iDBName $iConfPath;
			}
			
			m~BkpDirTLog~Deactivate $SMOCnn.TrueName $iDBName $iaRepoPath | % {$MsgCll.Add($_)};	

			#
			# Here I make decition what to do.
			#

			[Boolean]$DoBkp = -not $ModeCll.Count;
			[Boolean]$BkpCopyOnly = $false;

			if ($ModeCll.Contains('ChkBkpAge'))
			{	$DoBkp = $DoBkp -or ($BkpInfoLast.PSBackupStartDate + $iAgeTrg -le [datetime]::Now + [timespan]($Period.Ticks -shr 1))
                Write-Verbose ">Now       = $(Get-Date -f 'yyyy-MM-dd HH:mm:ss')";
                Write-Verbose ">LastBkpAt = $($BkpInfoLast.PSBackupStartDate.ToString('yyyy-MM-dd HH:mm:ss'))";
			}
			elseif ($ModeCll.Contains('DoCopyOnlyBkp')) 
			{	$DoBkp = $true}

			if ($ModeCll.Contains('ChkUsedSpace'))
			{	[Int64]$UsedSpace = m~SQL~DBTLogSpace~Get $SMOCnn $iDBName;
				Write-Verbose ">LogUsedSpace = $UsedSpace #$(m~DHex~ToString $UsedSpace)";
			}
			
			if (-not $DoBkp -and $ModeCll.Contains('DoEarlyBkp'))
			{	$DoBkp = ($UsedSpace -ge $iUsageMaxTrg)}
			
			if ($DoBkp -and $ModeCll.Contains('DoCopyOnlyBkp'))
			{	$BkpCopyOnly = ($UsedSpace -lt $iUsageMinTrg)}

			#
			# #
			#

			if ($DoBkp)
			{	if ($BkpCopyOnly)
				{	Write-Verbose 'Perform copy-only backup.'}
				else
				{	Write-Verbose 'Perform backup.'}
				
				[hashtable]$BkpFileNamePara = 
				@{  iaRepoPath = $iaRepoPath
				;   iSrvInst   = $SMOCnn.TrueName
				;   iDBName    = $iDBName
				;	iLSNLast   = [Decimal]('9' * 25)
				#;   iAt        = [datetime]::Now #!!!REM: backup date will written to backup file name after backup process will done.
				};
				
				$BkpFilePathArr = m~BkpFilePath~TLog~Gen @BkpFileNamePara;
				$Local:SMOBkp = m~BkpTlog~Prep $SMOSrv $iDBName $BkpFilePathArr $fCompression $BkpCopyOnly;
			}

			Write-Verbose 'Wait in queue.';

			while (m~QueueItem~Exists $iaRepoPath $Local:QIKey 'New') 
			{	Start-Sleep 1}
		
			if (-not (m~QueueItem~Exists $iaRepoPath $Local:QIKey 'Act'))
			{	$Local:QIKey = [String]::Empty;
				throw [InvalidOperationException]::new('Queue lost.');
			}
			
			Write-Verbose 'Wait finished.';

			if ($Init)
			{	m~QueueItem~Upd $iaRepoPath $Local:QIKey 'Act' @{'V-SrvInst' = $SMOCnn.TrueName}}

			if (-not $DoBkp)
			{	Write-Verbose 'No backup.';
				m~QueueItem~StateSet $iaRepoPath $Local:QIKey 'Act' 'Fin';
			}
			else
			{	Write-Verbose 'Backup process started.';
				
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
			
				Write-Verbose 'Backup process completed.';

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

				Write-Verbose 'Release queue item.';

				if ($MsgCll.Count)
				{	m~QueueItem~StateSet $iaRepoPath $Local:QIKey 'Act' 'Wrn'}
				else 
				{	m~QueueItem~StateSet $iaRepoPath $Local:QIKey 'Act' 'Fin'}
				
				Write-Verbose 'Read bkp hdr to perform renames and validation.';

				$BkpInfo = m~BkpFile~SQLHdr~Get $SMOSrv $BkpFilePathArr;
				$BkpFileNamePara['iAt'] = $BkpInfo.PSBackupFinishDate;
			
				if ($BkpCopyOnly)
				{	$BkpFileNamePara.Remove('iLSNLast')}
				else 
				{   $BkpFileNamePara['iLSNLast'] = $BkpInfo.PSLastLSN}
				
				[Int32]$Idx = -1;
				
				foreach($BkpFilePathIt in m~BkpFilePath~TLog~Gen @BkpFileNamePara)
				{	$Idx++;
					[IO.File]::Move($BkpFilePathArr[$Idx], $BkpFilePathIt);
				}
				
				$BkpFilePathArr = @();
				
				if ($BkpInfoLast.PSLastLSN -lt $BkpInfo.PSFirstLSN)
				{	if (-not $MsgCll.Count)
					{	m~QueueItem~StateSet $iaRepoPath $Local:QIKey 'Fin' 'Wrn'}

					$MsgCll.Add('Backup chain broken. Possibly some other t-log backup files is missing.')
				}

				$BkpInfoLast = $BkpInfo;
			}
			
			$DoInit = $false;
		}
		catch 
		{	if ($fAsShJob)
			{	~SJLog~MsgException~New Err $LogDate $_ -iLogSrc ($MyInvocation.MyCommand)}
			
			if (-not [String]::IsNullOrEmpty($Local:QIKey))
			{	try {m~QueueItem~StateSet $iaRepoPath $Local:QIKey 'Nil' 'Err'} catch {}}
			
			$DoInit = $true;
			$ErrCnt++;
			$SMOCnn.Disconnect();
			Write-Verbose 'Error occured.';
		}
		finally
		{	if ($null -ne $Local:SMOBkp)
			{	try 
				{	if ($Local:SMOBkp.AsyncStatus.ExecutionStatus -eq 'InProgress')
					{	$Local:SMOBkp.Abort()}
				} 
				catch {}
			}

			if ($fAsShJob -and $null -ne $MsgCll -and $MsgCll.Count)
			{	~SJLog~Msg~New Wrn $LogDate ($MsgCll.ToArray()) -iLogSrc ($MyInvocation.MyCommand)}

			$WrnCnt += $MsgCll.Count;
			$MsgCll.Clear();
			$Local:QIKey = [String]::Empty;
			$Local:SMOBkp = $null;
		}
		
		Write-Verbose 'Loop iteration.';

		# When 'timeout' ocuured next run will be after half of a period.
		if ($StartIt + $Period -le [datetime]::Now)
		{	$StartIt = [datetime]::Now + [timespan]($Period.Ticks -shr 1)}
		else 
		{	$StartIt += $Period}
	}
}
catch 
{	if ($fAsShJob)
	{	~SJLog~MsgException~New Err $LogDate $_ -iLogSrc ($MyInvocation.MyCommand)
		try {~SJLog~Msg~New Err $LogDate $ParamMsgCll -fAsKeyValue -iKey 'param' -iLogSrc ($MyInvocation.MyCommand)} catch {};
	}

	throw;
}
finally
{	if ($fAsShJob -and $null -ne $MsgCll -and $MsgCll.Count)
	{	~SJLog~Msg~New Wrn $LogDate ($MsgCll.ToArray()) -iLogSrc ($MyInvocation.MyCommand);
		$WrnCnt += $MsgCll.Count;
	}

	if ($fAsShJob -and $WrnCnt)
	{	~SJLog~Msg~New Wrn $LogDate $ParamMsgCll -fAsKeyValue -iKey 'param' -iLogSrc ($MyInvocation.MyCommand)}

	if ($fAsShJob -and $ErrCnt)
	{	~SJLog~Msg~New Err $LogDate $ParamMsgCll -fAsKeyValue -iKey 'param' -iLogSrc ($MyInvocation.MyCommand)}

	if (-not [String]::IsNullOrEmpty($Local:QIKey))
	{	try 
		{	m~QueueItem~StateSet $iaRepoPath $Local:QIKey 'Nil' 'Err'} 
		catch 
		{}
	}
}
}