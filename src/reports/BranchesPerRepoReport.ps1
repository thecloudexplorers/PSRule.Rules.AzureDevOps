#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Reports on branches per repository in Azure DevOps, identifying stale branches.

    .DESCRIPTION
    Collects branch details including last commit date, stale status, and last commit ID, then exports the results to an Excel file.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER PersonalAccessToken
    The Personal Access Token (PAT) for authenticating with Azure DevOps API.

    .PARAMETER PatTokenOwnerName
    The username associated with the PAT token, typically an email.

    .PARAMETER StaleThresholdDays
    Number of days after which a branch is considered stale.

    .EXAMPLE
    .\BranchesPerRepoReport.ps1 -Organization "myOrg" -PersonalAccessToken "myPAT" -PatTokenOwnerName "Ben John" -StaleThresholdDays 90
#>

param (
    [Parameter(Mandatory)]
    [System.String] $Organization,
    [Parameter(Mandatory)]
    [System.String] $PersonalAccessToken,
    [Parameter(Mandatory)]
    [System.String] $PatTokenOwnerName,
    [Parameter(Mandatory)]
    [System.Int32] $StaleThresholdDays
)

# Source the external function to create authentication header
. ".\src\helper-functions\New-AdoAuthenticationHeader.ps1"

# Source the external function to export to Excel
. ".\src\helper-functions\Export-ToExcel.ps1"

# Configure headers for HTTP requests to the Azure DevOps API
[System.Collections.Hashtable] $headers = New-AdoAuthenticationHeader -PatToken $PersonalAccessToken -PatTokenOwnerName $PatTokenOwnerName

# Validate PAT and API access
try {
    # Test API access with a simple call
    [System.String] $testUri = "https://dev.azure.com/$Organization/_apis/projects?api-version=7.1-preview.4&$top=1"
    $testResponse = Invoke-RestMethod -Uri $testUri -Headers $headers -Method Get
    Write-Host "PAT validation successful for organization [$Organization]." -ForegroundColor Cyan
} catch {
    Write-Error "PAT validation failed: [$($_.Exception.Message)]. Ensure PAT has 'Code (Read)' scope."
    exit
}

# Initialize report array
[System.Object[]] $report = @()

# Fetch all projects in the organization
try {
    # Construct API endpoint for project listing
    [System.String] $projectsUri = "https://dev.azure.com/$Organization/_apis/projects?api-version=7.1-preview.4"
    $projectsResponse = Invoke-RestMethod -Uri $projectsUri -Headers $headers -Method Get
    # Extract project list
    $projects = $projectsResponse.value
    Write-Host "Found [$($projects.Count)] projects." -ForegroundColor Cyan
} catch {
    Write-Error "Failed to fetch projects: [$($_.Exception.Message)]"
    exit
}

