function Mount-Database {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DatabaseName,

        [Parameter(Mandatory)]
        [string[]]$DatabaseFiles,

        [Parameter()]
        [string]$Server = 'localhost',

        [Parameter()]
        [string]$SqlcmdPath
    )

    if (-not $SqlcmdPath -or -not (Test-Path $SqlcmdPath)) {
        $SqlcmdPath = Get-SqlcmdPath
    }

    if (-not $SqlcmdPath) {
        Write-Log "sqlcmd not found, cannot attach database" -Level Warning
        return $false
    }

    foreach ($file in $DatabaseFiles) {
        if (-not (Test-Path $file)) {
            Write-Log "Database file not found: $file" -Level Warning
            return $false
        }
    }

    Write-Host "Attaching database: $DatabaseName"

    $fileList = ($DatabaseFiles | ForEach-Object {
        $escapedPath = $_.Replace("'", "''")
        "(FILENAME = N'$escapedPath')"
    }) -join ", "

    $escapedDbName = $DatabaseName.Replace("]", "]]")
    $attachQuery = "CREATE DATABASE [$escapedDbName] ON $fileList FOR ATTACH"

    try {
        $result = & $SqlcmdPath -S $Server -E -Q $attachQuery 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "sqlcmd failed: $result"
        }
        Write-Host "Database '$DatabaseName' attached successfully."
        return $true
    }
    catch {
        Write-Log "Failed to attach database '$DatabaseName': $_" -Level Warning
        return $false
    }
}

function Mount-Databases {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$JsonConfig,

        [Parameter()]
        [string]$Server = 'localhost'
    )

    Write-Host "Processing database attachments..."

    try {
        $databases = $JsonConfig | ConvertFrom-Json

        foreach ($db in $databases) {
            if (-not $db.dbName -or -not $db.dbFiles) {
                Write-Log "Skipping invalid database entry: missing dbName or dbFiles" -Level Warning
                continue
            }

            Mount-Database -DatabaseName $db.dbName -DatabaseFiles $db.dbFiles -Server $Server
        }
    }
    catch {
        Write-Log "Failed to parse ATTACH_DBS JSON: $_" -Level Warning
    }
}
