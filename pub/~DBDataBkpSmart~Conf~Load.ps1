#!!!TODO: implement
# DB Data smart backup process config parse and verify.
function ~MSSQLBR~DBDataBkpSmart~Conf~Load
{	param
	(	[parameter(Mandatory = 1, Position = 0)][Alias('Path', 'P')]
		[String]$iPath
	)
try 
{	[psobject[]]$ConfArr = ~SJob~FileConf~Parse $iPath 'MSSQLBkp' 'ConfBase';

	for ([Int32]$k = $ConfArr.Count; ($k--))
	{	

	}
}
catch 
{	throw}	
}
