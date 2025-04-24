#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Lists Azure DevOps organizations connected to an Entra ID tenant.

    .DESCRIPTION
    Queries the Azure DevOps EnterpriseCatalog API to retrieve a list of organizations connected to the 
    specified Entra ID tenant and exports the results to an Excel file.

    .PARAMETER TenantId
    The Entra ID (Azure AD) tenant ID used to scope the query.
    API: https://aexprodweu1.vsaex.visualstudio.com/_apis/EnterpriseCatalog/Organizations?tenantId={tenantId}

    .PARAMETER AccessToken
    A valid Azure DevOps Bearer token

    .PARAMETER PatTokenOwnerName
    The username associated with the PAT token, typically an email.

    .EXAMPLE
    .\TenantOrganizationConnections.ps1 -TenantId "a74be31f-7904-4c43-8ef5-c82967c8e559" -AccessToken "bearer" -PatTokenOwnerName "Ben John"
#>

param (
    [Parameter(Mandatory)]
    [System.String] $TenantId,

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

# Fetch organizations connected to the tenant
try {
    # Construct API endpoint for organization connections
    [System.String] $orgUri = "https://aexprodweu1.vsaex.visualstudio.com/_apis/EnterpriseCatalog/Organizations?tenantId=$TenantId"
    $headers['Accept'] = "text/csv"

    # Download CSV to temp file
    $tempFile = New-TemporaryFile
    Invoke-WebRequest -Uri $orgUri -Headers $headers -OutFile $tempFile -UseBasicParsing

    # Read and normalize CSV
    $data = Import-Csv -Path $tempFile | ForEach-Object {
        $cleaned = @{}
        $_.PSObject.Properties | ForEach-Object {
            $key = $_.Name.Trim()
            $cleaned[$key] = $_.Value
        }

        [PSCustomObject]@{
            OrganizationId   = $cleaned['Organization Id']
            OrganizationName = $cleaned['Organization Name']
            Url              = $cleaned['Url']
            Owner            = $cleaned['Owner']
            ExceptionType    = $cleaned['Exception Type']
            ErrorMessage     = $cleaned['Error Message']
        }
    }

    Write-Host "Found [$($data.Count)] organizations connected to tenant [$TenantId]." -ForegroundColor Cyan

    # Add data to report
    $report = $data

    # Clean up temp file
    Remove-Item -Path $tempFile -Force
}
catch {
    Write-Error "Failed to fetch tenant organization connections: [$($_.Exception.Message)]"
    if (Test-Path -Path $tempFile) {
        Remove-Item -Path $tempFile -Force
    }
    exit
}

# Exit if no organizations found
if ($report.Count -eq 0) {
    Write-Host "[No organizations found for tenant.]" -ForegroundColor Yellow
    exit
}

# Call the export function
Export-ToExcel -Report $report -ExportFileName "TenantOrganizationConnectionsReport.xlsx" -WorksheetName "TenantOrganizations"