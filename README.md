---
language: powershell
module: MSSQL.BackupRestore
module file: MSSQL.BackupRestore.psm1
---
# Powerhsell module `MSSQL.BackupRestore`.
Backup and restore automation for Microsoft SQL Server.

## Command  `New-MSSQLBkpRepo` (`~MSSQLBR~BkpRepo~Init`)
Initialize backup repo. Will create dirs tree.

## Command `Select-MSSQLBkpFile` (`~MSSQLBR~BkpRepo~Search` )
Search bkp files in repo.

## Command `New-MSSQLBkpFileName` (`~MSSQLBR~BkpFile~Name~Gen`)
Generate backup file name from SQL Baskup header data.

## Command `Backup-MSSQLDBData` (`~MSSQLBR~DBDataBkp~Do`)
DB Data backup process.

## Command `Import-MSSQLDBDataBkpConf` (`~MSSQLBR~DBDataBkpSmart~Conf~Load`)
DB Data smart backup process config parse and verify. Will generate hashtable with parameters for ~MSSQLBR~DBDataBkpSmart~Do.

## Command `Backup-MSSQLDBDataSmart` (`~MSSQLBR~DBDataBkpSmart~Do`)
DB Data backup process. Smart and tricky.

## Command `New-MSSQLBRDBFileRelocRule` (`~MSSQLBR~DBFileReloc~New`)
Will create database file relocation rules.

## Command `Test-MSSQLBRDBFileRelocRule` (`~MSSQLBR~DBFileReloc~Test`)
Will apply relocation rules and returns new file path.

## Command `Restore-MSSQLDB` (`~MSSQLBR~DBRstSmart~Do`)
Nice and sweet database restore.

## Command `Import-MSSQLBkpLangolierConf` (`~MSSQLBR~Langolier~Conf~Load`)
Langolier prcess config parse and verify. Will generate hashtable with parameters for ~MSSQLBR~Langolier~Do.

## Command `Invoke-MSSQLBkpLangolier` (`~MSSQLBR~Langolier~Do`)
Will Remove outdated backups.

## Command `Invoke-MSSQLBRQueueMtn` (`~MSSQLBR~QueueMtn~Do`)
Queue maintenance process. Remove old or activate new items.

## Command `Backup-MSSQLDBTLog` (`~MSSQLBR~TlogBkp~Do`)
DB TLog backup process.

## Command `Import-MSSQLDBTLogBkpConf` (`~MSSQLBR~TLogBkpSmart~Conf~Load`)
Will generate hashtable with parameters for ~MSSQLBR~TLogBkpSmart~Do.

## Command `Backup-MSSQLDBTLogSmart` (`~MSSQLBR~TLogBkpSmart~Do`)
DB TLog backup process. Smart and tricky.

## Command `Add-MSSQLBRDBSnapshot` (`~MSSQLBR~DBSnapshot~Create`)
Will create database snapshot.

## Command `Remove-MSSQLBRDBSnapshot` (`~MSSQLBR~DBSnapshot~Delete`)
Will remove database snapshots.
