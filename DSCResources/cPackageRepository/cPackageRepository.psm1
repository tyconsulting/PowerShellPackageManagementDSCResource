Function Get-TargetResource
{
    [CommandBidning()]
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
    Write-Vebose "Checking if PS Repository '$Name' exists."
    $PSRepository = Get-PSRepository | Where-Object {$_.Name -ieq $Name}
    If ($PSRepository -ne $null)
    {
      $Ensure = 'Present'
    } else {
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
    [CommandBidning()]
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
    $PSRepository = Get-PSRepository | Where-Object {$_.Name -ieq $Name}
    Write-Verbose "Ensure PS Repository '$Name' is '$Ensure'."
    Switch ($Ensure)
    {
      'Present'
      {
        If ($PSRepository -eq $null)
        {
          Write-Verbose "PS Repository '$Name' does not exist. creating it now."
          $Parms = @{
            Name = $Name
            InstallationPolicy = $InstallationPolicy
            SourceLocation = $SourceLocation
            PublishLocation = $PublishLocation
            PackageManagementProvider = $PackageManagementProvider
          }
          $NewPSRepository = Register-PSRepository @Parms
        } else {
          Write-Verbose "PS Repository '$Name' already exist. Setting with with configured parameters."
          $Parms = @{
            Name = $Name
            InstallationPolicy = $InstallationPolicy
            SourceLocation = $SourceLocation
            PublishLocation = $PublishLocation
            PackageManagementProvider = $PackageManagementProvider
          }
          $SetPSRepository = Set-PSRepository -Name @Parms 
        }
      }
      'Absent'
      {
        If ($PSRepository -ne $null)
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
    #If test result is $true, then check PS repository configurations
    If ($Result -eq $true)
    {
      if ($InstallationPolicy -ne $PSRepository.InstallationPolicy -or $SourceLocation -ne $PSRepository.SourceLocation -or $PublishLocation -ne $PSRepository.PublishLocation -or $PackageManagementProvider -ne $PSRepository.PackageManagementProvider)
      {
        Write-Verbose "PS Repository '$Name' configuration is not configured as defined in the configuration."
        $Result = $false
      }
    }
    $Result
}

Export-ModuleMember -Function *-TargetResource