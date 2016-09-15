Configuration HybridWorkerConfig
{
    Import-DSCResource -Name cPowerShellRepository -ModuleName cPowerShellPackageManagement
    Import-DSCResource -Name cPowerShellModuleManagement -ModuleName cPowerShellPackageManagement
    #Register to OMyGet repository
    $APIKey = '226e6904-df3d-43fa-95cf-30184e66814b'
    $SourceUri = "https://www.myget.org/F/MyGetUserName/auth/$APIKey/api/v2"
    $PublishUri = 'https://www.myget.org/F/MyGetUserName/api/v2/package'

    $FeedName = 'MyGet'
    Node PSModuleConfig {
      cPowerShellRepository MyGetRepo {
            Name = $FeedName
            SourceLocation = $SourceUri
            PublishLocation = $PublishUri
            Ensure = 'Present'
            InstallationPolicy = 'Trusted'
        }
        cPowerShellModuleManagement Gac {
            PSModuleName = 'Gac'
            PSModuleVersion = '1.0.0'
            Ensure = 'Present'
            RepositoryName = $FeedName
            DependsOn = "[cPowerShellRepository]MyGetRepo"
        }
        cPowerShellModuleManagement SharePointSDKWithMaintWindow {
            PSModuleName = 'SharePointSDK'
            Ensure = 'Present'
            RepositoryName = 'MyGet'
            MaintenanceStartHour = 22
            MaintenanceStartMinute = 20
            MaintenanceLengthMinute = 45
            DependsOn = "[cPowerShellRepository]MyGet"
        }
    }
}