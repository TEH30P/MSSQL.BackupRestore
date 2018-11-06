# Search bkp files in repo.
function ~MSSQLBR~BkpRepo~Search
{	param
	(   [parameter(Mandatory=1, position=0)]
			[Uri[]]$iaRepoPath
	,	[parameter(Mandatory=0, position=1)]
			[String]$iFltSrvInst
	,	[parameter(Mandatory=0, position=2)]
		   	[String]$iFltDBName
	,	[parameter(Mandatory=0)]
			[Nullable[Int32]]$iFltLast = $null
	,	[parameter(Mandatory=0)]
			[Nullable[DateTime]]$iFltAtMin = $null
	,	[parameter(Mandatory=0)]
			[Nullable[DateTime]]$iFltAtMax = $null
	,	[parameter(Mandatory=0)]
			[Nullable[Boolean]]$iFltCopyOnly = $null
	,   [parameter(Mandatory=1, ParameterSetName='PSet.TLog')]
			[switch]$fTLog
	,   [parameter(Mandatory=1, ParameterSetName='PSet.DBData')]
			[switch]$fDBData
	,   [parameter(Mandatory=0, ParameterSetName='PSet.DBData')]
			[switch]$fFltDiff
	);
try
{
	if ($fTLog)
	{	foreach ($BkpDir in m~BkpDirPathRoot~Tlog~Get $iaRepoPath)
		{	if (-not [IO.Directory]::Exists($BkpDir))
			{	throw [IO.FileNotFoundException]::new('Backup repo filesystem path not found.', $BkpDir)}
		}

		m~BkpFileTLog~Get $iaRepoPath $iFltSrvInst $iFltDBName -iFltLast $iFltLast -iFltAtMin $iFltAtMin -iFltAtMax $iFltAtMax -iFltCopyOnly $iFltCopyOnly;
	}
	else 
	{	foreach ($BkpDir in m~BkpDirPathRoot~Data~Get $iaRepoPath)
		{	if (-not [IO.Directory]::Exists($BkpDir))
			{	throw [IO.FileNotFoundException]::new('Backup repo filesystem path not found.', $BkpDir)}
		}

		[NMSSQL.MBkpRst.EBkpJobType]$JobType = if ($fFltDiff) {[NMSSQL.MBkpRst.EBkpJobType]::DBDiff} else {[NMSSQL.MBkpRst.EBkpJobType]::DBFull};
		m~BkpFileData~Get $iaRepoPath $iFltSrvInst $iFltDBName -iFltLast $iFltLast -iFltAtMin $iFltAtMin -iFltAtMax $iFltAtMax -iFltBkpJobType $JobType -iFltCopyOnly $iFltCopyOnly;
	}
}
catch 
{	throw}
}