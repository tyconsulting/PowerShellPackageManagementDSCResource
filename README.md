# cPowerShellPackageManagement DSC Resource
Used to manage PoweShell modules and package repositories
Author - Tao Yang

## DSC Resources
================
### CPowerShellRepository
-------------------------
#### Syntax
```PowerShell
cPowerShellRepository [String] #ResourceName
{
    Name = [string]
    [DependsOn = [string[]]]
    [Ensure = [string]{ Absent | Present }]
    [InstallationPolicy = [string]{ Trusted | Untrusted }]
    [PackageManagementProvider = [string]]
    [PsDscRunAsCredential = [PSCredential]]
    [PublishLocation = [string]]
    [SourceLocation = [string]]
}
```
#### Description
To register a feed, you will need to specify some basic information such as PublishLocation and SourceLocation. You can also set Ensure = Absent to un-register the feed with the name specified in the Name parameter.

When not specified, the InstallationPolicy field default value is “Untrusted”. If you’d like to set the repository as a trusted repository, set this value to “Trusted”.
##### Note:
since the repository registration is based on each user (as opposed to machine based settings) and DSC configuration is executed under LocalSystem context. you will not be able to see the repository added by this resource if you run Get-PSRepository cmdlet under your own user account. If you start PowerShell under LocalSystem by using PsExec (run **_psexec /i /s /d powershell.exe_**), you will be able to see the repository.

### CPowerShellModuleManagement
-------------------------------
#### Syntax
```PowerShell
cPowerShellModuleManagement [String] #ResourceName
{
    PSModuleName = [string]
    RepositoryName = [string]
    [DependsOn = [string[]]]
    [Ensure = [string]{ Absent | Present }]
    [MaintenanceLengthMinute = [Int32]]
    [MaintenanceStartHour = [Int32]]
    [MaintenanceStartMinute = [Int32]]
    [PsDscRunAsCredential = [PSCredential]]
    [PSModuleVersion = [string]]
}
```
#### Description
* **PSModuleName** – PowerShell module name. When this is set to 'all', all modules from the specified repository will be installed. `So please do not use 'all' against PSGallery!!`
* **RepositoryName** – Name of the repository where module will be installed from. This can be a public repository such as PowerShell Gallery, or your privately owned repository (i.e. your ProGet or MyGet feeds). You can use the cPowerShellRepository resource to configure the repository.
* **PSModuleVersion** – This is an optional field. when used, only the specified version will be installed (or un-installed). If not specified, the latest version of the module from the repository will be used. This field will not impact other versions that are already installed on the computer (i.e. when installing the latest version, earlier versions will not be uninstalled).
* **MaintenanceStartHour, MaintenanceStartMinute and MaintenanceLengthMinute** – Since the LCM will run the DSC configuration on a pre-configured interval, you may not want to install / uninstall modules during business hours. Therefore, you can set the maintenance start hour (0-23) and start minute (0-59) to specify the start time of the maintenance window. MaintenanceLengthMinute represents the length of the maintenance window in minutes. These fields are optional, when specified, module installation and uninstallation will only take place when the LCM runs the configuration within the maintenance window. Note: Please make sure the MaintenanceLengthMinute is greater than the value configured for the LCM ConfigurationModeFrequencyMins property.

## Sample DSC Configurations
============================
### Register to a On-Prem ProGet feed and install all modules from the feed
```PowerShell
Configuration SampleProGetConfiguration
{
    Import-DSCResource -Name cPowerShellRepository -ModuleName cPowerShellPackageManagement
    Import-DSCResource -Name cPowerShellModuleManagement -ModuleName cPowerShellPackageManagement
    #Register to On-Prem ProGet repository
    $SourceUri = "http://ProGetRepo/nuget/FeedName"
    $PublishUri = 'http://ProGetRepo/nuget/FeedName'
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
```
### Register to a feed hosted on MyGet, and install several specific modules
```PowerShell
Configuration SampleMyGetConfiguration
{
    Import-DSCResource -Name cPowerShellRepository -ModuleName cPowerShellPackageManagement
    Import-DSCResource -Name cPowerShellModuleManagement -ModuleName cPowerShellPackageManagement
    #Register to MyGet repository
    $APIKey = 'ebb965a2-76f9-4e7c-bba8-5be232bf1e08'
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
            PSModuleVersion = '1.0.1'
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
            DependsOn = "[cPowerShellRepository]MyGetRepo"
        }
    }
}
```