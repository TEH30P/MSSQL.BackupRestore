Import-Module JobShedule.Util -ArgumentList "$((Get-Item .).FullName)\rpt";
Import-Module '.\MSSQL.BackupRestore3\MSSQL.BackupRestore3.psm1' <# -ArgumentList '13.0.0.0' #>;

~MSSQLBR~TLogBkpSmart~Do `
    -iSrvInst '' `
    -iDBName '' `
    -iaRepoPath @('') `
    -iStartAt ([datetime]::now) `
    -iDuration '0.00:00:00' `
    -iAgeTrg '0.00:00:00' `
    -iUsageMinTrg 0 `
    -iUsageMaxTrg ([Int64]::MaxValue) `
    -iChkPeriod '0' `
    -iPriority 0 `
    -fCompression `
    -fAsShJob `
;
