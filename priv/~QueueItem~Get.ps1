# Find queue item.
function m~QueueItem~Get
(	[Uri[]]$iaRepoPath
,	[String]$iKey
,	[NMSSQL.MBkpRst.EBkpQItemState]$iState
)
{	[Collections.Generic.HashSet[Uri]]$aRepoPass = @();
	
	foreach ($RepoIt in $iaRepoPath)
	{	if (-not $aRepoPass.Add($RepoIt))
		{	continue}
		
		if ($RepoIt.Scheme -ne [Uri]::UriSchemeFile)
		{	throw [InvalidOperationException]::new("Invalid repo path. Only 'UriSchemeFile' scheme supported, got $($RepoIt.Scheme).")}

		[String[]]$aDir `
		=	if ($iState -eq 'Nil') 
			{	${m~Queue~aStateFSName}} 
			else 
			{	${m~Queue~dStateFSName}[[string]$iState]}
		;

		foreach ($DirIt in $aDir)
		{	[NMSSQL.MBkpRst.EBkpQItemState]$StateCurr = $DirIt;
			[String]$QueueDir = [IO.Path]::Combine($RepoIt.LocalPath, "queue\$DirIt");
			
			foreach ($QItemIt in [IO.Directory]::EnumerateFiles($QueueDir))
			{	if ([IO.Path]::GetFileName($QItemIt) -eq $iKey)
				{	return [PSCustomObject]@{PSRepo = $RepoIt; PSState = $StateCurr; PSFilePath = $QItemIt}} #<--
			}
		}
	}

	throw [Management.Automation.ItemNotFoundException]::new('Bkp queue item not found.')
}
