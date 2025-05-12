param (
    [string]$RepositoryRoot
)

Write-Host "Installing and importing required modules..." -ForegroundColor Cyan
Import-Module Microsoft.PowerShell.SecretStore
Import-Module Microsoft.PowerShell.SecretManagement
Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.1.1

# List of required environment variables
$requiredEnvVars = @(
    'ADO_ORGANIZATION',
    'ADO_PROJECT',
    'ADO_FEED_NAME',
    'ADO_REPO_NAME',
    'ADO_USERNAME',
    'ADO_PAT',
    'ADO_PACKAGE_PATH',
    'ADO_API_KEY'
)

# Check for missing variables
$missing = @()
foreach ($var in $requiredEnvVars) {
    Write-Host "Checking env var: [$var]"
    if (-not (Test-Path Env:$var)) {        
        $missing += $var
    }
}

if ($missing.Count -gt 0) {
    Write-Error "Missing required environment variables:`n - $($missing -join "`n - ")"
    exit 1
}

# Optional debug output
Write-Host "Repository directory: $RepositoryRoot"

# Import and run the target script
$PublishScript = Join-Path $RepositoryRoot "src/helper-functions/Publish-ToAzureArtifactsPSRepo.ps1"

if (-not (Test-Path $PublishScript)) {
    throw "Could not find publish script at: $PublishScript"
}

. $PublishScript

$params = @{
    Organization   = $env:ADO_ORGANIZATION
    Project        = $env:ADO_PROJECT
    FeedName       = $env:ADO_FEED_NAME
    RepositoryName = $env:ADO_REPO_NAME
    Username       = $env:ADO_USERNAME
    PatToken       = $env:ADO_PAT
    PackagePath    = $env:ADO_PACKAGE_PATH
    ApiKey         = $env:ADO_API_KEY
}

Publish-ToAzureArtifactsPSRepo @params
