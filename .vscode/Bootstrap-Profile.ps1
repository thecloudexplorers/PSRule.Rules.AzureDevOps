<#
.SYNOPSIS
    Adds ADO-related environment variables to the PowerShell profile and sets them in the current session.

.DESCRIPTION
    Each parameter corresponds to an environment variable used in Azure DevOps artifact publishing.
    If the variable is not yet in the profile, it's appended and also set in the current session.

.PARAMETER AdoOrganization
    Azure DevOps organization name.

.PARAMETER AdoProject
    Azure DevOps project name.

.PARAMETER AdoFeedName
    Name of the Azure Artifacts feed.

.PARAMETER AdoRepoName
    Name of the repository containing the artifact.

.PARAMETER AdoUsername
    Username used for publishing.

.PARAMETER AdoPat
    Personal Access Token for authentication.

.PARAMETER AdoPackagePath
    Path to the package to publish.

.PARAMETER AdoApiKey
    Optional API key to use when pushing packages.

.EXAMPLE
    .\Set-AdoEnvVars.ps1 -AdoOrganization "contoso" -AdoProject "platform" -AdoFeedName "shared" -AdoRepoName "infra-modules" -AdoUsername "svc-user" -AdoPat "xxxx" -AdoPackagePath "C:\out" -AdoApiKey "my-api-key"
#>
param (
    [Parameter(Mandatory = $true)] [string]$AdoOrganization,
    [Parameter(Mandatory = $true)] [string]$AdoProject,
    [Parameter(Mandatory = $true)] [string]$AdoFeedName,
    [Parameter(Mandatory = $true)] [string]$AdoRepoName,
    [Parameter(Mandatory = $true)] [string]$AdoUsername,
    [Parameter(Mandatory = $true)] [string]$AdoPat,
    [Parameter(Mandatory = $true)] [string]$AdoPackagePath,
    [Parameter(Mandatory = $true)] [string]$AdoApiKey
)

# Map parameter names to environment variable names
$envMap = @{
    'ADO_ORGANIZATION' = $AdoOrganization
    'ADO_PROJECT'      = $AdoProject
    'ADO_FEED_NAME'    = $AdoFeedName
    'ADO_REPO_NAME'    = $AdoRepoName
    'ADO_USERNAME'     = $AdoUsername
    'ADO_PAT'          = $AdoPat
    'ADO_PACKAGE_PATH' = $AdoPackagePath
    'ADO_API_KEY'      = $AdoApiKey
}

# Ensure the profile file exists
if (-not (Test-Path -Path $PROFILE)) {
    New-Item -Path $PROFILE -ItemType File -Force | Out-Null
    Write-Host "Created profile file: $PROFILE"
}

# Read current profile content
$currentProfile = Get-Content -Path $PROFILE -Raw

# Track what was added
$added = @()

foreach ($key in $envMap.Keys) {
    $line = "$" + "env:$key = '$($envMap[$key])'"

    # Check if this variable is already in the profile
    if ($currentProfile -notmatch [regex]::Escape("`$env:$key")) {
        Add-Content -Path $PROFILE -Value $line
        $added += $key
    }
}

if ($added.Count -eq 0) {
    Write-Host "All environment variables already exist in your PowerShell profile."
}
else {
    Write-Host "Added the following variables to your profile:`n - $($added -join "`n - ")"
    Write-Host "Restart PowerShell or VSCode to apply changes."
}

. $PROFILE
Write-Host "Profile reloaded. Environment variables now available in this session."