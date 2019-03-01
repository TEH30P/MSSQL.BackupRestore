# File relcation template processing. Will generate string from template.
function m~DBFReloc~Rule~Apply
(	[NMSSQL.MBkpRst.CDBFileReloc]$iRule
,	[String]$iSrvName
,	[String]$iDBName
,	[String]$iDBNameNew
,	[String]$iDBFilePName
,	[String]$iDBFileLName
,	[NMSSQL.MBkpRst.EDBFileType]$iDBFileType
,	[DateTime]$iBkpAt
,	[DateTime]$iNow
)
{	[String]$DBFileTypeStr = [string]::Empty;
	
	if ($null -ne $iRule.DTypeRelStr)
	{	[String]$DBFileTypeStr `
		= @{[NMSSQL.MBkpRst.EDBFileType]::TLog = 'L' `
		;	[NMSSQL.MBkpRst.EDBFileType]::Rows = 'D' `
		;	[NMSSQL.MBkpRst.EDBFileType]::FileStream = 'S' `
		}[$iDBFileType];

		$DBFileTypeStr = $iRule.DTypeRelStr[$DBFileTypeStr];
	}
	
	[String]$DBNameFSStdAlg = $iDBName;

	foreach($ChIt in [IO.Path]::InvalidPathChars)
	{	$DBNameFSStdAlg = $DBNameFSStdAlg.Replace($ChIt, [Char]'_')}

	foreach($ChIt in '?:%'.GetEnumerator())
	{	$DBNameFSStdAlg = $DBNameFSStdAlg.Replace($ChIt, [Char]'_')}

	[String]$DBFilePFileName = [IO.Path]::GetFileNameWithoutExtension($iDBFilePName);
	[String]$DBFilePFileNameRest = $DBFilePFileName;

	if ($DBFilePFileName.StartsWith($DBNameFSStdAlg, [StringComparison]::OrdinalIgnoreCase))
	{	[String]$DBFilePFileNameRest = $DBFilePFileName.Substring($DBNameFSStdAlg.Length)}
	else 
	{	[String]$DBFilePFileNameRest = $DBFilePFileName}

	[Collections.Generic.List[psvariable]]$VArr = [Collections.Generic.List[psvariable]]::new(6*2);

	[void]$VArr.Add([psvariable]::new('MSSQLSrv', (m~FSName~SQLSrvInst~Convert $iSrvName)));
	[void]$VArr.Add([psvariable]::new('MSSQLDB', (m~FSName~SQLObjName~Convert $iDBName)));
	[void]$VArr.Add([psvariable]::new('MSSQLDBNew', (m~FSName~SQLObjName~Convert $iDBNameNew)));
	[void]$VArr.Add([psvariable]::new('MSSQLDBFileLName', (m~FSName~SQLObjName~Convert $iDBFileLName)));
	[void]$VArr.Add([psvariable]::new('MSSQLDBFilePDir', [IO.Path]::GetDirectoryName($iDBFilePName).TrimEnd([IO.Path]::DirectorySeparatorChar)));
	[void]$VArr.Add([psvariable]::new('MSSQLDBFilePName', $DBFilePFileName));
	[void]$VArr.Add([psvariable]::new('MSSQLDBFilePNameRest', $DBFilePFileNameRest));
	[void]$VArr.Add([psvariable]::new('MSSQLDBFilePNameExt', [IO.Path]::GetFileName($iDBFilePName)));
	[void]$VArr.Add([psvariable]::new('MSSQLDBFilePExt', [IO.Path]::GetExtension($iDBFilePName)));
	[void]$VArr.Add([psvariable]::new('MSSQLDBFileTypeRelStr', $DBFileTypeStr));
	[void]$VArr.Add([psvariable]::new('MSSQLDBBkpAt', (m~FSName~DateTime~Convert $iBkpAt)));
	[void]$VArr.Add([psvariable]::new('SysDateTime', (m~FSName~DateTime~Convert $iNow)));

	return [String]$iRule.PathTmpl.InvokeWithContext($null, $VArr, $null);
}
