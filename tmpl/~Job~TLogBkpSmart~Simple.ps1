Import-Module '.\M_MSSQL.BackupRestore\MSSQL.BackupRestore.psm1' <# -ArgumentList '13.0.0.0' #>;

~MSSQLBR~TLogBkpSmart~Do `
    -iSrvInst '' <# сервер #> `
    -iDBName '' <# база #> `
    -iaRepoPath @('') <# папка для бекапов #> `
    -iStartAt ([datetime]::now) <# пох #> `
    -iDuration '0.00:00:00' <# временное окно см. tp.md #> `
    -iAgeTrg '0.00:00:00' <# максимальный откат см. tp.md #> `
    -iUsageMinTrg 0 <# мин. размер заполненности лога #> `
    -iUsageMaxTrg ([Int64]::MaxValue) <# макс. размер заполненности лога #> `
    -iChkPeriod '0' `
    -iPriority 0 `
    -fCompression 
;
