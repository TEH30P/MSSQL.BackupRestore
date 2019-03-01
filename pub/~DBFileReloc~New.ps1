# Will create database file relocation rules.
function ~MSSQLBR~DBFileReloc~New
{	[CmdletBinding()]param
	(	[parameter(Mandatory = 1, Position = 0, ParameterSetName='PSNFull')][Alias('Tmpl', 'T')]
			[psobject]$iTmpl
	,	[parameter(Mandatory = 0, Position = 1, ParameterSetName='PSNFull')][Alias('PhysName', 'PN')]
			[String[]]$iaPhysName
	,	[parameter(Mandatory = 0, Position = 2, ParameterSetName='PSNFull')][Alias('LogicName', 'LN')]
			[String[]]$iaLogicName
	,	[parameter(Mandatory = 0, Position = 3, ParameterSetName='PSNFull')][Alias('TypeRel', 'TR')]
			[hashtable]$idTypeRel
	,	[parameter(Mandatory = 1              , ParameterSetName='PSNSimple')][Alias('DataDir')]
			[String]$iDataDir
	,	[parameter(Mandatory = 1              , ParameterSetName='PSNSimple')][Alias('TLogDir')]
			[String]$iTLogDir
	,	[parameter(Mandatory = 0              , ParameterSetName='SNSimple')][Alias('AppendBkpDate')]
			[switch]$fAppendBkpDate
	,	[parameter(Mandatory = 0              , ParameterSetName='SNSimple')][Alias('AppendCurrDate')]
			[switch]$fAppendCurrDate
	)
try 
{	switch -Exact ($PSCmdlet.ParameterSetName) 
	{	'PSNFull'
		{	return m~DBFReloc~Rule~New $iTmpl $iaPhysName $iaLogicName $idTypeRel}
		'PSNSimple'
		{	return m~DBFReloc~RuleStd~New $iDataDir $iTLogDir $fAppendBkpDate $fAppendCurrDate}
		Default
		{	throw 'Main logic error!'}
	}
}
catch 
{	throw}
}