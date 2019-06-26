New-Alias -Name New-MSSQLBkpFileName  -Value '~MSSQLBR~BkpFile~Name~Gen' -Force;

# Generate backup file name from SQL Backup header data.
function ~MSSQLBR~BkpFile~Name~Gen
{	param
	(   [parameter(Mandatory=1, position=0)]
			[Uri[]]$iaRepoPath
	,	[parameter(Mandatory=1, position=1)]
			[Object]$iSrvInst
	,	[parameter(Mandatory=1, position=2)]
			[String[]]$iaBkpFilePath
	,	[parameter(Mandatory=0, position=3)]
			[Nullable[Int32]]$iRepoIdx = $null
	);
try
{	[Microsoft.SqlServer.Management.Smo.Server]$SMOSrv = $null;
	[Microsoft.SqlServer.Management.Common.ServerConnection]$SMOCnn = $null;
	. m~SMOSrv~Init~d; # << $iSrvInst
	
	if ($null -eq $iRepoIdx)
	{	return  m~BkpFile~Name~Gen $SMOSrv $iaRepoPath $iaBkpFilePath;}
	else
	{	return (m~BkpFile~Name~Gen $SMOSrv $iaRepoPath $iaBkpFilePath)[$iRepoIdx]}
}
catch 
{	throw}
}