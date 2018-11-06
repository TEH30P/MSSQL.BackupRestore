# Create and configure Smo.Backup object.
function m~BkpDBData~Prep
(   [Microsoft.SqlServer.Management.Smo.Server]$iSrvInstObj
,   [String]$iDBName
,   [String[]]$iaBkpFilePath
,   [Boolean]$iFDiff = $false
,   [Boolean]$iFCompression = $false
,   [Boolean]$iFCopyOnly = $false
)
{   [Microsoft.SqlServer.Management.Smo.Backup]$SMOBkp = [Microsoft.SqlServer.Management.Smo.Backup]::new();

    $SMOBkp.Action = 'Database';
    $SMOBkp.Incremental = $iFDiff;
    $SMOBkp.BackupSetDescription = "$($iDBName) backup.";
	$SMOBkp.BackupSetName = "$($iDBName) backup.";
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