# Process each project
foreach ($project in $projects) {
    # Encode project name for API compatibility
    [System.String] $projectName = [uri]::EscapeDataString($project.name)
    Write-Host "Processing project: [$($project.name)]" -ForegroundColor Cyan

    # Fetch all Git repositories in the project
    try {
        # Construct API endpoint for repository listing
        [System.String] $reposUri = "https://dev.azure.com/${Organization}/${projectName}/_apis/git/repositories?api-version=7.1-preview.1"
        $reposResponse = Invoke-RestMethod -Uri $reposUri -Headers $headers -Method Get
        [System.Object[]] $repositories = $reposResponse.value
        Write-Host "Found [$($repositories.Count)] repositories in [$($project.name)]." -ForegroundColor Cyan
    }
    # Catch errors and log without breaking to continue processing other projects
    catch {
        Write-Warning "Failed to fetch repositories for [$($project.name)]: [$($_.Exception.Message)]"
        continue
    }

    # Process each repository
    foreach ($repository in $repositories) {
        [System.String] $repositoryName = $repository.name
        [System.String] $repositoryId = $repository.id
        Write-Host "Processing repository: [$repositoryName]" -ForegroundColor Cyan

        # Fetch all branch references
        try {
            # Construct API endpoint for branch listing
            [System.String] $branchesUri = "https://dev.azure.com/${Organization}/${projectName}/_apis/git/repositories/${repositoryId}/refs?api-version=7.1-preview.1"
            $branchesResponse = Invoke-RestMethod -Uri $branchesUri -Headers $headers -Method Get
            Write-Debug "Raw refs response for [$repositoryName]: [$($branchesResponse | ConvertTo-Json -Depth 5)]"
            # Filter for branches only
            [System.Object[]] $branches = $branchesResponse.value | Where-Object { $_.name -like "refs/heads/*" }
            Write-Host "Found [$($branches.Count)] branches in [$repositoryName]." -ForegroundColor Cyan
            if ($branches.Count -eq 0) {
                Write-Debug "Filtered branches response for [$repositoryName] (refs/heads/*): [$($branchesResponse.value | ConvertTo-Json -Depth 5)]"
            }
        }
        # Catch errors and log without breaking to continue processing other repositories
        catch {
            Write-Warning "Failed to fetch branches for [$repositoryName] in [$($project.name)]: [$($_.Exception.Message)]"
            continue
        }

        # Process each branch
        foreach ($branch in $branches) {
            # Extract branch name
            [System.String] $branchName = $branch.name -replace "refs/heads/", ""
            [System.String] $lastCommitId = $branch.objectId
            [System.String] $lastCommitDate = "Unknown"
            [System.String] $isStale = "Unknown"

            # Validate commit ID
            if (-not $lastCommitId) {
                Write-Warning "No commit ID found for branch [$branchName] in [$repositoryName]."
                Write-Debug "Branch [$branchName] object: [$($branch | ConvertTo-Json -Depth 3)]"
                $lastCommitId = "None"
            } else {
                # Fetch commit details
                try {
                    # Construct API endpoint for commit details
                    [System.String] $commitUri = "https://dev.azure.com/${Organization}/${projectName}/_apis/git/repositories/${repositoryId}/commits/${lastCommitId}?api-version=7.1-preview.1"
                    $commitResponse = Invoke-RestMethod -Uri $commitUri -Headers $headers -Method Get
                    Write-Debug "Commit response for [$branchName] in [$repositoryName]: [$($commitResponse | ConvertTo-Json -Depth 5)]"
                    
                    if ($commitResponse.committer -and $commitResponse.committer.date) {
                        # Calculate stale status based on commit date
                        [System.DateTime] $lastCommitDateObj = [datetime] $commitResponse.committer.date
                        $lastCommitDate = $lastCommitDateObj.ToString("yyyy-MM-dd")
                        [System.Int32] $daysSinceLastCommit = ((Get-Date) - $lastCommitDateObj).Days
                        $isStale = if ($daysSinceLastCommit -ge $StaleThresholdDays) { "Yes" } else { "No" }
                    } else {
                        Write-Warning "No valid committer date for branch [$branchName] in [$repositoryName] (Commit ID: [$lastCommitId])."
                        Write-Debug "Invalid or missing committer date in commit response for [$branchName]: [$($commitResponse | ConvertTo-Json -Depth 3)]"
                    }
                }
                # Catch errors and log without breaking to continue processing branches
                catch {
                    Write-Warning "Failed to fetch commit details for branch [$branchName] in [$repositoryName]: [$($_.Exception.Message)]"
                    Write-Debug "Commit API error details: [$($_.Exception | ConvertTo-Json -Depth 3)]"
                }
            }

            # Add branch data to report
            $report += [PSCustomObject]@{
                ProjectName       = $project.name
                RepositoryName    = $repositoryName
                BranchName        = $branchName
                LastCommitDate    = $lastCommitDate
                Stale             = $isStale
                LastCommitId      = $lastCommitId
            }
        }
    }
}

# Exit if no data collected
if ($report.Count -eq 0) {
    Write-Host "[No repositories or branches found.]" -ForegroundColor Yellow
    exit
}

# Call the export function
Export-ToExcel -Report $report -ExportFileName "BranchesPerRepoReport.xlsx" -WorksheetName "Branches"