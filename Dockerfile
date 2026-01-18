# syntax=docker/dockerfile:1
# SQL Server 2022 Developer Edition on Windows Server Core 2022
# This image is for development and testing purposes only

FROM mcr.microsoft.com/windows/servercore:ltsc2025

LABEL maintainer="automated-build"
LABEL description="SQL Server 2022 Developer Edition on Windows Server Core 2022"
LABEL sql_version="2022"
LABEL base_os="Windows Server Core LTSC 2025"
LABEL org.opencontainers.image.source="https://github.com/jensk-dev/mssql-windows-container"

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV ACCEPT_EULA="" \
    SA_PASSWORD_PATH="C:\\ProgramData\\Docker\\secrets\\sa-password" \
    ATTACH_DBS="[]" \
    MSSQL_PID="Developer"

# stable files
COPY config/ C:/config/
COPY modules/ C:/modules/
COPY start.ps1 C:/start.ps1
COPY install.ini C:/install.ini
COPY scripts/ C:/scripts/

# volatile layer
RUN & C:\scripts\build-install-sqlserver.ps1; \
    Remove-Item -Path C:\scripts -Recurse -Force; \
    Remove-Item -Path C:\install.ini -Force

EXPOSE 1433

HEALTHCHECK --interval=10s --timeout=5s --start-period=90s --retries=5 \
    CMD ["powershell", "-Command", "if (Test-Path 'C:\\sa-ready') { exit 0 } else { exit 1 }"]

CMD ["powershell", "-File", "C:\\start.ps1"]
