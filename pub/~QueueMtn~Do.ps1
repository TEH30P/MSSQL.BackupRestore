New-Alias -Name Invoke-MSSQLBRQueueMtn -Value '~MSSQLBR~QueueMtn~Do' -Force;

# Queue maintenance process. Remove old or activate new items.
function ~MSSQLBR~QueueMtn~Do
{   param
	(	[parameter(Mandatory=1, position=0)]
			[Uri[]]$iaRepoPath
	,	[parameter(Mandatory=1, position=1)]
			[String][ValidateSet('Activity', 'A', 'History', 'H')]$iMode
	,	[parameter(Mandatory=1, position=2)]
			[timespan]$iRetention
	,	[parameter(Mandatory=0, position=3)]
			[int32]$iActivedCntMax = 0
	,   [parameter(Mandatory=0)]
			[switch]$fAsShJob
	)

	#!!!TODO: propertly handle io errors
try 
{	[datetime]$LogDate = [datetime]::Now;
	[String]$Mode = @{'A' = 'A'; 'Activity' = 'A'; 'H' = 'H'; 'History' = 'H'}[$iMode];

	if ('A' -ceq $Mode)
	{	# Active item to Error if no heartbit.

		[Int32]$ActCnt = 0;
		[datetime]$Oldest = [datetime]::Now - $iRetention;

		foreach ($QIIt in m~Queue~Get $iaRepoPath 'Act')
		{	if ([IO.FileInfo]::new($QIIt.PSFilePath).LastWriteTime -lt $Oldest)
			{	try 
				{	m~QueueItem~StateSet ($QIIt.PSRepo) ($QIIt.PSKey) ($QIIt.PSState) 'Err'} 
				catch 
				{	if (m~QueueItem~Exists ($QIIt.PSRepo) ($QIIt.PSKey) ($QIIt.PSState))
					{	throw}
				}
			}
			else
			{	$ActCnt++}
		}
		
		# NewItem to Active
		
		if ($iActivedCntMax)
		{	foreach ($QIIt in m~Queue~Get $iaRepoPath 'New')
			{	if ($ActCnt)
				{	try {m~QueueItem~StateSet ($QIIt.PSRepo) ($QIIt.PSKey) ($QIIt.PSState) 'Act'} catch {};
					$ActCnt--;
				}
			}
		}
		else 
		{	foreach ($QIIt in m~Queue~Get $iaRepoPath 'New')
			{	try {m~QueueItem~StateSet ($QIIt.PSRepo) ($QIIt.PSKey) ($QIIt.PSState) 'Act'} catch {}}
		}
	}

	if ('H' -ceq $Mode)
	{	# Finished and Error too old item remove.
		
		[datetime]$Oldest = [datetime]::Now - $iRetention;

		foreach ($QIIt in m~Queue~Get $iaRepoPath 'Fin')
		{	if ([IO.FileInfo]::new($QIIt.PSFilePath).LastWriteTime -lt $Oldest)
			{	m~QueueItem~StateSet ($QIIt.PSRepo) ($QIIt.PSKey) ($QIIt.PSState) 'Nil'}
		}

		foreach ($QIIt in m~Queue~Get $iaRepoPath 'Err')
		{	if ([IO.FileInfo]::new($QIIt.PSFilePath).LastWriteTime -lt $Oldest)
			{	m~QueueItem~StateSet ($QIIt.PSRepo) ($QIIt.PSKey) ($QIIt.PSState) 'Nil'}
		}

		foreach ($QIIt in m~Queue~Get $iaRepoPath 'Wrn')
		{	if ([IO.FileInfo]::new($QIIt.PSFilePath).LastWriteTime -lt $Oldest)
			{	m~QueueItem~StateSet ($QIIt.PSRepo) ($QIIt.PSKey) ($QIIt.PSState) 'Nil'}
		}
	}
}
catch 
{	if ($fAsShJob)
	{	~SJLog~MsgException~New Err $LogDate $_ -iLogSrc ($MyInvocation.MyCommand)}
	
	throw;
}
}