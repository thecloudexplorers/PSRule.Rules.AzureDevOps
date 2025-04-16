#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Reports on Azure DevOps artifact storage usage across projects.

    .DESCRIPTION
    Collects statistics on artifact storage usage by counting builds with artifacts and estimating artifact counts and sizes, 
    then exports the results to an Excel file.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER PersonalAccessToken
    The Personal Access Token (PAT) for authenticating with Azure DevOps API.

    .PARAMETER PatTokenOwnerName
    The username associated with the PAT token, typically an email.

    .EXAMPLE
    .\ArtifactStorageReport.ps1 -Organization "myOrg" -PersonalAccessToken "myPAT" -PatTokenOwnerName "Ben John"
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

# Configure API headers with PAT
[System.Collections.Hashtable] $headers = New-AdoAuthenticationHeader -PatToken $PersonalAccessToken -PatTokenOwnerName $PatTokenOwnerName

# Initialize report array
[System.Object[]] $report = @()

# Fetch all projects from Azure DevOps
try {
    [System.String] $projectsUri = "https://dev.azure.com/$Organization/_apis/projects?api-version=7.1-preview.4"
    $projectsResponse = Invoke-RestMethod -Uri $projectsUri -Headers $headers -Method Get
    $projects = $projectsResponse.value
    Write-Host "Found [$($projects.Count)] projects." -ForegroundColor Cyan
} catch {
    Write-Error "Failed to fetch projects: [$($_.Exception.Message)]"
    exit
}

# Iterate through each project
foreach ($project in $projects) {
    [System.String] $projectId = $project.id
    [System.String] $projectName = [uri]::EscapeDataString($project.name)
    Write-Host "Processing project: [$($project.name)]" -ForegroundColor Cyan

    # Initialize counters for build and artifact stats
    [System.Int32] $buildCountWithArtifacts = 0
    [System.Int32] $artifactCount = 0
    [System.Double] $totalArtifactSizeMB = 0

    # Fetch builds for the project
    try {
        [System.String] $buildsUri = "https://dev.azure.com/${Organization}/${projectName}/_apis/build/builds?api-version=7.1-preview.4"
        [System.String] $continuationToken = $null
        [System.Object[]] $builds = @()

        # Handle pagination to retrieve all builds
        do {
            [System.String] $uri = $buildsUri
            if ($continuationToken) {
                $uri += "&continuationToken=$continuationToken"
            }

            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
            $builds += $response.value
            $continuationToken = $response.PSObject.Properties['continuationToken']?.Value

        } while ($continuationToken)

        Write-Host "Found [$($builds.Count)] builds in [$($project.name)]." -ForegroundColor Cyan

        # Process each build for artifacts
        foreach ($build in $builds) {
            [System.String] $buildId = $build.id
            try {
                # Fetch artifacts for the build
                [System.String] $artifactsUri = "https://dev.azure.com/${Organization}/${projectName}/_apis/build/builds/${buildId}/artifacts?api-version=7.1-preview.1"
                $artifactsResponse = Invoke-RestMethod -Uri $artifactsUri -Headers $headers -Method Get
                $artifacts = $artifactsResponse.value

                if ($artifacts.Count -gt 0) {
                    $buildCountWithArtifacts++
                    $artifactCount += $artifacts.Count

                    # Estimate artifact sizes
                    foreach ($artifact in $artifacts) {
                        if ($artifact.resource.downloadUrl) {
                            try {
                                # Get artifact size via HEAD request
                                $artifactDetails = Invoke-RestMethod -Uri $artifact.resource.downloadUrl -Headers $headers -Method Head
                                [System.Int64] $sizeBytes = $artifactDetails.ContentLength
                                [System.Double] $sizeMB = [math]::Round($sizeBytes / 1MB, 2)
                                $totalArtifactSizeMB += $sizeMB
                            } catch {
                                Write-Warning "Failed to fetch size for artifact [$($artifact.name)] in build [$buildId]: [$($_.Exception.Message)]"
                            }
                        }
                    }
                }
            } catch {
                # Handle 404 errors silently as they indicate no artifacts
                if ($_.Exception.Response.StatusCode -eq 404) {
                    Write-Debug "404 means no artifacts for this build, which is normal; skipping warning."
                    continue
                }
                Write-Warning "Failed to fetch artifacts for build [$buildId] in [$($project.name)]: [$($_.Exception.Message)]"
            }
        }
    }
    # Catch non-terminating errors and log them without breaking to continue processing other projects
    catch {
        Write-Warning "Failed to fetch builds for [$($project.name)]: [$($_.Exception.Message)]"
    }

    # Add project stats to report
    $report += [PSCustomObject]@{
        ProjectName            = $project.name
        TotalBuilds            = $builds.Count
        BuildsWithArtifacts    = $buildCountWithArtifacts
        ArtifactCount          = $artifactCount
        TotalArtifactSizeMB    = $totalArtifactSizeMB
    }
}

# Exit if no projects were processed
if ($report.Count -eq 0) {
    Write-Host "[No projects found.]" -ForegroundColor Yellow
    exit
}

# Call the export function
Export-ToExcel -Report $report -ExportFileName "ArtifactStorageReport.xlsx" -WorksheetName "ArtifactStorage"