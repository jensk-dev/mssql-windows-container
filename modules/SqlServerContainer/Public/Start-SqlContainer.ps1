function Start-SqlContainer {
    [CmdletBinding()]
    param()

    $config = $script:Config

    Write-Banner "SQL Server Container Startup Script"

    if ($env:ACCEPT_EULA -ne 'Y' -and $env:ACCEPT_EULA -ne 'y') {
        Write-Log "You must accept the End User License Agreement (EULA) to start this container." -Level Error
        Write-Log "Set the environment variable ACCEPT_EULA=Y to accept the agreement." -Level Error
        exit 1
    }
    Write-Host "EULA accepted."

    $saPassword = Get-SaPasswordFromEnv
    if (-not $saPassword) {
        exit 1
    }

    if (-not (Start-SqlService)) {
        exit 1
    }

    if (-not (Test-SqlReady)) {
        Write-Log "SQL Server failed to start within the expected time." -Level Error
        Get-SqlErrorLog | Out-Null
        exit 1
    }

    Test-ExternalBinding | Out-Null

    try {
        Set-SaPassword -Password $saPassword
    }
    catch {
        Write-Log "Failed to configure SA password: $_" -Level Error
        exit 1
    }

    # used in health check
    $readyMarker = "C:\sa-ready"
    Set-Content -Path $readyMarker -Value (Get-Date -Format "o")
    Write-Host "Ready marker written to $readyMarker"

    if ($env:ATTACH_DBS -and $env:ATTACH_DBS -ne '[]' -and $env:ATTACH_DBS -ne '') {
        Mount-Databases -JsonConfig $env:ATTACH_DBS
    }

    Write-Host ""
    Write-Banner "SQL Server is running and ready."

    Start-ServiceMonitor
}

function Get-SaPasswordFromEnv {
    [CmdletBinding()]
    param()

    $config = $script:Config
    $saPassword = $null
    $saSecretPath = $env:SA_PASSWORD_PATH

    if ($env:SA_PASSWORD -and $env:SA_PASSWORD -ne '') {
        $saPassword = $env:SA_PASSWORD
        Write-Host "SA password configured from environment variable."
    }
    elseif ($saSecretPath -and (Test-Path $saSecretPath)) {
        $saPassword = (Get-Content -Path $saSecretPath -Raw).Trim()
        Write-Host "SA password configured from secrets file: $saSecretPath"
    }

    if (-not $saPassword -or $saPassword -eq '') {
        Write-Log "SA password not provided." -Level Error
        Write-Log "Set SA_PASSWORD environment variable or mount a secrets file at SA_PASSWORD_PATH" -Level Error
        return $null
    }

    if ($saPassword.Length -lt $config.Defaults.PasswordMinLength) {
        Write-Log "SA password must be at least $($config.Defaults.PasswordMinLength) characters long." -Level Error
        return $null
    }

    return $saPassword
}

function Start-SqlService {
    [CmdletBinding()]
    param()

    $config = $script:Config
    $serviceName = $config.SqlServer.ServiceName

    Write-Host "Starting SQL Server service..."

    try {
        Start-Service $serviceName -ErrorAction Stop
        Write-Host "SQL Server service start command issued."
    }
    catch {
        Write-Log "Failed to start SQL Server service: $_" -Level Error

        $svc = Get-Service $serviceName -ErrorAction SilentlyContinue
        if ($svc) {
            Write-Host "Service status: $($svc.Status)"
        }
        return $false
    }

    Start-Sleep -Seconds $config.Defaults.InitialStartupWaitSeconds

    $svc = Get-Service $serviceName -ErrorAction SilentlyContinue
    Write-Host "SQL Server service status: $($svc.Status)"

    if ($svc.Status -ne 'Running') {
        Write-Log "SQL Server service is not running." -Level Error
        Get-SqlErrorLog | Out-Null
        return $false
    }

    return $true
}

function Start-ServiceMonitor {
    [CmdletBinding()]
    param()

    $config = $script:Config
    $serviceName = $config.SqlServer.ServiceName
    $statusInterval = $config.Defaults.StatusReportIntervalMinutes
    $monitorInterval = $config.Defaults.MonitorIntervalSeconds

    $lastCheck = Get-Date

    while ($true) {
        $service = Get-Service $serviceName -ErrorAction SilentlyContinue

        if ($service.Status -ne 'Running') {
            Write-Log "SQL Server service has stopped unexpectedly." -Level Error
            exit 1
        }

        $now = Get-Date
        if (($now - $lastCheck).TotalMinutes -ge $statusInterval) {
            Write-Host "[$now] SQL Server service is running."
            $lastCheck = $now
        }

        Start-Sleep -Seconds $monitorInterval
    }
}
