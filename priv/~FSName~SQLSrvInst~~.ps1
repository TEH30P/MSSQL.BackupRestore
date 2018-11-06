# SQL Inst Name <-> FileSystem name
#--------------------------------#
function m~FSName~SQLSrvInst~Convert
(	[String]$iValue)
{	return $iValue.ToLower().Replace('\default', '').Replace('\', '$')}
#--------------------------------#
function m~FSName~SQLSrvInst~Parse
(	[String]$iValue)
{	return $iValue.Replace('$', '\')}
##################################
