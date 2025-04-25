#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Retrieves the general billing settings of an Azure DevOps organization.

    .DESCRIPTION
    Queries the Azure DevOps Commerce API to retrieve general billing setup information such as billing status, 
    subscription ID, and account settings, and exports the results to an Excel file. 
    Optionally verifies if the subscription ID matches an expected value.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER OrganizationId
    The GUID of the Azure DevOps organization.

    .PARAMETER AccessToken
    The Bearer token (e.g., OAuth 2.0 access token from Microsoft Entra ID) for authenticating with the Azure DevOps API.

    .PARAMETER ExpectedSubscriptionId
    The expected Azure subscription ID to compare against the billing setup. Optional.

    .EXAMPLE
    .\OrganizationGeneralBillingSettings.ps1 -Organization "myOrg" -OrganizationId "a6c61e95-bc6a-4998-b599-5c1add3fd48b" -AccessToken "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ik..." -ExpectedSubscriptionId "6f1ae004-9078-4e65-8424-fe70a5aaaedc"

    .NOTES
    This script uses the Azure DevOps Commerce API:
    https://azdevopscommerce.dev.azure.com/{orgId}/_apis/AzComm/BillingSetup?api-version=7.1-preview.1
#>

param (
    [Parameter(Mandatory)]
    [System.String] $Organization,

    [Parameter(Mandatory)]
    [System.String] $OrganizationId,

    [Parameter(Mandatory)]
    [System.String] $AccessToken,

    [Parameter()]
    [System.String] $ExpectedSubscriptionId
)

# Source the external function to create authentication header
. ".\src\helper-functions\New-AdoAuthenticationHeader.ps1"

# Source the external function to export to Excel
. ".\src\helper-functions\Export-ToExcel.ps1"

# Configure headers for HTTP requests to the Azure DevOps API
[System.Collections.Hashtable] $headers = New-AdoAuthenticationHeader -AccessToken $AccessToken

# Initialize report array
[System.Object[]] $report = @()

# Fetch billing settings
try {
    # Construct API endpoint for billing settings
    [System.String] $billingUri = "https://azdevopscommerce.dev.azure.com/$OrganizationId/_apis/AzComm/BillingSetup?api-version=7.1-preview.1"
    $response = Invoke-RestMethod -Uri $billingUri -Headers $headers -Method Get
    Write-Debug "Raw API Response: $($response | ConvertTo-Json -Depth 3)"

    # Determine subscription match
    [System.String] $subscriptionMatch = if ($response.PSObject.Properties.Name -contains 'subscriptionId' -and $response.subscriptionId -and $ExpectedSubscriptionId) {
        if ($response.subscriptionId -eq $ExpectedSubscriptionId) {
            "Match"
        } else {
            "Mismatch (Expected: $ExpectedSubscriptionId)"
        }
    } elseif ($ExpectedSubscriptionId) {
        "No Subscription ID Found"
    } else {
        "Not Verified"
    }

    # Log billing settings
    Write-Host "Billing settings for organization [$Organization]: Subscription Status [$($response.subscriptionStatus)]" -ForegroundColor Cyan

    # Add result to report
    $report += [PSCustomObject]@{
        OrganizationName          = $response.currentOrganizationName
        SubscriptionStatus        = $response.subscriptionStatus
        SubscriptionId            = if ($response.PSObject.Properties.Name -contains 'subscriptionId') { $response.subscriptionId } else { "Not Configured" }
        IsEnterpriseBillingEnabled = $response.isEnterpriseBillingEnabled
        IsAssignmentBillingEnabled = $response.isAssignmentBillingEnabled
        SubscriptionMatch         = $subscriptionMatch
    }
}
catch {
    Write-Host "Error Details: $($_.Exception.Response.Content)" -ForegroundColor Red
    Write-Error "Failed to fetch billing settings: [$($_.Exception.Message)]"
    exit
}

# Exit if no billing settings found (should not occur, but included for consistency)
if ($report.Count -eq 0) {
    Write-Host "[No billing settings found.]" -ForegroundColor Yellow
    exit
}

# Call the export function
Export-ToExcel -Report $report -ExportFileName "BillingSettingsReport.xlsx" -WorksheetName "BillingSettings"