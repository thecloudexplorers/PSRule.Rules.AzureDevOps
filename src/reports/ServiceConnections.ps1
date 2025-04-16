#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Generates a report of all Azure DevOps service connections across projects.

    .DESCRIPTION
    Retrieves all service connections across all projects in the specified Azure DevOps organization, extracting details 
    such as connection name, type, service principal ID, creator, and creation date, and exports the data to an Excel file.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER PersonalAccessToken
    A valid Azure DevOps Personal Access Token (PAT) used for authentication.

    .PARAMETER PatTokenOwnerName
    The username associated with the PAT token, typically an email.

    .EXAMPLE
    .\ServiceConnections.ps1 -Organization "myOrg" -PersonalAccessToken "xxxxxxx" -PatTokenOwnerName "Ben John"

    .NOTES
    Requires the ImportExcel PowerShell module to be pre-installed.
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

# Define the base API URL
[System.String] $baseUrl = "https://dev.azure.com/$Organization"

# Initialize report array
[System.Object[]] $report = @()

# Fetch all projects in the organization
try {
    # Construct API endpoint for project listing
    [System.String] $projectsUrl = "$baseUrl/_apis/projects?api-version=7.2-preview.4"
    $projectsResponse = Invoke-RestMethod -Uri $projectsUrl -Headers $headers -Method Get
    [System.Object[]] $projects = $projectsResponse.value
    Write-Host "Found [$($projects.Count)] projects." -ForegroundColor Cyan
    if ($projects.Count -eq 0) {
        Write-Debug "No projects found for organization [$Organization]. Response: [$($projectsResponse | ConvertTo-Json -Depth 3)]"
    }
}
# Catch errors and exit to report project fetch issues
catch {
    Write-Error "Failed to fetch projects: [$($_.Exception.Message)]"
    exit
}

# Process each project
foreach ($project in $projects) {
    [System.String] $projectName = $project.name
    Write-Host "Processing project: [$projectName]" -ForegroundColor Cyan

    # Fetch service connections for the project
    try {
        [System.String] $scUrl = "$baseUrl/$projectName/_apis/serviceendpoint/endpoints?api-version=7.2-preview.4"
        $scResponse = Invoke-RestMethod -Uri $scUrl -Headers $headers -Method Get
        [System.Object[]] $serviceConnections = $scResponse.value
        Write-Host "Found [$($serviceConnections.Count)] service connections in [$projectName]." -ForegroundColor Cyan
        if ($serviceConnections.Count -eq 0) {
            Write-Debug "No service connections found for project [$projectName]. Response: [$($scResponse | ConvertTo-Json -Depth 3)]"
        }
    }
    # Catch errors and log without breaking to continue processing other projects
    catch {
        Write-Warning "Failed to fetch service connections for [$projectName]: [$($_.Exception.Message)]"
        continue
    }

    # Process each service connection
    foreach ($connection in $serviceConnections) {
        # Extract service principal ID
        [System.String] $spnId = if ($connection.authorization?.parameters?.serviceprincipalid) {
            $connection.authorization.parameters.serviceprincipalid
        } else {
            "N/A"
        }

        # Extract creator and creation date
        [System.String] $createdBy = if ($connection.createdBy?.displayName) {
            $connection.createdBy.displayName
        } else {
            "Unknown"
        }
        [System.String] $creationDate = if ($connection.creationDate) {
            (Get-Date $connection.creationDate).ToString("yyyy-MM-dd HH:mm:ss")
        } else {
            "N/A"
        }

        # Add service connection details to report
        $report += [PSCustomObject]@{
            Project            = $projectName
            ConnectionName     = $connection.name
            ConnectionType     = $connection.type
            ServicePrincipalId = $spnId
            CreatedBy          = $createdBy
            CreationDate       = $creationDate
        }
    }
}

# Exit if no service connections found
if ($report.Count -eq 0) {
    Write-Host "[No service connections found.]" -ForegroundColor Yellow
    exit 
}

# Call the export function
Export-ToExcel -Report $report -ExportFileName "ServiceConnectionsReport.xlsx" -WorksheetName "ServiceConnections"