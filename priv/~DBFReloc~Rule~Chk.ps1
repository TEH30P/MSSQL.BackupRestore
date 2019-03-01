function m~DBFReloc~Rule~Chk
(	[NMSSQL.MBkpRst.CDBFileReloc]$iRule
,	[String]$iDBFilePName
,	[String]$iDBFileLName
,	[System.Nullable[NMSSQL.MBkpRst.EDBFileType]]$iDBFileType
)
{	[Byte]$FiltState = 3;

	if ($null -ne $iRule.ALogicNamePtrn -and $iRule.ALogicNamePtrn.GetEnumerator().MoveNext() `
		-and -not [String]::IsNullOrEmpty($iDBFileLName))
	{	foreach ($PtrnIt in $iRule.ALogicNamePtrn)
		{	if ($iDBFileLName -like $PtrnIt)
			{	$FiltState--;
				break;
			}
		}
	}
	else
	{	$FiltState--}
	
	if ($null -ne $iRule.APhysNamePtrn -and $iRule.APhysNamePtrn.GetEnumerator().MoveNext() `
		-and -not [String]::IsNullOrEmpty($iDBFilePName))
	{	foreach ($PtrnIt in $iRule.APhysNamePtrn)
		{	if ($iDBFilePName -like $PtrnIt)
			{	$FiltState--;
				break;
			}
		}
	}
	else
	{	$FiltState--}

	if ($null -ne $iRule.DTypeRelStr -and $iRule.DTypeRelStr.Count `
		-and $null -ne $iDBFileType)
	{	[String]$DBFileTypeStr `
		= @{[NMSSQL.MBkpRst.EDBFileType]::TLog = 'L' `
		;	[NMSSQL.MBkpRst.EDBFileType]::Rows = 'D' `
		;	[NMSSQL.MBkpRst.EDBFileType]::FileStream = 'S' `
		}[$iDBFileType];
		
		if (([System.Collections.IDictionary]$iRule.DTypeRelStr).Contains($DBFileTypeStr))
		{	$FiltState--}
	}
	else
	{	$FiltState--}

	return -not $FiltState;
}