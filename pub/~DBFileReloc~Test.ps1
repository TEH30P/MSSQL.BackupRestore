# !!!TODO: test it!
# Will apply relocation rules and returns new file path.
function ~MSSQLBR~DBFileReloc~Test
{	[CmdletBinding()]param
	(	[parameter(Mandatory = 0)]
			[String]$iSrvInstSrc
	,	[parameter(Mandatory = 0)]
			[String]$iDBNameSrc
	,	[parameter(Mandatory = 0)]
			[String]$iDBName
	,	[parameter(Mandatory = 1)]
			[String]$iDBFilePName
	,	[parameter(Mandatory = 0)]
			[String]$iDBFileLName
	,	[parameter(Mandatory = 0)]
			[NMSSQL.MBkpRst.EDBFileType]$iDBFileType
	,	[parameter(Mandatory = 0)]
			[DateTime]$iBkpAt
	,	[parameter(Mandatory = 0)]
			[DateTime]$iNow = (Get-Date)
	,	[parameter(Mandatory = 0, ValueFromPipeline = 1)]
			[psobject[]]$iaDBFileReloc
	)
begin
{	[datetime]$LogDate = [datetime]::Now;
	[System.Collections.Generic.List[NMSSQL.MBkpRst.CDBFileReloc]]$DBFRelocCll = @();
}
process
{	if ($null -ne $iaDBFileReloc)
	{	$iaDBFileReloc | % {[Void]$DBFRelocCll.Add($_)}}
}
end
{	try 
	{	[NMSSQL.MBkpRst.CDBFileReloc[]]$DBFRelocCll = `
		for([Int32]$k = $DBFRelocCll.Count; ($k--);)
		{	$DBFRelocCll[$k]}
		;

		foreach($DBFRelocIt in $DBFRelocCll)
		{	if (m~DBFReloc~Rule~Chk $DBFRelocIt $iDBFilePName $iDBFileLName $iDBFileType)
			{	m~DBFReloc~Rule~Apply $DBFRelocIt $iSrvInstSrc $iDBNameSrc $iDBName $iDBFilePName $iDBFileLName $iDBFileType $iBkpAt $iNow | Out-Default; #<--
				break;
			}
		}
	}
	catch 
	{	throw}
}
}