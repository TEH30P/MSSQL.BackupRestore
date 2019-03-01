# Restore single backup.
function m~RstDB~Prep
(	[Microsoft.SqlServer.Management.Smo.RestoreActionType]$iRstAct
,   [Microsoft.SqlServer.Management.Smo.Server]$iSrvObj
,   [String[]]$iaBkpFilePath
,	[Boolean]$iDoReplace
,	[Boolean]$iNoRecovery
,	[NMSSQL.MBkpRst.CDBFileReloc[]]$aDBFReloc
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

	if ($aDBFReloc.Count)
	{	[Data.DataTable]$Tbl = $SMORst.ReadFileList($iSrvObj);
		
		foreach($TRow in $Tbl.Rows)
		{	[String]$DBFNameL = $TRow.Item($Tbl.Columns['LogicalName'])
			[String]$DBFNameP = $TRow.Item($Tbl.Columns['PhysicalName'])
			[NMSSQL.MBkpRst.EDBFileType]$DBFType = $TRow.Item($Tbl.Columns['Type']);
			
			foreach($DBFRelocIt in $aDBFReloc)
			{	if (m~DBFReloc~Rule~Chk $DBFRelocIt $DBFNameP $DBFNameL $DBFType)
				{	$DBFNameP = m~DBFReloc~Rule~Apply $DBFRelocIt $iSrvNameSrc $iDBNameSrc $iDBName $DBFNameP $DBFNameL $DBFType $iBkpAt $iNow;
					[Void]$SMORst.RelocateFiles.Add([Microsoft.SqlServer.Management.Smo.RelocateFile]::new($DBFNameL, $DBFNameP))
					break;
				}
			}
		}
	}

	if ($null -ne $iPointInTime)
	{	$SMORst.ToPointInTime = $iPointInTime.ToString('yyyyMMdd HH:mm:ss')}
	
	$SMORst.PercentCompleteNotification = 0;
	$SMORst.ReplaceDatabase = $iDoReplace;
	$SMORst.NoRecovery = $iNoRecovery;

	return $SMORst; #<--
}