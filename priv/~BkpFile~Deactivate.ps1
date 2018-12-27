#!!!TODO: test it.
# Will analise active backup file and will try to set strong name for it.
function m~BkpFile~DataLost~Deactivate
(	[String]$iSrvInst
,	[String]$iDBName
,	[Uri[]]$iaRepoPath
,	[NMSSQL.MBkpRst.EBkpJobType]$iJobType
,	[Microsoft.SqlServer.Management.Smo.Server]$iSrvInstObj
)
{	[String]$Mode = 'Analise';
	[String[]]$FilePathArr = [Array]::CreateInstance([String], $iaRepoPath.Count);
	
	if ($iJobType -eq 'TLog')
	{	[String[]]$DirPathArr = m~BkpDirPath~TLog~Gen $iSrvInst $iDBName $iaRepoPath}
	else 
	{	[String[]]$DirPathArr = m~BkpDirPath~Data~Gen $iSrvInst $iDBName $iaRepoPath}
	
	[Int32]$Idx = 0;

	foreach ($BkpDirIt in $DirPathArr)
	{	foreach ($BkpFileIt in [IO.Directory]::EnumerateFiles($BkpDirIt, "$(m~FSName~DateTime~NConvert -fNullHigh).*"))
		{	if (-not [String]::IsNullOrEmpty($FilePathArr[$Idx]))
			{	[String[]]$FilePathArr = @();
				$Idx = -1;
				break;
			}
			
			$FilePathArr[($Idx++)] = $BkpFileIt;
		}
	}

	if ($Idx -eq 0)
	{	return} #<---
	elseif ($Idx -eq $iaRepoPath.Count)
	{	$Mode = 'Rename'}
	else 
	{	$Mode = 'Clean'}
	
	if ('Rename' -ceq $Mode)
	{	<#!!!INF: 
			In case when other backup process is active and holding the files, I'll try to rename files first. 
			This will possibly break other backup process but this situation is not good anywhere.
		#>

		for([Int32]$k = 0; $k -lt $FilePathArr; $k++)
		{	[String]$BkpFilePathIt = [IO.Path]::ChangeExtension($FilePathArr[$k], '.~' + [IO.Path]::GetExtension($FilePathArr[$k]));
			[IO.File]::Replace($FilePathArr[$k], $BkpFilePathIt);
			$FilePathArr[$Idx] = $BkpFilePathIt;
		}
		
		[Int32]$Idx = 0;
			
		foreach($BkpFilePathIt in m~BkpFile~Name~Gen $iSrvInstObj $iaRepoPath $FilePathArr)
		{	[IO.File]::Move($FilePathArr[$Idx], $BkpFilePathIt);
			$FilePathArr[$Idx] = $BkpFilePathIt;
			$Idx++;
		}

		return 'Lost active backup files found.'; #<---
	}

	if ('Clean'-ceq $Mode)
	{	foreach ($BkpFileIt in $FilePathArr)
		{	if ([IO.File]::Exists($BkpFileIt))
			{	[IO.File]::Delete($BkpFileIt)}
		}
		
		foreach ($BkpDirIt in $DirPathArr)
		{	foreach ($BkpFileIt in [IO.Directory]::EnumerateFiles($BkpDirIt, "$(m~FSName~DateTime~NConvert -fNullHigh).*.bak"))
			{	[IO.File]::Delete($BkpFileIt)}
		}

		if ('CleanRepair' -ceq $Mode)
		{	return 'Lost active files repair failed. Cleanup.'} #<--
		else
		{	return 'Corrupted active backup files found.'} #<--
	}

	throw 'Main logic error!';
}