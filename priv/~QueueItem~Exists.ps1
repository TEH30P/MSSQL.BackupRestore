# Find queue item.
function m~QueueItem~Exists
(	[Uri[]]$iaRepoPath
,	[String]$iKey
,	[NMSSQL.MBkpRst.EBkpQItemState]$iState
)
{	[String[]]$aDir `
	=	if ($iState -eq 'Nil') 
		{	${m~Queue~aStateFSName}} 
		else 
		{	${m~Queue~dStateFSName}[[string]$iState]}
	;
	
	foreach ($QueueRootIt in m~QueueDirPathRoot~Get $iaRepoPath)
	{	foreach ($DirIt in $aDir)
		{	if ([IO.File]::Exists("$QueueRootIt\$DirIt\$iKey"))
			{	return $true} #<--
		}
	}
	
	return $false; #<--
}
