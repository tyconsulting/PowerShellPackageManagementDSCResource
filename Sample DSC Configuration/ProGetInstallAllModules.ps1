Configuration HybridWorkerConfiguration
{
    Import-DSCResource -Name cPowerShellRepository -ModuleName cPowerShellPackageManagement
    Import-DSCResource -Name cPowerShellModuleManagement -ModuleName cPowerShellPackageManagement
    #Register to On-Prem ProGet repository
    $SourceUri = "http://packagerepo/nuget/HybridWorkerPackages"
    $PublishUri = 'http://packagerepo/nuget/HybridWorkerPackages'
    $FeedName = 'ProGet'
    Node PowerShellModuleConfig {
      cPowerShellRepository ProGetRepo {
            Name = $FeedName
            SourceLocation = $SourceUri
            PublishLocation = $PublishUri
            Ensure = 'Present'
            InstallationPolicy = 'Trusted'
        }
        cPowerShellModuleManagement InstallAllModules {
            PSModuleName = 'All'
            Ensure = 'Present'
            RepositoryName = $FeedName
            DependsOn = "[cPowerShellRepository]ProGetRepo"
        }
    }
}