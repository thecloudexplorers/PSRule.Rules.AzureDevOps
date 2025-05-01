#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Reports on repositories without branch policies.

    .DESCRIPTION
    Identifies Git repositories across all projects in the specified Azure DevOps organization that 
    lack branch policies on their default branches and exports the results to an Excel file.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER PersonalAccessToken
    The Personal Access Token (PAT) for authenticating with the Azure DevOps API.

    .PARAMETER PatTokenOwnerName
    The username associated with the PAT token, typically an email.

    .EXAMPLE
    .\ReposWithoutBranchingPolicies.ps1 -Organization "myOrg" -PersonalAccessToken "myPAT" -PatTokenOwnerName "Ben John"
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
    [System.String] $projectsUri = "https://dev.azure.com/$Organization/_apis/projects?api-version=7.0"
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
    [System.String] $projectName = $project.name
    Write-Host "Processing project: [$projectName]" -ForegroundColor Cyan

    # Fetch all repositories for the project
    try {
        [System.String] $reposUri = "https://dev.azure.com/$Organization/$projectName/_apis/git/repositories?api-version=7.0"
        $reposResponse = Invoke-RestMethod -Uri $reposUri -Headers $headers -Method Get
        [System.Object[]] $repositories = $reposResponse.value
        Write-Host "Found [$($repositories.Count)] repositories in [$projectName]." -ForegroundColor Cyan
        if ($repositories.Count -eq 0) {
            Write-Debug "No repositories found for project [$projectName]. Response: [$($reposResponse | ConvertTo-Json -Depth 3)]"
        }
    }
    # Catch errors and log without breaking to continue processing other projects
    catch {
        Write-Warning "Failed to fetch repositories for [$projectName]: [$($_.Exception.Message)]"
        continue
    }

    # Process each repository
    foreach ($repository in $repositories) {
        [System.String] $repoName = $repository.name
        [System.String] $defaultBranch = $repository.defaultBranch ? ($repository.defaultBranch -replace 'refs/heads/', '') : 'Not Set'

        # Fetch branch policies for the repository
        [System.Boolean]$hasPoliciesOnDefaultBranch = $false
        try {
            [System.String] $policiesUri = "https://dev.azure.com/$Organization/$projectName/_apis/policy/configurations?repositoryId=$($repository.id)&api-version=7.0"
            $policiesResponse = Invoke-RestMethod -Uri $policiesUri -Headers $headers -Method Get
            $policies = $policiesResponse.value

            # Check if any policy applies to the default branch
            if ($defaultBranch -ne "Not Set" -and $policies.Count -gt 0) {
                foreach ($policy in $policies) {
                    if ($policy.settings -and $policy.settings.scope) {
                        $scopes = $policy.settings.scope
                        foreach ($scope in $scopes) {
                            if ($scope.refName -eq "refs/heads/$defaultBranch") {
                                $hasPoliciesOnDefaultBranch = $true
                                break
                            }
                        }
                    }
                    if ($hasPoliciesOnDefaultBranch) { break }
                }
            }
        }
        # Catch errors and log without breaking to continue processing other repositories
        catch {
            Write-Warning "Failed to fetch policies for repository [$repoName] in [$projectName]: [$($_.Exception.Message)]"
            continue
        }

        # Add repository details to report
        $report += [PSCustomObject]@{ 
            Project        = $projectName
            RepoName       = $repoName
            DefaultBranch  = $defaultBranch
            HasPolicies = $hasPoliciesOnDefaultBranch ? "Yes" : "No"
        }
    }
}

# Exit if no repositories found
if ($report.Count -eq 0) {
    Write-Host "[No repositories found.]" -ForegroundColor Yellow
    exit 
}

# Call the export function
Export-ToExcel -Report $report -ExportFileName "GitRepoBranchPolicyReport.xlsx" -WorksheetName "RepoDetails"