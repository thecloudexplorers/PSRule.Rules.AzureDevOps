#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Reports on branch structure per repository in Azure DevOps.

    .DESCRIPTION
    Collects branch details, including branch name and hierarchical path, for each repository across all projects  
    and exports the results to an Excel file.The branch path reflects the naming convention used (e.g., feature/subfeature).

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER PersonalAccessToken
    The Personal Access Token (PAT) for authenticating with the Azure DevOps API.

    .PARAMETER PatTokenOwnerName
    The username associated with the PAT token, typically an email.

    .EXAMPLE
    .\BranchStructureReport.ps1 -Organization "myOrg" -PersonalAccessToken "myPAT" -PatTokenOwnerName "Ben John"
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
}
# Catch errors and exit to report project fetch issues
catch {
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
        if ($repositories.Count -eq 0) {
            Write-Debug "No repositories found for project [$($project.name)]. Response: [$($reposResponse | ConvertTo-Json -Depth 3)]"
        }
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
            # Extract branch name and path
            [System.String] $branchName = $branch.name -replace "refs/heads/", ""
            [System.String] $branchPath = $branchName

            # Add branch data to report
            $report += [PSCustomObject]@{
                ProjectName    = $project.name       
                RepositoryName = $repositoryName
                BranchName     = $branchName          
                BranchPath     = $branchPath          
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
Export-ToExcel -Report $report -ExportFileName "BranchStructureReport.xlsx" -WorksheetName "BranchStructure"