<#
    .SYNOPSIS
    Retrieves and exports Azure DevOps organization-level security policy settings.

    .DESCRIPTION
    This script provides functions to query and export organization-level security policy settings from Azure DevOps using an internal, undocumented API endpoint. 
    The settings can be displayed in the console or exported to a JSON file for further analysis.

    .NOTES
    WARNING: This script uses an internal and undocumented API endpoint:
             https://dev.azure.com/{org}/_settings/organizationPolicy?__rt=fps&__ver=2
             This endpoint is not part of the officially supported Azure DevOps REST API.
             Microsoft may change, deprecate, or remove it at any time without notice.
             Use in production scenarios at your own risk and validate regularly.


    .LINK
    https://github.com/PoshCode/PowerShellPracticeAndStyle
    https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines
#>

function Read-AdoOrganizationSecurityPolicies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Organization,

        [Parameter(Mandatory = $true)]
        [string]
        $AccessToken
    )

    # Construct the internal policy settings endpoint
    $uri = "https://dev.azure.com/$Organization/_settings/organizationPolicy?__rt=fps&__ver=2"

    # Set headers with Bearer token
    $headers = @{
        Authorization = "Bearer $AccessToken"
        Accept        = "application/json"
    }

    try {
        # Use Invoke-WebRequest to allow content inspection before parsing
        $rawResponse = Invoke-WebRequest -Uri $uri -Method Get -Headers $headers -UseBasicParsing

        # Check for HTML content which likely means the token is expired or invalid
        if ($rawResponse.Content -match '<html' -or $rawResponse.RawContent -match 'Sign In') {
            throw "Access denied or token expired. Please verify your Bearer token is still valid."
        }

        # Convert HTML-safe content into PowerShell object
        $response = $rawResponse.Content | ConvertFrom-Json

        # Navigate to the internal data provider
        $policyData = $response.fps.dataProviders.data.'ms.vss-admin-web.organization-policies-data-provider'

        # Output settings to console for assessment
        Write-Host ""
        Write-Host "===== Azure DevOps Organization Security Policy Assessment ====="
        Write-Host ""

        $settings = @{}
        foreach ($categoryName in $policyData.policies.PSObject.Properties.Name) {
            $policies = $policyData.policies.$categoryName

            Write-Host $categoryName.ToUpper()

            foreach ($entry in $policies) {
                $p = $entry.policy
                $name = $p.name
                $desc = $entry.description
                $effective = $p.effectiveValue

                Write-Host " - $desc"
                Write-Host "   Name: $name"
                Write-Host "   Effective: $effective"
                Write-Host ""

                # Store settings with camelCase keys for JSON consistency
                $settingsKey = $name -replace '\s+', '' -replace '^.', { $_.Value.ToLower() }
                $settings[$settingsKey] = $effective
            }
        }

        Write-Host "Assessment complete."
        Write-Host ""

        # Return the settings object
        return $settings
    }
    catch {
        throw "Failed to retrieve or parse organization policy data: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function Read-AdoOrganizationSecurityPolicies

<#
    .SYNOPSIS
    Exports Azure DevOps organization security policy settings to a JSON file or returns them as an object.

    .DESCRIPTION
    The Export-AdoOrganizationSecurityPolicies function retrieves security policy settings for a specified Azure DevOps organization using the provided access token. 
    It formats the settings with metadata (e.g., ObjectType, ObjectName) and either saves them to a JSON file or returns them as an object, d
    epending on the parameters provided. Requires a prior connection to Azure DevOps via Connect-AzDevOps.

    .PARAMETER Organization
    The name of the Azure DevOps organization whose security policy settings will be exported.

    .PARAMETER AccessToken
    The Bearer token used for authenticating API requests to Azure DevOps.

    .PARAMETER OutputPath
    The file path where the security policy settings will be saved as a JSON file. If not specified, the settings are not saved to a file. Mutually exclusive with -PassThru.

    .PARAMETER PassThru
    If specified, returns the security policy settings as a PowerShell object instead of saving to a file. Mutually exclusive with -OutputPath.

    .EXAMPLE
    Export-AdoOrganizationSecurityPolicies -Organization "MyOrg" -AccessToken "abc123" -OutputPath "C:\Exports"
    Exports the security policy settings for "MyOrg" to "C:\Exports\OrganizationSecurityPolicies.ado.json".

    .EXAMPLE
    Export-AdoOrganizationSecurityPolicies -Organization "MyOrg" -AccessToken "abc123" -PassThru
    Retrieves and returns the security policy settings for "MyOrg" as a PowerShell object.

    .NOTES
    - Requires a prior call to Connect-AzDevOps to establish a connection.
    - The function depends on Read-AdoOrganizationSecurityPolicies to retrieve settings.
    - The output JSON file is named "OrganizationSecurityPolicies.ado.json" when using -OutputPath.

    .LINK
    https://docs.microsoft.com/en-us/rest/api/azure/devops/
#>
function Export-AdoOrganizationSecurityPolicies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Organization,

        [Parameter(Mandatory = $true)]
        [string]
        $AccessToken,

        [Parameter(ParameterSetName = 'JsonFile')]
        [string]
        $OutputPath,

        [Parameter(ParameterSetName = 'PassThru')]
        [switch]
        $PassThru
    )

    # Check for active connection
    if ($null -eq $script:connection) {
        throw 'Not connected to Azure DevOps. Run Connect-AzDevOps first.'
    }

    # Retrieve security policy settings
    try {
        $settings = Read-AdoOrganizationSecurityPolicies -Organization $Organization -AccessToken $AccessToken
        if ($null -eq $settings) {
            throw "No Organization security policy settings returned from Read-AdoOrganizationSecurityPolicies."
        }
    }
    catch {
        throw "Failed to get Organization security policy settings from Azure DevOps: $($_.Exception.Message)"
    }

    # Process settings into exportable format
    $settingsDetails = @()
    $settingsObject = [PSCustomObject]$settings

    # Add metadata properties
    $settingsObject | Add-Member -MemberType NoteProperty -Name ObjectType -Value 'Azure.DevOps.Organization.Security.Policies' -Force
    $settingsObject | Add-Member -MemberType NoteProperty -Name ObjectName -Value "$($script:connection.Organization).OrganizationSecurityPolicies" -Force
    $settingsObject | Add-Member -MemberType NoteProperty -Name name -Value "OrganizationSecurityPolicies" -Force

    # Create structured id object
    $id = @{
        originalId   = $null
        resourceName = "OrganizationSecurityPolicies"
        organization = $script:connection.Organization
    } | ConvertTo-Json -Depth 100
    $settingsObject | Add-Member -MemberType NoteProperty -Name id -Value $id -Force

    $settingsDetails += $settingsObject

    # Output based on parameters
    if ($PassThru) {
        Write-Output $settingsDetails
    }
    else {
        $settingsDetails | ConvertTo-Json -Depth 100 | Out-File -FilePath "$OutputPath\OrganizationSecurityPolicies.ado.json"
    }
}

Export-ModuleMember -Function Export-AdoOrganizationSecurityPolicies