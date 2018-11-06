# UInt64 | UInt32 | UInt16 | Byte <-> FileSystem name.
#--------------------------------#
function m~FSName~UInt~Parse
(	[String]$iValue)
{	return [Bigint]::Parse($iValue, 'Integer', [Globalization.CultureInfo]::InvariantCulture)}
#--------------------------------#
function m~FSName~UInt~NParse
(	[String]$iValue)
{	if (-not ($iValue.GetEnumerator() | ? {'_' -ceq $_ -or '~' -ceq $_}))
    {   return [Bigint]::Parse($iValue, 'Integer', [Globalization.CultureInfo]::InvariantCulture)}
}
#--------------------------------#
function m~FSName~UInt~Convert
(	$iValue, [Int32]$iPrec)
{	return $iValue.ToString("D$($iPrec)")}
#--------------------------------#
function m~FSName~UInt~NConvert
(	$iValue, [Int32]$iPrec, [switch]$fNullHigh)
{	if ($null -eq $iValue)
	{	if ($fNullHigh) 
		{	return '~' * $iPrec}
		else 
		{	return '_' * $iPrec}
	}
	else 
	{	return $iValue.ToString("D$($iPrec)")}
}