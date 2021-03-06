# New queue item for backup.
function m~Queue~Rst~New
(	[Uri[]]$iaRepoPath
,	[Byte]$iPriority
,	[System.Nullable[NMSSQL.MBkpRst.EBkpJobType]]$iJobType
,	[String]$iSrvInst
,	[String]$iDBName
,	[String]$iSrvInstSrc
,	[String]$iDBNameSrc
,	[String]$iConfPath)
{	
	[DateTime]$Now = [datetime]::Now;
	[int32]$HeartBit = [Environment]::TickCount;
	[Byte[]]$MainId = $Host.InstanceId.ToByteArray();
	[String]$JobType = 'Mixed'

	if ($null -ne $iJobType)
	{	$JobType = $iJobType}
	
	[String]$QItemName = 'r.{0}.{1}.{2}.{3}.json' `
		-f	(m~FSName~UInt~Convert $iPriority 2) `
		,	(m~FSName~DateTime~Convert $Now) `
		,	(m~FSName~SQLSrvInst~Convert $iSrvInst) `
		,	(m~DHex~ToString ([bigint]::new($MainId)));

	[hashtable]$dQIContent =
	@{	'V-HeartBit'   = $HeartBit
	;	'V-Host'       = $env:COMPUTERNAME
	;	'V-HostProcId' = [System.Diagnostics.Process]::GetCurrentProcess().Id
	;	'V-SrvInst'    = $iSrvInst
	;	'V-DBName'     = $iDBName
	;	'V-SrvInstSrc' = $iSrvInstSrc
	;	'V-DBNameSrc'  = $iDBNameSrc
	;	'V-JobType'    = $JobType
	;	'V-ConfPath'   = $iConfPath
	;	'L-Msg'        = @()
	};

	foreach ($QueueRootIt in m~QueueDirPathRoot~Get $iaRepoPath)
	{	@{'O-MSSQLBkpQ' = $dQIContent} | ConvertTo-Json -Compress | Out-File -Encoding Utf8 -LiteralPath "$QueueRootIt\new\$QItemName"}

	return $QItemName;
}