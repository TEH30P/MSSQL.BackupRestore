New-Alias -Name Import-MSSQLDBDataBkpConf  -Value '~MSSQLBR~DBDataBkpSmart~Conf~Load' -Force;

# DB Data smart backup process config parse and verify. Will generate hashtable with parameters for ~MSSQLBR~DBDataBkpSmart~Do.
function ~MSSQLBR~DBDataBkpSmart~Conf~Load
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
	{	[NPSShJob.CConfData]$ConfData = m~ConfData~DBDataBkpSmartQue~Inherit $ConfCll;
		m~ConfData~DBDataBkpSmart~Parse $ConfData;
		
		if($fRaw)
		{	return $ConfData} #<--
	}
		
	[Collections.IDictionary]$Rule = $ConfData.ValueTree.OVDataBkpRule;

	[hashtable]$Ret = 
	@{	iSrvInst   = $ConfData.ValueTree.SVSrvInst.Is
	;	iDBName    = $ConfData.ValueTree.SVDBName.Is
	;	iaRepoPath = $ConfData.ValueTree.SLRepo.Is
	;	iStartAt   = [datetime]::Now
	;	iDuration  = $Rule.SVDuration.Is
	;	iDiffFullRatioMax = $Rule.SVDiffFullRatioMax.Is
	;	iDiffSizeFactor   = $Rule.SVDiffSizeFactor.Is
	;	fAsShJob  = $true
	;	iConfPath = $ConfData.FilePath
	};
	
	if ($null -ne $Rule.SVTotalSizeMax) {$Ret['iTotalSizeMax'] = $Rule.SVTotalSizeMax.Is}
	if ($null -ne $Rule.SVOperAllow)    {$Ret['iOperAllow'] = $Rule.SVOperAllow.Is}
	if ($null -ne $Rule.SVArcLayer)     {$Ret['iArcLayer'] = $Rule.SVArcLayer.Is}
	if ($null -ne $Rule.SVCompression)  {$Ret['fCompression'] = $Rule.SVCompression.Is}

	return $Ret; #<--
}
}
