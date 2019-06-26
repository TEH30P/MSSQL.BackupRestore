# Restore single backup.
function m~RstDB~Prep
(	[Microsoft.SqlServer.Management.Smo.RestoreActionType]$iRstAct
,	[Microsoft.SqlServer.Management.Smo.Server]$iSrvObj
,	[String[]]$iaBkpFilePath
,	[Boolean]$iDoReplace
,	[Boolean]$iNoRecovery
,	[Boolean]$iStandby
,	[NMSSQL.MBkpRst.CDBFileReloc[]]$iaDBFReloc
,	[String]$iSrvNameSrc
,	[String]$iDBNameSrc
,	[String]$iDBName
,	[System.Nullable[DateTime]]$iPointInTime
,	[DateTime]$iBkpAt
,	[DateTime]$iNow
)
{   [Microsoft.SqlServer.Management.Smo.Restore]$SMORst = [Microsoft.SqlServer.Management.Smo.Restore]::new();
	
	$iaBkpFilePath | % {$SMORst.Devices.AddDevice($_, 'File')};
	$SMORst.Action = $iRstAct;
	$SMORst.Database = $iDBName;
		
	if ($iaDBFReloc.Count)
	{	[Data.DataTable]$Tbl = $SMORst.ReadFileList($iSrvObj);
		
		foreach($TRow in $Tbl.Rows)
		{	[String]$DBFNameL = $TRow.Item($Tbl.Columns['LogicalName'])
			[String]$DBFNameP = $TRow.Item($Tbl.Columns['PhysicalName'])
			[NMSSQL.MBkpRst.EDBFileType]$DBFType = $TRow.Item($Tbl.Columns['Type']);

			if ($DBFType -eq [NMSSQL.MBkpRst.EDBFileType]::TLog -and $iStandby)
			{	[String]$StandbyPath = [IO.Path]::ChangeExtension($DBFNameP, 'sdf')

				if (m~DBFReloc~Rule~Chk $DBFRelocIt $StandbyPath $null $DBFType)
				{	$StandbyPath = m~DBFReloc~Rule~Apply $DBFRelocIt $iSrvNameSrc $iDBNameSrc $iDBName $StandbyPath $null $DBFType $iBkpAt $iNow}
			}
			
			foreach($DBFRelocIt in $iaDBFReloc)
			{	if (m~DBFReloc~Rule~Chk $DBFRelocIt $DBFNameP $DBFNameL $DBFType)
				{	$DBFNameP = m~DBFReloc~Rule~Apply $DBFRelocIt $iSrvNameSrc $iDBNameSrc $iDBName $DBFNameP $DBFNameL $DBFType $iBkpAt $iNow;
					[Void]$SMORst.RelocateFiles.Add([Microsoft.SqlServer.Management.Smo.RelocateFile]::new($DBFNameL, $DBFNameP))
					break;
				}
			}
		}
	}
    elseif ($iStandby)
    {	[Data.DataTable]$Tbl = $SMORst.ReadFileList($iSrvObj);

		foreach($TRow in $Tbl.Rows)
		{	[NMSSQL.MBkpRst.EDBFileType]$DBFType = $TRow.Item($Tbl.Columns['Type']);

			if ($DBFType -eq [NMSSQL.MBkpRst.EDBFileType]::TLog)
			{	[String]$StandbyPath = [IO.Path]::ChangeExtension($TRow.Item($Tbl.Columns['PhysicalName']), 'sdf')}
		}
    }

	if ($null -ne $iPointInTime)
	{	$SMORst.ToPointInTime = $iPointInTime.ToString('yyyyMMdd HH:mm:ss')}
	
	$SMORst.PercentCompleteNotification = 0;
	$SMORst.ReplaceDatabase = $iDoReplace;

	if ($iStandby)
	{	$SMORst.StandbyFile = $StandbyPath}
	else 
	{	$SMORst.NoRecovery = $iNoRecovery}
	
	return $SMORst; #<--
}