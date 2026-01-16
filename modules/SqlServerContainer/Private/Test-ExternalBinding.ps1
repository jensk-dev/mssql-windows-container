function Test-ExternalBinding {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$Port,

        [Parameter()]
        [int]$MaxAttempts,

        [Parameter()]
        [int]$RetryIntervalSeconds
    )

    $config = $script:Config
    $port = if ($Port) { $Port } else { $config.SqlServer.Port }
    $maxAttempts = if ($MaxAttempts) { $MaxAttempts } else { $config.Defaults.MaxBindingAttempts }
    $retryInterval = if ($RetryIntervalSeconds) { $RetryIntervalSeconds } else { $config.Defaults.RetryIntervalSeconds }

    Write-Host "Verifying SQL Server is listening on external interfaces..."

    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        try {
            $listeners = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue

            if ($listeners) {
                $allInterfaces = $listeners | Where-Object { $_.LocalAddress -eq $config.Network.ListenAllInterfaces }
                if ($allInterfaces) {
                    Write-Host "SQL Server is listening on all interfaces ($($config.Network.ListenAllInterfaces):$port)"
                    return $true
                }

                $containerIP = (Get-NetIPAddress -AddressFamily IPv4 |
                               Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.IPAddress -notlike '169.254.*' } |
                               Select-Object -First 1).IPAddress

                if ($containerIP) {
                    $ipBinding = $listeners | Where-Object { $_.LocalAddress -eq $containerIP }
                    if ($ipBinding) {
                        Write-Host "SQL Server is listening on container IP ($containerIP`:$port)"
                        return $true
                    }
                }
            }
        }
        catch {
            $netstatOutput = netstat -an | Select-String -Pattern "$($config.Network.ListenAllInterfaces -replace '\.', '\.')`:$port\s+.*LISTENING"
            if ($netstatOutput) {
                Write-Host "SQL Server is listening on all interfaces ($($config.Network.ListenAllInterfaces):$port)"
                return $true
            }
        }

        Write-Host "Attempt $attempt/$maxAttempts - Waiting for external interface binding..."
        Start-Sleep -Seconds $retryInterval
    }

    Write-Log "SQL Server may only be listening on localhost (127.0.0.1)." -Level Warning
    Write-Host "Connections from outside the container may fail."

    Write-Host "=== Current TCP listeners on port $port ==="
    try {
        Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
            ForEach-Object { Write-Host "  $($_.LocalAddress):$($_.LocalPort)" }
    }
    catch {
        netstat -an | Select-String -Pattern ":$port" | ForEach-Object { Write-Host "  $_" }
    }

    return $false
}
