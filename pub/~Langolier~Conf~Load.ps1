New-Alias -Name Import-MSSQLBkpLangolierConf -Value '~MSSQLBR~Langolier~Conf~Load' -Force;

# Langolier prcess config parse and verify. Will generate hashtable with parameters for ~MSSQLBR~Langolier~Do.
function ~MSSQLBR~Langolier~Conf~Load
{	[CmdletBinding()]param
	(	[parameter(Mandatory = 1, Position = 0, ParameterSetName='PSNRaw'     , ValueFromPipeline = 1)][Alias('Path', 'P')]
			[String[]]$iaPath
	,	[parameter(Mandatory = 1, Position = 0, ParameterSetName='PSNPrepared')][Alias('ConfObj', 'O')]
			[psobject]$iConf
	,	[parameter(Mandatory = 0, Position = 1, ParameterSetName='PSNRaw'     )][Alias('PathDef', 'PD')]
			[String]$iPathDef
	,	[parameter(Mandatory = 0              , ParameterSetName='PSNRaw'     )][Alias('Raw')]
			[switch]$fRaw
	)
begin
{	[System.Collections.ArrayList]$ConfCll = @()}
process
{	
	try 
	{	if ($PSCmdlet.ParameterSetName -eq 'PSNPrepared')
		{	[void]$ConfCll.Add($iConf)}
		else 
		{	foreach ($PathIt in $iaPath)
			{	[void]$ConfCll.AddRange(@(~SJConf~File~Parse $PathIt 'MSSQLBkp' -iKeyBasePath 'Inherits' -iBasePath $iPathDef))}
		}
	}
	catch 
	{	throw}
}
end
{	if ($PSCmdlet.ParameterSetName -eq 'PSNPrepared')
	{	[Object]$ConfData = $ConfCll[0]}
	else
	{	[NPSShJob.CConfData]$ConfData = m~ConfData~LangolierQue~Inherit $ConfCll;
		m~ConfData~Langolier~Parse $ConfData;
		
		if($fRaw)
		{	return $ConfData} #<--
	}
		
	[Collections.IDictionary]$Rule = $ConfData.ValueTree.OVLangolierRule;

	[hashtable]$Ret = 
	@{	iSrvInst   = $ConfData.ValueTree.SVSrvInst.Is
	;	iDBName    = $ConfData.ValueTree.SVDBName.Is
	;	iaRepoPath = $ConfData.ValueTree.SLRepo.Is
	;	iaDataRtn  = $Rule.SLDataRtn.Is
	;	fAsShJob  = $true
	;	iConfPath = $ConfData.FilePath
	};
	
	$Ret['iTlogRtn'] = if ($null -ne $Rule.SVTlogRtn) {$Rule.SVTlogRtn.Is} else {[TimeSpan]::Zero}
	if ($null -ne $Rule.SVKeepCopyOnly) {$Ret['iKeepCopyOnly'] = $Rule.SVKeepCopyOnly.Is}

	return $Ret; #<--
}
}
