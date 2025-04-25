<#
    .SYNOPSIS
    Retrieves Azure DevOps organization-level general overview settings.

    .DESCRIPTION
    Queries the internal Azure DevOps organization overview endpoint to retrieve metadata including the description, timezone, region, geography, and organization owner.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER AccessToken
    A valid Azure DevOps Bearer token with access to read organization-level settings.

    .EXAMPLE
    Read-AdoOrganizationGeneralOverview -Organization "MyOrg" -AccessToken "abc123"

    .NOTES
    WARNING: This script uses an internal and undocumented API endpoint:
    https://dev.azure.com/{org}/_settings/organizationOverview?__rt=fps&__ver=2
    This endpoint is not part of the officially supported Azure DevOps REST API and may change or be removed without notice.
#>

function Read-AdoOrganizationGeneralOverview {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Organization,

        [Parameter(Mandatory = $true)]
        [string]
        $AccessToken
    )

    # Define endpoint for organization overview query
    $uri = "https://dev.azure.com/$Organization/_settings/organizationOverview?__rt=fps&__ver=2"

    # Set headers for authentication
    $headers = @{
        Authorization  = "Bearer $AccessToken"
        "Content-Type" = "application/json"
    }

    try {
        # Invoke API to retrieve settings
        $rawResponse = Invoke-WebRequest -Uri $uri -Method Get -Headers $headers -UseBasicParsing

        # Validate response for authentication errors
        if ($rawResponse.Content -match '<html' -or $rawResponse.RawContent -match 'Sign In') {
            throw "Access denied or token expired. Please verify your Bearer token is still valid."
        }

        # Parse response
        $response = $rawResponse.Content | ConvertFrom-Json
        $settings = [PSCustomObject]@{
            description = if ([string]::IsNullOrWhiteSpace($response.fps.dataProviders.data.'ms.vss-admin-web.organization-admin-overview-data-provider'.description)) { "Not Set" } else { $response.fps.dataProviders.data.'ms.vss-admin-web.organization-admin-overview-data-provider'.description }
            timeZone    = $response.fps.dataProviders.data.'ms.vss-admin-web.organization-admin-overview-data-provider'.timeZone.displayName
            geography   = $response.fps.dataProviders.data.'ms.vss-admin-web.organization-admin-overview-data-provider'.geography
            region      = $response.fps.dataProviders.data.'ms.vss-admin-web.organization-admin-overview-data-provider'.region
            owner       = $response.fps.dataProviders.data.'ms.vss-web.page-data'.user.displayName
        }

        # Output settings to console
        Write-Host ""
        Write-Host "===== Azure DevOps Organization Overview Assessment ====="
        Write-Host ""

        Write-Host "Description: $($settings.description)"
        Write-Host "Time Zone : $($settings.timeZone)"
        Write-Host "Geography : $($settings.geography)"
        Write-Host "Region    : $($settings.region)"
        Write-Host "Owner     : $($settings.owner)"
        Write-Host ""
        Write-Host "Assessment complete."

        # Return the settings object
        return $settings
    }
    catch {
        throw "Failed to retrieve organization overview: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function Read-AdoOrganizationGeneralOverview

<#
    .SYNOPSIS
    Exports Azure DevOps organization general overview settings to a JSON file or returns them as an object.

    .DESCRIPTION
    The Export-AdoOrganizationGeneralOverview function retrieves general overview settings for a specified Azure DevOps organization using the provided access token. It formats the settings with metadata (e.g., ObjectType, ObjectName) and either saves them to a JSON file or returns them as an object, depending on the parameters provided. Requires a prior connection to Azure DevOps via Connect-AzDevOps.

    .PARAMETER Organization
    The name of the Azure DevOps organization whose general overview settings will be exported.

    .PARAMETER AccessToken
    The Bearer token used for authenticating API requests to Azure DevOps.

    .PARAMETER OutputPath
    The file path where the general overview settings will be saved as a JSON file. If not specified, the settings are not saved to a file. Mutually exclusive with -PassThru.

    .PARAMETER PassThru
    If specified, returns the general overview settings as a PowerShell object instead of saving to a file. Mutually exclusive with -OutputPath.

    .EXAMPLE
    Export-AdoOrganizationGeneralOverview -Organization "MyOrg" -AccessToken "abc123" -OutputPath "C:\Exports"
    Exports the general overview settings for "MyOrg" to "C:\Exports\OrganizationGeneralOverview.ado.json".

    .EXAMPLE
    Export-AdoOrganizationGeneralOverview -Organization "MyOrg" -AccessToken "abc123" -PassThru
    Retrieves and returns the general overview settings for "MyOrg" as a PowerShell object.

    .NOTES
    - Requires a prior call to Connect-AzDevOps to establish a connection.
    - The function depends on Read-AdoOrganizationGeneralOverview to retrieve settings.
    - The output JSON file is named "OrganizationGeneralOverview.ado.json" when using -OutputPath.

    .LINK
    https://docs.microsoft.com/en-us/rest/api/azure/devops/
#>

function Export-AdoOrganizationGeneralOverview {
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

    # Retrieve general overview settings
    try {
        $settings = Read-AdoOrganizationGeneralOverview -Organization $Organization -AccessToken $AccessToken
        if ($null -eq $settings) {
            throw "No Organization general overview settings returned from Read-AdoOrganizationGeneralOverview."
        }
    }
    catch {
        throw "Failed to get Organization general overview settings from Azure DevOps: $($_.Exception.Message)"
    }

    # Process settings into exportable format
    $settingsDetails = @()
    $settingsObject = [PSCustomObject]@{
        description = $settings.description
        timeZone    = $settings.timeZone
        geography   = $settings.geography
        region      = $settings.region
        owner       = $settings.owner
    }

    # Add metadata properties
    $settingsObject | Add-Member -MemberType NoteProperty -Name ObjectType -Value 'Azure.DevOps.Organization.GeneralOverview' -Force
    $settingsObject | Add-Member -MemberType NoteProperty -Name ObjectName -Value "$($script:connection.Organization).OrganizationGeneralOverview" -Force
    $settingsObject | Add-Member -MemberType NoteProperty -Name name -Value "OrganizationGeneralOverview" -Force

    # Create structured id object
    $id = @{
        originalId   = $null
        resourceName = "OrganizationGeneralOverview"
        organization = $script:connection.Organization
    } | ConvertTo-Json -Depth 100
    $settingsObject | Add-Member -MemberType NoteProperty -Name id -Value $id -Force

    $settingsDetails += $settingsObject

    # Output based on parameters
    if ($PassThru) {
        Write-Output $settingsDetails
    }
    else {
        $settingsDetails | ConvertTo-Json -Depth 100 | Out-File -FilePath "$OutputPath\OrganizationGeneralOverview.ado.json"
    }
}

Export-ModuleMember -Function Export-AdoOrganizationGeneralOverview