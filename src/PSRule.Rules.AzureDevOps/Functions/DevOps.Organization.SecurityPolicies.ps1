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
        Write-Verbose "Querying API: $uri"
        $rawResponse = Invoke-WebRequest -Uri $uri -Method Get -Headers $headers -UseBasicParsing

        # Check for HTML content indicating invalid/expired token
        if ($rawResponse.Content -match '<html' -or $rawResponse.RawContent -match 'Sign In') {
            throw "Access denied or token expired. Please verify your Bearer token is still valid."
        }

        # Parse JSON response
        $response = $rawResponse.Content | ConvertFrom-Json

        # Navigate to the internal data provider
        $policyData = $response.fps.dataProviders.data.'ms.vss-admin-web.organization-policies-data-provider'
        if ($null -eq $policyData) {
            throw "Policy data not found in API response."
        }

        # Expected policy fields (without Policy. prefix)
        $expectedPolicies = @(
            'Disallow Secure Shell',
            'Allow Request Access Token',
            'Allow Team Admins Invitations Access Token',
            'Allow Feedback Collection',
            'Enforce AAD Conditional Access',
            'Disallow OAuth Authentication',
            'Log Audit Events',
            'Artifacts External Package Protection Token',
            'Allow Anonymous Access',
            'Disallow Aad Guest User Access'
        )

        # Output settings to console for assessment
        Write-Host ""
        Write-Host "===== Azure DevOps Organization Security Policy Assessment ====="
        Write-Host ""

        $settings = @{}
        $foundPolicies = @()
        foreach ($categoryName in $policyData.policies.PSObject.Properties.Name) {
            $policies = $policyData.policies.$categoryName

            Write-Host $categoryName.ToUpper()

            foreach ($entry in $policies) {
                $p = $entry.policy
                $name = $p.name
                $desc = $entry.description
                $effective = [bool]$p.effectiveValue  # Ensure boolean type

                Write-Host " - $desc"
                Write-Host "   Name: $name"
                Write-Host "   Effective: $effective"
                Write-Host ""

                # Store settings with camelCase keys and single policy. prefix
                $settingsKey = $name -replace '^Policy\.', '' -replace '\s+', '' -replace '^.', { $_.Value.ToLower() }
                $settings[$settingsKey] = $effective  # Removed extra "policy." prefix

                # Track policy names without Policy. prefix for validation
                $cleanName = $name -replace '^Policy\.', ''
                $foundPolicies += $cleanName
            }
        }

        # Validate expected policies
        $missingPolicies = $expectedPolicies | Where-Object { $_ -notin $foundPolicies }
        if ($missingPolicies) {
            Write-Warning "Missing expected policies in API response: $($missingPolicies -join ', ')"
        }
        else {
            Write-Verbose "All expected policies found in API response."
        }

        Write-Host "Assessment complete."
        Write-Host ""

        # Return the settings object
        return $settings
    }
    catch {
        Write-Error "Failed to retrieve or parse organization policy data: $($_.Exception.Message)"
        throw
    }
}

Export-ModuleMember -Function Read-AdoOrganizationSecurityPolicies

<#
    .SYNOPSIS
    Exports Azure DevOps organization security policy settings to a JSON file or returns them as an object.

    .DESCRIPTION
    The Export-AdoOrganizationSecurityPolicies function retrieves security policy settings for a specified Azure DevOps organization using the provided access token. 
    It formats the settings with metadata (e.g., ObjectType, ObjectName) and either saves them to a JSON file or returns them as an object, depending on the parameters provided. 
    Requires a prior connection to Azure DevOps via Connect-AzDevOps.

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
        Write-Verbose "Retrieving security policy settings for organization: $Organization"
        $settings = Read-AdoOrganizationSecurityPolicies -Organization $Organization -AccessToken $AccessToken -Verbose
        if ($null -eq $settings -or $settings.Count -eq 0) {
            throw "No organization security policy settings returned from Read-AdoOrganizationSecurityPolicies."
        }
    }
    catch {
        Write-Error "Failed to get organization security policy settings: $($_.Exception.Message)"
        throw
    }

    # Create settings object with metadata
    $settingsObject = [PSCustomObject]@{
        ObjectType = 'Azure.DevOps.Organization.Security.Policies'
        ObjectName = "$($script:connection.Organization).OrganizationSecurityPolicies"
        name       = 'OrganizationSecurityPolicies'
        id         = @{
            resourceName = 'OrganizationSecurityPolicies'
            organization = $script:connection.Organization
            originalId   = $null
        }
    }

    # Add policy settings with single policy. prefix
    foreach ($key in $settings.Keys) {
        $settingsObject | Add-Member -MemberType NoteProperty -Name "policy.$key" -Value $settings[$key] -Force
    }

    # Output based on parameters
    if ($PassThru) {
        Write-Verbose "Returning settings object"
        Write-Output $settingsObject
    }
    else {
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        $outputFile = Join-Path $OutputPath 'OrganizationSecurityPolicies.ado.json'
        Write-Verbose "Exporting settings to: $outputFile"
        $settingsObject | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding UTF8
        Write-Host "Exported security policy settings to: $outputFile"
    }
}

Export-ModuleMember -Function Export-AdoOrganizationSecurityPolicies