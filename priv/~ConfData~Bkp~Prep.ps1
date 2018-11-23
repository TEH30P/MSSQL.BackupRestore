# Loads configuration, and handle inheritance queue.
function m~ConfData~Bkp~Prep
(	[psobject[]]$iaData)
{	
	[System.Collections.Queue]$ConfDataQue = [System.Collections.Queue]::new($iaData);

	[psobject]$Ret = $ConfDataQue.Dequeue();

	while ($ConfDataQue.Count) 
	{	$Child = $ConfDataQue.Dequeue();
		m~ConfDataS~Inherit $Ret $Child VSrvInst;
		m~ConfDataS~Inherit $Ret $Child VDBName;
		m~ConfDataL~Inherit $Ret $Child LRepo;
		m~ConfDataS~Inherit $Ret $Child VPolicy;
		
		if ($null -eq $Ret.VRuleDef)
		{	$Ret.VRuleDef = $Child.VRuleDef}
		elseif ($null -ne $Child.VRuleDef)
		{	m~ConfDataS~Inherit $Ret.VRuleDef $Child.VRuleDef VDBName;
			m~ConfDataS~Inherit $Ret.VRuleDef $Child.VRuleDef VDiffFullRatioMax;
			m~ConfDataS~Inherit $Ret.VRuleDef $Child.VRuleDef VDiffSizeFactor;
			m~ConfDataS~Inherit $Ret.VRuleDef $Child.VRuleDef VDiffFullSizeMax;
			m~ConfDataL~Inherit $Ret.VRuleDef $Child.VRuleDef LDataBkpDTW;
			m~ConfDataL~Inherit $Ret.VRuleDef $Child.VRuleDef LTlogBkpDTW;
			m~ConfDataL~Inherit $Ret.VRuleDef $Child.VRuleDef LLangolier;
		}

		m~ConfDataL~Inherit $Ret $Child LRule;
	}

	if ($null -ne $Ret.LRule)
	{	foreach ($ConfDataRuleIt in $Ret.LRule)
		{	m~ConfDataS~Inherit $ConfDataRuleIt $Child.VRuleDef VDBName;
			m~ConfDataS~Inherit $ConfDataRuleIt $Child.VRuleDef VDiffFullRatioMax;
			m~ConfDataS~Inherit $ConfDataRuleIt $Child.VRuleDef VDiffSizeFactor;
			m~ConfDataS~Inherit $ConfDataRuleIt $Child.VRuleDef VDiffFullSizeMax;
			m~ConfDataL~Inherit $ConfDataRuleIt $Child.VRuleDef LDataBkpDTW;
			m~ConfDataL~Inherit $ConfDataRuleIt $Child.VRuleDef LTlogBkpDTW;
			m~ConfDataL~Inherit $ConfDataRuleIt $Child.VRuleDef LLangolier;
		}
	}
	
	return $Ret; #<--
}