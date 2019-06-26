New-Alias -Name Add-MSSQLBRDBSnapshot -Value '~MSSQLBR~DBSnapshot~Create' -Force;

# DB Snapshot creation process.
function ~MSSQLBR~DBSnapshot~Create
{	[CmdletBinding()]param
	(   [parameter(Mandatory=1, position=0)]
			[Object]$iSrvInst
	,   [parameter(Mandatory=1, position=1)]
			[String]$iDBName
	,	[parameter(Mandatory = 0, ValueFromPipeline = 1)]
			[psobject[]]$iaDBFileReloc
	,   [parameter(Mandatory=0)]
			[switch]$fAsShJob
	,   [parameter(Mandatory=0)]
			[String]$iConfPath = [string]::Empty
	);
	begin
	{	[datetime]$LogDate = [datetime]::Now;
		[System.Collections.Generic.List[NMSSQL.MBkpRst.CDBFileReloc]]$DBFRelocCll = @();
		[String[]]$ParamMsgCll = 'iSrvInst', '.unknown.', 'iDBName', $iDBName;
		
		if ($iSrvInst -is [String])
		{	$ParamMsgCll[1] = $iSrvInst}
		else 
		{	$ParamMsgCll[1] = $iSrvInst.Name}
	}
	process
	{	if ($null -ne $iaDBFileReloc)
		{	$iaDBFileReloc | % {[Void]$DBFRelocCll.Add($_)}}
	}
	end
	{	try 
		{	# Some Relocation management.
			
			[NMSSQL.MBkpRst.CDBFileReloc[]]$DBFRelocCll = `
				for([Int32]$k = $DBFRelocCll.Count; ($k--);)
				{	$DBFRelocCll[$k]}
			;
					
			[Microsoft.SqlServer.Management.Smo.Server]$SMOSrv = $null;
			[Microsoft.SqlServer.Management.Common.ServerConnection]$SMOCnn = $null;
			. m~SMOSrv~Init~d; # << $iSrvInst

			if ($iSrvInst -is [String])
			{	[String]$SrvName = $iSrvInst}
			else 
			{	[String]$SrvName = $iSrvInst.TrueName}

			[DateTime]$Now = [DateTime]::now;
			[String]$NowStr = $Now.ToString('yyyyMMdd_HHmmss');
			[Microsoft.SqlServer.Management.Smo.Database]$SMODBSnap = [Microsoft.SqlServer.Management.Smo.Database]::new($SMOSrv, "$($iDBName)_sh_$($NowStr)");
			#!!!INF: instruction "{$SMOSrv.Databases[$iDBName]}" will not throw exception if can not connect to sql but instruction below will do.
			[Microsoft.SqlServer.Management.Smo.Database]$SMODB = $SMOSrv.Databases | ? {$_.Name -eq $iDBName};

			if ($null -eq $Local:SMODB)
			{	throw [Microsoft.SqlServer.Management.Smo.MissingObjectException]::new("Database [$($iDBName.Replace(']', ']]'))] is not found.")}

			$SMODBSnap.DatabaseSnapshotBaseName = $iDBName;

			foreach ($SMODBFG in $SMODB.FileGroups)
			{	if ($SMODBFG.FileGroupType -eq 'FileStreamDataFileGroup')
				{	continue}
				
				[Microsoft.SqlServer.Management.Smo.FileGroup]$SMODBFGSnap = [Microsoft.SqlServer.Management.Smo.FileGroup]::new($SMODBSnap, $SMODBFG.Name);

				foreach($DBFGFile in $SMODBFG.Files)
				{	if ($DBFRelocCll.Count)	
					{	foreach($DBFRelocIt in $iaDBFReloc)
						{	if (m~DBFReloc~Rule~Chk $DBFRelocIt ($DBFGFile.FileName) ($DBFGFile.Name) D)
							{	[String]$DBFileName = m~DBFReloc~Rule~Apply $DBFRelocIt $SrvName $DBName ($SMODBSnap.Name) ($DBFGFile.FileName) ($DBFGFile.Name) D $Now $Now;
								break;
							}
						}
					}
					else
					{	[String]$DBFileName = [IO.Path]::ChangeExtension($DBFGFile.FileName, $NowStr + [IO.Path]::GetExtension($DBFGFile.FileName))}
				
					$SMODBFGSnap.Files.Add(([Microsoft.SqlServer.Management.Smo.DataFile]::new($SMODBFGSnap, $DBFGFile.Name, $DBFileName)));
				}
				
				$SMODBSnap.FileGroups.Add($SMODBFGSnap);
			}

            try 
            {   $SMODBSnap.Create()}
            catch
            {   $SMOSrv.Databases.Refresh(); 
                
                if (-not ($SMOSrv.Databases.Contains($SMODBSnap.Name) -and $SMOSrv.Databases[$SMODBSnap.Name].DatabaseSnapshotBaseName -eq $SMODBSnap.DatabaseSnapshotBaseName))
                {   throw}
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
}