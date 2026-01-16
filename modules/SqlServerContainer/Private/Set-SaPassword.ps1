function Set-SaPassword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Password,

        [Parameter()]
        [string]$Server = 'localhost',

        [Parameter()]
        [string]$SqlcmdPath
    )

    if (-not $SqlcmdPath -or -not (Test-Path $SqlcmdPath)) {
        $SqlcmdPath = Get-SqlcmdPath
    }

    if (-not $SqlcmdPath) {
        throw "sqlcmd not found"
    }

    Write-Host "Configuring SA password..."

    try {
        $escapedPassword = $Password.Replace("'", "''")
        $query = "ALTER LOGIN [sa] WITH PASSWORD = N'$escapedPassword'"

        $result = & $SqlcmdPath -S $Server -E -Q $query 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "sqlcmd failed with exit code $LASTEXITCODE : $result"
        }

        Write-Host "SA password configured successfully."
        return $true
    }
    catch {
        throw "Failed to configure SA password: $_"
    }
}
