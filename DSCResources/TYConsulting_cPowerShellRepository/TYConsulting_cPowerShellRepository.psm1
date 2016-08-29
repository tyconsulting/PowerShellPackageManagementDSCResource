Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
      [ValidateSet("Present","Absent")]
		  [System.String]
		  $Ensure = "Present",

		  [parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $Name,

      [ValidateSet("Trusted","Untrusted")]
		  [System.String]
		  $InstallationPolicy = "Untrusted",

		  [parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $SourceLocation,

		  [parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $PublishLocation,

		  [parameter(Mandatory = $false)]
		  [System.String]
		  $PackageManagementProvider = 'NuGet'
    )
    Write-Verbose "Checking if PS Repository '$Name' exists."
    $PSRepository = Get-PSRepository -Name $Name -ErrorVariable ev1 -ErrorAction SilentlyContinue
    If ($null -eq $ev1 -or $ev1.count -eq 0)
    {
      Write-Verbose "PS Repository '$Name' is Present."
      $Ensure = 'Present'
    } else {
    Write-Verbose "PS Repository '$Name' is Absent."
      $Ensure = 'Absent'
    }
    
    $GetTargetResourceResult = $null
    $GetTargetResourceResult = @{
      Name = $PSRepository.Name
      Ensure = $Ensure
      InstallationPolicy = $PSRepository.InstallationPolicy
      SourceLocation = $PSRepository.SourceLocation
      PublishLocation = $PSRepository.PublishLocation
      PackageManagementProvider = $PSRepository.PackageManagementProvider
    }
    $GetTargetResourceResult
}

Function Set-TargetResource
{
    [CmdletBinding()]
    param(
      [ValidateSet("Present","Absent")]
		  [System.String]
		  $Ensure = "Present",

		  [parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $Name,

      [ValidateSet("Trusted","Untrusted")]
		  [System.String]
		  $InstallationPolicy = "Untrusted",

		  [parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $SourceLocation,

		  [parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $PublishLocation,

		  [parameter(Mandatory = $false)]
		  [System.String]
		  $PackageManagementProvider = 'NuGet'
    )
    #$PSRepository = Get-PSRepository | Where-Object {$_.Name -ieq $Name}
    Write-Verbose "Ensure PS Repository '$Name' is '$Ensure'."
    $PSRepository = Get-PSRepository -Name $Name -ErrorVariable ev2 -ErrorAction SilentlyContinue
    Switch ($Ensure)
    {
      'Present'
      {
        If ($null -eq $ev2 -or $ev2.count -eq 0)
        {
          Write-Verbose "PS Repository '$Name' already exist. Configuring it with configured parameters."
          $Parms = @{
            Name = $Name
            InstallationPolicy = $InstallationPolicy
            SourceLocation = $SourceLocation
            PublishLocation = $PublishLocation
            PackageManagementProvider = $PackageManagementProvider
          }
          $SetPSRepository = Set-PSRepository @Parms 
        } else {
          Write-Verbose "PS Repository '$Name' does not exist. creating it now."
          $Parms = @{
            Name = $Name
            InstallationPolicy = $InstallationPolicy
            SourceLocation = $SourceLocation
            PublishLocation = $PublishLocation
            PackageManagementProvider = $PackageManagementProvider
          }
          $NewPSRepository = Register-PSRepository @Parms
        }
      }
      'Absent'
      {
        If ($null -eq $ev2 -or $ev2.count -eq 0)
        {
          Write-Verbose "PS Repository '$Name' exists, removing it now."
          $RemovePSRepository = Unregister-PSRepository -Name $Name
        } else {
          Write-Verbose "PS Repository '$Name' does not exist. No need to remove it."
        }
      }
    }
    if(!(Test-TargetResource @PSBoundParameters))
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

		  [parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $Name,

      [ValidateSet("Trusted","Untrusted")]
		  [System.String]
		  $InstallationPolicy = "Untrusted",

		  [parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $SourceLocation,

		  [parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
		  [System.String]
		  $PublishLocation,

		  [parameter(Mandatory = $false)]
		  [System.String]
		  $PackageManagementProvider = 'NuGet'
    )
    $PSRepository = Get-TargetResource @PSBoundParameters
    $Result = ($PSRepository.Ensure -eq $Ensure)
    #If test result is $true and Ensure = "Present", then check PS repository configurations
    If ($Result -eq $true -and $Ensure -ieq "Present")
    {
      if ($InstallationPolicy -ine $PSRepository.InstallationPolicy)
      {
        Write-Verbose "PS Repository '$Name' InstallationPolicy is not configured as defined in the configuration. Desired Value: '$InstallationPolicy', Current Configuration: '$($PSRepository.InstallationPolicy)'"
        $Result = $false
      }
      if ($SourceLocation -ine $PSRepository.SourceLocation)
      {
        Write-Verbose "PS Repository '$Name' SourceLocation is not configured as defined in the configuration. Desired Value: '$SourceLocation', Current Configuration: '$($PSRepository.SourceLocation)'"
        $Result = $false
      }
      if ($PublishLocation -ine $PSRepository.PublishLocation)
      {
        Write-Verbose "PS Repository '$Name' PublishLocation is not configured as defined in the configuration. Desired Value: '$PublishLocation', Current Configuration: '$($PSRepository.PublishLocation)'"
        $Result = $false
      }
      if ($PackageManagementProvider -ine $PSRepository.PackageManagementProvider)
      {
        Write-Verbose "PS Repository '$Name' PackageManagementProvider is not configured as defined in the configuration. Desired Value: '$PackageManagementProvider', Current Configuration: '$($PSRepository.PackageManagementProvider)'"
        $Result = $false
      }
    }
    Write-Verbose "Test Result: $Result"
    $Result
}

Export-ModuleMember -Function *-TargetResource