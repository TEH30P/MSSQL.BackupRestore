#--------------------------------#
# Generate data backup filename.
function m~BkpFilePath~Data~Gen
(	[String]$iSrvInst
,	[String]$iDBName
,	[Uri[]]$iaRepoPath
,	[NMSSQL.MBkpRst.EBkpJobType]$iJobType
,	[String]$iDBObjName
,	[Nullable[Byte]]$iArcLayer
,	[DateTime]$iAt
)
{	if ($iaRepoPath.Count -gt 1)
	{	[String]$DevSeqCode = 'a.'}
	else 
	{	[String]$DevSeqCode = ''}

	foreach ($BkpDirIt in m~BkpDirPath~Data~Gen $iSrvInst $iDBName $iaRepoPath)
	{	if (-not [IO.Directory]::Exists($BkpDirIt))
		{	[Void][IO.Directory]::CreateDirectory($BkpDirIt)}

		if (($iJobType -band [NMSSQL.MBkpRst.EBkpJobType]::CodeMask) -eq [NMSSQL.MBkpRst.EBkpJobType]::DBCode)
		{	'{0}\{1}.{2}.{3}.{4}bak' -f `
					$BkpDirIt `
				,	(m~FSName~DateTime~NConvert $iAt -fNullHigh) `
				,	${m~FSName~EBkpJobType~dToFS}[[String]$iJobType] `
				,	(m~FSName~UInt~NConvert $iArcLayer 2) `
				,	$DevSeqCode ; #<--
		}
		elseif ([NMSSQL.MBkpRst.EBkpJobType]::FlCode, [NMSSQL.MBkpRst.EBkpJobType]::FGCode -contains ($iJobType -band [NMSSQL.MBkpRst.EBkpJobType]::CodeMask))
		{	'{0}\{1}.{2}.{3}.{4}.{5}bak' -f `
					$BkpDirIt `
				,	(m~FSName~DateTime~NConvert $iAt -fNullHigh) `
				,	${m~FSName~EBkpJobType~dToFS}[[String]$iJobType] `
				,	(m~FSName~SQLObjName~Convert $iDBObjName) `
				,	(m~FSName~UInt~NConvert $iArcLayer 2) `
				,	$DevSeqCode ; #<--
		} 
		else 
		{	throw [ArgumentException]::new('Not supported backup job type')}

		if ($DevSeqCode.Length)
		{	$DevSeqCode = [char]::ConvertFromUtf32([char]::ConvertToUtf32($DevSeqCode, 0) + 1) + '.'}
	}
}
#--------------------------------#
# Generate tlog backup filename.
function m~BkpFilePath~TLog~Gen
(	[String]$iSrvInst
,	[String]$iDBName
,	[Uri[]]$iaRepoPath
,	[DateTime]$iAt
,	[Nullable[Decimal]]$iLSNLast
)
{	if ($iaRepoPath.Count -gt 1)
	{	[String]$DevSeqCode = 'a.'}
	else 
	{	[String]$DevSeqCode = ''}

	foreach ($BkpDirIt in m~BkpDirPath~TLog~Gen $iSrvInst $iDBName $iaRepoPath)
	{	if (-not [IO.Directory]::Exists($BkpDirIt))
		{	[Void][IO.Directory]::CreateDirectory($BkpDirIt)}

		'{0}\{1}.{2}.{3}trn' -f `
        		$BkpDirIt `
        	,	(m~FSName~DateTime~NConvert $iAt -fNullHigh) `
        	,	(m~FSName~SQLLSN~NConvert $iLSNLast -fNullHigh) `
        	,	$DevSeqCode ; #<--

		if ($DevSeqCode.Length)
		{	$DevSeqCode = [char]::ConvertFromUtf32([char]::ConvertToUtf32($DevSeqCode, 0) + 1) + '.'}
	}
}
