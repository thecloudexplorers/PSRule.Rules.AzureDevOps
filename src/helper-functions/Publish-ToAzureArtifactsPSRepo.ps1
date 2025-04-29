function Publish-ToAzureArtifactsPSRepo {
    <#
    .SYNOPSIS
        Publishes a PowerShell package to a private Azure Artifacts feed.

    .DESCRIPTION
        This function registers a PSRepository backed by an Azure Artifacts feed, manages credentials securely using SecretManagement and SecretStore,
        and publishes a specified PowerShell package.

    .PARAMETER Organization
        The name of your Azure DevOps organization.

    .PARAMETER Project
        The Azure DevOps project name.

    .PARAMETER FeedName
        The name of the Azure Artifacts feed.

    .PARAMETER RepositoryName
        Desired name for the PowerShell repository registration.

    .PARAMETER Username
        Username for the Azure DevOps PAT (usually 'Azure DevOps').

    .PARAMETER PatToken
        Azure DevOps Personal Access Token (passed via environment variable or as argument).

    .PARAMETER PackagePath
        The full path to the PowerShell module/package to publish.

    .PARAMETER ApiKey
        The API key used for publishing to the Azure Artifacts feed (can be dummy if not used).

    .PARAMETER SecretVault
        (Optional) Secret vault name. Defaults to 'LocalVault'.

    .EXAMPLE
        Publish-ToAzureArtifactsPSRepo -Organization 'contoso' -Project 'MyProject' -FeedName 'MyFeed' -RepositoryName 'MyPSRepo' \
            -Username 'Azure DevOps' -PatToken $env:MyPatToken -PackagePath 'C:\Modules\MyModule' -ApiKey 'dummy'

    .NOTES
        Author: Wesley
        Date: 2025-04-29
        Version: 1.1
        Reference: https://learn.microsoft.com/en-us/azure/devops/artifacts/tutorials/private-powershell-library
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$Organization,
        [Parameter(Mandatory)][string]$Project,
        [Parameter(Mandatory)][string]$FeedName,
        [Parameter(Mandatory)][string]$RepositoryName,
        [Parameter(Mandatory)][string]$Username,
        [Parameter(Mandatory)][string]$PatToken,
        [Parameter(Mandatory)][string]$PackagePath,
        [Parameter(Mandatory)][string]$ApiKey,
        [string]$SecretVault = "LocalVault"
    )

    try {
        Write-Host "Installing and importing required modules..." -ForegroundColor Cyan
        Install-Module -Name Microsoft.PowerShell.SecretStore -Repository PSGallery -Force -ErrorAction Stop
        Install-Module -Name Microsoft.PowerShell.SecretManagement -Repository PSGallery -Force -ErrorAction Stop
        Install-Module -Name Microsoft.PowerShell.PSResourceGet -Repository PSGallery -Force -ErrorAction Stop
        Import-Module Microsoft.PowerShell.SecretStore
        Import-Module Microsoft.PowerShell.SecretManagement
        Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.1.1

        $feedUrl = "https://pkgs.dev.azure.com/$Organization/$Project/_packaging/$FeedName/nuget/v2"
        $secureToken = $PatToken | ConvertTo-SecureString -AsPlainText -Force
        $credential = [PSCredential]::new($Username, $secureToken)

        if (-not (Get-SecretVault -Name $SecretVault -ErrorAction SilentlyContinue)) {
            Register-SecretVault -Name $SecretVault -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
        }

        Reset-SecretStore -Authentication None -Interaction None -Force
        Set-Secret -Name "MyCredential" -Secret $credential -Vault $SecretVault

        if (-not (Get-PSRepository -Name $RepositoryName -ErrorAction SilentlyContinue)) {
            Register-PSRepository -Name $RepositoryName -SourceLocation $feedUrl \
            -InstallationPolicy Trusted -Credential $credential
        }

        Write-Host "Publishing package from: $PackagePath" -ForegroundColor Cyan
        Publish-PSResource -Path $PackagePath -Repository $FeedName -Credential $credential -ApiKey $ApiKey
    } catch {
        Write-Error "❌ Error occurred: $_"
    }
}
