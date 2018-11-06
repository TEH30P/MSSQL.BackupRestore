# New queue item for backup.
function m~Queue~Bkp~New
(	[Uri[]]$iaRepoPath
,	[Byte]$iPriority
,	[NMSSQL.MBkpRst.EBkpJobType]$iJobType
,	[String]$iSrvInst
,	[String]$iDBName
,	[String]$iConfPath)
{	
	[DateTime]$Now = [datetime]::Now;
	[int32]$HeartBit = [Environment]::TickCount;
	[Byte[]]$MainId = $Host.InstanceId.ToByteArray();
		
	<##!!!REM: too wacky
	[Security.Cryptography.HashAlgorithm]$HashAlg = [System.Security.Cryptography.SHA1]::Create();
	[Byte[]]$MainId = [Text.Encoding]::UTF8.GetBytes([Uri]::new("process://$env:COMPUTERNAME/$([System.Diagnostics.Process]::GetCurrentProcess().Name)?id=$([System.Diagnostics.Process]::GetCurrentProcess().Id)").AbsoluteUri);
	#>
	[String]$QItemName = 'b.{0}.{1}.{2}.{3}.json' `
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
	;	'V-JobType'    = [string]$iJobType
	;	'V-ConfPath'   = $iConfPath
	;	'L-Msg'        = @()
	};

	[Collections.Generic.HashSet[Uri]]$aRepoPass = @();
	
	foreach ($RepoIt in $iaRepoPath)
	{	if (-not $aRepoPass.Add($RepoIt))
		{	continue}

		if ($RepoIt.Scheme -ne [Uri]::UriSchemeFile)
		{	throw [InvalidOperationException]::new("Invalid repo path. Only 'UriSchemeFile' scheme supported, got $($RepoIt.Scheme).")}

		[String]$QueueDir = [IO.Path]::Combine($RepoIt.LocalPath, 'queue\new');
		@{'O-MSSQLBkpQ' = $dQIContent} | ConvertTo-Json -Compress | Out-File -Encoding Utf8 -LiteralPath "$QueueDir\$QItemName";
	}

	return $QItemName;
}