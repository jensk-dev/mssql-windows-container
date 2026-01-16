@{
    RootModule        = 'SqlServerContainer.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'Automated Build'
    Description       = 'SQL Server Windows Container support module'
    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Start-SqlContainer'
    )

    PrivateData = @{
        PSData = @{
            Tags = @('SQLServer', 'Container', 'Docker', 'Windows')
        }
    }
}
