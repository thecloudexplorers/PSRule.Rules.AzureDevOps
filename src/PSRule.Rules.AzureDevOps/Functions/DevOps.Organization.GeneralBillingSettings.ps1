<#
    .SYNOPSIS
    Retrieves Azure DevOps organization-level general billing settings.

    .DESCRIPTION
    Queries the Azure DevOps Commerce API to retrieve billing setup information such as billing status and subscription ID.

    .PARAMETER OrganizationId
    The GUID of the Azure DevOps organization (e.g., 'a6c61e95-bc6a-4998-b599-5c1add3fd48b').

    .PARAMETER AccessToken
    A valid Azure DevOps Bearer token with permission to query billing details.

    .PARAMETER ExpectedSubscriptionId
    (Optional) The expected Azure subscription ID to compare against the billing setup.

    .EXAMPLE
    Read-AdoOrganizationGeneralBillingSettings -OrganizationId "a6c61e95-bc6a-4998-b599-5c1add3fd48b" -AccessToken "abc123"
#>
function Read-AdoOrganizationGeneralBillingSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OrganizationId,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken,

        [Parameter()]
        [string]$ExpectedSubscriptionId
    )

    # Validate OrganizationId format (should be a GUID)
    if (-not ($OrganizationId -match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')) {
        Write-Error "OrganizationId '$OrganizationId' is not a valid GUID."
        return
    }

    $uri = "https://azdevopscommerce.dev.azure.com/$OrganizationId/_apis/AzComm/BillingSetup?api-version=7.1-preview.1"
    $headers = @{
        Authorization = $AccessToken
        Accept        = "application/json"
    }

    try {
        $rawResponse = Invoke-WebRequest -Uri $uri -Method Get -Headers $headers -UseBasicParsing
        if ($rawResponse.Content -match '<html' -or $rawResponse.RawContent -match 'Sign In') {
            throw "Access denied or token expired. Please verify your Bearer token is still valid."
        }

        $response = $rawResponse.Content | ConvertFrom-Json
        $settings = [PSCustomObject]@{
            organizationName           = $response.currentOrganizationName
            subscriptionStatus         = $response.subscriptionStatus
            subscriptionId             = if ($response.PSObject.Properties.Name -contains 'subscriptionId' -and $response.subscriptionId) { $response.subscriptionId } else { $null }
            isEnterpriseBillingEnabled = $response.isEnterpriseBillingEnabled
            isAssignmentBillingEnabled = $response.isAssignmentBillingEnabled
            updatedDateTime            = $response.updatedDateTime
            updatedBy                  = $response.updatedBy
            allowedBillingOperations   = $response.allowedBillingOperations
            accountName                = $response.accountName
            resourceGroupName          = $response.resourceGroupName
        }

        Write-Host ""
        Write-Host "===== Azure DevOps Billing Configuration Assessment ====="
        Write-Host ""

        Write-Host "Organization Name     : $($response.currentOrganizationName)"
        Write-Host "Subscription Status   : $($response.subscriptionStatus)"
        Write-Host "Enterprise Billing    : $($response.isEnterpriseBillingEnabled)"
        Write-Host "Assignment Billing    : $($response.isAssignmentBillingEnabled)"

        if ($settings.subscriptionId) {
            Write-Host "Subscription ID       : $($settings.subscriptionId)"
            if ($ExpectedSubscriptionId -and $settings.subscriptionId -ne $ExpectedSubscriptionId) {
                Write-Host "Subscription ID match : Mismatch. Expected: [$ExpectedSubscriptionId]"
            }
            Write-Host "Billing is configured."
        }
        else {
            Write-Host "Billing is not currently configured for this organization."
        }
        Write-Host "Assessment complete."

        return $settings
    }
    catch {
        Write-Error "Failed to retrieve billing settings: $_"
    }
}

Export-ModuleMember -Function Read-AdoOrganizationGeneralBillingSettings

<#
    .SYNOPSIS
    Exports Azure DevOps organization general billing settings to a JSON file or returns them as an object.

    .DESCRIPTION
    Retrieves billing settings for an Azure DevOps organization and either saves them to a JSON file or returns them as an object.

    .PARAMETER OrganizationId
    The GUID of the Azure DevOps organization (e.g., 'a6c61e95-bc6a-4998-b599-5c1add3fd48b').

    .PARAMETER Organization
    The name of the Azure DevOps organization (e.g., 'myOrg').

    .PARAMETER AccessToken
    The Bearer token for authenticating API requests to Azure DevOps.

    .PARAMETER ExpectedSubscriptionId
    (Optional) The expected Azure subscription ID to compare against the billing setup.

    .PARAMETER OutputPath
    The file path where the billing settings will be saved as a JSON file. Mutually exclusive with -PassThru.

    .PARAMETER PassThru
    If specified, returns the billing settings as a PowerShell object instead of saving to a file. Mutually exclusive with -OutputPath.

    .EXAMPLE
    Export-AdoOrganizationGeneralBillingSettings -OrganizationId "a6c61e95-bc6a-4998-b599-5c1add3fd48b" -Organization "myOrg" -AccessToken "abc123" -OutputPath "C:\Exports"
#>
function Export-AdoOrganizationGeneralBillingSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OrganizationId,

        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken,

        [Parameter()]
        [string]$ExpectedSubscriptionId,

        [Parameter(ParameterSetName = 'JsonFile')]
        [string]$OutputPath,

        [Parameter(ParameterSetName = 'PassThru')]
        [switch]$PassThru
    )

    $settings = Read-AdoOrganizationGeneralBillingSettings -OrganizationId $OrganizationId -AccessToken $AccessToken -ExpectedSubscriptionId $ExpectedSubscriptionId
    if ($null -eq $settings) {
        Write-Error "No billing settings returned from Read-AdoOrganizationGeneralBillingSettings."
        return
    }

    $settingsObject = [PSCustomObject]@{
        organizationName           = $settings.organizationName
        subscriptionStatus         = $settings.subscriptionStatus
        subscriptionId             = $settings.subscriptionId
        isEnterpriseBillingEnabled = $settings.isEnterpriseBillingEnabled
        isAssignmentBillingEnabled = $settings.isAssignmentBillingEnabled
        updatedDateTime            = $settings.updatedDateTime
        updatedBy                  = $settings.updatedBy
        allowedBillingOperations   = $settings.allowedBillingOperations
        accountName                = $settings.accountName
        resourceGroupName          = $settings.resourceGroupName
        ObjectType                 = 'Azure.DevOps.Organization.GeneralBillingSettings'
        ObjectName                 = "$Organization.OrganizationGeneralBillingSettings"
        name                       = "OrganizationGeneralBillingSettings"
        id                         = (@{ originalId = $null; resourceName = "OrganizationGeneralBillingSettings"; organization = $Organization } | ConvertTo-Json -Depth 100)
    }

    if ($PassThru) {
        Write-Output @($settingsObject)
    }
    else {
        @($settingsObject) | ConvertTo-Json -Depth 100 | Out-File -FilePath "$OutputPath\OrganizationGeneralBillingSettings.ado.json"
        Write-Host "Billing settings exported to $OutputPath\OrganizationGeneralBillingSettings.ado.json" -ForegroundColor Green
    }
}

Export-ModuleMember -Function Export-AdoOrganizationGeneralBillingSettings