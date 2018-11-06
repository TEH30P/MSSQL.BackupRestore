# Set heartbit value for queue item.
function m~QueueItem~Upd
(	[Uri[]]$iaRepoPath
,	[String]$iKey
,	[NMSSQL.MBkpRst.EBkpQItemState]$iState
,	[hashtable]$idCont
)
#!!!TODO: add file rename in corresponding to function parameters.
{try{
	foreach ($FindResIt in m~QueueItem~Get $iaRepoPath $iKey $iState)
	{	[PSCustomObject]$QICont = [IO.File]::ReadAllText($FindResIt.PSFilePath) | ConvertFrom-Json;
			
		foreach ($KVIt in $idCont.GetEnumerator())
		{	$QICont.'O-MSSQLBkpQ'."$($KVIt.Key)" = $KVIt.Value}

		$QICont | ConvertTo-Json -Compress | Out-File -Encoding Utf8 -LiteralPath ($FindResIt.PSFilePath);
	}
}
catch
{	throw}}