# Generate iaMsg param value for ~SJLog~Msg~New function.
function m~BkpAttr~LogMsg~Gen
(	[Object]$iSrvInst
,	[String]$iDBName
,	[Uri[]]$iaRepoPath)
{	'iSrvInst';

	if ($iSrvInst -is [String])
	{	$iSrvInst}
	else 
	{	try
		{	$iSrvInst.Name}
		catch
		{	'.unknown.'}
	}
	
	'iDBName'; $iDBName;

	'iaRepoPath'; ([String[]]$iaRepoPath) -join ';';
}
