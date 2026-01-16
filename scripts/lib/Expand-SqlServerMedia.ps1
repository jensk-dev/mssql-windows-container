function Expand-SqlServerMedia {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$InstallerPath,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [Parameter()]
        [ValidateSet('CAB', 'Full')]
        [string]$MediaType = 'CAB',

        [Parameter()]
        [string]$TempPath
    )

    if (-not $TempPath) {
        $TempPath = Split-Path $OutputPath -Parent
    }

    Write-Host ""
    Write-Host "Extracting SQL Server media (MediaType: $MediaType)..."
    Write-Host "This may take several minutes..."

    $arguments = @(
        "/Action=Download",
        "/MediaPath=$OutputPath",
        "/MediaType=$MediaType",
        "/Quiet"
    )

    Write-Host "Executing: $InstallerPath"
    Write-Host "Arguments: $($arguments -join ' ')"
    Write-Host "Media target path: $OutputPath"

    $stdOutLog = Join-Path $TempPath "installer-$($MediaType.ToLower())-stdout.log"
    $stdErrLog = Join-Path $TempPath "installer-$($MediaType.ToLower())-stderr.log"

    $process = Start-Process -FilePath $InstallerPath -ArgumentList $arguments `
        -Wait -PassThru `
        -RedirectStandardOutput $stdOutLog `
        -RedirectStandardError $stdErrLog

    Write-Host "Process completed with exit code: $($process.ExitCode)"

    if (Test-Path $stdOutLog) {
        $stdOut = Get-Content $stdOutLog -Raw -ErrorAction SilentlyContinue
        if ($stdOut) {
            Write-Host ""
            Write-Host "=== Standard Output ==="
            Write-Host $stdOut
        }
    }

    if (Test-Path $stdErrLog) {
        $stdErr = Get-Content $stdErrLog -Raw -ErrorAction SilentlyContinue
        if ($stdErr) {
            Write-Host ""
            Write-Host "=== Standard Error ==="
            Write-Host $stdErr
        }
    }

    Write-Host ""
    Write-Host "=== Contents of media path after download attempt ==="
    if (Test-Path $OutputPath) {
        Get-ChildItem -Path $OutputPath -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "  $($_.FullName) ($([math]::Round($_.Length / 1KB, 2)) KB)"
        }
    }
    else {
        Write-Host "  Media path does not exist: $OutputPath"
    }

    if ($process.ExitCode -ne 0) {
        Write-Warning "Media download returned exit code: $($process.ExitCode)"
        Show-CommonExitCodes
    }

    $setupExe = Get-ChildItem -Path $OutputPath -Filter "setup.exe" -Recurse -ErrorAction SilentlyContinue |
                Select-Object -First 1

    if ($setupExe) {
        return $setupExe.DirectoryName
    }

    $selfExtractor = Get-ChildItem -Path $OutputPath -Filter "SQLServer*.exe" -ErrorAction SilentlyContinue |
                    Select-Object -First 1

    if ($selfExtractor) {
        Write-Host ""
        Write-Host "=== Extracting self-extracting archive ==="
        Write-Host "Found: $($selfExtractor.FullName)"

        $extractedPath = Join-Path $OutputPath "extracted"
        New-Item -ItemType Directory -Path $extractedPath -Force | Out-Null

        Write-Host "Extracting to: $extractedPath"
        Write-Host "This may take a few minutes..."

        $extractArgs = "/x:$extractedPath", "/q"
        Write-Host "Executing: $($selfExtractor.FullName) $($extractArgs -join ' ')"

        $extractStdOut = Join-Path $TempPath "extract-stdout.log"
        $extractStdErr = Join-Path $TempPath "extract-stderr.log"

        $extractProcess = Start-Process -FilePath $selfExtractor.FullName -ArgumentList $extractArgs `
            -Wait -PassThru `
            -RedirectStandardOutput $extractStdOut `
            -RedirectStandardError $extractStdErr

        Write-Host "Extraction completed with exit code: $($extractProcess.ExitCode)"

        if (Test-Path $extractStdOut) {
            $extractOut = Get-Content $extractStdOut -Raw -ErrorAction SilentlyContinue
            if ($extractOut) {
                Write-Host "=== Extraction Output ==="
                Write-Host $extractOut
            }
        }

        if (Test-Path $extractStdErr) {
            $extractErr = Get-Content $extractStdErr -Raw -ErrorAction SilentlyContinue
            if ($extractErr) {
                Write-Host "=== Extraction Errors ==="
                Write-Host $extractErr
            }
        }

        Write-Host "=== Contents after extraction ==="
        Get-ChildItem -Path $extractedPath -Recurse -ErrorAction SilentlyContinue | Select-Object -First 20 | ForEach-Object {
            Write-Host "  $($_.FullName)"
        }

        $setupExe = Get-ChildItem -Path $extractedPath -Filter "setup.exe" -Recurse -ErrorAction SilentlyContinue |
                    Select-Object -First 1

        if ($setupExe) {
            Write-Host "Found setup.exe at: $($setupExe.FullName)"
            return $setupExe.DirectoryName
        }
    }

    return $null
}

function Show-CommonExitCodes {
    Write-Host ""
    Write-Host "=== Common exit codes ==="
    Write-Host "  0    = Success"
    Write-Host "  1    = General error"
    Write-Host "  1602 = User cancelled"
    Write-Host "  1603 = Fatal error during installation"
    Write-Host "  3010 = Success, reboot required"
    Write-Host ""
}

function Find-SetupExecutable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$SearchPaths
    )

    foreach ($path in $SearchPaths) {
        if (-not (Test-Path $path)) { continue }

        $setup = Get-ChildItem -Path $path -Filter "setup.exe" -Recurse -ErrorAction SilentlyContinue |
                 Select-Object -First 1

        if ($setup) {
            Write-Host "Found setup.exe at: $($setup.FullName)"
            return $setup
        }
    }

    return $null
}
