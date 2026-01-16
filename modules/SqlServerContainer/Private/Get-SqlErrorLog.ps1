function Get-SqlErrorLog {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$TailLines,

        [Parameter()]
        [string]$InstancePath
    )

    $config = $script:Config
    $tailLines = if ($TailLines) { $TailLines } else { $config.Defaults.LogTailLines }
    $instancePath = if ($InstancePath) { $InstancePath } else { $config.SqlServer.InstancePath }

    $errorLogPath = Join-Path $config.Paths.SqlBase "$instancePath\$($config.Paths.ErrorLogRelative)"

    if (Test-Path $errorLogPath) {
        Write-Host "=== SQL Server Error Log (last $tailLines lines) ==="
        Get-Content $errorLogPath -Tail $tailLines | ForEach-Object { Write-Host $_ }
        return $true
    }

    Write-Log "Error log not found at: $errorLogPath" -Level Warning
    return $false
}
