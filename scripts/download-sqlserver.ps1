param(
    [string]$OutputPath = ".\sql-media",
    [string]$TempPath = ".\temp-download"
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$OutputPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PWD, $OutputPath))
$TempPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PWD, $TempPath))

. "$PSScriptRoot\lib\Get-SqlServerInstaller.ps1"
. "$PSScriptRoot\lib\Expand-SqlServerMedia.ps1"

Write-Host "SQL Server 2022 Developer Edition Media Downloader"
Write-Host "===================================================="
Write-Host ""
Write-Host "Resolved paths:"
Write-Host "  Output path: $OutputPath"
Write-Host "  Temp path: $TempPath"
Write-Host ""

Write-Host "Creating directories..."
foreach ($path in @($TempPath, $OutputPath)) {
    if (Test-Path $path) {
        Remove-Item -Path $path -Recurse -Force
    }
    New-Item -ItemType Directory -Path $path -Force | Out-Null
}

$installerPath = Get-SqlServerInstaller -OutputPath $TempPath
if (-not $installerPath) {
    exit 1
}

$mediaPath = Join-Path $TempPath "media"
New-Item -ItemType Directory -Path $mediaPath -Force | Out-Null

$setupDir = $null

try {
    $setupDir = Expand-SqlServerMedia -InstallerPath $installerPath -OutputPath $mediaPath -MediaType 'CAB' -TempPath $TempPath
}
catch {
    Write-Warning "Primary extraction failed: $_"
    Write-Host "Exception type: $($_.Exception.GetType().FullName)"
    Write-Host "Exception message: $($_.Exception.Message)"
    if ($_.Exception.InnerException) {
        Write-Host "Inner exception: $($_.Exception.InnerException.Message)"
    }
    Write-Host "Stack trace: $($_.ScriptStackTrace)"
    Write-Host ""
    Write-Host "Attempting alternative extraction method..."
}

if (-not $setupDir) {
    Write-Host ""
    Write-Host "=== Alternative Extraction Method ==="
    Write-Host "Attempting to extract installation files with MediaType=Full..."

    $extractPath = Join-Path $TempPath "extract"
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

    $setupDir = Expand-SqlServerMedia -InstallerPath $installerPath -OutputPath $extractPath -MediaType 'Full' -TempPath $TempPath
}

if (-not $setupDir) {
    Write-Host "Searching all temp directories for SQL Server setup files..."

    $setupExe = Find-SetupExecutable -SearchPaths @($TempPath, $mediaPath)
    if ($setupExe) {
        $setupDir = $setupExe.DirectoryName
    }
}

if (-not $setupDir) {
    Write-Error "Failed to extract SQL Server media. setup.exe not found."
    Write-Host "Contents of temp directory:"
    Get-ChildItem -Path $TempPath -Recurse | ForEach-Object { Write-Host $_.FullName }
    exit 1
}

Write-Host ""
Write-Host "Copying media to output directory: $OutputPath"
Copy-Item -Path "$setupDir\*" -Destination $OutputPath -Recurse -Force

$outputSetup = Join-Path $OutputPath "setup.exe"
if (Test-Path $outputSetup) {
    Write-Host ""
    Write-Host "===================================================="
    Write-Host "SQL Server media extraction completed successfully!"
    Write-Host "Output directory: $OutputPath"
    Write-Host "===================================================="
    Write-Host ""
    Write-Host "Key files:"
    Get-ChildItem -Path $OutputPath -Depth 1 | ForEach-Object {
        Write-Host "  $($_.Name)"
    }
}
else {
    Write-Error "setup.exe not found in output directory"
    exit 1
}

Write-Host ""
Write-Host "Cleaning up temporary files..."
Remove-Item -Path $TempPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Done!"
