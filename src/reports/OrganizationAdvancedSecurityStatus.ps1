#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Determines whether Advanced Security is enabled for an Azure DevOps organization.

    .DESCRIPTION
    Queries the Azure DevOps Advanced Security API to detect whether Advanced Security is enabled for the 
    organization and exports the results to an Excel file. Reports billing date, billable status, 
    unique committer count, and billed users if enabled and usage data is available.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER OrganizationId
    The GUID of the Azure DevOps organization.

    .PARAMETER AccessToken
    The Bearer token (e.g., OAuth 2.0 access token from Microsoft Entra ID) for authenticating with the Azure DevOps API.

    .EXAMPLE
    .\OrganizationAdvancedSecurityStatus.ps1 -Organization "myOrg" -OrganizationId "a6c61e95-bc6a-4998-b599-5c1add3fd48b" -AccessToken "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ik..."

    .NOTES
    This script uses the Azure DevOps Advanced Security API:
    https://advsec.dev.azure.com/{org}/_apis/Management/MeterUsage/Last?api-version=7.1-preview.1
#>

param (
    [Parameter(Mandatory)]
    [System.String] $Organization,

    [Parameter(Mandatory)]
    [System.String] $OrganizationId,

    [Parameter(Mandatory)]
    [System.String] $AccessToken
)

# Source the external function to create authentication header
. ".\src\helper-functions\New-AdoAuthenticationHeader.ps1"

# Source the external function to export to Excel
. ".\src\helper-functions\Export-ToExcel.ps1"

# Configure headers for HTTP requests to the Azure DevOps API
[System.Collections.Hashtable] $headers = New-AdoAuthenticationHeader -AccessToken $AccessToken

# Initialize report array
[System.Object[]] $report = @()

# Fetch Advanced Security status
try {
    # Construct API endpoint for Advanced Security status
    [System.String] $advSecUri = "https://advsec.dev.azure.com/$Organization/_apis/Management/MeterUsage/Last?api-version=7.1-preview.1"
    $response = Invoke-RestMethod -Uri $advSecUri -Headers $headers -Method Get
    Write-Debug "Raw API Response: $($response | ConvertTo-Json -Depth 3)"

    # Process response
    [System.String] $status = if ($response.isAdvSecEnabled -eq $true) {
        "Enabled"
    } else {
        "Not Enabled"
    }
    [System.String] $billingDate = $response.billingDate ?? "N/A"
    [System.String] $isBillable = $response.isAdvSecBillable ?? "N/A"
    [System.Int32] $committerCount = $response.uniqueCommitterCount ?? 0
    [System.String] $billedUsers = if ($response.billedUsers) {
        ($response.billedUsers | ForEach-Object { $_.userIdentity.displayName }) -join "; "
    } else {
        "None"
    }

    Write-Host "Advanced Security status for organization [$Organization]: [$status]" -ForegroundColor Cyan

    # Add result to report
    $report += [PSCustomObject]@{
        Organization              = $Organization
        OrganizationId            = $OrganizationId
        IsAdvancedSecurityEnabled = $status
        BillingDate               = $billingDate
        IsBillable                = $isBillable
        UniqueCommitterCount      = $committerCount
        BilledUsers               = $billedUsers
    }
}
catch {
    $message = $_.ErrorDetails.Message

    [System.String] $status = "Unknown"
    if ($message -match 'AdvSecNotEnabledForOrgException') {
        $status = "Not Enabled"
        Write-Host "Advanced Security status for organization [$Organization]: [Not Enabled]" -ForegroundColor Cyan
    } elseif ($message -match 'MeterUsageNotFoundException') {
        $status = "Enabled (No Usage Data)"
        Write-Host "Advanced Security status for organization [$Organization]: [Enabled but usage data not available]" -ForegroundColor Cyan
    } else {
        Write-Host "Error Details: $($_.Exception.Response.Content)" -ForegroundColor Red
        Write-Error "Failed to fetch Advanced Security status: [$($_.Exception.Message)]"
        exit
    }

    # Add result to report for non-fatal errors
    $report += [PSCustomObject]@{
        Organization              = $Organization
        OrganizationId            = $OrganizationId
        IsAdvancedSecurityEnabled = $status
        BillingDate               = "N/A"
        IsBillable                = "N/A"
        UniqueCommitterCount      = 0
        BilledUsers               = "None"
    }
}

# Exit if no status found (should not occur, but included for consistency)
if ($report.Count -eq 0) {
    Write-Host "[No Advanced Security status found.]" -ForegroundColor Yellow
    exit
}

# Call the export function
Export-ToExcel -Report $report -ExportFileName "AdvancedSecurityStatusReport.xlsx" -WorksheetName "AdvancedSecurity"