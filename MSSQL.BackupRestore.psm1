param 
(	[version]$iSMOVer = '0.0.0.0')

[String]$Script:mSrciptDir = $PSScriptRoot;
[String]$Script:mScriptFile = [IO.Path]::GetFileName($MyInvocation.MyCommand.Path);

[psobject]$Script:mPSModule = $ExecutionContext.SessionState.Module;

if ($null -eq $iSMOVer -or $iSMOVer -eq '0.0.0.0')
{	for([Int32]$MajorVer = 14; $MajorVer -ge 11; $MajorVer--)
	{	try	
		{	Add-Type -AssemblyName `
				"Microsoft.SqlServer.ConnectionInfo, Version=$MajorVer.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"`
			,	"Microsoft.SqlServer.Smo, Version=$MajorVer.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"`
			,	"Microsoft.SqlServer.SmoExtended, Version=$MajorVer.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
			
			break;
		}
		catch
		{	}
	}

	if ($MajorVer -lt 11)
	{	throw 'Microsoft.SqlServer.Smo assembly is not found.'}
}
else
{	Add-Type -AssemblyName `
		"Microsoft.SqlServer.ConnectionInfo, Version=$($iSMOVer.ToString()), Culture=neutral, PublicKeyToken=89845dcd8080cc91"`
	,	"Microsoft.SqlServer.Smo, Version=$($iSMOVer.ToString()), Culture=neutral, PublicKeyToken=89845dcd8080cc91"`
	,	"Microsoft.SqlServer.SmoExtended, Version=$($iSMOVer.ToString()), Culture=neutral, PublicKeyToken=89845dcd8080cc91"
}

<#!!!REM: Debug version
function m~PSModuleComponent~Load
(	[string]$FileName)
{	. $FileName
	Write-Warning "Loaded '$FileName': for test/dev."
}
#>
#!!!REM: Release version
function m~PSModuleComponent~Load
(	[string]$FileName)
{	$ExecutionContext.InvokeCommand.InvokeScript(
		$false
	,	([scriptblock]::Create([IO.File]::ReadAllText($FileName, [Text.Encoding]::UTF8)))
	,	$null
	,	$null)	
}
#>

[String]$FileName = "$mSrciptDir\priv";

foreach ($FileName in [IO.Directory]::GetFiles($FileName))
{	if ($FileName.EndsWith('.ps1')) 
	{	. m~PSModuleComponent~Load $FileName}
}

[String]$FileName = "$mSrciptDir\pub";

foreach ($FileName in [IO.Directory]::GetFiles($FileName))
{	if ($FileName.EndsWith('.ps1'))
	{	. m~PSModuleComponent~Load $FileName}

	if ($FileName.EndsWith('.cs'))
	{	if ([IO.Path]::GetFileNameWithoutExtension($FileName) -as [Type])
		{	continue}

		[String[]]$aRefAcc = @();
		[String]$Definiction = [string]::Empty;

		foreach ($LineIt in [IO.File]::ReadAllLines($FileName, [Text.Encoding]::UTF8))
		{	if ($LineIt.StartsWith('//ref:'))
			{	$aRefAcc += $LineIt.Substring(('//ref:').Length).TrimStart()}
			else
			{	$Definiction += "`r`n" + $LineIt}
		}

		Add-Type -ReferencedAssemblies $aRefAcc -TypeDefinition $Definiction | Out-Null;
	}
}

Export-ModuleMember `
	-Function '~MSSQLBR~*' `
	-Cmdlet '~MSSQLBR~*' `
	-Alias 'New-MSSQLBkpFileName', 'New-MSSQLBkpRepo', 'Select-MSSQLBkpFile', 'New-MSSQLDBDataBkp', 'Import-MSSQLDBDataBkpConf', 'Invoke-MSSQLDBDataBkp', 'New-MSSQLBRDBFileRelocRule', 'Test-MSSQLBRDBFileRelocRule', 'Invoke-MSSQLDBRst', 'Add-MSSQLBRDBSnapshot', 'Remove-MSSQLBRDBSnapshot', 'Import-MSSQLBkpLangolierConf', 'Invoke-MSSQLBkpLangolier', 'Invoke-MSSQLBRQueueMtn', 'New-MSSQLDBTLogBkp', 'Import-MSSQLDBTLogBkpConf', 'Invoke-MSSQLDBTLogBkp' `
;