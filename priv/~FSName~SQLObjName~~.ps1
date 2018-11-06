# SQL Name <-> FileSystem name
[String]${m~FSName~SQLObjName~Escapes} = '?*\/:|><.%'
#--------------------------------#
function m~FSName~SQLObjName~Convert
(	[String]$iValue)
{	[String]$Ret = '';

	foreach ($ChIt in $iValue.GetEnumerator())
	{	if (${m~FSName~SQLObjName~Escapes}.Contains($ChIt))
		{	$Ret += '%{0:X2}' -f [Char]::ConvertToUtf32(${m~FSName~SQLObjName~Escapes}, ${m~FSName~SQLObjName~Escapes}.IndexOf($ChIt))}
		else 
		{	$Ret += $ChIt}
	}

	return $Ret;
}
#--------------------------------#
function m~FSName~SQLObjName~Parse
(	[String]$iValue)
{	return [Uri]::UnescapeDataString($iValue)}
##################################
