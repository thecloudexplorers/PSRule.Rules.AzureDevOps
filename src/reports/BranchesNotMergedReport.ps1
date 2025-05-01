#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Generates a report on branches per repository in Azure DevOps, identifying branches not merged into the main or master branch.

    .DESCRIPTION
    This script retrieves all projects, their repositories, and branches using the Azure DevOps REST API.
    For each branch, it checks if the latest commit is in the main (or master) branch's history to determine
    merge status. The results are exported to an Excel file, showing which branches contain unmerged changes.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER PersonalAccessToken
    The Personal Access Token (PAT) used to authenticate API requests. Must have "Code (Read)" scope.

    .PARAMETER PatTokenOwnerName
    The username associated with the PAT token, typically an email.

    .EXAMPLE
    .\BranchesNotMergedReport.ps1 -Organization "myOrg" -PersonalAccessToken "myPAT" -PatTokenOwnerName "Ben John"
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
        $repositories = $reposResponse.value
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
            # Filter for branches only
            [System.Object[]] $branches = $branchesResponse.value | Where-Object { $_.name -like "refs/heads/*" }
            Write-Host "Found [$($branches.Count)] branches in [$repositoryName]." -ForegroundColor Cyan
            # Log debug info if no branches found
            if ($branches.Count -eq 0) {
                Write-Debug "Branches response for [$repositoryName]: [$($branchesResponse | ConvertTo-Json -Depth 5)]"
            }
        }
        # Catch errors and log without breaking to continue processing other repositories
        catch {
            Write-Warning "Failed to fetch branches for [$repositoryName] in [$($project.name)]: [$($_.Exception.Message)]"
            continue
        }

        # Identify main branch (main or master)
        $mainBranch = $branches | Where-Object { $_.name -eq "refs/heads/main" }
        [System.String] $mainBranchName = "main"
        if (-not $mainBranch) {
            $mainBranch = $branches | Where-Object { $_.name -eq "refs/heads/master" }
            $mainBranchName = "master"
        }
        if (-not $mainBranch) {
            Write-Warning "No main or master branch found in [$repositoryName]. Skipping merge checks."
            continue
        }
        [System.String] $mainCommitId = $mainBranch.commit.commitId

        # Process each branch for merge status
        foreach ($branch in $branches) {
            # Extract branch name
            [System.String] $branchName = $branch.name -replace "refs/heads/", ""
            [System.String] $mergeStatus = "Unknown"
            # Handle main/master branch
            if ($branchName -eq $mainBranchName) {
                $mergeStatus = "Main Branch"
            } else {
                # Get branch commit ID
                [System.String] $branchCommitId = $branch.commit.commitId
                if (-not $branchCommitId) {
                    Write-Warning "No commit ID found for branch [$branchName] in [$repositoryName]."
                    $mergeStatus = "No Commits"
                } else {
                    # Check merge status
                    try {
                        # Construct API endpoint for commit comparison
                        [System.String] $commitUri = "https://dev.azure.com/${Organization}/${projectName}/_apis/git/repositories/${repositoryId}/commits?searchCriteria.itemVersion.version=$branchName&searchCriteria.compareVersion.version=$mainBranchName&api-version=7.1-preview.1"
                        $commitResponse = Invoke-RestMethod -Uri $commitUri -Headers $headers -Method Get
                        # Check if branch commit is in main's history
                        $isMerged = $commitResponse.value | Where-Object { $_.commitId -eq $branchCommitId }
                        $mergeStatus = $isMerged ? "Merged" : "Not Merged"
                        # Log debug if no commits returned
                        if (-not $commitResponse.value) {
                            Write-Debug "No commits returned for [$branchName] vs [$mainBranchName] in [$repositoryName]."
                        }
                    }
                    # Catch errors and log without breaking to continue processing branches
                    catch {
                        Write-Warning "Failed to check merge status for branch [$branchName] in [$repositoryName]: [$($_.Exception.Message)]"
                    }
                }
            }

            # Add branch data to report
            $report += [PSCustomObject]@{
                ProjectName    = $project.name
                RepositoryName = $repositoryName
                BranchName     = $branchName
                MergeStatus    = $mergeStatus
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
Export-ToExcel -Report $report -ExportFileName "BranchesNotMergedReport.xlsx" -WorksheetName "BranchesNotMerged"