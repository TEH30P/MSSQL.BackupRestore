New-Alias -Name Remove-MSSQLBRDBSnapshot -Value '~MSSQLBR~DBSnapshot~Delete' -Force;

# DB Snapshot deletion process.
function ~MSSQLBR~DBSnapshot~Delete
{	param
	(   [parameter(Mandatory=1, position=0)]
			[Object]$iSrvInst
	,   [parameter(Mandatory=1, position=1)]
			[String]$iDBName
	,	[parameter(Mandatory = 0, position=2)]
			[DateTime]$iLastAt = [DateTime]::MaxValue
	,	[parameter(Mandatory = 0, position=3)]
			[DateTime]$iFirstAt = [DateTime]::MaxValue
	,   [parameter(Mandatory=0)]
			[switch]$fAsShJob
	,   [parameter(Mandatory=0)]
			[String]$iConfPath = [string]::Empty
	);
	try 
	{	
		[datetime]$LogDate = [datetime]::Now;
		[String[]]$ParamMsgCll = 'iSrvInst', '.unknown.', 'iDBName', $iDBName, 'iAtMin', $iLastAt.ToString('O'), 'iAtMax', $iFirstAt.ToString('O');
		
		if ($iSrvInst -is [String])
		{	$ParamMsgCll[1] = $iSrvInst}
		else 
		{	$ParamMsgCll[1] = $iSrvInst.Name}
				
		[Microsoft.SqlServer.Management.Smo.Server]$SMOSrv = $null;
		[Microsoft.SqlServer.Management.Common.ServerConnection]$SMOCnn = $null;
		. m~SMOSrv~Init~d; # << $iSrvInst

		[regex]$REDBShName = [regex]::new('^' + [regex]::Escape($iDBName) + '_sh_\d{8}_\d{6}$', 'IgnoreCase, Compiled, Singleline');
		[Microsoft.SqlServer.Management.Smo.Database[]]$DBArr = $SMOSrv.Databases | ? {$iDBName -eq $_.DatabaseSnapshotBaseName};

		foreach ($DBIt in $DBArr)
		{	if (-not $REDBShName.IsMatch($DBIt.Name))
			{	continue}
			
			[DateTime]$ShAt = [DateTime]::Now;
			
			if (-not [DateTime]::TryParseExact($DBIt.Name.Substring($iDBName.Length + '_sh_'.Length), 'yyyyMMdd_HHmmss', [Globalization.CultureInfo]::InvariantCulture, 'None', [ref]$ShAt))
			{	continue}

			if ($ShAt -lt $iLastAt -or $ShAt -gt $iFirstAt)
			{	$DBIt.Drop()}
		}
	}
	catch 
	{	if ($fAsShJob)
		{	~SJLog~MsgException~New Err $LogDate $_ -iLogSrc ($MyInvocation.MyCommand);
			try {~SJLog~Msg~New Err $LogDate $ParamMsgCll -fAsKeyValue -iKey 'param' -iLogSrc ($MyInvocation.MyCommand)} catch {};
		}
		
		throw;
	}
}