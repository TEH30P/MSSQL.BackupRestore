# Generate iaMsg param value for ~SJLog~Msg~New function.
function m~RstAttr~LogMsg~Gen
(	[Uri[]]$iaRepoPath
,	[Object]$iSrvInst
,	[String]$iDBName
,	[String]$iSrvInstSrc
,	[String]$iDBNameSrc

)
{	'iaRepoPath'; ([String[]]$iaRepoPath) -join ';';
	'iSrvInst';

	if ($iSrvInst -is [String])
	{	$iSrvInst}
	else 
	{	try
		{	$iSrvInst.Name}
		catch
		{	'.unknown.'}
	}
	
	'iDBName'; $iDBName;
	'iSrvInstSrc'; $iSrvInstSrc;
	'iDBNameSrc'; $iDBNameSrc;
}
