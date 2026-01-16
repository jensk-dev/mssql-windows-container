function Invoke-ProcessWithLogging {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter()]
        [string[]]$ArgumentList,

        [Parameter()]
        [string]$LogPrefix = 'process',

        [Parameter()]
        [string]$TempPath = $env:TEMP
    )

    $stdOutLog = Join-Path $TempPath "$LogPrefix-stdout.log"
    $stdErrLog = Join-Path $TempPath "$LogPrefix-stderr.log"

    Write-Host "Executing: $FilePath"
    Write-Host "Arguments: $($ArgumentList -join ' ')"

    $processParams = @{
        FilePath               = $FilePath
        Wait                   = $true
        PassThru               = $true
        RedirectStandardOutput = $stdOutLog
        RedirectStandardError  = $stdErrLog
    }

    if ($ArgumentList) {
        $processParams['ArgumentList'] = $ArgumentList
    }

    $process = Start-Process @processParams

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

    return [PSCustomObject]@{
        ExitCode  = $process.ExitCode
        StdOutLog = $stdOutLog
        StdErrLog = $stdErrLog
    }
}
