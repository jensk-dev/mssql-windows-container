function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $prefix = switch ($Level) {
        'Warning' { 'WARNING: ' }
        'Error'   { 'ERROR: ' }
        default   { '' }
    }

    $formattedMessage = "${prefix}${Message}"

    switch ($Level) {
        'Error'   { Write-Error $formattedMessage }
        'Warning' { Write-Warning $formattedMessage }
        default   { Write-Host $formattedMessage }
    }
}

function Write-Banner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    $separator = '=' * 52
    Write-Host $separator
    Write-Host $Title
    Write-Host $separator
}
