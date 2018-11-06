# Find queue item.
function m~QueueItem~Exists
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
		{	if ([IO.File]::Exists([IO.Path]::Combine($RepoIt.LocalPath, "queue\$DirIt\$iKey")))
			{	return $true} #<--
		}
	}
	
	return $false; #<--
}
