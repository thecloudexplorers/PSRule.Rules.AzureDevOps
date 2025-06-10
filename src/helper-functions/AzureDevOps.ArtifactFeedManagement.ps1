#Requires -Modules Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore, Microsoft.PowerShell.PSResourceGet

function Register-AzureDevOpsArtifactFeed {
    <#
    .SYNOPSIS
        Initialize and register an Azure DevOps Artifacts feed as a PowerShell PSResource repository, and install custom
         modules.

    .DESCRIPTION
        Imports required modules, enforces TLS 1.2, configures a SecretStore vault,
        stores a PAT-based PSCredential with an auto-generated vault password,
        registers the specified Azure Artifacts feed,
        and installs any custom modules from that feed.

    .PARAMETER Organization
        Azure DevOps organization name.

    .PARAMETER Project
        Azure DevOps project name.

    .PARAMETER FeedName
        Azure Artifacts feed name.

    .PARAMETER PatUser
        PatUser for the Azure DevOps PAT credential.

    .PARAMETER PatToken
        Azure DevOps Personal Access Token (PAT) with feed-read permissions as a SecureString.

    .PARAMETER CustomModules
        Array of module names to install after registering the repository.

    .EXAMPLE
        $initFeedParams = @{
            Organization = 'Contoso'
            Project      = 'WebApp'
            FeedName         = 'Modules'
            PatUser          = 'build'
            PatToken         = (ConvertTo-SecureString -String $env:ADO_PAT -AsPlainText -Force)
            CustomModules    = @('PSRule.Rules.AzureDevOps', 'Another.Module')
            Verbose          = $true
        }

        .\Register-AzureDevOpsArtifactFeed.ps1 @initFeedParams
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Organization,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Project,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $FeedName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $PatUser,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Security.SecureString] $PatToken,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $PSRepositoryName,

        [Parameter()]
        [System.String[]] $CustomModules = @()
    )
    Begin {
        $ErrorActionPreference = 'Stop'

        Write-Verbose 'Loading required modules'
        Import-Module Microsoft.PowerShell.SecretStore      -ErrorAction Stop
        Import-Module Microsoft.PowerShell.SecretManagement -ErrorAction Stop
        Import-Module Microsoft.PowerShell.PSResourceGet    -ErrorAction Stop

        # Static configuration
        $vaultName = 'SecretVault'
        $secretName = 'MyCredential'
        $passwordTimeout = -1

        # Generate random password for vault
        $randomChars = 97..122 | Get-Random -Count 10 | ForEach-Object { [char]$_ }
        $password = -join $randomChars
        # Random vault password
        $securePwd = ConvertTo-SecureString -String $password -AsPlainText -Force
    }
    Process {
        Write-Host "##[section]Initializing Azure Artifacts as PowerShell Gallery."
        Write-Verbose '## Enforcing TLS 1.2'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        Write-Host '##[group] Prepare variables'
        $feedUrl = "https://pkgs.dev.azure.com/$Organization/$Project/_packaging/$FeedName/nuget/v3/index.json"
        Write-Host '##[endgroup]'

        Write-Host '##[group] Configure SecretStore'
        if (Get-SecretVault -Name $vaultName -ErrorAction SilentlyContinue) {
            Write-Verbose "Vault $vaultName exists; unregistering"
            Unregister-SecretVault -Name $vaultName -ErrorAction Stop
        }
        $vaultParams = @{
            Name         = $vaultName
            ModuleName   = 'Microsoft.PowerShell.SecretStore'
            DefaultVault = $true
            ErrorAction  = 'Stop'
        }
        Register-SecretVault @vaultParams

        $resetParams = @{
            Scope           = 'CurrentUser'
            Authentication  = 'Password'
            Interaction     = 'None'
            Password        = $securePwd
            PasswordTimeout = $passwordTimeout
            Force           = $true
            ErrorAction     = 'Stop'
        }
        Reset-SecretStore @resetParams

        $unlockParams = @{
            Password    = $resetParams.Password
            ErrorAction = 'Stop'
        }
        Unlock-SecretStore @unlockParams

        $cred = New-Object System.Management.Automation.PSCredential (
            $PatUser,
            $PatToken
        )
        $secretParams = @{
            Name        = $secretName
            Secret      = $cred
            Vault       = $vaultName
            ErrorAction = 'Stop'
        }
        Set-Secret @secretParams

        $credentialInfo = [Microsoft.PowerShell.PSResourceGet.UtilClasses.PSCredentialInfo]::new(
            $vaultName,
            $secretName
        )
        Write-Host '##[endgroup]'

        Write-Host '##[group] Register PSResource repository'
        if (Get-PSResourceRepository -Name $PSRepositoryName -ErrorAction SilentlyContinue) {
            Write-Verbose "Unregistering existing repository $PSRepositoryName"
            Unregister-PSResourceRepository -Name $PSRepositoryName -ErrorAction Stop
        }
        $repoParams = @{
            Name           = $PSRepositoryName
            Uri            = $feedUrl
            Trusted        = $true
            CredentialInfo = $credentialInfo
            ErrorAction    = 'Stop'
        }
        Register-PSResourceRepository @repoParams
        Write-Verbose "Registered PSResourceRepositories"

        Write-Host '##[endgroup]'

        Write-Host "##[group] Install custom modules: $($CustomModules -join ', ')"
        foreach ($module in $CustomModules) {
            $installParams = @{
                Name        = $module
                Repository  = $PSRepositoryName
                Credential  = $cred
                ErrorAction = 'Stop'
            }
            Install-PSResource @installParams
        }
        Write-Host '##[endgroup]'
    }
    End {
        Write-Host "##[section] Azure Artifacts initialization complete." -ForegroundColor Green
    }
}




