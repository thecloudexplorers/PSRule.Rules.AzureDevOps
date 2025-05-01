#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Retrieves the general overview settings of an Azure DevOps organization.

    .DESCRIPTION
    Queries the Azure DevOps organization overview endpoint to retrieve metadata including description, 
    timezone, geography, region, and organization owner, and exports the results to an Excel file.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER OrganizationId
    The GUID of the Azure DevOps organization.

    .PARAMETER AccessToken
    The Bearer token (e.g., OAuth 2.0 access token from Microsoft Entra ID) for authenticating with the Azure DevOps API.

    .EXAMPLE
    .\OrganizationGeneralOverview.ps1 -Organization "myOrg" -OrganizationId "a6c61e95-bc6a-4998-b599-5c1add3fd48b" -AccessToken "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ik..."

    .NOTES
    WARNING: This script uses an internal and undocumented API endpoint:
    https://dev.azure.com/{org}/_settings/organizationOverview?__rt=fps&__ver=2
    This endpoint is not part of the officially supported Azure DevOps REST API and may change or be removed without notice.
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

# Fetch organization overview
try {
    # Construct API endpoint for organization overview
    [System.String] $overviewUri = "https://dev.azure.com/$Organization/_settings/organizationOverview?__rt=fps&__ver=2"
    $response = Invoke-RestMethod -Uri $overviewUri -Headers $headers -Method Get
    Write-Debug "Raw API Response: $($response | ConvertTo-Json -Depth 5)"

    # Parse response
    $overviewData = $response.fps.dataProviders.data.'ms.vss-admin-web.organization-admin-overview-data-provider'
    $userInfo = $response.fps.dataProviders.data.'ms.vss-web.page-data'

    # Log the structure of overviewData and userInfo for debugging
    Write-Debug "Overview Data: $($overviewData | ConvertTo-Json -Depth 3)"
    Write-Debug "User Info: $($userInfo | ConvertTo-Json -Depth 3)"

    # Extract fields with fallback values
    [System.String] $description = if ([string]::IsNullOrWhiteSpace($overviewData.description)) { "Not Set" } else { $overviewData.description }
    [System.String] $timeZone = $overviewData.timeZone?.displayName ?? "Unknown"
    [System.String] $geography = $overviewData.geography?.displayName ?? $overviewData.geography ?? "Unknown"
    [System.String] $region = $overviewData.region?.displayName ?? $overviewData.region ?? "Unknown"
    [System.String] $owner = $userInfo.user?.displayName ?? $userInfo.owner?.displayName ?? "Unknown"

    Write-Host "Organization overview for [$Organization]:" -ForegroundColor Cyan
    Write-Host "Description   : [$description]" -ForegroundColor Cyan
    Write-Host "TimeZone      : [$timeZone]" -ForegroundColor Cyan
    Write-Host "Geography     : [$geography]" -ForegroundColor Cyan
    Write-Host "Region        : [$region]" -ForegroundColor Cyan
    Write-Host "Owner         : [$owner]" -ForegroundColor Cyan
    

    # Add result to report
    $report += [PSCustomObject]@{
        Organization    = $Organization
        OrganizationId  = $OrganizationId
        Description     = $description
        TimeZone        = $timeZone
        Geography       = $geography
        Region          = $region
        Owner           = $owner
    }
}
catch {
    Write-Host "Error Details: $($_.Exception.Response.Content)" -ForegroundColor Red
    Write-Error "Failed to fetch organization overview: [$($_.Exception.Message)]"
    exit
}

# Exit if no overview data found (should not occur, but included for consistency)
if ($report.Count -eq 0) {
    Write-Host "[No organization overview data found.]" -ForegroundColor Yellow
    exit
}

# Call the export function
Export-ToExcel -Report $report -ExportFileName "OrganizationOverviewReport.xlsx" -WorksheetName "OrganizationOverview"