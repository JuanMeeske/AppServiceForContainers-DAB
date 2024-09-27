param(
    [string]$ServerName,
    [string]$DatabaseName,
    [string]$Username,
    [string]$Password
)

# SQL command to create the tables
$sqlCommand = @"
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[table1]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[table1] (
        id INT PRIMARY KEY,
        name NVARCHAR(100),
        email NVARCHAR(255),
        age INT,
        created_at DATETIME2 DEFAULT SYSDATETIME()
    )
END

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[table2]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[table2] (
        id INT PRIMARY KEY,
        name NVARCHAR(100),
        email NVARCHAR(255),
        age INT,
        created_at DATETIME2 DEFAULT SYSDATETIME()
    )
END
"@

# Create connection string
$connectionString = "Server=$ServerName.database.windows.net;Database=$DatabaseName;User ID=$Username;Password=$Password;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# Execute SQL command
try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()

    $cmd = New-Object System.Data.SqlClient.SqlCommand($sqlCommand, $connection)
    $cmd.ExecuteNonQuery()

    Write-Host "Tables 'table1' and 'table2' created successfully."
}
catch {
    Write-Host "An error occurred: $_"
    exit 1
}
finally {
    if ($connection.State -eq 'Open') {
        $connection.Close()
    }
}