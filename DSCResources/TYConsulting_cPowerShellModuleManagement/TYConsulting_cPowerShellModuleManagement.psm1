Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Array])]
    param(
      [ValidateSet('Present','Absent')]
		  [System.String]
		  $Ensure = 'Present',

		  [parameter(Mandatory = $true, HelpMessage="Enter the PowerShell module name. Enter 'All' to include all modules in the repository.")]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $PSModuleName,

		  [parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
		  [System.Version]
		  $PSModuleVersion,

		  [parameter(Mandatory = $true,HelpMessage='Enter PowerShell Repository Name')]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $RepositoryName
    )
    $arrModules = @()
    
    $parms = @{
      Repository = $RepositoryName
    }
    If ($PSModuleName -ine 'all')
    {
      $parms.Add('Name', $PSModuleName)
      If ($PSBoundParameters.ContainsKey('PSModuleVersion'))
      {
        $parms.Add('RequiredVersion', $PSModuleVersion)
        Write-Verbose ("Getting module '{0}' version '{1}' from repository  '{2}'." -f $PSModuleName, $PSModuleVersion, $RepositoryName)
      } else {
        Write-Verbose ("Getting the latest version of module '{0}' from repository  '{1}'." -f $PSModuleName, $RepositoryName)
      }
    } else {
      Write-Verbose ("Getting all modules from repository  '{0}'." -f $RepositoryName)
    }

    $ModulesInRepo = Find-Module @parms -ErrorVariable ev -ErrorAction SilentlyContinue
    Write-Verbose "Modules found in repository: $($ModulesInRepo.Count)"
    Foreach ($ModuleInRepo in $ModulesInRepo)
    {
      Write-Verbose ("Checking module '{0}' version '{1}'." -f $ModuleInRepo.Name, $ModuleInRepo.Version.Tostring())
      $localModule = Get-Module -Name $($ModuleInRepo.Name) -ListAvailable | Where-Object {$_.version -eq $($ModuleInRepo.Version)}
      $objProperties = @{
        Name = $ModuleInRepo.Name
        Version = $ModuleInRepo.Version
      }
      If ($localModule)
      {
        Write-Verbose ("Module '{0}' version '{1}' is Present." -f $ModuleInRepo.Name, $ModuleInRepo.Version.Tostring())
        $objProperties.Add('Ensure', 'Present')
      } else {
        Write-Verbose ("Module '{0}' version '{1}' is Absent." -f $ModuleInRepo.Name, $ModuleInRepo.Version.Tostring())
        $objProperties.Add('Ensure', 'Absent')
      }
      $objLocalModule = new-object PSObject -Property $objProperties
      $arrModules +=$objLocalModule
    }
    ,$arrModules
}

Function Set-TargetResource
{
    [CmdletBinding()]
    param(
      [ValidateSet('Present','Absent')]
		  [System.String]
		  $Ensure = 'Present',

		  [parameter(Mandatory = $true, HelpMessage="Enter the PowerShell module name. Enter 'All' to include all modules in the repository.")]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $PSModuleName,

		  [parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
		  [System.Version]
		  $PSModuleVersion,

		  [parameter(Mandatory = $true,HelpMessage='Add help message for user')]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $RepositoryName
    )
    Write-Output ("Getting modules from repository  '{0}'." -f $RepositoryName)
    $parms = @{
      Repository = $RepositoryName
    }
    If ($PSModuleName -ine 'all')
    {
      $parms.Add('Name', $PSModuleName)
      If ($PSBoundParameters.ContainsKey('PSModuleVersion'))
      {
        $parms.Add('RequiredVersion', $PSModuleVersion)
      }
    }

    $ModulesInRepo = Find-Module @parms -ErrorVariable ev -ErrorAction SilentlyContinue

    Foreach ($ModuleInRepo in $ModulesInRepo)
    {
      $localModule = Get-Module -Name $($ModuleInRepo.Name) -ListAvailable | Where-Object {$_.version -eq $($ModuleInRepo.Version)}
      If ($localModule)
      {
        Write-Verbose ("Module {0} version '{1}' is already installed." -f $ModuleInRepo.Name, $ModuleInRepo.Version)
        If ($Ensure -ieq 'absent')
        {
          If ($PSBoundParameters.ContainsKey('PSModuleVersion'))
          {
            Write-Verbose ("Uinstalling Module {0} version '{1}'." -f $ModuleInRepo.Name, $ModuleInRepo.Version)
            $UninstallModule = Uninstall-Module -Name $ModuleInRepo.Name -RequiredVersion $ModuleInRepo.Version -Force -ErrorVariable ev -ErrorAction SilentlyContinue
          } else {
            Write-Verbose ("Uinstalling all versions of Module {0}." -f $ModuleInRepo.Name)
            $UninstallModule = Uninstall-Module -Name $ModuleInRepo.Name -AllVersions -Force -ErrorVariable ev -ErrorAction SilentlyContinue
          }
          
        }
      } else {
        Write-Verbose ("Module {0} version '{1}' is not installed." -f $ModuleInRepo.Name, $ModuleInRepo.Version)
        if ($Ensure -ieq 'present')
        {
          Write-Verbose ("installing Module {0} version '{1}' now." -f $ModuleInRepo.Name, $ModuleInRepo.Version)
          $InstallModule = Install-Module -Name $($ModuleInRepo.Name) -RequiredVersion $($ModuleInRepo.Version) -Repository $RepositoryName
        }
        
      }
    }

    If(!(Test-TargetResource @PSBoundParameters))
    {
        throw 'Set-TargetResouce failed'
    }
}

Function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
      [ValidateSet('Present','Absent')]
		  [System.String]
		  $Ensure = 'Present',

		  [parameter(Mandatory = $true, HelpMessage="Enter the PowerShell module name. Enter 'All' to include all modules in the repository.")]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $PSModuleName,

		  [parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
		  [System.Version]
		  $PSModuleVersion,

		  [parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $RepositoryName
    )
    $arrModules = Get-TargetResource @PSBoundParameters
    $result = $true
    Foreach ($item in $arrModules)
    {
      Write-Verbose "$($item.Name) is currently $($item.Ensure), desired configuration is $ensure."
      if ($item.Ensure -ine $Ensure)
      {
        $result = $false
      }
    }
    $result
}
Export-ModuleMember -Function *-TargetResource