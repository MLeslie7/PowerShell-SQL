# PowerShell-SQL-Query-Loop
PowerShell scripts for SQL Server

This script will run a SQL query in a loop to allow testing connectivity during AG failover and other scenarios.
Requires MSSQL Management objects (SQLPS PowerShell Module)
change this section to fit your server line 123-4


Run-Query -DBName "lab-test" -TableName "dbo.test_table1" -SelectColumns "ID, [Insert-Date],SomeValue" `
-SelectOrderColumn "ID" -SelectCount 5 -InsertColumn "SomeValue"  -CountColumn "ID" -QueryLoopCount 5 -QuerySleepInterval 1
