#--------------------------------#
# Configuration values parse.
function m~ConfData~BkpMain~Parse
(	[Collections.IDictionary]$oiObj
)
{	if (-not ([System.Collections.IDictionary]$oiObj).Contains('SLRepo') -or -not $oiObj['SLRepo'].Count)
	{	throw [Exception]::new('''SLRepo'' configuration attribute is required.')}
	
	~SJConf~List~Parse $oiObj SLRepo String;
	~SJConf~Scalar~Parse $oiObj SVSrvInst String;
	~SJConf~Scalar~Parse $oiObj SVDBName String;
}
#--------------------------------#
# Configuration values parse for DBDataBkpSmart.
function m~ConfData~DBDataBkpSmart~Parse
(	[NPSShJob.CConfData]$oiData)
{		
	m~ConfData~BkpMain~Parse $oiData.ValueTree;
	$Rule = $oiData.ValueTree.OVDataBkpRule;

	if ($null -eq $Rule)
	{	throw [Exception]::new('''OVDataBkpRule'' configuration section not found.')}

	~SJConf~Scalar~Parse $Rule SVOperAllow String -fNullable;
	~SJConf~Scalar~Parse $Rule SVDiffFullRatioMax Double;
	~SJConf~Scalar~Parse $Rule SVTotalSizeMax Int64 -fNullable;
	~SJConf~Scalar~Parse $Rule SVDiffSizeFactor Double;
	~SJConf~Scalar~Parse $Rule SVArchLayer Byte -fNullable;
	~SJConf~Scalar~Parse $Rule SVCompression Boolean -fNullable;
	~SJConf~Scalar~Parse $Rule SVBegin DateTime -fNullable;
	~SJConf~Scalar~Parse $Rule SVDuration TimeSpan;	
}
#--------------------------------#
# Configuration values parse for TLogBkpSmart.
function m~ConfData~TLogBkpSmart~Parse
(	[NPSShJob.CConfData]$oiData)
{	
	m~ConfData~BkpMain~Parse $oiData.ValueTree;
	$Rule = $oiData.ValueTree.OVTLogBkpRule;
	
	if ($null -eq $Rule)
	{	throw [Exception]::new('''OVTLogBkpRule'' configuration section not found.')}

	~SJConf~Scalar~Parse $Rule SVAgeTrg TimeSpan -fNullable;
	~SJConf~Scalar~Parse $Rule SVUsageMaxTrg Int64 -fNullable;
	~SJConf~Scalar~Parse $Rule SVUsageMinTrg Int64 -fNullable;
	~SJConf~Scalar~Parse $Rule SVChkPeriod TimeSpan -fNullable;
	~SJConf~Scalar~Parse $Rule SVCompression Boolean -fNullable;
	~SJConf~Scalar~Parse $Rule SVBegin DateTime -fNullable;
	~SJConf~Scalar~Parse $Rule SVDuration TimeSpan;
}
#--------------------------------#
# Configuration values parse for Langolier.
function m~ConfData~Langolier~Parse
(	[NPSShJob.CConfData]$oiData)
{	
	m~ConfData~BkpMain~Parse $oiData.ValueTree;
	$Rule = $oiData.ValueTree.OVLangolierRule;
	
	if ($null -eq $Rule)
	{	throw [Exception]::new('''OVLangolierRule'' configuration section not found.')}
	
	~SJConf~Scalar~Parse $Rule SVKeepCopyOnly Boolean -fNullable;
	~SJConf~Scalar~Parse $Rule SVTlogRtn TimeSpan -fNullable;
	~SJConf~List~Parse $Rule SLDataRtn TimeSpan;
}
#--------------------------------#
