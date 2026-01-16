function Get-SqlServerInstaller {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OutputPath,

        [Parameter()]
        [string]$DownloadUrl = 'https://go.microsoft.com/fwlink/p/?linkid=2215158'
    )

    $installerPath = Join-Path $OutputPath "SQL2022-SSEI-Dev.exe"

    Write-Host "Downloading SQL Server 2022 installer from Microsoft..."
    Write-Host "URL: $DownloadUrl"

    try {
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $installerPath -UseBasicParsing
        Write-Host "Download completed: $installerPath"
    }
    catch {
        Write-Error "Failed to download SQL Server installer: $_"
        return $null
    }

    if (-not (Test-Path $installerPath)) {
        Write-Error "Installer file not found after download"
        return $null
    }

    $fileSize = (Get-Item $installerPath).Length / 1MB
    Write-Host "Downloaded file size: $([math]::Round($fileSize, 2)) MB"

    return $installerPath
}
