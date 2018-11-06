# Set heartbit value for queue item.
function m~QueueItem~HeartBit
(	[Uri[]]$iaRepoPath
,	[String]$iKey
)
{	m~QueueItem~Upd $iaRepoPath $iKey 'Act' @{'V-HeartBit' = [Environment]::TickCount}}