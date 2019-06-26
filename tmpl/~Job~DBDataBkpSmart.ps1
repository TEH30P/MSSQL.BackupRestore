# Will do db data backup. Required configuration file path as $0 parameter.
Import-Module JobShedule.Util -ArgumentList "$((Get-Item .).FullName)\rpt";
Import-Module MSSQL.BackupRestore <# -ArgumentList '13.0.0.0' #>;
~MSSQLBR~DBDataBkpSmart~Conf~Load -iaPath ($args[0]) | % {~MSSQLBR~DBDataBkpSmart~Do @_};