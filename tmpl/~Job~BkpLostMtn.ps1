# Will search lost backup files and will remove broken files or will rename its if files is ok. Required backup configuration file path as $0 parameter.
[datetime]$LogDate = Get-Date;

Import-Module MSSQL.BackupRestore <# -ArgumentList '13.0.0.0' #>;
Import-Module JobShedule.Util -ArgumentList "$((Get-Item .).FullName)\rpt";

[String]$ScriptDir = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition).TrimEnd('\');
[String]$ScriptFile = [IO.Path]::GetFileName($MyInvocation.MyCommand.Definition);

try 
{   ~SJLog~Dir~Set "$((Get-Item .).FullName)\rpt" -fRoot;

    [String[]]$ParamMsgCll = 'Param0', $args[0];

    $Opt = ~SJConf~File~Parse -iPath (Resolve-Path $args[0]) -iKeyRoot 'OV-MSSQLBkp';
    [String]$RepoPath = ~SJConf~List~Parse $Opt.ValueTree 'SLRepo' String -fOut;
	[Collections.ArrayList]$DBDirArr = @();
	[IO.Directory]::EnumerateDirectories([IO.Path]::Combine($RepoPath, 'Data')) | % {[Void]$DBDirArr.Add($_)};
	[IO.Directory]::EnumerateDirectories([IO.Path]::Combine($RepoPath, 'Tlog')) | % {[Void]$DBDirArr.Add($_)};
	
    foreach ($DirIt in $DBDirArr | % {[IO.Directory]::EnumerateDirectories($_)})
	{	foreach ($FileIt in [IO.Directory]::EnumerateFiles($DirIt, '~~~~*.*'))
		{	if ([IO.File]::GetLastWriteTimeUtc($FileIt) + [TimeSpan]'0.00:05:00' -ge [DateTime]::Now.ToUniversalTime())
			{	continue}
			
			try
			{
				[String]$FileNew = ~MSSQLBR~BkpFile~Name~Gen -iaRepoPath $RepoPath -iSrvInst . -iaBkpFilePath $FileIt
			}
			catch 
			{	[String]$FileNew = [String]::Empty}
			
			if ($FileNew.Length)
			{	[IO.File]::Move($FileIt, $FileNew)}
			else
			{	[IO.File]::Delete($FileIt)}
		}
    }
}
catch
{   ~SJLog~MsgException~New Err $LogDate $_ -iLogSrc $ScriptFile;

	try 
	{	~SJLog~Msg~New Wrn $LogDate $ParamMsgCll -iKey 'Para' -fAsKeyValue -iLogSrc $ScriptFile}
	catch 
	{}

    throw;
}