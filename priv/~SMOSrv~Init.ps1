# Create and configute SMO.Server object.
function m~SMOSrv~Init~d
#	[Object]$iSrvInst <#in#>
#	[Microsoft.SqlServer.Management.Common.ServerConnection]$SMOCnn = $null
#   [Microsoft.SqlServer.Management.Smo.Server]$SMOSrv = $null
#	[Object]$iSrvInst <#in#>
{	if ($iSrvInst -is [String])
    {   $SMOCnn = [Microsoft.SqlServer.Management.Common.ServerConnection]::new($iSrvInst);
        $SMOCnn.ApplicationName = "Powershell($mScriptFile)";
        $SMOCnn.LockTimeout = 1 * 60; # 1 minute;
        $SMOCnn.StatementTimeout = 0; # infinite;
        $SMOSrv = [Microsoft.SqlServer.Management.Smo.Server]::new($SMOCnn);
    }
    elseif ($null -eq $iSrvInst)
    {   throw [ArgumentNullException]::new('iaRepoPath')}
    else
    {	$SMOSrv = $iSrvInst;
        $SMOCnn = $SMOSrv.ConnectionContext;
    }
}