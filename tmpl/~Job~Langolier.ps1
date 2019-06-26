# Will remove outdated backups. Required configuration file wildcard as $0 parameter.
[datetime]$LogDate = Get-Date;

[String]$ScriptDir = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition).TrimEnd('\');
[String]$ScriptFile = [IO.Path]::GetFileName($MyInvocation.MyCommand.Definition);

Import-Module JobShedule.Util -ArgumentList $ScriptDir;

try 
{   ~SJLog~Dir~Set "$((Get-Item .).FullName)\rpt" -fRoot;
    Import-Module MSSQL.BackupRestore <# -ArgumentList '13.0.0.0' #>;

    [Collections.Generic.SortedSet[String]]$DirCll = [Collections.Generic.SortedSet[String]]::new();

    foreach ($ConfFileIt in Get-ChildItem $args[0])
    {   try
        {   [NPSShJob.CConfData]$ConfData = ~MSSQLBR~Langolier~Conf~Load -iaPath ($ConfFileIt.FullName) -fRaw;
            [Boolean]$Runnable = $true;
        }
        catch
        {   [Boolean]$Runnable = $false}

        if (-not $Runnable)
        {   continue}

        [String[]]$Local:BkpRepoArr = ~SJConf~List~Parse   $ConfData.ValueTree SLRepo    String -fNullable -fOut;
        [String]$Local:SrvInst      = ~SJConf~Scalar~Parse $ConfData.ValueTree SVSrvInst String -fNullable -fOut;
        [String]$Local:DBName       = ~SJConf~Scalar~Parse $ConfData.ValueTree SVDBName  String -fNullable -fOut;

        [Boolean]$Runnable = $null -ne $Local:BkpRepoArr;
        [Boolean]$Runnable = $Runnable -and -not [String]::IsNullOrEmpty($Local:SrvInst);
        [Boolean]$Runnable = $Runnable -and -not [String]::IsNullOrEmpty($Local:DBName);

        if (-not $Runnable)
        {   continue}

        $Runnable = $false;
        $Local:BkpRepoArr `
        |   % {$Runnable = $Runnable -or $DirCll.Add([IO.Path]::Combine($_, [Uri]::EscapeDataString($Local:SrvInst) + '\' + [Uri]::EscapeDataString($Local:DBName)))};
        
        if (-not $Runnable)
        {   continue}
        
        try
        {   ~MSSQLBR~Langolier~Conf~Load -iConf $ConfData | % {~MSSQLBR~Langolier~Do @_}}
        catch
        {   <# ~MSSQLBR~Langolier~Conf~Load will send message to log in case of error. #>>}
    }
}
catch 
{   ~SJLog~MsgException~New Err $LogDate $_ -iLogSrc ($MyInvocation.MyCommand);
    throw;
}
