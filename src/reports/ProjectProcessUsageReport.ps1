#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Generates a report of process usage by projects in Azure DevOps.

    .DESCRIPTION
    Fetches all projects in an Azure DevOps organization and reports the process type (e.g., Agile, Scrum) used by each project, 
    providing a summary of process usage and a detailed breakdown, exported to an Excel file.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER PersonalAccessToken
    The Personal Access Token (PAT) for authenticating with the Azure DevOps API.

    .PARAMETER PatTokenOwnerName
    The username associated with the PAT token, typically an email.

    .EXAMPLE
    .\ProjectProcessUsage.ps1 -Organization "myOrg" -PersonalAccessToken "myPAT" -PatTokenOwnerName "Ben John"
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

# Initialize detailed report array
[System.Object[]] $detailedReport = @()

# Fetch all projects in the organization
try {
    # Construct API endpoint for project listing
    [System.String] $projectsUri = "https://dev.azure.com/$Organization/_apis/projects?api-version=7.1-preview.4"
    $projectsResponse = Invoke-RestMethod -Uri $projectsUri -Headers $headers -Method Get
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

# Fetch process type for each project
Write-Host "`nFetching process type for each project..." -ForegroundColor Cyan
foreach ($project in $projects) {
    [System.String] $projectId = $project.id
    [System.String] $projectName = $project.name
    [System.String] $processUri = "https://dev.azure.com/$Organization/_apis/projects/$projectId`?api-version=7.1-preview.4&includeCapabilities=true"
    [System.String] $processName = "Unknown" # Default value

    # Fetch process details for the project
    try {
        $processResponse = Invoke-RestMethod -Uri $processUri -Headers $headers -Method Get
        if ($processResponse.PSObject.Properties.Name -contains "capabilities" -and 
            $processResponse.capabilities.PSObject.Properties.Name -contains "processTemplate") {
            $processName = if ($processResponse.capabilities.processTemplate.templateName) {
                $processResponse.capabilities.processTemplate.templateName
            } else {
                "Not Specified"
            }
        } else {
            Write-Warning "No process template data found for project [$projectName]."
            Write-Debug "Process response for [$projectName]: [$($processResponse | ConvertTo-Json -Depth 3)]"
        }
    }
    # Catch errors and log without breaking to continue processing other projects
    catch {
        Write-Warning "Failed to fetch process for project [$projectName]: [$($_.Exception.Message)]"
        continue
    }

    Write-Host "Project: [$projectName] => Process: [$processName]"

    # Add project process details to report
    $detailedReport += [PSCustomObject]@{
        ProjectName = $projectName
        Process     = $processName
    }
}

# Group projects by process type
$processGroups = $detailedReport | Group-Object -Property Process

# Generate summary report
$summary = $processGroups | 
    Select-Object @{Name = "Process Type"; Expression = { $_.Name }}, 
                  @{Name = "Number of Projects"; Expression = { $_.Count }}

# Display summary report
Write-Host "`n=== Process Usage Summary ===" -ForegroundColor Green
$summary | Format-Table -AutoSize

# Display detailed breakdown by process
Write-Host "`n=== Detailed Breakdown by Process ===" -ForegroundColor Green
foreach ($group in $processGroups | Sort-Object Name) {
    Write-Host "`nProjects using [$($group.Name)]:" -ForegroundColor Yellow
    $group.Group | ForEach-Object { Write-Host " - [$($_.ProjectName)]" }
}

# Call the export function
Export-ToExcel -Report $detailedReport -ExportFileName "ProjectProcessUsageReport.xlsx" -WorksheetName "Process Usage"