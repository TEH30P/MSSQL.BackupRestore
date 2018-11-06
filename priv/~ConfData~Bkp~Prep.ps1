# Loads configuration, and handle inheritance queue.
function m~ConfData~Bkp~Prep
(	[string]$iPath)
{	
	[psobject]$ConfData = m~ConfFile~Load $iPath 'OV-MSSQLBkp';
	[System.Collections.Queue]$ConfDataQue = [System.Collections.Queue]::new();
	$ConfDataQue.Enqueue($ConfData);
	
	while ($null -ne $ConfData.VInherits)
	{	[psobject]$ConfData = m~ConfFile~Load ($ConfData.VInherits.Is) 'OV-MSSQLBkp';
		$ConfDataQue.Enqueue($ConfData);
	}

	[psobject]$ConfData = $ConfDataQue.Dequeue();
	$ConfData | Add-Member -MemberType NoteProperty -Name FilePath -Value ([PSCustomObject]@{Is = $iPath})

	while ($ConfDataQue.Count) 
	{	$ConfDataIt = $ConfDataQue.Dequeue();
		m~ConfDataS~Inherit $ConfData $ConfDataIt VSrvInst;
		m~ConfDataS~Inherit $ConfData $ConfDataIt VDBName;
		m~ConfDataL~Inherit $ConfData $ConfDataIt LRepo;
		m~ConfDataS~Inherit $ConfData $ConfDataIt VPolicy;
		
		if ($null -eq $ConfData.VRuleDef)
		{	$ConfData.VRuleDef = $ConfDataIt.VRuleDef}
		elseif ($null -ne $ConfDataIt.VRuleDef)
		{	m~ConfDataS~Inherit $ConfData.VRuleDef $ConfDataIt.VRuleDef VDBName;
			m~ConfDataS~Inherit $ConfData.VRuleDef $ConfDataIt.VRuleDef VDiffFullRatioMax;
			m~ConfDataS~Inherit $ConfData.VRuleDef $ConfDataIt.VRuleDef VDiffSizeFactor;
			m~ConfDataS~Inherit $ConfData.VRuleDef $ConfDataIt.VRuleDef VDiffFullSizeMax;
			m~ConfDataL~Inherit $ConfData.VRuleDef $ConfDataIt.VRuleDef LDataBkpDTW;
			m~ConfDataL~Inherit $ConfData.VRuleDef $ConfDataIt.VRuleDef LTlogBkpDTW;
			m~ConfDataL~Inherit $ConfData.VRuleDef $ConfDataIt.VRuleDef LLangolier;
		}

		m~ConfDataL~Inherit $ConfData $ConfDataIt LRule;
	}

	if ($null -ne $ConfData.LRule)
	{	foreach ($ConfDataRuleIt in $ConfData.LRule)
		{	m~ConfDataS~Inherit $ConfDataRuleIt $ConfDataIt.VRuleDef VDBName;
			m~ConfDataS~Inherit $ConfDataRuleIt $ConfDataIt.VRuleDef VDiffFullRatioMax;
			m~ConfDataS~Inherit $ConfDataRuleIt $ConfDataIt.VRuleDef VDiffSizeFactor;
			m~ConfDataS~Inherit $ConfDataRuleIt $ConfDataIt.VRuleDef VDiffFullSizeMax;
			m~ConfDataL~Inherit $ConfDataRuleIt $ConfDataIt.VRuleDef LDataBkpDTW;
			m~ConfDataL~Inherit $ConfDataRuleIt $ConfDataIt.VRuleDef LTlogBkpDTW;
			m~ConfDataL~Inherit $ConfDataRuleIt $ConfDataIt.VRuleDef LLangolier;
		}
	}
	
	return $ConfData; #<--
}