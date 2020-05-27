# Find queue item.
function m~QueueItem~Get
(	[Uri[]]$iaRepoPath
,	[String]$iKey
,	[NMSSQL.MBkpRst.EBkpQItemState]$iState
)
{	
	[String[]]$aDir `
	=	if ($iState -eq 'Nil') 
		{	${m~Queue~aStateFSName}} 
		else 
		{	${m~Queue~dStateFSName}[[string]$iState]}
	;
	
	foreach ($QueueRootIt in m~QueueDirPathRoot~Get $iaRepoPath)
	{	foreach ($DirIt in $aDir)
		{	foreach ($QItemIt in [IO.Directory]::EnumerateFiles("$QueueRootIt\$DirIt"))
			{	if ([IO.Path]::GetFileName($QItemIt) -eq $iKey)
				{	return [PSCustomObject]@{PSState = ([NMSSQL.MBkpRst.EBkpQItemState]$DirIt); PSFilePath = ([String]$QItemIt); PSQueueDirPath=$QueueRootIt}} #<--
			}
		}
	}

	return [PSCustomObject]@{PSState = ([NMSSQL.MBkpRst.EBkpQItemState]::Nil)};
}
