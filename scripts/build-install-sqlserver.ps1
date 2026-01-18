# build-install-sqlserver.ps1
# Orchestrates SQL Server download, install, and cleanup during Docker build
# Uses existing library functions for modularity

param(
    [string]$ConfigFile = "C:\install.ini",
    [string]$DownloadUrl = "https://go.microsoft.com/fwlink/p/?linkid=2215158"
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

. "$PSScriptRoot\lib\Get-SqlServerInstaller.ps1"
. "$PSScriptRoot\lib\Expand-SqlServerMedia.ps1"

$TempPath = "C:\sql-temp"
$MediaPath = "C:\sql-media"

foreach ($path in @($TempPath, $MediaPath)) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
}

Write-Host "=== Downloading SQL Server installer ==="
$installerPath = Get-SqlServerInstaller -OutputPath $TempPath -DownloadUrl $DownloadUrl
if (-not $installerPath) { throw "Failed to download installer" }

Write-Host "=== Extracting SQL Server media ==="
$setupDir = Expand-SqlServerMedia -InstallerPath $installerPath -OutputPath $MediaPath -MediaType 'CAB' -TempPath $TempPath

if (-not $setupDir) {
    Write-Host "CAB extraction failed, trying Full..."
    $setupDir = Expand-SqlServerMedia -InstallerPath $installerPath -OutputPath $MediaPath -MediaType 'Full' -TempPath $TempPath
}

if (-not $setupDir) {
    $setupExe = Find-SetupExecutable -SearchPaths @($TempPath, $MediaPath)
    if ($setupExe) { $setupDir = $setupExe.DirectoryName }
}

if (-not $setupDir) { throw "Failed to extract SQL Server media" }

Write-Host "=== Installing SQL Server ==="
$setupExe = Join-Path $setupDir "setup.exe"
$process = Start-Process -FilePath $setupExe -ArgumentList "/ConfigurationFile=$ConfigFile" -Wait -PassThru -NoNewWindow

if ($process.ExitCode -ne 0) {
    $summaryLog = Get-ChildItem -Path 'C:\Program Files\Microsoft SQL Server\160\Setup Bootstrap\Log' -Filter 'Summary.txt' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($summaryLog) { Get-Content $summaryLog.FullName | Write-Host }
    throw "SQL Server installation failed with exit code: $($process.ExitCode)"
}

Write-Host "=== Cleaning up ==="
@($TempPath, $MediaPath, "C:\temp") | ForEach-Object {
    if (Test-Path $_) { Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Host "=== SQL Server installation completed ==="