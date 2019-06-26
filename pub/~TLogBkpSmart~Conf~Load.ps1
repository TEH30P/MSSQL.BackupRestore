New-Alias -Name Import-MSSQLDBTLogBkpConf -Value '~MSSQLBR~TLogBkpSmart~Conf~Load' -Force;

# DB TLog smart backup process config parse and verify. Will generate hashtable with parameters for ~MSSQLBR~TLogBkpSmart~Do.
function ~MSSQLBR~TLogBkpSmart~Conf~Load
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
	{	[NPSShJob.CConfData]$ConfData = m~ConfData~TLogBkpSmartQue~Inherit $ConfCll;
		m~ConfData~TLogBkpSmart~Parse $ConfData;
		
		if($fRaw)
		{	return $ConfData} #<--
	}
		
	[Collections.IDictionary]$Rule = $ConfData.ValueTree.OVTLogBkpRule;

	[hashtable]$Ret = 
	@{	iSrvInst   = $ConfData.ValueTree.SVSrvInst.Is
	;	iDBName    = $ConfData.ValueTree.SVDBName.Is
	;	iaRepoPath = $ConfData.ValueTree.SLRepo.Is
	;	iStartAt   = [datetime]::Now
	;	iDuration  = $Rule.SVDuration.Is
	;	fAsShJob  = $true
	;	iConfPath = $ConfData.FilePath
	};
	
	if ($null -ne $Rule.SVAgeTrg) {$Ret['iAgeTrg'] = $Rule.SVAgeTrg.Is}
	if ($null -ne $Rule.SVUsageMinTrg) {$Ret['iUsageMinTrg'] = $Rule.SVUsageMinTrg.Is}
	if ($null -ne $Rule.SVUsageMaxTrg) {$Ret['iUsageMaxTrg'] = $Rule.SVUsageMaxTrg.Is}
	if ($null -ne $Rule.SVChkPeriod) {$Ret['iChkPeriod'] = $Rule.SVChkPeriod.Is}
	if ($null -ne $Rule.SVCompression) {$Ret['fCompression'] = $Rule.SVCompression.Is}

	return $Ret; #<--
}
}
