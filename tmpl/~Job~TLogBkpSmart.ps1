Import-Module JobShedule.Util -ArgumentList "$((Get-Item .).FullName)\rpt";
Import-Module '.\M_MSSQL.BackupRestore\MSSQL.BackupRestore.psm1' <# -ArgumentList '13.0.0.0' #>;
~MSSQLBR~TLogBkpSmart~Conf~Load -iaPath ($args[0]) | % {~MSSQLBR~TLogBkpSmart~Do @_};