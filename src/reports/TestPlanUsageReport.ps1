#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Reports on Azure DevOps test plan usage across projects.

    .DESCRIPTION
    Collects details on test plan usage by identifying which projects in the specified Azure DevOps organization have 
    test plans enabled and how many actual test plans exist, then exports the results to an Excel file.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER PersonalAccessToken
    The Personal Access Token (PAT) for authenticating with the Azure DevOps API.

    .PARAMETER PatTokenOwnerName
    The username associated with the PAT token, typically an email.

    .EXAMPLE
    .\TestPlanUsage.ps1 -Organization "myOrg" -PersonalAccessToken "myPAT" -PatTokenOwnerName "Ben John"
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

# Fetch all projects in the organization
try {
    # Construct API endpoint for project listing with capabilities
    [System.String] $projectsUri = "https://dev.azure.com/$Organization/_apis/projects?api-version=7.1-preview.4&includeCapabilities=true"
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

# Process each project
foreach ($project in $projects) {
    [System.String] $projectId = $project.id
    [System.String] $projectName = $project.name
    Write-Host "Processing project: [$projectName]" -ForegroundColor Cyan

    # Check if test plans are enabled
    [System.String] $testPlansEnabled = "No"
    if ($project.capabilities -and $project.capabilities.PSObject.Properties.Name -contains "testPlans") {
        $testPlansEnabled = "Yes"
    }

    # Fetch actual test plans
    [System.Int32] $testPlanCount = 0
    try {
        # Construct API endpoint for test plans
        [System.String] $testPlansUri = "https://dev.azure.com/$Organization/$projectId/_apis/testplan/plans?api-version=7.1-preview.1"
        $testPlansResponse = Invoke-RestMethod -Uri $testPlansUri -Headers $headers -Method Get
        $testPlans = $testPlansResponse.value
        $testPlanCount = $testPlans.Count
        Write-Host "Found [$testPlanCount] test plans in [$projectName]." -ForegroundColor Cyan
        if ($testPlanCount -eq 0) {
            Write-Debug "No test plans found for project [$projectName]. Response: [$($testPlansResponse | ConvertTo-Json -Depth 3)]"
        }
    }
    # Catch errors and log without breaking to continue processing other projects
    catch {
        if ($_.Exception.Response.StatusCode -eq 403) {
            Write-Warning "Permission denied fetching test plans for [$projectName]. Test plans may exist but are inaccessible."
        } else {
            Write-Warning "Failed to fetch test plans for [$projectName]: [$($_.Exception.Message)]"
        }
    }

    # Add project test plan details to report
    $report += [PSCustomObject]@{
        ProjectName      = $projectName
        TestPlansEnabled = $testPlansEnabled
        TestPlanCount    = $testPlanCount
    }
}

# Exit if no projects found
if ($report.Count -eq 0) {
    Write-Host "[No projects found.]" -ForegroundColor Yellow
    exit
}

# Call the export function
Export-ToExcel -Report $report -ExportFileName "TestPlanUsageReport.xlsx" -WorksheetName "TestPlanUsage"