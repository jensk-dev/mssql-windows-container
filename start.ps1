$ErrorActionPreference = 'Stop'

# Import the SQL Server Container module
$modulePath = Join-Path $PSScriptRoot 'modules\SqlServerContainer\SqlServerContainer.psm1'

if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
}
else {
    Write-Error "SqlServerContainer module not found at: $modulePath"
    exit 1
}

# Start the container using the module function
Start-SqlContainer
