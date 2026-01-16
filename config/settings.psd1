@{
    SqlServer = @{
        InstancePath     = 'MSSQL16.MSSQLSERVER'
        InstanceName     = 'MSSQLSERVER'
        ServiceName      = 'MSSQLSERVER'
        Port             = 1433
        Version          = '2022'
        DownloadUrl      = 'https://go.microsoft.com/fwlink/p/?linkid=2215158'
        OdbcVersion      = '170'
        SetupBootstrap   = '160'
    }

    Paths = @{
        SqlBase          = 'C:\Program Files\Microsoft SQL Server'
        ErrorLogRelative = 'MSSQL\Log\ERRORLOG'
    }

    Defaults = @{
        PasswordMinLength           = 8
        InitialStartupWaitSeconds   = 5
        MaxConnectionAttempts       = 30
        MaxBindingAttempts          = 10
        RetryIntervalSeconds        = 2
        MonitorIntervalSeconds      = 10
        LogTailLines                = 50
        StatusReportIntervalMinutes = 5
    }

    Network = @{
        ListenAllInterfaces  = '0.0.0.0'
        LocalhostAddresses   = @('localhost', '127.0.0.1')
    }
}
