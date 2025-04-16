#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Retrieves and exports a list of installed Azure DevOps extensions.

    .DESCRIPTION
    Queries the Azure DevOps REST API to fetch installed extensions for the specified organization and exports their details, 
    including extension name, publisher, and version, to an Excel file.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER PersonalAccessToken
    The Personal Access Token (PAT) for authenticating with the Azure DevOps API.

    .PARAMETER PatTokenOwnerName
    The username associated with the PAT token, typically an email.

    .EXAMPLE
    .\InstalledExtensions.ps1 -Organization "myOrg" -PersonalAccessToken "myPAT" -PatTokenOwnerName "Ben John"
#>

param (
    [Parameter(Mandatory)]
    [System.String] $Organization,
    [Parameter(Mandatory)]
    [System.String] $PersonalAccessToken,
    [Parameter(Mandatory)]
    [System.String] $PatTokenOwnerName
)

# Source the external function to create authentication header
. ".\src\helper-functions\New-AdoAuthenticationHeader.ps1"

# Source the external function to export to Excel
. ".\src\helper-functions\Export-ToExcel.ps1"

# Configure headers for HTTP requests to the Azure DevOps API
[System.Collections.Hashtable] $headers = New-AdoAuthenticationHeader -PatToken $PersonalAccessToken -PatTokenOwnerName $PatTokenOwnerName

# Initialize report array
[System.Object[]] $report = @()

# Fetch all installed extensions
try {
    # Construct API endpoint for installed extensions
    [System.String] $extensionsUri = "https://extmgmt.dev.azure.com/$Organization/_apis/extensionmanagement/installedextensions?api-version=7.2-preview.2"
    $extensionsResponse = Invoke-RestMethod -Uri $extensionsUri -Headers $headers -Method Get
    [System.Object[]] $installedExtensions = $extensionsResponse.value
    Write-Host "Found [$($installedExtensions.Count)] installed extensions." -ForegroundColor Cyan
    if ($installedExtensions.Count -eq 0) {
        Write-Debug "No installed extensions found for organization [$Organization]. Response: [$($extensionsResponse | ConvertTo-Json -Depth 3)]"
    }
}
# Catch errors and exit to report extensions fetch issues
catch {
    Write-Error "Failed to fetch installed extensions: [$($_.Exception.Message)]"
    exit
}

# Process each extension
foreach ($extension in $installedExtensions) {
    # Add extension details to report
    $report += [PSCustomObject]@{
        ExtensionName = $extension.extensionName
        Publisher     = $extension.publisherName
        Version       = $extension.version
    }
}

# Exit if no extensions found
if ($report.Count -eq 0) {
    Write-Host "[No extensions found.]" -ForegroundColor Yellow
    exit 
}

# Call the export function
Export-ToExcel -Report $report -ExportFileName "InstalledExtensions.xlsx" -WorksheetName "Extensions"