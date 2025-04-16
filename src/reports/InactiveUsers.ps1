#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Identifies inactive Azure DevOps users.

    .DESCRIPTION
    Fetches user entitlements and identifies users who have not accessed the organization for over 90 days or 
    have never logged in, exporting the results to an Excel file.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER PersonalAccessToken
    The Personal Access Token (PAT) for authenticating with the Azure DevOps API.

    .PARAMETER PatTokenOwnerName
    The username associated with the PAT token, typically an email.

    .EXAMPLE
    .\InactiveUsers.ps1 -Organization "myOrg" -PersonalAccessToken "myPAT" -PatTokenOwnerName "Ben John"
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

# Fetch all user entitlements
try {
    # Construct API endpoint for user entitlements
    [System.String] $usersUri = "https://vsaex.dev.azure.com/$Organization/_apis/userentitlements?api-version=7.1-preview.1"
    $usersResponse = Invoke-RestMethod -Uri $usersUri -Headers $headers -Method Get
    [System.Object[]] $userEntitlements = $usersResponse.value
    Write-Host "Found [$($userEntitlements.Count)] user entitlements." -ForegroundColor Cyan
    if ($userEntitlements.Count -eq 0) {
        Write-Debug "No user entitlements found for organization [$Organization]. Response: [$($usersResponse | ConvertTo-Json -Depth 3)]"
    }
}
# Catch errors and exit to report user fetch issues
catch {
    Write-Error "Failed to fetch user entitlements: [$($_.Exception.Message)]"
    exit
}

# Define threshold for inactivity (90 days ago)
[System.DateTime] $thresholdDate = (Get-Date).AddDays(-90)

# Process each user entitlement
foreach ($user in $userEntitlements) {
    # Extract last accessed date
    [System.DateTime] $lastAccessed = if ($user.lastAccessedDate -and $user.lastAccessedDate -ne "0001-01-01T00:00:00Z") {
        [System.DateTime] $user.lastAccessedDate
    } else {
        $null
    }

    # Check for inactivity
    if (-not $lastAccessed -or $lastAccessed -lt $thresholdDate) {
        # Format last accessed date or use "Never"
        [System.String] $lastAccessedFormatted = if ($lastAccessed) {
            $lastAccessed.ToString("yyyy-MM-dd")
        } else {
            "Never"
        }

        # Add user to report
        $report += [PSCustomObject]@{
            User         = $user.user.principalName
            LastAccessed = $lastAccessedFormatted
        }
    }
}

# Exit if no inactive users found
if ($report.Count -eq 0) {
    Write-Host "[No inactive users found.]" -ForegroundColor Yellow
    exit 
}

# Call the export function
Export-ToExcel -Report $report -ExportFileName "InactiveUsersReport.xlsx" -WorksheetName "InactiveUsers"