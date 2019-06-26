# Query DB TLog space used.
function m~SQL~DBTLogSpace~Get
(	[Microsoft.SqlServer.Management.Common.ServerConnection]$iSMOCnn
,	[string]$iDBName	
)
{	[Data.DataTable]$Tbl = [Data.DataTable]::new();
	$Tbl.Load($iSMOCnn.ExecuteReader('DBCC SQLPERF (LOGSPACE)'), 'OverwriteChanges');
	
	[System.Data.DataRow]$TRowIt = $null;
	[Int32]$DBNameColIdx = $Tbl.Columns['Database Name'].Ordinal;

	foreach($TRowIt in $Tbl.Rows)
	{	if ($iDBName -cne $TRowIt[$DBNameColIdx])
		{	continue}

		[Int64]$TLogSizeP = ([Int64][Math]::Floor([Double]$TRowIt['Log Size (MB)']) * 1MB + [Int64](([Double]$TRowIt['Log Size (MB)'] - [Math]::Floor([Double]$TRowIt['Log Size (MB)'])) * 1MB)) / 8KB;
		return [Int64]($TLogSizeP * ([Double]$TRowIt['Log Space Used (%)'] / 100)) * 8KB;
	}
}