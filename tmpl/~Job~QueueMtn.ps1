[Int32]   $QueueActiveChkPeriod = 1;
[Int32]   $QueueActiveCntMax = 0;
[timespan]$QueueActiveRtn = '0.00:05:00'
[Int32]   $QueueHistoryChkPeriod = 60*60;
[timespan]$QueueHistoryRtn = '1.00:00:00'
[uri[]]$RepoPathArr = @();

#--------------------------------#
Import-Module JobShedule.Util -ArgumentList "$((Get-Item .).FullName)\rpt";
Import-Module '.\MSSQL.BackupRestore3\MSSQL.BackupRestore3.psm1' <# -ArgumentList '13.0.0.0' #>;

[datetime]$HistChkTime = [datetime]::Now.AddSeconds($QueueHistoryChkPeriod);

while ($true)
{	try 
	{	Start-Sleep $QueueActiveChkPeriod;
        ~MSSQLBR~QueueMtn~Do $RepoPathArr A $QueueActiveRtn $QueueActiveCntMax -fAsShJob;
        
        if ([datetime]::Now -ge $HistChkTime)
        {   ~MSSQLBR~QueueMtn~Do $RepoPathArr H $QueueHistoryRtn -fAsShJob;
            $HistChkTime = [datetime]::Now.AddSeconds($QueueHistoryChkPeriod);
        }
	}
	catch 
	{	}
}
