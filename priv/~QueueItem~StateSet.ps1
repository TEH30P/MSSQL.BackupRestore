# Remove queue item from active.
function m~QueueItem~StateSet
(	[Uri[]]$iaRepoPath
,	[String]$iKey
,	[NMSSQL.MBkpRst.EBkpQItemState]$iState
,	[NMSSQL.MBkpRst.EBkpQItemState]$iStateNew
)
{try{
	foreach ($FindResIt in m~QueueItem~Get $iaRepoPath $iKey $iState)
	{	[NMSSQL.MBkpRst.EBkpQItemState]$StateCurr = $FindResIt.PSState;
		
		if ($iStateNew -eq 'Nil')
		{	[IO.File]::Delete($FindResIt.PSFilePath)}
		elseif ($StateCurr -ne $iStateNew)
		{	[String]$DirSrc = ${m~Queue~dStateFSName}[[string]$StateCurr];
			[String]$DirTrg = ${m~Queue~dStateFSName}[[string]$iStateNew];
			[String]$DirQueue = [IO.Path]::Combine($FindResIt.PSRepo.LocalPath, 'queue');
			[IO.File]::Move("$DirQueue\$DirSrc\$iKey", "$DirQueue\$DirTrg\$iKey");
		}
	}
}
catch
{	throw}}