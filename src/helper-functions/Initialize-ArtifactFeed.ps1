<#
.SYNOPSIS
    Initialize and register an Azure DevOps Artifacts feed as a PowerShell PSResource repository, and install custom modules.

.DESCRIPTION
    Imports required modules, enforces TLS 1.2, configures a SecretStore vault,
    stores a PAT-based PSCredential with an auto-generated vault password,
    registers the specified Azure Artifacts feed,
    and installs any custom modules from that feed.

.PARAMETER OrganizationName
    Azure DevOps organization name.

.PARAMETER ProjectName
    Azure DevOps project name.

.PARAMETER FeedName
    Azure Artifacts feed name.

.PARAMETER PatUser
    Username for the Azure DevOps PAT credential.

.PARAMETER PatToken
    Azure DevOps Personal Access Token (PAT) with feed-read permissions.

.PARAMETER CustomModules
    Array of module names to install after registering the repository.

.EXAMPLE
    $initFeedParams = @{
        OrganizationName = 'Contoso'
        ProjectName      = 'WebApp'
        FeedName         = 'Modules'
        PatUser          = 'build'
        PatToken         = 'abc123'
        CustomModules    = @('PSRule.Rules.AzureDevOps', 'Another.Module')
        Verbose          = $true
    }

    .\Initialize-ArtifactFeed.ps1 @initFeedParams
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $OrganizationName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $ProjectName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $FeedName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $PatUser,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $PatToken,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string[]] $CustomModules
)

Begin {
    # Static configuration values for vault, secret, and repository
    $vaultName = 'SecretVault'
    $secretName = 'MyCredential'
    $repositoryName = 'PowershellPSResourceRepository'
    $passwordTimeout = -1

    # Generate a random lowercase password of length 10
    # Justified: secret is only available in memory via runtime injection
    $password = -join ( (97..122) | Get-Random -Count 10 | ForEach-Object { [char]$_ } ) |
    ConvertTo-SecureString -AsPlainText -Force

    Write-Host "##[group]Importing PowerShell Modules"
    try {
        # Ensure required modules are loaded
        Import-Module Microsoft.PowerShell.SecretStore     -Force -ErrorAction Stop
        Import-Module Microsoft.PowerShell.SecretManagement -Force -ErrorAction Stop
        Import-Module Microsoft.PowerShell.PSResourceGet    -Force -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to import modules: $_"
        throw
    }
    Write-Output "##[endgroup]"
}

Process {
    # Enforce TLS 1.2 for secure connections
    Write-Verbose 'Enforcing TLS 1.2'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Host "##[group]Prepare variables"
    # Construct the feed URL
    $feedUrl = "https://pkgs.dev.azure.com/$OrganizationName/$ProjectName/_packaging/$FeedName/nuget/v3/index.json"

    # Convert PAT to secure PSCredential
    # Justified: secret is only available in memory via runtime injection
    $secureToken = $PatToken | ConvertTo-SecureString -AsPlainText -Force
    $credentials = New-Object System.Management.Automation.PSCredential($PatUser, $secureToken)
    Write-Host "##[endgroup]"

    Write-Host "##[group]Set secret vault and secret store"
    # Unregister existing vault if present
    if (Get-SecretVault -Name $vaultName -ErrorAction SilentlyContinue) {
        Write-Host "Vault [$vaultName] exists; removing."
        Unregister-SecretVault -Name $vaultName -ErrorAction Stop
    }

    # Register a new SecretStore vault
    Register-SecretVault -Name $vaultName -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault -ErrorAction Stop

    # Reset the vault with splatting for long call
    $resetParams = @{
        Scope           = 'CurrentUser'
        Authentication  = 'Password'
        Interaction     = 'None'
        Password        = $password
        PasswordTimeout = $passwordTimeout
        Force           = $true
        ErrorAction     = 'Stop'
    }
    Reset-SecretStore @resetParams

    # Unlock the vault
    $unlockParams = @{
        Password    = $resetParams.Password;
        ErrorAction = 'Stop'
    }

    Unlock-SecretStore @unlockParams

    # Store the PSCredential in the vault
    $secretParams = @{ Name = $secretName; Secret = $credentials; Vault = $vaultName; ErrorAction = 'Stop' }
    Set-Secret @secretParams
    $credentialInfo = [Microsoft.PowerShell.PSResourceGet.UtilClasses.PSCredentialInfo]::new($vaultName, $secretName)
    Write-Host "##[endgroup]"

    Write-Host "##[group]Set Azure Artifacts as PowerShell Repository"
    # Unregister existing repository if present
    if (Get-PSResourceRepository -Name $repositoryName -ErrorAction SilentlyContinue) {
        Write-Host "Removing existing PSResource repo [$repositoryName]"
        Unregister-PSResourceRepository -Name $repositoryName -ErrorAction Stop
    }

    # Register the repository using splatting
    $repoParams = @{
        Name           = $repositoryName
        Uri            = $feedUrl
        Trusted        = $true
        CredentialInfo = $credentialInfo
        ErrorAction    = 'Stop'
    }
    Register-PSResourceRepository @repoParams

    Write-Host "##[endgroup]"

    Write-Host "##[group]Import custom modules [$($CustomModules -join ', ')]"
    foreach ($module in $CustomModules) {
        # Install each module using splatting for long calls
        $installParams = @{
            Name        = $module
            Repository  = $repositoryName
            Credential  = $credentials
            ErrorAction = 'Stop'
        }
        Install-PSResource @installParams
    }
    Write-Host "##[endgroup]"
}

End {
    Write-Verbose 'Initialization complete.'
}
