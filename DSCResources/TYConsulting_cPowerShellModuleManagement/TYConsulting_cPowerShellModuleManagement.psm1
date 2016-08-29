Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Array])]
    param(
      [ValidateSet("Present","Absent")]
		  [System.String]
		  $Ensure = "Present",

		  [parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $ModuleName,

		  [parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
		  [System.Version]
		  $ModuleVersion,

		  [parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $RepositoryName
    )
    $arrModules = @()
    Write-Output "Getting modules from repository  '$RepositoryName'."
    $parms = @{
      Repository = $RepositoryName
    }
    If ($PSBoundParameters.ContainsKey('ModuleName'))
    {
      $parms.Add('Name', $ModuleName)
      If ($PSBoundParameters.ContainsKey('ModuleVersion'))
      {
        $parms.Add('RequiredVersion', $ModuleVersion)
      }
    }

    $ModulesInRepo = Find-Module @parms
    Foreach ($ModuleInRepo in $ModulesInRepo)
    {
      Write-Verbose "Checking module '$($ModuleInRepo.Name)' version '$($ModuleInRepo.Version.Tostring())'."
      $localModule = Get-Module -Name $($ModuleInRepo.Name) -ListAvailable | Where-Object {$_.version -eq $($ModuleInRepo.Version)}
      $objProperties = @{
        Name = $ModuleInRepo.Name
        Version = $ModuleInRepo.Version
      }
      If ($localModule)
      {
        Write-Verbose "Module '$($ModuleInRepo.Name)' version '$($ModuleInRepo.Version.Tostring())' is Present."
        $objProperties.Add('Ensure', 'Present')
      } else {
        Write-Verbose "Module '$($ModuleInRepo.Name)' version '$($ModuleInRepo.Version.Tostring())' is Absent."
        $objProperties.Add('Ensure', 'Absent')
      }
      $objLocalModule = new-object PSObject -Property $objProperties
      $arrModules.Add($objLocalModule)
    }
    $arrModules
}

Function Set-TargetResource
{
    [CmdletBinding()]
    param(
      [ValidateSet("Present","Absent")]
		  [System.String]
		  $Ensure = "Present",

		  [parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $ModuleName,

		  [parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
		  [System.Version]
		  $ModuleVersion,

		  [parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $RepositoryName
    )
    Write-Output "Getting modules from repository  '$RepositoryName'."
    $parms = @{
      Repository = $RepositoryName
    }
    If ($PSBoundParameters.ContainsKey('ModuleName'))
    {
      $parms.Add('Name', $ModuleName)
      If ($PSBoundParameters.ContainsKey('ModuleVersion'))
      {
        $parms.Add('RequiredVersion', $ModuleVersion)
      }
    }

    $ModulesInRepo = Find-Module @parms

    Foreach ($ModuleInRepo in $ModulesInRepo)
    {
      $localModule = Get-Module -Name $($ModuleInRepo.Name) -ListAvailable | Where-Object {$_.version -eq $($ModuleInRepo.Version)}
      If ($localModule)
      {
        Write-Verbose "Module $($ModuleInRepo.Name) version '$($ModuleInRepo.Version)' is already installed."
      } else {
        Write-Verbose "Module $($ModuleInRepo.Name) version '$($ModuleInRepo.Version)' is not installed, installing it now."
        $InstallModule = Install-Module -Name $($ModuleInRepo.Name) -RequiredVersion $($ModuleInRepo.Version) -Repository $RepositoryName
      }
    }

    If(!(Test-TargetResource @PSBoundParameters))
    {
        throw "Set-TargetResouce failed"
    }
}

Function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
      [ValidateSet("Present","Absent")]
		  [System.String]
		  $Ensure = "Present",

		  [parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $ModuleName,

		  [parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
		  [System.Version]
		  $ModuleVersion,

		  [parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $RepositoryName
    )
    $arrModules = Get-TargetResource @PSBoundParameters
    $result = $true
    Foreach ($item in $arrModules)
    {
      if ($item.Ensure -ine $Ensure)
      {
        $result = $false
      }
    }
    $result
}
Export-ModuleMember -Function *-TargetResource