#--------------------------------#
# Configuration inheritance.
function m~ConfData~BkpMain~Inherit
(	[Collections.IDictionary]$oiObj
,	[Collections.IDictionary]$iObjChild
)
{	~SJConf~List~Inherit $oiObj $iObjChild SLRepo;
	~SJConf~Scalar~Inherit $oiObj $iObjChild SVSrvInst;
	~SJConf~Scalar~Inherit $oiObj $iObjChild SVDBName;
}
#--------------------------------#
# Configuration inheritance queue for DBDataBkpSmart.
function m~ConfData~DBDataBkpSmartQue~Inherit
(	[NPSShJob.CConfData[]]$iaData)
{	
	[NPSShJob.CConfData]$Ret = [NPSShJob.CConfData]::new();
	$Ret.ValueTree = [NPSShJob.CConfData]::ValueTreeFactory();
	[Collections.Stack]$Stc = [Collections.Stack]::new($iaData);

	while ($Stc.Count) 
	{	$Child = $Stc.Pop();
		m~ConfData~BkpMain~Inherit $Ret.ValueTree $Child.ValueTree;

		$Rule = $Ret.ValueTree.OVDataBkpRule;
		$RuleChld = $Child.ValueTree.OVDataBkpRule;

		if ($null -eq $Rule)
		{	$Ret.ValueTree.OVDataBkpRule = $RuleChld}
		elseif ($null -ne $RuleChld)
		{	~SJConf~Scalar~Inherit $Rule $RuleChld SVOperAllow;
			~SJConf~Scalar~Inherit $Rule $RuleChld SVDiffFullRatioMax;
			~SJConf~Scalar~Inherit $Rule $RuleChld SVTotalSizeMax;
			~SJConf~Scalar~Inherit $Rule $RuleChld SVDiffSizeFactor;
			~SJConf~Scalar~Inherit $Rule $RuleChld SVArchLayer;
			~SJConf~Scalar~Inherit $Rule $RuleChld SVCompression;
			~SJConf~Scalar~Inherit $Rule $RuleChld SVBegin;
			~SJConf~Scalar~Inherit $Rule $RuleChld SVDuration;
		}	
	}

	$Ret.FilePath = $Child.FilePath;
	return $Ret;
}
#--------------------------------#
# Configuration inheritance queue for TLogBkpSmart.
function m~ConfData~TLogBkpSmartQue~Inherit
(	[NPSShJob.CConfData[]]$iaData)
{	
	[NPSShJob.CConfData]$Ret = [NPSShJob.CConfData]::new();
	$Ret.ValueTree = [NPSShJob.CConfData]::ValueTreeFactory();
	[Collections.Stack]$Stc = [Collections.Stack]::new($iaData);
	
	while ($Stc.Count) 
	{	$Child = $Stc.Pop();
		m~ConfData~BkpMain~Inherit $Ret.ValueTree $Child.ValueTree;

		$Rule = $Ret.ValueTree.OVTLogBkpRule;
		$RuleChld = $Child.ValueTree.OVTLogBkpRule;
		
		if ($null -eq $Rule)
		{	$Ret.ValueTree.OVTLogBkpRule = $RuleChld}
		elseif ($null -ne $RuleChld)
		{	~SJConf~Scalar~Inherit $Rule $RuleChld SVAgeTrg;
			~SJConf~Scalar~Inherit $Rule $RuleChld SVUsageMaxTrg;
			~SJConf~Scalar~Inherit $Rule $RuleChld SVUsageMinTrg;
			~SJConf~Scalar~Inherit $Rule $RuleChld SVChkPeriod;
			~SJConf~Scalar~Inherit $Rule $RuleChld SVCompression;
			~SJConf~Scalar~Inherit $Rule $RuleChld SVBegin;
			~SJConf~Scalar~Inherit $Rule $RuleChld SVDuration;
		}	
	}

	$Ret.FilePath = $Child.FilePath;
	return $Ret;
}
#--------------------------------#
# Configuration inheritance queue for Langolier.
function m~ConfData~LangolierQue~Inherit
(	[NPSShJob.CConfData[]]$iaData)
{	
	[NPSShJob.CConfData]$Ret = [NPSShJob.CConfData]::new();
	$Ret.ValueTree = [NPSShJob.CConfData]::ValueTreeFactory();
	[Collections.Stack]$Stc = [Collections.Stack]::new($iaData);

	[System.Collections.Generic.SortedList[Int32, Collections.IDictionary]]$DataRtnDic = @{}

	while ($Stc.Count) 
	{	$Child = $Stc.Pop();
		m~ConfData~BkpMain~Inherit $Ret.ValueTree $Child.ValueTree;

		$Rule = $Ret.ValueTree.OVLangolierRule;
		$RuleChld = $Child.ValueTree.OVLangolierRule;
		
		if ($null -eq $Rule)
		{	$Ret.ValueTree.OVLangolierRule = $RuleChld}
		elseif ($null -ne $RuleChld)
		{	~SJConf~Scalar~Inherit $Rule $RuleChld SVKeepCopyOnly;
			~SJConf~Scalar~Inherit $Rule $RuleChld SVTlogRtn;
		}
		
		if ($null -ne $RuleChld)
		{	[System.Collections.Generic.SortedSet[Int32]]$DataRtnLvlSet = [System.Collections.Generic.SortedSet[Int32]]::new();

			for ([Int32]$k = 0; $k -lt $RuleChld.SLDataRtn.Count; $k++)
			{	[Collections.IDictionary]$PropIt = $RuleChld.SLDataRtn[$k]
				
				if (([Collections.IDictionary]$PropIt).Contains('SVLayer'))
				{	[Int32]$Layer = ~SJConf~Scalar~Parse $PropIt SVLayer Int32 -fOut}
				else
				{	[Int32]$Layer = $k}

				if (-not $DataRtnLvlSet.Add($Layer))
				{	throw [System.FormatException]::new('LangolierRule/SLDataRtn contains not unique elements "SVLayer".')}

				$DataRtnDic[$Layer] = [NPSShJob.CConfData]::ValueTreeFactory() | % {$_['Is'] = $PropIt['Is']; $_};
			}
		}
	}

	if (([Collections.IDictionary]$Ret.ValueTree).Contains('OVLangolierRule'))
	{	[Collections.IDictionary[]]$Arr = [Array]::CreateInstance([Collections.IDictionary], $DataRtnDic.Count)

		for ([Int32]$k = 0; $k -lt $Arr.Count; $k++)
		{	if (-not ([Collections.IDictionary]$DataRtnDic).Contains($k))
			{	throw [System.FormatException]::new('LangolierRule/SLDataRtn not all layers (SVLayer) covered.')}

			$Arr[$k] = $DataRtnDic[$k];
		}

		$Ret.ValueTree.OVLangolierRule.SLDataRtn = $Arr;
	}

	$Ret.FilePath = $Child.FilePath;
	return $Ret;
}
#--------------------------------#
