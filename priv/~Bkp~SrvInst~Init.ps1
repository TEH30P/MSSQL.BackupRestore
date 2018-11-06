# Create and configute SMO.Server object.
function m~Bkp~SrvInst~Init~o
(	[Object]$iSrvInst)
{	if ($iSrvInst -is [String])
    {   [Microsoft.SqlServer.Management.Common.ServerConnection]$SMOCnn = [Microsoft.SqlServer.Management.Common.ServerConnection]::new($iSrvInst);
        $SMOCnn.ApplicationName = "Powershell($mScriptFile)";
        $SMOCnn.LockTimeout = 1 * 60; # 1 minute;
        $SMOCnn.StatementTimeout = 0; # infinite;
        [Microsoft.SqlServer.Management.Smo.Server]$SMOSrv = [Microsoft.SqlServer.Management.Smo.Server]::new($SMOCnn);
    }
    elseif ($null -eq $iSrvInst)
    {   throw [ArgumentNullException]::new('iaRepoPath')}
    else
    {	[Microsoft.SqlServer.Management.Smo.Server]$SMOSrv = $iSrvInst;
        [Microsoft.SqlServer.Management.Common.ServerConnection]$SMOCnn = $SMOSrv.ConnectionContext;
    }

}