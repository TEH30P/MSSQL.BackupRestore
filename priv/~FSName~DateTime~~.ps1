# DateTime <-> FileSystem name.
#--------------------------------#
function m~FSName~DateTime~Parse
(	[String]$iValue)
{	return [DateTime]::ParseExact($iValue, 'yyyyMMdd-HHmmss', [cultureinfo]::InvariantCulture)}
#--------------------------------#
function m~FSName~DateTime~NParse
(	[String]$iValue)
{	if ('________-______' -cne $iValue -and '~~~~~~~~-~~~~~~' -cne $iValue)
	{	return [DateTime]::ParseExact($iValue, 'yyyyMMdd-HHmmss', [cultureinfo]::InvariantCulture)}
}
#--------------------------------#
function m~FSName~DateTime~Convert
(	[DateTime]$iValue)
{	return $iValue.ToString('yyyyMMdd-HHmmss')}
#--------------------------------#
function m~FSName~DateTime~NConvert
(	[Nullable[DateTime]]$iValue, [switch]$fNullHigh)
{	if ($null -eq $iValue)
	{	if ($fNullHigh) 
		{	return '~~~~~~~~-~~~~~~'} 
		else 
		{	return '________-______'}
	}
	else 
	{	return $iValue.ToString('yyyyMMdd-HHmmss')}
}