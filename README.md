# MSSQL Server 2022 Windows Container

A Windows container image for SQL Server 2022 Developer Edition, built nightly and published to GitHub Container Registry.

## Quick Start

```powershell
docker pull ghcr.io/jensk-dev/mssql-server-windows-developer:latest

docker run -d `
  -e ACCEPT_EULA=Y `
  -e SA_PASSWORD=YourStrong!Password123 `
  -p 1433:1433 `
  --name mssql `
  ghcr.io/jensk-dev/mssql-server-windows-developer:latest
```

## Image Tags

| Tag | Description |
|-----|-------------|
| `latest` | Most recent build |
| `2022` | SQL Server 2022 on Windows Server Core LTSC 2025 |

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ACCEPT_EULA` | Yes | Set to `Y` to accept the SQL Server license agreement |
| `SA_PASSWORD` | Yes* | SA account password (min 8 characters) |
| `SA_PASSWORD_PATH` | No | Path to file containing SA password (alternative to `SA_PASSWORD`) |
| `ATTACH_DBS` | No | JSON array of databases to attach on startup |

*Either `SA_PASSWORD` or `SA_PASSWORD_PATH` must be provided.

## Usage Examples

### Basic Usage

```powershell
docker run -d `
  -e ACCEPT_EULA=Y `
  -e SA_PASSWORD=YourStrong!Password123 `
  -p 1433:1433 `
  ghcr.io/jensk-dev/mssql-server-windows-developer:latest
```

### Using Docker Secrets

```powershell
# Create a secrets file
echo "YourStrong!Password123" > sa-password.txt

docker run -d `
  -e ACCEPT_EULA=Y `
  -v ${PWD}/sa-password.txt:C:/ProgramData/Docker/secrets/sa-password:ro `
  -p 1433:1433 `
  ghcr.io/jensk-dev/mssql-server-windows-developer:latest
```

### Attaching Databases

```powershell
docker run -d `
  -e ACCEPT_EULA=Y `
  -e SA_PASSWORD=YourStrong!Password123 `
  -e ATTACH_DBS='[{"dbName":"MyDB","dbFiles":["C:\\data\\MyDB.mdf","C:\\data\\MyDB_log.ldf"]}]' `
  -v C:\databases:C:\data `
  -p 1433:1433 `
  ghcr.io/jensk-dev/mssql-server-windows-developer:latest
```

### Persisting Data

```powershell
docker run -d `
  -e ACCEPT_EULA=Y `
  -e SA_PASSWORD=YourStrong!Password123 `
  -v sqldata:C:/var/opt/mssql `
  -p 1433:1433 `
  ghcr.io/jensk-dev/mssql-server-windows-developer:latest
```

## Connecting to SQL Server

### Using sqlcmd

```powershell
sqlcmd -S localhost -U sa -P YourStrong!Password123 -Q "SELECT @@VERSION"
```

### Using PowerShell

```powershell
Invoke-Sqlcmd -ServerInstance "localhost" -Username "sa" -Password "YourStrong!Password123" -Query "SELECT @@VERSION" -TrustServerCertificate
```

### Connection String

```
Server=localhost,1433;Database=master;User Id=sa;Password=YourStrong!Password123;TrustServerCertificate=True;
```

## Building Locally

### Prerequisites

- Windows 10/11 or Windows Server 2022
- Tooling to build windows container images
- PowerShell 5.1 or later

### Build Steps

1. Download SQL Server media:
   ```powershell
   .\scripts\download-sqlserver.ps1 -OutputPath .\sql-media
   ```

2. Build the image:
   ```powershell
   docker build -t mssql-server-windows-developer:local .
   ```

3. Run the container:
   ```powershell
   docker run -d -e ACCEPT_EULA=Y -e SA_PASSWORD=YourStrong!Password123 -p 1433:1433 mssql-server-windows-developer:local
   ```

## Technical Details

- **Base Image**: `mcr.microsoft.com/windows/servercore:ltsc2025`
- **SQL Server Version**: 2022 Developer Edition
- **Features Installed**: SQLENGINE only (minimal installation)
- **Port**: 1433 (TCP)
- **Authentication**: Mixed mode (SQL and Windows)

## License

SQL Server Developer Edition is free for development and testing purposes. Production use requires a valid SQL Server license.

By using this image, you agree to the [Microsoft SQL Server License Terms](https://go.microsoft.com/fwlink/?linkid=857698).

## Disclaimer

This image is provided for development and testing purposes only. It is not officially supported by Microsoft.
