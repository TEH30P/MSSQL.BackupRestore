# MS SQL LSN <-> FileSystem.
#--------------------------------#
function m~FSName~SQLLSN~Parse
(	[String]$iValue)
{	return m~DHex~ToInt $iValue}
#--------------------------------#
function m~FSName~SQLLSN~NParse
(	[String]$iValue)
{	if ('_' * 17 -cne $iValue -and '~' * 17 -cne $iValue)
	{	return m~DHex~ToInt $iValue}
}
#--------------------------------#
function m~FSName~SQLLSN~Convert
(	[Decimal]$iValue)
{	return m~DHex~ToString $iValue}
#--------------------------------#
function m~FSName~SQLLSN~NConvert
(	[Nullable[Decimal]]$iValue, [switch]$fNullHigh)
{	if ($null -eq $iValue)
	{	if ($fNullHigh) 
		{	return '~' * 17}
		else 
		{	return '_' * 17}
	}
	else 
	{	return (m~DHex~ToString $iValue).PadLeft(17, [char]'0')}
}
##################################
