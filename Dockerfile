# SQL Server 2022 Developer Edition on Windows Server Core 2022
# This image is for development and testing purposes only

FROM mcr.microsoft.com/windows/servercore:ltsc2025

LABEL maintainer="automated-build"
LABEL description="SQL Server 2022 Developer Edition on Windows Server Core 2022"
LABEL sql_version="2022"
LABEL base_os="Windows Server Core LTSC 2025"

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV ACCEPT_EULA="" \
    SA_PASSWORD_PATH="C:\\ProgramData\\Docker\\secrets\\sa-password" \
    ATTACH_DBS="[]" \
    MSSQL_PID="Developer"

RUN New-Item -ItemType Directory -Path C:\\sql-media -Force | Out-Null; \
    New-Item -ItemType Directory -Path C:\\temp -Force | Out-Null

COPY sql-media/ C:/sql-media/

# Copy configuration and modules
COPY config/ C:/config/
COPY modules/ C:/modules/
COPY start.ps1 C:/start.ps1
COPY install.ini C:/install.ini

RUN Write-Host 'Installing SQL Server 2022...'; \
    $setupPath = Get-ChildItem -Path 'C:\\sql-media' -Filter 'setup.exe' -Recurse | Select-Object -First 1 -ExpandProperty FullName; \
    if (-not $setupPath) { throw 'setup.exe not found in sql-media directory' }; \
    Write-Host \"Found setup at: $setupPath\"; \
    $process = Start-Process -FilePath $setupPath -ArgumentList '/ConfigurationFile=C:\\install.ini' -Wait -PassThru -NoNewWindow; \
    if ($process.ExitCode -ne 0) { \
        $summaryLog = Get-ChildItem -Path 'C:\\Program Files\\Microsoft SQL Server\\160\\Setup Bootstrap\\Log' -Filter 'Summary.txt' -Recurse | Select-Object -First 1; \
        if ($summaryLog) { Get-Content $summaryLog.FullName | Write-Host }; \
        throw \"SQL Server installation failed with exit code: $($process.ExitCode)\" \
    }; \
    Write-Host 'SQL Server installation completed successfully'; \
    Remove-Item -Path 'C:\\sql-media' -Recurse -Force; \
    Remove-Item -Path 'C:\\temp' -Recurse -Force; \
    Remove-Item -Path 'C:\\install.ini' -Force

EXPOSE 1433

HEALTHCHECK --interval=10s --timeout=5s --start-period=90s --retries=5 \
    CMD ["powershell", "-Command", "if (Test-Path 'C:\\sa-ready') { exit 0 } else { exit 1 }"]

CMD ["powershell", "-File", "C:\\start.ps1"]
