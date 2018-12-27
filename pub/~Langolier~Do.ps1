# Remove outdated backups.
function ~MSSQLBR~Langolier~Do
{   [CmdletBinding()]param
    (	[parameter(Mandatory=1, position=0)]
			[String]$iSrvInst
	,	[parameter(Mandatory=1, position=1)]
			[String]$iDBName
	,	[parameter(Mandatory=1, position=2)]
			[Uri[]]$iaRepoPath
	,	[parameter(Mandatory=1)]
			[TimeSpan[]]$iaDataRtn
	,	[parameter(Mandatory=1)]
			[TimeSpan]$iTLogRtn
	,	[parameter(Mandatory=0)]
			[switch]$fKeepCopyOnly
	,	[parameter(Mandatory=0)]
			[switch]$fAsShJob
	,	[parameter(Mandatory=0)]
			[String]$iConfPath = [string]::Empty
    )
try 
{	[datetime]$LogDate = [datetime]::Now;
	[String[]]$ParamMsgCll = m~BkpAttr~LogMsg~Gen $iSrvInst $iDBName $iaRepoPath;
	
	#
	# Data backups.
	# 
	
	[DateTime]$TLogAtMin = [DateTime]::Now - $iTLogRtn;
	[datetime]$DBDDataOnTLogLast = $TLogAtMin;
	[Collections.ArrayList]$BkpArr = [Collections.ArrayList]::new();

	m~BkpFileData~Get $iaRepoPath $iSrvInst $iDBName | % {[void]$BkpArr.Add($_)};
	[Boolean[]]$KeepArr = [Array]::CreateInstance([Boolean], $BkpArr.Count);
	
	for ([Int32]$k = $BkpArr.Count; ($k--))
	{	$KeepArr[$k] = $true}

	#!!!TODO: Too complex fragment.

	for ([Int32]$Layer = $iaDataRtn.Count; ($Layer--))
	{	[DateTime]$DBDataAtMin = [DateTime]::Now - $iaDataRtn[$Layer];

		for ([Int32]$k = 0; $k -lt $BkpArr.Count; $k++)
		{	if ($null -eq $BkpArr[$k].PSArcLayer -or $BkpArr[$k].PSArcLayer -le $Layer)
			{	$KeepArr[$k] = $BkpArr[$k].PSAt -ge $DBDataAtMin -and ($fKeepCopyOnly -or -not $BkpArr[$k].PSIsCopyOnly)}

			if ($KeepArr[$k])
			{	if ($BkpArr[$k].PSJobType -eq 'DBDiff')
				{	for ([Int32]$m = $k; ($m--))
					{	if ($BkpArr[$m].PSJobType -eq 'DBFull' -and -not $BkpArr[$m].PSIsCopyOnly)
						{	$KeepArr[$m] = $true;
							break;
						}
					}
				}
				
				if (-not $Layer `
					-and $BkpArr[$k].PSAt -lt $TLogAtMin `
					-and -not $BkpArr[$k].PSIsCopyOnly `
					-and (($BkpArr[$k].PSJobType -band 'CodeMask') -eq 'Data') `
				)
				{	$DBDDataOnTLogLast = $BkpArr[$k].PSAt}
			}
		}
	}
	
	if ($KeepArr -notcontains $true)
	{	[boolean]$Last = $true;
		
		for ([Int32]$m = $BkpArr.Count - 1; $m -ge 0; $m--)
		{	if (-not $BkpArr[$m].PSIsCopyOnly)
			{	$DBDDataOnTLogLast = $BkpArr[$m].PSAt;

				if ($BkpArr[$m].PSJobType -eq 'DBFull')
				{	$KeepArr[$m] = $true;
					break;
				}
				elseif ($Last -and $BkpArr[$m].PSJobType -eq 'DBDiff')
				{	$KeepArr[$m] = $true;
					$Last = $false;
				}
			}
			
			$KeepArr[$m] = $m -eq $BkpArr.Count - 1;
		}
	}

	for ([Int32]$k = 0; $k -lt $BkpArr.Count; $k++)
	{	if (-not $KeepArr[$k])
		{	[IO.File]::Delete($BkpArr[$k].PSFilePath)}
	}
	
	#
	# TLog backups.
	# 

	$BkpArr.Clear();
	m~BkpFileTLog~Get $iaRepoPath $iSrvInst $iDBName | % {[void]$BkpArr.Add($_)};
	[Int32]$IdxLast = 0;

	for ([Int32]$k = 1; $k -lt $BkpArr.Count; $k++)
	{	if (-not $BkpArr[$k].PSIsCopyOnly)
		{	if ($BkpArr[$k].PSAt -ge $DBDDataOnTLogLast)
			{	break}
			
			$IdxLast = $k;
		}
	}

	for ([Int32]$k = 0; $k -lt $BkpArr.Count - 1; $k++)
	{	if ($k -lt $IdxLast -or $BkpArr[$k].PSIsCopyOnly)
		{	[IO.File]::Delete($BkpArr[$k].PSFilePath)}	
	}
	#!!!DBG: for testing
	#{	ri ($BkpArr[$k].PSFilePath) -WhatIf} #
}
catch 
{	if ($fAsShJob)
	{	~SJLog~MsgException~New Err $LogDate $_ -iLogSrc ($MyInvocation.MyCommand);
		try {~SJLog~Msg~New Err $LogDate $ParamMsgCll -fAsKeyValue -iKey 'param' -iLogSrc ($MyInvocation.MyCommand)} catch {};
	}
	
	throw;
}}