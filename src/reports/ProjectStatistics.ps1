#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Generates Azure DevOps project statistics with charts.

    .DESCRIPTION
    Collects project statistics, including pull requests (created and completed), commits, builds, and releases, 
    across all projects in the specified organization, and exports them to an Excel file with charts for PRs Created, 
    PRs Completed, and Builds.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER PersonalAccessToken
    The Personal Access Token (PAT) for authenticating with the Azure DevOps API.

    .PARAMETER PatTokenOwnerName
    The username associated with the PAT token, typically an email.

    .EXAMPLE
    .\ProjectStatistics.ps1 -Organization "myOrg" -PersonalAccessToken "myPAT" -PatTokenOwnerName "Ben John"
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
    [System.String] $projectsUri = "$baseUrl/_apis/projects?api-version=7.2-preview.4"
    $projectsResponse = Invoke-RestMethod -Uri $projectsUri -Headers $headers -Method Get
    [System.Object[]] $projects = $projectsResponse.value
    Write-Host "Found [$($projects.Count)] projects." -ForegroundColor Cyan
    if ($projects.Count -eq 0) {
        Write-Debug "No projects found for organization [$Organization]. Response: [$($projectsResponse | ConvertTo-Json -Depth 3)]"
        Write-Host "[No projects found.]" -ForegroundColor Yellow
        exit
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
    Write-Host "Processing: [$projectName]" -ForegroundColor Cyan

    # Initialize counters for statistics
    [System.Int32] $prCreated = 0
    [System.Int32] $prCompleted = 0
    [System.Int32] $commits = 0
    [System.Int32] $builds = 0
    [System.Int32] $releases = 0

    # Fetch all repositories for the project
    try {
        [System.String] $reposUri = "$baseUrl/$projectName/_apis/git/repositories?api-version=7.2-preview.1"
        $reposResponse = Invoke-RestMethod -Uri $reposUri -Headers $headers -Method Get
        [System.Object[]] $repositories = $reposResponse.value
        Write-Host "Found [$($repositories.Count)] repositories in [$projectName]." -ForegroundColor Cyan
        if ($repositories.Count -eq 0) {
            Write-Debug "No repositories found for project [$projectName]. Response: [$($reposResponse | ConvertTo-Json -Depth 3)]"
        }
    }
    # Catch errors and log, but continue processing the project
    catch {
        Write-Warning "Failed to fetch repositories for [$projectName]: [$($_.Exception.Message)]"
        # Continue processing the project even if repositories fail
    }

    # Process each repository if repositories were fetched
    if ($repositories) {
        foreach ($repository in $repositories) {
            [System.String] $repoId = $repository.id

            # Fetch pull requests for the repository
            try {
                [System.String] $prsUri = "$baseUrl/$projectName/_apis/git/repositories/$repoId/pullrequests?api-version=7.2-preview.1"
                $prsResponse = Invoke-RestMethod -Uri $prsUri -Headers $headers -Method Get
                $pullRequests = $prsResponse.value
                $prCreated += $pullRequests.Count
                $prCompleted += ($pullRequests | Where-Object { $_.status -eq "completed" }).Count
                Write-Debug "Repository [$($repository.name)] in [$projectName]: PRs Created=[$prCreated], PRs Completed=[$prCompleted]"
            }
            # Catch errors and log, but continue processing other repositories
            catch {
                Write-Warning "Failed to fetch pull requests for repository [$($repository.name)] in [$projectName]: [$($_.Exception.Message)]"
                continue
            }

            # Fetch commits (up to 1000) for the repository
            try {
                [System.String] $commitsUri = "$baseUrl/$projectName/_apis/git/repositories/$repoId/commits?api-version=7.2-preview.1&`$top=1000"
                $commitsResponse = Invoke-RestMethod -Uri $commitsUri -Headers $headers -Method Get
                $commits += $commitsResponse.count
                Write-Debug "Repository [$($repository.name)] in [$projectName]: Commits=[$commits]"
            }
            # Catch errors and log, but continue processing other repositories
            catch {
                Write-Warning "Failed to fetch commits for repository [$($repository.name)] in [$projectName]: [$($_.Exception.Message)]"
                continue
            }
        }
    }

    # Fetch build count for the project
    try {
        [System.String] $buildsUri = "$baseUrl/$projectName/_apis/build/builds?api-version=7.2-preview.7"
        $buildsResponse = Invoke-RestMethod -Uri $buildsUri -Headers $headers -Method Get
        $builds = $buildsResponse.count
        Write-Debug "Project [$projectName]: Builds=[$builds]"
    }
    # Catch errors and log, but continue processing the project
    catch {
        Write-Warning "Failed to fetch builds for [$projectName]: [$($_.Exception.Message)]"
        $builds = 0
    }

    # Fetch release count for the project
    try {
        [System.String] $releasesUri = "$baseUrl/$projectName/_apis/release/releases?api-version=7.2-preview.8"
        $releasesResponse = Invoke-RestMethod -Uri $releasesUri -Headers $headers -Method Get
        $releases = $releasesResponse.count
    }
    # Catch errors and log, but continue processing the project
    catch {
        # Only log warning for non-404 errors (404 is expected if no releases exist)
        if ($_.Exception.Response.StatusCode -ne 404) {
            Write-Warning "Failed to fetch releases for [$projectName]: [$($_.Exception.Message)]"
        }
        $releases = 0
    }

    # Add project statistics to report
    Write-Host "Statistics for [$projectName]: PRs Created=[$prCreated], PRs Completed=[$prCompleted], Commits=[$commits], Builds=[$builds], Releases=[$releases]" -ForegroundColor Cyan
    $report += [PSCustomObject]@{
        Project      = $projectName
        PRsCreated   = $prCreated
        PRsCompleted = $prCompleted
        Commits      = $commits
        Builds       = $builds
        Releases     = $releases
    }
}

# Proceed to export even if all statistics are 0
if ($report.Count -eq 0) {
    Write-Host "[No projects processed successfully. Check warnings for details.]" -ForegroundColor Yellow
    exit
}

# Call the export function
Export-ToExcel -Report $report -ExportFileName "ProjectStatisticsReport.xlsx" -WorksheetName "ProjectStats"