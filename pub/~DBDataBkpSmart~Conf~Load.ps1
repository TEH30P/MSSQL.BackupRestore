#!!!TODO: implement
# DB Data smart backup process config parse and verify.
function ~MSSQLBR~DBDataBkpSmart~Conf~Load
{	param
	(	[parameter(Mandatory = 1, Position = 0)][Alias('Path', 'P')]
		[string]$iPath
	)
try 
{	[psobject]$ConfData = m~ConfFile~Load $iPath;
	[System.Collections.Queue]$ConfDataQue = [System.Collections.Queue]::new();
	$ConfDataQue.Enqueue($ConfData);

	while ($null -ne $ConfData.PSVInherits)
	{	[psobject]$ConfData = m~ConfFile~Load ($ConfData.PSVInherits.Is);
		$ConfDataQue.Enqueue($ConfData);
	}

	[psobject]$ConfData = $ConfDataQue.Dequeue();

	while ($ConfDataQue.Count) 
	{	
	}
}
catch 
{	throw}	
}
