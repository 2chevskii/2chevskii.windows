#!powershell

#Requires -Version 5.1

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options = @{
    name    = @{
      type     = 'str'
      required = $true
    }
    version = @{ type = 'str' }
    state   = @{
      type    = 'str'
      choices = 'present', 'absent', 'latest'
      default = 'present'
    }
    scope   = @{
      type    = 'str'
      choices = 'current_user', 'all_users'
      default = 'current_user'
    }
  }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$module.Result.changed = $false

$powershellGetVersion = Get-Module -Name 'PowerShellGet' | Select-Object -ExpandProperty Version

Function __writeModuleLog {
  Param (
    $Message
  )

  If ($null -eq $module.Result.log) {
    $module.Result.log = @()
  }

  $module.Result.log += $Message
}

$installedModule = Get-Module -Name $module.Params.name
$isInstalled = $null -ne $installedModule

Function __getLatestVersion {
  If ($powershellGetVersion -ge '2.0.0') {
    Return Find-Module -Name $module.Params.name -AllowPrerelease | Select-Object -ExpandProperty Version
  } Else {
    Return Find-Module -Name $module.Params.name | Select-Object -ExpandProperty Version
  }
}

Function __uninstallModule {
  __writeModuleLog "Uninstalling module $($installedModule.Name) v$($installedModule.Version)"

  Uninstall-Module -Name $module.Params.name
  $module.Result.changed = $true
}

Function __installModule {
  Param (
    $Version
  )

  __writeModuleLog "Installing module $($module.Params.name) v$Version"
  If ($powershellGetVersion -ge '2.0.0') {
    Install-Module -Name $module.Params.name -AllowPrerelease -RequiredVersion $Version
  } Else {
    Install-Module -Name $module.Params.name -RequiredVersion $Version
  }
  $module.Result.changed = $true
}

Switch ($module.Params.state) {
  'present' {
    $latestVersion = __getLatestVersion

    If (-not $isInstalled) {
      If ($null -ne $module.Params.version) {
        __installModule -Version $module.Params.version
      } Else {
        __installModule -Version $latestVersion
      }
      $module.ExitJson()
    } ElseIf ($null -ne $module.Params.version -and ($installedModule.Version -ne $module.Params.version)) {
      If ($installedModule.Version -lt $module.Params.version) {
        __writeModuleLog "Package $($installedModule.Name) needs upgrade"
        __uninstallModule
        __installModule -Version $module.Params.version
        $module.ExitJson()
      } ElseIf ($installedModule.Version -gt $module.Params.version) {
        __writeModuleLog "Package $($installedModule.Name) needs downgrade"
        __uninstallModule
        __installModule -Version $module.Params.version
        $module.ExitJson()

      } Else {
        $module.FailJson("Package $($installedModule.Name) version is not equal to required version, but it is not greater nor less ($($installedModule.Version) != $($module.Params.version)). This might indicate a problem with parameters")
      }
    }
  }
  'latest' {
    $latestVersion = __getLatestVersion

    If (-not $isInstalled) {
      __installModule -Version $latestVersion
    } ElseIf ($installedModule.Version -lt $latestVersion) {
      __uninstallModule
      __installModule -Version $latestVersion
    }
    $module.ExitJson()
  }
  'absent' {
    If ($isInstalled) {
      __uninstallModule
    }
    $module.ExitJson()
  }
}
