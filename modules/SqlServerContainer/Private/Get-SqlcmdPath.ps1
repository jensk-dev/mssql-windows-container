function Get-SqlcmdPath {
    [CmdletBinding()]
    param()

    $config = $script:Config
    $odbcVersion = $config.SqlServer.OdbcVersion
    $basePath = $config.Paths.SqlBase

    $knownPath = Join-Path $basePath "Client SDK\ODBC\$odbcVersion\Tools\Binn\SQLCMD.EXE"
    if (Test-Path $knownPath) {
        return $knownPath
    }

    $found = Get-ChildItem -Path $basePath -Filter "SQLCMD.EXE" -Recurse -ErrorAction SilentlyContinue |
             Select-Object -First 1 -ExpandProperty FullName

    return $found
}
