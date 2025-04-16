#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Reports on branch policy configurations across all repositories in an Azure DevOps organization.

    .DESCRIPTION
    Retrieves branch policy settings for all repositories in all projects, including minimum reviewers, 
    automatic reviewers, comment resolution, build validation, and linked work items, and exports the results to an Excel file.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER PersonalAccessToken
    The Personal Access Token (PAT) for authenticating with the Azure DevOps API.

    .PARAMETER PatTokenOwnerName
    The username associated with the PAT token, typically an email.

    .EXAMPLE
    .\BranchPoliciesOnAllRepos.ps1 -Organization "myOrg" -PersonalAccessToken "myPAT" -PatTokenOwnerName "Ben John"
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
        [System.String] $reposUri = "https://dev.azure.com/$Organization/$projectName/_apis/git/repositories?api-version=7.1-preview.1"
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

        # Fetch policy configurations for the repository
        try {
            # Construct API endpoint for policy configurations
            [System.String] $policiesUri = "https://dev.azure.com/$Organization/$projectName/_apis/policy/configurations?repositoryId=$repositoryId&api-version=7.1-preview.1"
            $policiesResponse = Invoke-RestMethod -Uri $policiesUri -Headers $headers -Method Get
            [System.Object[]] $policies = $policiesResponse.value
            Write-Debug "Policies response for [$repositoryName]: [$($policiesResponse | ConvertTo-Json -Depth 5)]"
            Write-Host "Found [$($policies.Count)] policies in [$repositoryName]." -ForegroundColor Cyan
            if ($policies.Count -eq 0) {
                Write-Debug "No policies found for repository [$repositoryName]."
            }
        }
        # Catch errors and log without breaking to continue processing other repositories
        catch {
            Write-Warning "Failed to fetch policies for [$repositoryName] in [$($project.name)]: [$($_.Exception.Message)]"
            continue
        }

        # Initialize policy settings with default values
        [System.Collections.Hashtable]$policyResults = @{
            Project           = $project.name
            Repository        = $repositoryName
            MinReviewers      = $false  
            AutoReviewers     = $false  
            CommentResolution = $false  
            BuildValidation   = $false  
            LinkedWorkItems   = $false  
        }
        
        # Evaluate each policy
        foreach ($policy in $policies) {
            if ($policy.type -and $policy.type.displayName) {
                switch ($policy.type.displayName) {
                    "Minimum number of reviewers" { 
                        $policyResults.MinReviewers = $true  
                    }
                    "Automatically include code reviewers" { 
                        $policyResults.AutoReviewers = $true  
                    }
                    "Check for comment resolution" { 
                        $policyResults.CommentResolution = $true  
                    }
                    "Build validation" { 
                        $policyResults.BuildValidation = $true  
                    }
                    "Check for linked work items" { 
                        $policyResults.LinkedWorkItems = $true  
                    }
                    default {
                        Write-Debug "Unknown policy type [$($policy.type.displayName)] for [$repositoryName]."
                    }
                }
            }
            else {
                Write-Debug "Policy missing type or displayName for [$repositoryName]: [$($policy | ConvertTo-Json -Depth 3)]"
            }
        }
        
        # Add policy results to report
        $report += [PSCustomObject]$policyResults
    }
}

# Exit if no data collected
if ($report.Count -eq 0) { 
    Write-Host "[No repositories found.]" -ForegroundColor Yellow
    exit 
}

# Call the export function
Export-ToExcel -Report $report -ExportFileName "BranchPoliciesReport.xlsx" -WorksheetName "BranchPolicies"