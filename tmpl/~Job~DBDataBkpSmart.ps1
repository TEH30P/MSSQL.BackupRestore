Import-Module JobShedule.Util -ArgumentList "$((Get-Item .).FullName)\rpt";
Import-Module '.\MSSQL.BackupRestore3\MSSQL.BackupRestore3.psm1' <# -ArgumentList '13.0.0.0' #>;

~MSSQLBR~DBDataBkpSmart~Do `
    -iSrvInst '' `
    -iDBName '' `
    -iaRepoPath @('') `
    -iStartAt ([datetime]::now) `
    -iDuration '0.00:00:00' `
    -iDiffFullRatioMax 0.25 `
    -iDiffSizeFactor 2 `
    -iTotalSizeMax 0GB `
    -iOperAllow 'df' `
    -iArcLayer 0 `
    -iPriority 0 `
    -fCompression `
    -fAsShJob `
;

    