function Publish-AzureDevOpsArtifactPackage {
    <#
.SYNOPSIS
    Publishes a PowerShell package to a private Azure Artifacts feed.

.DESCRIPTION
    This function publishes a specified PowerShell package to an Azure Artifacts feed.
    It can work with repositories that use SecretStore credentials or with direct credential authentication.
    If the repository uses SecretStore, it will attempt to unlock the vault using a provided password.

.PARAMETER PatUser
    PatUser for the Azure DevOps PAT (usually 'Azure DevOps').

.PARAMETER PatToken
    Azure DevOps Personal Access Token as a SecureString.

.PARAMETER PSRepositoryName
    The name of the PSRepository to publish to.

.PARAMETER PackagePath
    The full path to the PowerShell module/package to publish.

.PARAMETER ApiKey
    The API key used for publishing to the Azure Artifacts feed (can be dummy if not used).

.EXAMPLE
    # Define all parameters for direct credential publishing
    $securePat = ConvertTo-SecureString -String $env:MyPatToken -AsPlainText -Force
    $publishParams = @{
        PatUser          = 'Azure DevOps'
        PatToken         = $securePat
        PSRepositoryName = 'MyRepository'
        PackagePath      = 'C:\Modules\MyModule'
        ApiKey           = 'dummy'
    }

    # Invoke the function using splatting
    Publish-AzureDevOpsArtifactPackage @publishParams
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $PatUser,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Security.SecureString] $PatToken,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $PSRepositoryName,

        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [System.String] $PackagePath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ApiKey
    )
    Begin {
        # Fail fast on all errors
        $ErrorActionPreference = 'Stop'

        Write-Host "##[group]Importing PowerShell Modules"
        try {
            # Ensure required modules are loaded
            Import-Module Microsoft.PowerShell.SecretStore -Force -ErrorAction Stop
            Import-Module Microsoft.PowerShell.SecretManagement -Force -ErrorAction Stop
            Import-Module Microsoft.PowerShell.PSResourceGet -Force -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to import modules: $_"
            throw
        }
        Write-Output "##[endgroup]"
    }
    Process {
        Write-Host "##[section]Publishing PowerShell Module." -ForegroundColor Green

        Write-Verbose '## Enforcing TLS 1.2'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $repository = Get-PSResourceRepository -Name $PSRepositoryName -ErrorAction SilentlyContinue
        if ($repository -and $repository.CredentialInfo) {
            Write-Verbose "Repository uses SecretStore credentials. Resetting and unlocking vault."

            # Static configuration matching the Register function
            $passwordTimeout = -1
            $vaultName = 'SecretVault'
            $secretName = 'MyCredential'

            # Generate random password for vault (same approach as Register function)
            $randomChars = 97..122 | Get-Random -Count 10 | ForEach-Object { [char]$_ }
            $password = -join $randomChars
            $securePwd = ConvertTo-SecureString -String $password -AsPlainText -Force

            try {
                # Reset the SecretStore with new random password
                $resetParams = @{
                    Scope           = 'CurrentUser'
                    Authentication  = 'Password'
                    Interaction     = 'None'
                    Password        = $securePwd
                    PasswordTimeout = $passwordTimeout
                    Force           = $true
                    ErrorAction     = 'Stop'
                }
                Reset-SecretStore @resetParams

                # Unlock the vault with the new password
                $unlockParams = @{
                    Password    = $securePwd
                    ErrorAction = 'Stop'
                }
                Unlock-SecretStore @unlockParams

                # Re-store the credentials after vault reset
                $credential = New-Object System.Management.Automation.PSCredential ($PatUser, $PatToken)
                $secretParams = @{
                    Name        = $secretName
                    Secret      = $credential
                    Vault       = $vaultName
                    ErrorAction = 'Stop'
                }
                Set-Secret @secretParams

                Write-Verbose "SecretStore vault reset, unlocked, and credentials restored successfully."
            }
            catch {
                Write-Warning "Failed to reset/unlock SecretStore vault: $_"
                Write-Verbose "Proceeding with direct credential authentication."
            }
        }

        Write-Host '##[group] Publishing module' -ForegroundColor Green

        $credential = New-Object System.Management.Automation.PSCredential ($PatUser, $PatToken)

        # Publish the module using splatted parameters
        $publishParams = @{
            Path        = $PackagePath
            Repository  = $PSRepositoryName
            ApiKey      = $ApiKey
            Credential  = $credential
            ErrorAction = 'Stop'
        }
        Publish-PSResource @publishParams
        Write-Host '##[endgroup]'

        Write-Host "##[section] Module publication complete." -ForegroundColor Green
    }
    End {
        Write-Verbose 'Initialization complete.'
    }
}
