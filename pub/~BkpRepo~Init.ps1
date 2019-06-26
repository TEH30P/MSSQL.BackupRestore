New-Alias -Name New-MSSQLBkpRepo  -Value '~MSSQLBR~BkpRepo~Init' -Force;

# Initialize backup repo. Will create dirs tree.
function ~MSSQLBR~BkpRepo~Init
{	param
	(   [parameter(Mandatory=1, position=0)]
			[Uri[]]$iaRepoPath
	);
try
{	
	foreach ($DirIt in m~BkpDirPathRoot~Tlog~Get $iaRepoPath)
	{	if (-not [IO.Directory]::Exists($DirIt))
		{	[Void][IO.Directory]::CreateDirectory($DirIt)}
	}

	foreach ($DirIt in m~BkpDirPathRoot~Data~Get $iaRepoPath)
	{	if (-not [IO.Directory]::Exists($DirIt))
		{	[Void][IO.Directory]::CreateDirectory($DirIt)}
	}

	foreach ($DirIt in m~QueueDirPathRoot~Get $iaRepoPath)
	{	if (-not [IO.Directory]::Exists($DirIt))
		{	[Void][IO.Directory]::CreateDirectory($DirIt)}
	}
}
catch 
{	throw}
}