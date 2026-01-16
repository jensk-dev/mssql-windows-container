function Test-SqlReady {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Server = 'localhost',

        [Parameter()]
        [int]$Port,

        [Parameter()]
        [int]$MaxAttempts,

        [Parameter()]
        [int]$RetryIntervalSeconds,

        [Parameter()]
        [string]$SqlcmdPath
    )

    $config = $script:Config
    $maxAttempts = if ($MaxAttempts) { $MaxAttempts } else { $config.Defaults.MaxConnectionAttempts }
    $retryInterval = if ($RetryIntervalSeconds) { $RetryIntervalSeconds } else { $config.Defaults.RetryIntervalSeconds }
    $port = if ($Port) { $Port } else { $config.SqlServer.Port }

    if (-not $SqlcmdPath -or -not (Test-Path $SqlcmdPath)) {
        $SqlcmdPath = Get-SqlcmdPath
    }

    if ($SqlcmdPath) {
        Write-Host "Using sqlcmd at: $SqlcmdPath"
    }

    Write-Host "Waiting for SQL Server to accept connections..."

    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        try {
            if ($SqlcmdPath -and (Test-Path $SqlcmdPath)) {
                $null = & $SqlcmdPath -S $Server -E -Q "SELECT 1" -h -1 -W 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "SQL Server is ready and accepting connections."
                    return $true
                }
                Write-Host "Attempt $attempt/$maxAttempts - SQL Server not ready yet (exit code: $LASTEXITCODE), waiting..."
            }
            else {
                $tcp = New-Object System.Net.Sockets.TcpClient
                $tcp.Connect($Server, $port)
                $tcp.Close()
                Write-Host "SQL Server is ready (port $port is listening)."
                return $true
            }
        }
        catch {
            Write-Host "Attempt $attempt/$maxAttempts - SQL Server not ready yet, waiting..."
        }

        Start-Sleep -Seconds $retryInterval
    }

    return $false
}
