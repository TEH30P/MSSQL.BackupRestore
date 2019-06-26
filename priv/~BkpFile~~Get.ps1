#--------------------------------#
# Return file list from given repo.
function m~BkpFile~Get
(	[Uri[]]$iaRepoPath
,	[NMSSQL.MBkpRst.EBkpJobType]$iBkpJobType
,	[String]$iFltSrvInst
,   [String]$iFltDBName
,	[Nullable[Int32]]$iFltLast = $null
)
{	[Collections.Generic.HashSet[Uri]]$aRepoPass = @();

	foreach ($RepoIt in $iaRepoPath)
	{	if (-not $aRepoPass.Add($RepoIt))
		{	continue}
		
		if ($iBkpJobType -eq 'TLog')
		{	[String]$RepoDir = m~BkpDirPathRoot~TLog~Get $RepoIt}
		else
		{	[String]$RepoDir = m~BkpDirPathRoot~Data~Get $RepoIt}

		foreach ($SrvInstDir in [IO.Directory]::EnumerateDirectories($RepoDir))
		{	[String]$SrvInst = m~FSName~SQLSrvInst~Parse ([IO.Path]::GetFileName($SrvInstDir));

			if (-not [String]::IsNullOrEmpty($iFltSrvInst))
			{	if ($iFltSrvInst -ne $SrvInst)
				{	continue}
			}

			foreach ($DBNameDir in [IO.Directory]::EnumerateDirectories($SrvInstDir))
			{	[String]$DBName = m~FSName~SQLObjName~Parse ([IO.Path]::GetFileName($DBNameDir));
				
				if (-not [String]::IsNullOrEmpty($iFltDBName))
				{	if ($iFltDBName -ne $DBName)
					{	continue}
				}
				
				[Collections.Generic.List[String]]$FilePathCll = [Collections.Generic.List[String]]::new([IO.Directory]::EnumerateFiles($DBNameDir));
				
				#!!!WRN: Hardcode check that is date of backup is <null>.

				for ([Int32]$Idx = $FilePathCll.Count; ($Idx--);)
				{	[String]$FileKey = [IO.Path]::GetFileName($FilePathCll[$Idx]).Substring(0, 15);
					
					if ($null -eq (m~FSName~DateTime~NParse $FileKey))
					{	$FilePathCll.RemoveAt($Idx)}
				}
				
				$FilePathCll.Sort();
				[Int32]$IdxPass = 0

				if ($null -ne $iFltLast)
				{	$FilePathCll.Reverse();
					$IdxPass = $FilePathCll.Count;
					[Int32]$Idx = 0;
					[String]$FileKey = ' ' * 15;

					foreach ($FilePath in $FilePathCll)
					{	# Files with equal date name part is belong to one backup.
						if (-not [IO.Path]::GetFileName($FilePath).StartsWith($FileKey))
						{	$FileKey = [IO.Path]::GetFileName($FilePath).Substring(0, 15);
							
							if (($Idx++) -eq $iFltLast) {break}
						}

						$IdxPass--;
					}
	
					$FilePathCll.Reverse();
				}
				
				foreach ($FilePath in $FilePathCll)
				{	if ($IdxPass)
					{	$IdxPass--; continue}
					
					[PSCustomObject] `
					@{	PSRepo     = $RepoIt
					;	PSSrvInst  = $SrvInst
					;	PSDBName   = $DBName
					;	PSFilePath = $FilePath
					}; #<--
				}
			}
		}
	}
}
#--------------------------------#
# Returns parsed filenames of tlog repo.
function m~BkpFileTLog~Get
(	[Uri[]]$iaRepoPath
,	[String]$iFltSrvInst
,   [String]$iFltDBName
,	[Nullable[Int32]]$iFltLast = $null
,	[Nullable[DateTime]]$iFltAtMin = $null
,	[Nullable[DateTime]]$iFltAtMax = $null
,	[Nullable[Boolean]]$iFltCopyOnly = $null
)
{	<#!!!DBG: dummy $BkpInfo obj
		[PSCustomObject]$BkpInfo = [PSCustomObject]::new(@{PSFilePath=''; PSSrvInst = ''; PSDBName=''; PSRepo=[Uri]'C:\Windows';PSAt=[datetime]::now; PSJobType = [NMSSQL.MBkpRst.EBkpJobType]::CodeMask; PSLSNLast=[Decimal]('9'*20)} )
	#>
	
	[Nullable[Int32]]$FltLateLast = $null;

	if ($null -eq $iFltAtMin -and $null -eq $iFltAtMax -and $null -eq $iFltCopyOnly)
	{	[Nullable[Int32]]$FltEarlyLast = $iFltLast}
	elseif ($null -ne $iFltLast)
	{	[Collections.Generic.LinkedList[pscustomobject]]$LastFileCll = @();
		[Collections.Generic.SortedSet[datetime]]$LastCll = @();
		$FltLateLast = $iFltLast;
	}
	
	foreach ($BkpInfo in  m~BkpFile~Get $iaRepoPath TLog $iFltSrvInst $iFltDBName $FltEarlyLast)
	{	m~BkpFileTLog~Name~Parse ([IO.Path]::GetFileName($BkpInfo.PSFilePath)) -ioBkpInfo $BkpInfo;
		
		if ($null -ne $iFltAtMin)
		{	if ($BkpInfo.PSAt -lt $iFltAtMin)
			{	continue}
		}

		if ($null -ne $iFltAtMax)
		{	if ($BkpInfo.PSAt -gt $iFltAtMax)
			{	continue}
		}

		if ($null -ne $iFltCopyOnly)
		{	if ($iFltCopyOnly -and -not $BkpInfo.PSIsCopyOnly)
			{	continue}

			if (-not $iFltCopyOnly -and $BkpInfo.PSIsCopyOnly)
			{	continue}
		}
		
		if ($null -eq $FltLateLast)
		{	$BkpInfo} #<--
		else
		{	[Void]$LastFileCll.AddLast($BkpInfo);
			[Void]$LastCll.Add($BkpInfo.PSAt);
			
			if ($LastCll.Count -gt $FltLateLast)
			{	[datetime]$AtFirst = $LastCll | Select-Object -First 1;

				while ($LastFileCll.First.Value.PSAt -eq $AtFirst)
				{	$LastFileCll.RemoveFirst()}

				[Void]$LastCll.Remove($AtFirst);
			}
		}
	}

	if ($null -ne $FltLateLast)
	{	$LastFileCll} #<--
}
#--------------------------------#
# Returns parsed filenames of data repo.
function m~BkpFileData~Get
(	[Uri[]]$iaRepoPath
,	[String]$iFltSrvInst
,   [String]$iFltDBName
,	[Nullable[Int32]]$iFltLast = $null
,	[Nullable[DateTime]]$iFltAtMin = $null
,	[Nullable[DateTime]]$iFltAtMax = $null
,	[Nullable[NMSSQL.MBkpRst.EBkpJobType]]$iFltBkpJobType = $null
,	[Nullable[Boolean]]$iFltCopyOnly = $null
)
{	<#!!!DBG: dummy $BkpInfo obj
		[PSCustomObject]$BkpInfo = [PSCustomObject]::new(@{PSFilePath=''; PSSrvInst = ''; PSDBName=''; PSRepo=[Uri]'C:\Windows';PSAt=[datetime]::now; PSJobType = [NMSSQL.MBkpRst.EBkpJobType]::CodeMask; PSArcLayer=0} )
	#>
	
	[Nullable[Int32]]$FltLateLast = $null;

	if ($null -eq $iFltAtMin -and $null -eq $iFltAtMax -and $null -eq $iFltBkpJobType -and $null -eq $iFltCopyOnly)
	{	[Nullable[Int32]]$FltEarlyLast = $iFltLast}
	elseif ($null -ne $iFltLast)
	{	[Collections.Generic.LinkedList[pscustomobject]]$LastFileCll = @();
		[Collections.Generic.SortedSet[datetime]]$LastCll = @();
		$FltLateLast = $iFltLast;
	}

	foreach ($BkpInfo in  m~BkpFile~Get $iaRepoPath Data $iFltSrvInst $iFltDBName $FltEarlyLast)
	{	m~BkpFileData~Name~Parse ([IO.Path]::GetFileName($BkpInfo.PSFilePath)) -ioBkpInfo $BkpInfo;
		
		if ($null -ne $iFltAtMin)
		{	if ($BkpInfo.PSAt -lt $iFltAtMin)
			{	continue}
		}

		if ($null -ne $iFltAtMax)
		{	if ($BkpInfo.PSAt -gt $iFltAtMax)
			{	continue}
		}

		if ($null -ne $iFltBkpJobType)
		{	if ($BkpInfo.PSJobType -ne $iFltBkpJobType -and ($BkpInfo.PSJobType -band [NMSSQL.MBkpRst.EBkpJobType]::CodeMask) -ne $iFltBkpJobType)
			{	continue}
		}

		if ($null -ne $iFltCopyOnly)
		{	if ($iFltCopyOnly -and -not $BkpInfo.PSIsCopyOnly)
			{	continue}

			if (-not $iFltCopyOnly -and $BkpInfo.PSIsCopyOnly)
			{	continue}
		}
		
		if ($null -eq $FltLateLast)
		{	$BkpInfo} #<--
		else
		{	[Void]$LastFileCll.AddLast($BkpInfo);
			[Void]$LastCll.Add($BkpInfo.PSAt)
			
			if ($LastCll.Count -gt $FltLateLast)
			{	[datetime]$AtFirst = $LastCll | Select-Object -First 1;

				while ($LastFileCll.First.Value.PSAt -eq $AtFirst)
				{	$LastFileCll.RemoveFirst()}

				[Void]$LastCll.Remove($AtFirst);
			}
		}
	}

	if ($null -ne $FltLateLast)
	{	$LastFileCll} #<--
}
