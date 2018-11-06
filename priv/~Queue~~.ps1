#--------------------------------#
[hashtable]${m~Queue~dStateShortName} =
@{	'New' = 'N'; 'NewItem' = 'N'; 'N' = 'N'
;	'Act' = 'A'; 'Active' = 'A'; 'A' = 'A'
;	'Fin' = 'F'; 'Finished' = 'F'; 'F' = 'F'
;	'Wrn' = 'W'; 'Warning' = 'W'; 'W' = 'W'
;	'Err' = 'E'; 'Error' = 'E'; 'E' = 'E'
};
#--------------------------------#
[hashtable]${m~Queue~dStateFSName} =
@{	'New' = 'New'; 'NewItem' = 'New'; 'N' = 'New'
;	'Act' = 'Act'; 'Active' = 'Act'; 'A' = 'Act'
;	'Fin' = 'Fin'; 'Finished' = 'Fin'; 'F' = 'Fin'
;	'Wrn' = 'Wrn'; 'Warning' = 'Wrn'; 'W' = 'Wrn'
;	'Err' = 'Err'; 'Error' = 'Err'; 'E' = 'Err'
};
#--------------------------------#
[string[]]${m~Queue~aStateFSName} = @('New', 'Act', 'Fin', 'Wrn', 'Err');
#--------------------------------#
# Get all queue items.
function m~Queue~Get
(	[Uri[]]$iaRepoPath
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
			{	 [PSCustomObject]@{PSRepo = $RepoIt; PSState = $StateCurr; PSKey = [IO.Path]::GetFileName($QItemIt); PSFilePath = $QItemIt}} #<--
		}
	}
}
