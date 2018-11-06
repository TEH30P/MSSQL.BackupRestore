Import-Module JobShedule.Util -ArgumentList "$((Get-Item .).FullName)\rpt";
Import-Module '.\MSSQL.BackupRestore3\MSSQL.BackupRestore3.psm1' <# -ArgumentList '13.0.0.0' #>;

~MSSQLBR~Langolier~Do `
    -iSrvInst '' `
    -iDBName '' `
    -iaRepoPath @('') `
    -iDataRtn '0' `
    -iLayer 0 `
    -iTLogRtn '0' `
    -fAsShJob `
;
