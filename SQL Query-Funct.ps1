[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") 
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") 

Function ConnectSQLServer{

    Param([Parameter(Mandatory=$true)][string]$SQLServer)

    #Connect to server
    $SQLCon = New-SMOconnection -server $SQLServer

    Return $SQLCon

}
Function New-SMOconnection {

    Param (
        [Parameter(Mandatory=$true)]
        [string]$server,
        [int]$StatementTimeout=0
    )

        $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($server)

        $conn.applicationName = "PowerShell SMO"

        $conn.StatementTimeout = $StatementTimeout

        Try {
    
            $conn.Connect()
            $smo = New-Object Microsoft.SqlServer.Management.Smo.Server($conn)
            $smo
        }

        Catch{

            if ($conn.IsOpen -eq $false) {

                Write-Warning "Could not connect to the SQL Server Instance $server. Try ServerName\InstanceName"
                $smo = "NOConnection"
                $smo        
            }
        }
  
}
Function Execute-SQLQuery {
    
    Param (
        [Parameter(Mandatory=$true)]
        [Microsoft.SqlServer.Management.Smo.SqlSmoObject]$ServerConnection,
        [Parameter(Mandatory=$true)][string]$QueryText,
        [Parameter(Mandatory=$true)][string]$DBName
    )

        $db = $ServerConnection.Databases["$DBName"]

        $rs = $db.ExecuteWithResults($QueryText)

        return $rs.Tables.Rows

}
function Run-Query {

    Param (
        [Parameter(Mandatory=$true)][string]$DBName,
        [Parameter(Mandatory=$true)][string]$TableName,
        [Parameter(Mandatory=$true)][string]$SelectColumns,
        [Parameter(Mandatory=$true)][string]$SelectOrderColumn,
        [Parameter(Mandatory=$true)][int]$SelectCount,
        [Parameter(Mandatory=$false)][string]$InsertColumn,
        [Parameter(Mandatory=$false)][string]$CountColumn,
        [Parameter(Mandatory=$true)][int]$QueryLoopCount,
        [Parameter(Mandatory=$true)][int]$QuerySleepInterval
    )

$i = 1;

$CountText = @"
Select Count($CountColumn) as [$TableName Row-Count] From $TableName
"@

$SelectText = @"
Select Top($SelectCount) $SelectColumns
From $TableName
Order By $SelectOrderColumn Desc
"@

    do{ 

$InsertText = @"
Insert Into $TableName 
($InsertColumn)
Values 
('$i')
"@
    
    Write-Warning "Running query loop [$i] of [$QueryLoopCount]"

    $ct = Execute-SQLQuery -ServerConnection $SQLConn -QueryText $CountText -DBName $DBName
    $ct | ft -AutoSize

    Start-Sleep -Seconds $QuerySleepInterval

    Execute-SQLQuery -ServerConnection $SQLConn -QueryText $InsertText -DBName $DBName
    
    Start-Sleep -Seconds $QuerySleepInterval

    $st = Execute-SQLQuery -ServerConnection $SQLConn -QueryText $SelectText -DBName $DBName
    $st | ft -AutoSize

    Start-Sleep -Seconds $QuerySleepInterval

    $i++

    }until($i -ge ($QueryLoopCount+1))

}


$SQLConn = ConnectSQLServer -SQLServer "Lab-SQLHA"

Run-Query -DBName "lab-test" -TableName "dbo.test_table1" -SelectColumns "ID, [Insert-Date],SomeValue" `
-SelectOrderColumn "ID" -SelectCount 5 -InsertColumn "SomeValue"  -CountColumn "ID" -QueryLoopCount 5 -QuerySleepInterval 1

$SQLConn.ConnectionContext.Disconnect()
