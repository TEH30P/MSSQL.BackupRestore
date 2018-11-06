# Create and configure Smo.Backup object.
function m~BkpFile~SQLHdr~Get
(   [Microsoft.SqlServer.Management.Smo.Server]$iSrvInstObj
,   [String[]]$iaBkpFilePath
)
{   [Microsoft.SqlServer.Management.Smo.Restore]$SMORst = [Microsoft.SqlServer.Management.Smo.Restore]::new();
    
    $iaBkpFilePath | % {$SMORst.Devices.AddDevice($_, 'File')};
	[Data.DataTable]$Tbl = $SMORst.ReadBackupHeader($iSrvInstObj);
    [PSCustomObject]$Ret = [PSCustomObject]::new();

    foreach ($TCol in $Tbl.Columns)
    {   $Ret | Add-Member -MemberType NoteProperty -Name ('PS' + $TCol.Caption) -Value ($Tbl.Rows[0].Item($TCol))}
    
    return $Ret;
}