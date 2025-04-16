#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Reports on Azure DevOps pipeline agent pools.

    .DESCRIPTION
    Collects pipeline details and their associated agent pools across all projects in the specified 
    organization and exports them to an Excel file.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER PersonalAccessToken
    The Personal Access Token (PAT) for authenticating with the Azure DevOps API.

    .PARAMETER PatTokenOwnerName
    The username associated with the PAT token, typically an email.

    .EXAMPLE
    .\ProjectAgentPools.ps1 -Organization "myOrg" -PersonalAccessToken "myPAT" -PatTokenOwnerName "Ben John"
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
    # Encode project name for API compatibility
    [System.String] $projectName = [uri]::EscapeDataString($project.name)
    Write-Host "Processing project: [$projectName]" -ForegroundColor Cyan
    
    # Fetch all pipeline definitions for the project
    try {
        [System.Object[]] $pipelineDefs = @()
        [System.String] $pipelinesUri = "https://dev.azure.com/$Organization/$projectName/_apis/build/definitions?api-version=7.0"
        [System.String] $continuationToken = $null
        
        # Handle pagination for pipeline definitions
        do {
            [System.String] $uri = $pipelinesUri
            if ($continuationToken) {
                $uri += "&continuationToken=$continuationToken"
            }
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
            $pipelineDefs += $response.value
            $continuationToken = $response.PSObject.Properties['continuationToken']?.Value
        } while ($continuationToken)
        
        Write-Host "Found [$($pipelineDefs.Count)] pipelines in [$projectName]." -ForegroundColor Cyan
        if ($pipelineDefs.Count -eq 0) {
            Write-Debug "No pipelines found for project [$projectName]. Response: [$($response | ConvertTo-Json -Depth 3)]"
        }

        # Process each pipeline definition
        foreach ($pipeline in $pipelineDefs) {
            # Determine agent pool name
            [System.String] $agentPoolName = "Unknown"
            if ($pipeline.pool -and $pipeline.pool.name) {
                $agentPoolName = $pipeline.pool.name
            }
            elseif ($pipeline.queue -and $pipeline.queue.name) {
                $agentPoolName = $pipeline.queue.name
            }
            
            # Add pipeline details to report
            [System.String] $pipelineName = if ($pipeline.name) { $pipeline.name } else { "Unnamed Pipeline" }
            $report += [PSCustomObject]@{
                ProjectName   = $project.name
                PipelineName  = $pipelineName
                AgentPoolName = $agentPoolName
            }
        }
    }
    # Catch errors and log without breaking to continue processing other projects
    catch {
        Write-Warning "Failed to fetch pipelines for [$($project.name)]: [$($_.Exception.Message)]"
        continue
    }
}

# Exit if no pipelines or agent pools found
if ($report.Count -eq 0) {
    Write-Host "[No pipelines or agent pools found.]" -ForegroundColor Yellow
    exit
}

# Call the export function
Export-ToExcel -Report $report -ExportFileName "ProjectAgentPoolsReport.xlsx" -WorksheetName "AgentPools"