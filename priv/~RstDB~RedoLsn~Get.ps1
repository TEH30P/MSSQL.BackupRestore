# Returns redo start LSN of restoring database.
function m~RstDB~RedoLsn~Get
(	[Microsoft.SqlServer.Management.Common.ServerConnection]$iCnnObj
,	[String]$iDBName
)
{	[String]$SQL = @"
	SELECT	MIN([redo_start_lsn])
	FROM	sys.[master_files] 
	WHERE	[database_id] = db_id(N'$($iDBName.Replace('''', ''''''))');
"@;
	$SQLRet = $iCnnObj.ExecuteScalar($SQL);

	if ([DBNull]::Value -ne $SQLRet)
	{	return $SQLRet} #<---
}
