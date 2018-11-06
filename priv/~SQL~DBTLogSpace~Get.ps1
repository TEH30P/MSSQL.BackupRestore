# Query DB TLog space used.
function m~SQL~DBTLogSpace~Get
(	[Microsoft.SqlServer.Management.Common.ServerConnection]$iSMOCnn
,	[string]$iDBName	
)
{	[String]$DBNamePara = '[' + $iDBName.Replace(']', ']]') + ']';
	[String]$SQL = @"
		DECLARE @sql nvarchar(4000)
		SET @sql 
		=	'USE $DBNamePara;
' 		+	'SELECT	used_p = SUM(CAST(FILEPROPERTY([name] , ''SpaceUsed'') as BIGINT)) 
' 		+	'FROM	sys.[database_files] 
' 		+	'WHERE	[type] = 1;'
		EXEC(@sql)
"@		;
	
	return [Int64]$iSMOCnn.ExecuteScalar($SQL) * 8kb;
}