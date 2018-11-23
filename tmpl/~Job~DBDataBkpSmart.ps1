Import-Module JobShedule.Util -ArgumentList "$((Get-Item .).FullName)\rpt";
Import-Module '.\MSSQL.BackupRestore\MSSQL.BackupRestore.psm1' <# -ArgumentList '13.0.0.0' #>;

~MSSQLBR~DBDataBkpSmart~Do `
    -iSrvInst '' <# сервер #> `
    -iDBName '' <# база #> `
    -iaRepoPath @('') <# папка для бекапов #> `
    -iStartAt ([datetime]::now) <# не трогай лучше #> `
    -iDuration '0.00:00:00' <# временное окно см. tp.md #> `
    -iDiffFullRatioMax 0.25 <# забей #> `
    -iDiffSizeFactor 2 <# забей #> `
    -iTotalSizeMax 0GB <# масимальный размер бекапа для алертов #> `
    -iOperAllow 'df' <# что делать 'd' = diff, 'f' = full #> `
    -iArcLayer 0 <# забей #> `
    -iPriority 0 <# не работает пока #> `
    -fCompression <# компрессию вкл/выкл #>> `
    -fAsShJob <# не трогай :) #> `
;

    