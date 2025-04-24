#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Retrieves the default license type for new users in an Azure DevOps organization.

    .DESCRIPTION
    Queries the Azure DevOps billing API to determine the default license type assigned to new users 
    (e.g., Basic, Stakeholder) and exports the result to an Excel file.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER OrganizationId
    The GUID of the Azure DevOps organization.
    This function uses the internal Azure DevOps billing API:
    https://azdevopscommerce.dev.azure.com/{orgId}/_apis/AzComm/DefaultLicenseType

    .PARAMETER PersonalAccessToken
    The Personal Access Token (PAT) for authenticating with the Azure DevOps API.

    .PARAMETER PatTokenOwnerName
    The username associated with the PAT token, typically an email.

    .EXAMPLE
    .\DefaultLicenseType.ps1 -Organization "myOrg" -OrganizationId "20b34e00-7898-7763-950d-098764ad3d2c" -PersonalAccessToken "myPAT" -PatTokenOwnerName "Ben John"
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

# Fetch default license type
try {
    # Construct API endpoint for default license type
    [System.String] $licenseUri = "https://azdevopscommerce.dev.azure.com/$OrganizationId/_apis/AzComm/DefaultLicenseType?api-version=7.1-preview.1"
    $licenseResponse = Invoke-RestMethod -Uri $licenseUri -Headers $headers -Method Get
    Write-Debug "Raw API Response: $($licenseResponse | ConvertTo-Json -Depth 3)"

    # Handle both numeric and string license types
    [System.String] $licenseValue = $licenseResponse.defaultLicenseType
    [System.Int32] $licenseId = 0
    [System.String] $licenseName = ""

    switch ($licenseValue) {
        { $_ -eq 2 -or $_ -eq "basic" } {
            $licenseId = 2
            $licenseName = "Basic"
        }
        { $_ -eq 5 -or $_ -eq "stakeholder" } {
            $licenseId = 5
            $licenseName = "Stakeholder"
        }
        default {
            $licenseId = -1
            $licenseName = "Unknown ($licenseValue)"
            Write-Warning "Unexpected license type value: [$licenseValue]"
        }
    }

    Write-Host "Default license type for organization [$Organization]: [$licenseName]" -ForegroundColor Cyan

    # Add result to report
    $report += [PSCustomObject]@{
        Organization    = $Organization
        LicenseTypeId   = $licenseId
        LicenseTypeName = $licenseName
    }
}
catch {
    Write-Host "Error Details: $($_.Exception.Response.Content)" -ForegroundColor Red
    Write-Error "Failed to fetch default license type: [$($_.Exception.Message)]"
    exit
}

# Exit if no license type found (should not occur, but included for consistency)
if ($report.Count -eq 0) {
    Write-Host "[No default license type found.]" -ForegroundColor Yellow
    exit
}

# Call the export function
Export-ToExcel -Report $report -ExportFileName "DefaultLicenseTypeReport.xlsx" -WorksheetName "DefaultLicenseType"