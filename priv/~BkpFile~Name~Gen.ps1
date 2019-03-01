# Will research some backup file and will generate it name.
function m~BkpFile~Name~Gen
(   [Microsoft.SqlServer.Management.Smo.Server]$iSrvObj
,	[Uri[]]$iaRepoPath
,   [String[]]$iaBkpFilePath
)
{	$BkpInfo = m~BkpFile~SQLHdr~Get $iSrvObj $iaBkpFilePath;
			
	#!!!TODO: No DB object name.
	
	switch -Exact ($BkpInfo.PSBackupType) 
	{	1 #Database
		{	[NMSSQL.MBkpRst.EBkpJobType]$JobType = 'DBFull';
			[String]$DBObjName = [String]::Empty;
		}
		2 #Transaction log
		{	[NMSSQL.MBkpRst.EBkpJobType]$JobType = 'TLog';
			[String]$DBObjName = [String]::Empty;
		}
		4 #File
		{	[NMSSQL.MBkpRst.EBkpJobType]$JobType = 'FlFull';
			[String]$DBObjName = [Guid]::NewGuid().ToString('N');
		}
		5 #Differential database
		{	[NMSSQL.MBkpRst.EBkpJobType]$JobType = 'DBDiff';
			[String]$DBObjName = [String]::Empty;
		}
		6 #Differential file
		{	[NMSSQL.MBkpRst.EBkpJobType]$JobType = 'FlDiff';
			[String]$DBObjName = [Guid]::NewGuid().ToString('N');
		}
		7 #Partial
		{	[NMSSQL.MBkpRst.EBkpJobType]$JobType = 'FGFull';
			[String]$DBObjName = [Guid]::NewGuid().ToString('N');
		}
		8 #Differential partial
		{	[NMSSQL.MBkpRst.EBkpJobType]$JobType = 'FGDiff';
			[String]$DBObjName = [Guid]::NewGuid().ToString('N');
		}
		default 
		{	throw 'Unknown backup type'}
	}

	if ($JobType -eq 'TLog')
	{	return m~BkpFilePath~TLog~Gen $BkpInfo.PSServerName $BkpInfo.PSDatabaseName $iaRepoPath $BkpInfo.PSBackupFinishDate $BkpInfo.PSLastLSN}
	else 
	{	return m~BkpFilePath~Data~Gen $BkpInfo.PSServerName $BkpInfo.PSDatabaseName $iaRepoPath $JobType $DBObjName 0 $BkpInfo.PSBackupFinishDate}
}