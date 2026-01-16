function Get-FolderChecksum {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [ValidateSet('SHA256', 'SHA384', 'SHA512', 'MD5')]
        [string]$Algorithm = 'SHA256'
    )

    if (-not (Test-Path $Path)) {
        throw "Path does not exist: $Path"
    }

    $Path = [System.IO.Path]::GetFullPath($Path)

    $files = Get-ChildItem -Path $Path -File -Recurse |
             Sort-Object { $_.FullName.Substring($Path.Length) }

    if ($files.Count -eq 0) {
        throw "No files found in path: $Path"
    }

    Write-Host "Computing checksum for $($files.Count) files..."

    $hashBuilder = [System.Text.StringBuilder]::new()

    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($Path.Length).TrimStart('\', '/')
        $fileHash = (Get-FileHash -Path $file.FullName -Algorithm $Algorithm).Hash

        [void]$hashBuilder.AppendLine("${relativePath}:${fileHash}")
    }

    $combinedString = $hashBuilder.ToString()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($combinedString)
    $stream = [System.IO.MemoryStream]::new($bytes)

    try {
        $finalHash = (Get-FileHash -InputStream $stream -Algorithm $Algorithm).Hash
        return $finalHash.ToLower()
    }
    finally {
        $stream.Dispose()
    }
}
