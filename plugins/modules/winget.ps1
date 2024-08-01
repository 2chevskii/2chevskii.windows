#!powershell

#Requires -Version 5.1
#Requires -Modules @{ ModuleName = 'Microsoft.WinGet.Client'; ModuleVersion = '1.8.0' }

#AnsibleRequires -CSharpUtil Ansible.Basic

using namespace System.Linq

Import-Module -Name 'Microsoft.WinGet.Client'

$spec = @{
  options = @{
    id      = @{
      type     = 'str'
      required = $true
      aliases  = @('package_id', 'package')
    }
    version = @{ type = 'str' }
    state   = @{
      type    = 'str'
      choices = @('present', 'absent', 'latest')
      default = 'present'
    }
  }
  # supports_check_mode = $true
}

<#
  TODO: Implement check mode
#>

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

Function __validateModuleArguments {
  $isOk = $true

  If ($module.Params.state -eq 'latest' -and ($null -ne $module.Params.version)) {
    $module.FailJson('Parameter version is not allowed when state is set to latest')
    $isOk = $false
  }

  Return $isOk
}

Function __getInstallationStatus {
  $installedPackage = Get-WinGetPackage -Id $module.Params.id -MatchOption Equals
  $installationStatus = @{
    isInstalled = $null -ne $installedPackage
    package     = $installedPackage
  }
  Return $installationStatus
}

Function __writeModuleLog {
  Param (
    $Message
  )

  If ($null -eq $module.Result.log) {
    $module.Result.log = @()
  }

  $module.Result.log += $Message
}

Function __toTypedVersion {
  Param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [string]$StringVersion
  )

  $sanitizedVersion = $StringVersion.
  TrimStart('v', 'V').
  Trim(' ', "`t").
  Split(' ', [System.StringSplitOptions]::TrimEntries -bor [System.StringSplitOptions]::RemoveEmptyEntries) |
  Select-Object -First 1

  Try {
    return [semver]$sanitizedVersion
  } Catch {
    return [version]$sanitizedVersion
  }
}

Function __getLatestVersion {
  Param($WinGetPackage)
  return $WinGetPackage |
  Select-Object -ExpandProperty AvailableVersions |
  ForEach-Object { $_ | __toTypedVersion } |
  Sort-Object -Descending |
  Select-Object -First 1
}

Function __installLatestPackageVersion {
  $installationStatus = __getInstallationStatus
  $pkg = Find-WinGetPackage -Id $module.Params.id -MatchOption Equals

  If ($null -eq $pkg) {
    $module.FailJson("Package not found: $($module.Params.id)")
    Return
  }

  $latestVersion = __getLatestVersion -WinGetPackage $pkg

  If ($installationStatus.isInstalled) {
    If (($installationStatus.package.InstalledVersion | __toTypedVersion) -eq $latestVersion) {
      __writeModuleLog "Package $($installationStatus.package.Id) latest version $($installationStatus.package.InstalledVersion) is already installed"
      Return
    }

    __writeModuleLog "Uninstalling old version of package $($installationStatus.package.Id) v$($installationStatus.package.InstalledVersion)"
    __uninstallPackage
  }

  __writeModuleLog "Installing package $($pkg.Id) v$($latestVersion)"
  Install-WinGetPackage -Id $pkg.Id -Version $latestVersion -MatchOption Equals | Out-Null
  $module.Result.changed = $true
}

Function __installLatestPackageVersionIfNotPresent {
  $installationStatus = __getInstallationStatus
  If ($installationStatus.isInstalled) {
    __writeModuleLog "Package $($installationStatus.package.Id) v$($installationStatus.package.InstalledVersion) is already installed"
    Return
  }

  __installLatestPackageVersion
}

Function __installExactPackageVersion {
  $installationStatus = __getInstallationStatus
  $requestedVersion = $module.Params.version | __toTypedVersion

  If ($installationStatus.isInstalled) {
    If (($installationStatus.package.InstalledVersion | __toTypedVersion) -eq $requestedVersion) {
      __writeModuleLog "Package $($installationStatus.package.Id) version $requestedVersion is already installed (exact)"
      Return
    }

    __writeModuleLog "Uninstalling currently installed version of package $($installationStatus.package.Id) v$($installationStatus.package.InstalledVersion)"
    __uninstallPackage
  }

  $pkg = Find-WinGetPackage -Id $module.Params.id -MatchOption Equals

  If ($null -eq $pkg) {
    $module.FailJson("Package not found: $($module.Params.id)")
    Return
  }

  $requestedPackageVersion = $pkg |
  Select-Object -ExpandProperty AvailableVersions |
  ForEach-Object { $_ | __toTypedVersion } |
  Where-Object { $_ -eq $requestedVersion } |
  Select-Object -First 1

  If ($null -eq $requestedPackageVersion) {
    $module.FailJson("Package version $requestedVersion not found for package $($module.Params.id)")
    Return
  }

  __writeModuleLog "Installing package $($pkg.Id) v$($requestedPackageVersion)"
  Install-WinGetPackage -Id $pkg.Id -Version $requestedPackageVersion -MatchOption Equals | Out-Null
  $module.Result.changed = $true
}

Function __uninstallPackage {
  $installationStatus = __getInstallationStatus
  If (-not $installationStatus.isInstalled) {
    __writeModuleLog "Package $($module.Params.id) is not installed"
    Return
  }

  __writeModuleLog "Uninstalling package $($installationStatus.package.Id) v$($installationStatus.package.InstalledVersion)"
  Uninstall-WinGetPackage -Id $installationStatus.package.Id -MatchOption Equals | Out-Null
  $module.Result.changed = $true
}

If (__validateModuleArguments) {
  Switch ($module.Params.state) {
    'present' {
      If ($null -eq $module.Params.version) {
        __installLatestPackageVersionIfNotPresent
      } ElseIf ($module.Params.version -like 'latest') {
        __installLatestPackageVersion
      } Else {
        __installExactPackageVersion
      }
    }

    'latest' {
      __installLatestPackageVersion
    }

    'absent' {
      __uninstallPackage
    }
  }

  $module.ExitJson()
}
