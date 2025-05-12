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
    
    function Publish-ToAzureArtifactsPSRepo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Organization,

        [Parameter(Mandatory)]
        [string]$Project,

        [Parameter(Mandatory)]
        [string]$FeedName,

        [Parameter(Mandatory)]
        [string]$RepositoryName,

        [Parameter(Mandatory)]
        [string]$Username,

        [Parameter(Mandatory)]
        [string]$PatToken,

        [Parameter(Mandatory)]
        [string]$PackagePath,

        [Parameter(Mandatory)]
        [string]$ApiKey
    )

    try {
        # Ensure TLS 1.2 for secure connection
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        # Build feed URL (NuGet v3 for PSResourceGet)
        $feedUrl = "https://pkgs.dev.azure.com/$Organization/$Project/_packaging/$FeedName/nuget/v3/index.json"

        # Convert PAT to secure credential
        $secureToken = ConvertTo-SecureString $PatToken -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential($Username, $secureToken)

        # Register the repository if not already registered
        if (-not (Get-PSResourceRepository -Name $FeedName -ErrorAction SilentlyContinue)) {
            Register-PSResourceRepository -Name $FeedName -Uri $feedUrl -Trusted
        }

        # Publish the module
        Write-Host "Publishing module to: [$FeedName]" -ForegroundColor Cyan
        Publish-PSResource -Path $PackagePath -Repository $FeedName -ApiKey $ApiKey -Credential $credential
    }
    catch {
        Write-Error "❌ Error occurred: $_"
    }
}
