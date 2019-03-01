#--------------------------------#
# Will create new file relocation rule.
function m~DBFReloc~Rule~New 
(   [psobject]$iTmpl
,   [String[]]$iaPNamePtrn
,   [String[]]$iaLNamePtrn
,   [hashtable]$idTypeRel
)
{	[NMSSQL.MBkpRst.CDBFileReloc]$Ret = [NMSSQL.MBkpRst.CDBFileReloc]::new();
	
	if ($iTmpl -is [string])
	{	$Ret.PathTmpl = [scriptblock]::Create('"' + $iTmpl.Replace('"', '`"') + '"')}
	else
	{	$Ret.PathTmpl = $iTmpl}
	
	if ($null -ne $idTypeRel -and $idTypeRel.Count)
	{	$Ret.DTypeRelStr = [System.Collections.IDictionary]$TypeRelDic = [System.Collections.Generic.Dictionary[String, String]]::new();

		foreach($KVIt in $idTypeRel.GetEnumerator())
		{	[void]$TypeRelDic.Add($KVIt.Key, $KVIt.Value)}
	}

	if ($iaPNamePtrn -ne $null -and $iaPNamePtrn.Count)
	{	$Ret.APhysNamePtrn = $iaPNamePtrn}

	if ($iaLNamePtrn -ne $null -and $iaLNamePtrn.Count)
	{	$Ret.ALogicNamePtrn = $iaLNamePtrn}

	return $Ret; #<--
}
#--------------------------------#
# Will create new file relocation rule.
function m~DBFReloc~RuleStd~New
(   [String]$iDataDir
,   [String]$iTLogDir
,   [Boolean]$iAppendBkpDate
,   [Boolean]$iAppendCurrDate
)
{	if ($iAppendBkpDate -and $iAppendCurrDate)
	{	[scriptblock]$Tmpl = [scriptblock]::Create({"$MSSQLDBFileTypeRelStr\${MSSQLDBNew}${MSSQLDBFilePNameRest}_${MSSQLDBBkpAt}_${SysDateTime}${MSSQLDBFilePExt}"}.ToString())}
	elseif ($iAppendBkpDate)
	{	[scriptblock]$Tmpl = [scriptblock]::Create({"$MSSQLDBFileTypeRelStr\${MSSQLDBNew}${MSSQLDBFilePNameRest}_${MSSQLDBBkpAt}${MSSQLDBFilePExt}"}.ToString())}
	elseif ($iAppendCurrDate)
	{	[scriptblock]$Tmpl = [scriptblock]::Create({"$MSSQLDBFileTypeRelStr\${MSSQLDBNew}${MSSQLDBFilePNameRest}_${SysDateTime}${MSSQLDBFilePExt}"}.ToString())}
	else
	{	[scriptblock]$Tmpl = [scriptblock]::Create({"$MSSQLDBFileTypeRelStr\${MSSQLDBNew}${MSSQLDBFilePNameRest}${MSSQLDBFilePExt}"}.ToString())}
	
	[System.Collections.IDictionary]$TypeRelDic = [System.Collections.Generic.Dictionary[String, String]]::new();
	[void]$TypeRelDic.Add('D', $iDataDir.TrimEnd([IO.Path]::DirectorySeparatorChar));
	[void]$TypeRelDic.Add('S', $iDataDir.TrimEnd([IO.Path]::DirectorySeparatorChar));
	[void]$TypeRelDic.Add('L', $iTLogDir.TrimEnd([IO.Path]::DirectorySeparatorChar));

	return New-Object NMSSQL.MBkpRst.CDBFileReloc -Property @{PathTmpl=$Tmpl; DTypeRelStr=$TypeRelDic};
}