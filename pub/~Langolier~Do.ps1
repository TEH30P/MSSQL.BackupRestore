# Remove outdated backups.
#!!!TODO: test
function ~MSSQLBR~Langolier~Do
{   [CmdletBinding()]param
    (	[parameter(Mandatory=1, position=0)]
			[String]$iSrvInst
	,	[parameter(Mandatory=1, position=1)]
			[String]$iDBName
	,	[parameter(Mandatory=1, position=2)]
			[Uri[]]$iaRepoPath
	,	[parameter(Mandatory=1)]
			[TimeSpan]$iDataRtn
	,	[parameter(Mandatory=1)]
			[TimeSpan]$iTLogRtn
	,	[parameter(Mandatory=0)]
			[Byte]$iLayer = 0
	,	[parameter(Mandatory=0)]
			[switch]$fKeepCopyOnly
    )
try 
{	#
	# Data backups.
	# 
	
	[DateTime]$TLogAtMin = [DateTime]::Now - $iTLogRtn;
	[datetime]$DBDDataOnTLogLast = $TLogAtMin;
	[DateTime]$DBDataAtMin = [DateTime]::Now - $iDataRtn;
	[Collections.ArrayList]$BkpArr = [Collections.ArrayList]::new();

	m~BkpFileData~Get $iaRepoPath $iSrvInst $iDBName | % {[void]$BkpArr.Add($_)};
	[Boolean[]]$KeepArr = [Array]::CreateInstance([Boolean], $BkpArr.Count);

	for ([Int32]$k = 0; $k -lt $BkpArr.Count; $k++)
	{	if (($KeepArr[$k] = `
				(	($BkpArr[$k].PSAt -ge $DBDataAtMin -and ($fKeepCopyOnly -or -not $BkpArr[$k].PSIsCopyOnly)) `
				-or ($null -ne $BkpArr[$k].PSArcLayer -and $BkpArr[$k].PSArcLayer -gt $iLayer)) `
			))
		{	if ($BkpArr[$k].PSJobType -eq 'DBDiff')
			{	for ([Int32]$m = $k - 1; $m -ge 0; $m--)
				{	if ($BkpArr[$m].PSJobType -eq 'DBFull' -and -not $BkpArr[$m].PSIsCopyOnly)
					{	$KeepArr[$m] = $true;
						break;
					}
				}
			}
			
			if ($BkpArr[$k].PSAt -lt $TLogAtMin -and -not $BkpArr[$k].PSIsCopyOnly -and (($BkpArr[$k].PSJobType -band 'CodeMask') -eq 'Data'))
			{	$DBDDataOnTLogLast = $BkpArr[$k].PSAt}
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
	# TLog bakups.
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
{	throw}
}