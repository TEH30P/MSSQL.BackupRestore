[regex]${m~BkpDirData~REActParser} = [regex]::new('.+?(\.~\w+)?\.bak$', 'Compiled, IgnoreCase')
[regex]${m~BkpDirTLog~REActParser} = [regex]::new('.+?(\.~\w+)?\.trn$', 'Compiled, IgnoreCase')

# Recover name of active tlog backup file.
function m~BkpDirTLog~Deactivate
(	[String]$iSrvInst
,	[String]$iDBName
,	[Uri[]]$iaRepoPath
)
{	[Int32]$Cnt = 0;
	
	foreach ($BkpDirIt in m~BkpDirPath~TLog~Gen $iSrvInst $iDBName $iaRepoPath)
	{	if ([IO.Directory]::Exists($BkpDirIt))
		{	$Cnt += m~BkpDir~Deactivate $BkpDirIt '~~~~~~~~-~~~~~~.*.trn' ${m~BkpDirTLog~REActParser}}
	}

	if ($Cnt)
	{	return "$Cnt lost actived backup files found in TLog repo."}
}

#--------------------------------#
# Recover name of active data backup file.
function m~BkpDirData~Deactivate
(	[String]$iSrvInst
,	[String]$iDBName
,	[Uri[]]$iaRepoPath
)
{	[Int32]$Cnt = 0;
	
	foreach ($BkpDirIt in m~BkpDirPath~Data~Gen $iSrvInst $iDBName $iaRepoPath)
	{	if ([IO.Directory]::Exists($BkpDirIt))
		{	$Cnt += m~BkpDir~Deactivate $BkpDirIt '~~~~~~~~-~~~~~~.*.bak' ${m~BkpDirData~REActParser}}
	}

	if ($Cnt)
	{	return "$Cnt lost actived backup files found in Data repo."}
}

function m~BkpDir~Deactivate
(	[String]$iDir
,	[String]$iFileWCPattern
,	[regex]$iFileREPattern
)
{	[String]$FileExt = $iFileWCPattern.Substring($iFileWCPattern.Length - 4);
	[System.Collections.Generic.SortedSet[String]]$PathCll = [System.Collections.Generic.SortedSet[String]]::new( `
		[IO.Directory]::EnumerateFiles($iDir, $iFileWCPattern) `
	);

	foreach ($Path in $PathCll)
	{	[Text.RegularExpressions.Match]$REM = $iFileREPattern.Match([IO.Path]::GetFileName($Path));
		
		if (-not $REM.Groups[1].Success)
		{	for ([Int32]$k = 1; $true; $k++)
			{	[String]$PathNew = [IO.Path]::ChangeExtension($Path, ".~$(m~DHex~ToString $k)$FileExt");

				if (-not $PathCll.Contains($PathNew) -and -not [IO.File]::Exists($PathNew))
				{	[IO.File]::Move($Path, $PathNew);
					break;
				}
			}
		}
	}

	return $PathCll.Count;
}