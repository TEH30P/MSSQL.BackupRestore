# Create and configure Smo.Backup object.
function m~BkpTlog~Prep
(   [Microsoft.SqlServer.Management.Smo.Server]$iSrvInstObj
,   [String]$iDBName
,   [String[]]$iaBkpFilePath
,   [Boolean]$iFCompression = $false
,   [Boolean]$iFCopyOnly = $false
)
{   [Microsoft.SqlServer.Management.Smo.Backup]$SMOBkp = [Microsoft.SqlServer.Management.Smo.Backup]::new();

    $SMOBkp.Action = 'Log';
    $SMOBkp.BackupSetDescription = "$($iDBName) tlog backup.";
	$SMOBkp.BackupSetName = "$($iDBName) tlog backup.";
	$SMOBkp.Database = $iDBName;
	$SMOBkp.Initialize = $true;
	$SMOBkp.PercentCompleteNotification = 0;
    $SMOBkp.CopyOnly = $iFCopyOnly;
    
    if ($iFCompression)
    {	$SMOBkp.CompressionOption = 'On'}
    else
    {	$SMOBkp.CompressionOption = 'Off'}
    
    $iaBkpFilePath | % {$SMOBkp.Devices.AddDevice($_, 'File')};
    
    return $SMOBkp;
}