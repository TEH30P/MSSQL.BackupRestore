#--------------------------------#
#!!!TODO: test
function m~BkpFileData~Name~Parse
(	[String]$iName
,	[PSCustomObject]$ioBkpInfo
)
{	[String[]]$FileNameArr = $iName.Split('.');
	
	if ($FileNameArr.Count -lt 3 -or $FileNameArr[-1] -ne 'bak')
	{	throw [FormatException]::new('Invalid bakup file path format.')}
	
	[NMSSQL.MBkpRst.EBkpJobType]$JobType = ${m~FSName~EBkpJobType~dFromFS}[$FileNameArr[1]];
	
	if (($JobType -band [NMSSQL.MBkpRst.EBkpJobType]::CodeMask) -eq [NMSSQL.MBkpRst.EBkpJobType]::DBCode)
	{	if ((4, 5 -notcontains $FileNameArr.Count))
		{	throw [FormatException]::new('Invalid bakup file path format.')}

		$ioBkpInfo | Add-Member -NotePropertyName PSAt       -NotePropertyValue (m~FSName~DateTime~Parse $FileNameArr[0]);
		$ioBkpInfo | Add-Member -NotePropertyName PSJobType  -NotePropertyValue $JobType;
		$ioBkpInfo | Add-Member -NotePropertyName PSArcLayer -NotePropertyValue (m~FSName~UInt~NParse $FileNameArr[2]);
		
		if ($FileNameArr.Count -gt 4)
		{	$ioBkpInfo | Add-Member -MemberType NoteProperty -Name 'PSDevSeqCode' -Value ($FileNameArr[3])}
	}
	else 
	{	if ((5, 6 -notcontains $FileNameArr.Count))
		{	throw [FormatException]::new('Invalid bakup file path format.')}
	
		$ioBkpInfo | Add-Member -NotePropertyName PSAt        -NotePropertyValue (m~FSName~DateTime~Parse $FileNameArr[0]);
		$ioBkpInfo | Add-Member -NotePropertyName PSJobType   -NotePropertyValue $JobType;
		$ioBkpInfo | Add-Member -NotePropertyName PSDBObjName -NotePropertyValue (m~FSName~SQLObjName~Parse $FileNameArr[2]);
		$ioBkpInfo | Add-Member -NotePropertyName PSArcLayer  -NotePropertyValue (m~FSName~UInt~NParse $FileNameArr[3]);
		
		if ($FileNameArr.Count -gt 5)
		{	$ioBkpInfo | Add-Member -MemberType NoteProperty -Name 'PSDevSeqCode' -Value ($FileNameArr[4])}
	}

	$ioBkpInfo | Add-Member -NotePropertyName PSIsCopyOnly -NotePropertyValue ($null -eq $ioBkpInfo.PSArcLayer);
}
#--------------------------------#
#!!!TODO: test
function m~BkpFileTLog~Name~Parse
(	[String]$iName
,	[PSCustomObject]$ioBkpInfo
)
{	[String[]]$FileNameArr = $iName.Split('.');
	
	if ((3, 4 -notcontains $FileNameArr.Count) -or $FileNameArr[-1] -ne 'trn')
	{	throw [FormatException]::new('Invalid bakup file path format.')}

	$ioBkpInfo | Add-Member -NotePropertyName PSAt      -NotePropertyValue (m~FSName~DateTime~Parse $FileNameArr[0]);
	$ioBkpInfo | Add-Member -NotePropertyName PSLSNLast -NotePropertyValue (m~FSName~SQLLSN~NParse $FileNameArr[1]);
	
	$ioBkpInfo | Add-Member -NotePropertyName PSJobType -NotePropertyValue ([NMSSQL.MBkpRst.EBkpJobType]::TLog);
	
	if ($FileNameArr.Count -gt 3)
	{	$ioBkpInfo | Add-Member -MemberType NoteProperty -Name 'PSDevSeqCode' -Value ($FileNameArr[2])}

	$ioBkpInfo | Add-Member -NotePropertyName PSIsCopyOnly -NotePropertyValue ($null -eq $ioBkpInfo.PSLSNLast);
}
#--------------------------------#
#!!!TODO: test
# Parse backup file name and path. Returns gathered info.
function m~BkpFile~Path~Parse
(	[String]$iPath)
{	[String]$DirPath = [IO.Path]::GetDirectoryName($iPath);
	
	[String]$DBName = m~FSName~SQLObjName~Parse ([IO.Path]::GetFileName($DirPath));
	[String]$DirPath = [IO.Path]::GetDirectoryName($DirPath);
	[String]$SrvInst = m~FSName~SQLSrvInst~Parse ([IO.Path]::GetFileName($DirPath));
	[String]$DirPath = [IO.Path]::GetDirectoryName($DirPath);

	[NMSSQL.MBkpRst.EBkpJobType]$JobType `
		= switch -Exact ([IO.Path]::GetFileName($DirPath))
		{	'data'
			{	[NMSSQL.MBkpRst.EBkpJobType]::Data}
			'tlog'
			{	[NMSSQL.MBkpRst.EBkpJobType]::TLog}
			default
			{	throw [FormatException]::new('Invalid bakup file path format.')}
		};
	
	[PSCustomObject]$Ret = [PSCustomObject] `
	@{	PSSrvInst  = $SrvInst 
	;	PSDBName   = $DBName
	;	PSFilePath = $iPath};

	if ($JobType -eq 'TLog')
	{	m~BkpFileTLog~Name~Parse ([IO.Path]::GetFileName($iPath)) -ioBkpInfo $Ret}
	else 
	{	m~BkpFileData~Name~Parse ([IO.Path]::GetFileName($iPath)) -ioBkpInfo $Ret}

	return $Ret; #<--
}