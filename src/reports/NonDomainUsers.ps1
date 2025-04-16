#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Lists non-domain (external) users in Azure DevOps.

    .DESCRIPTION
    Identifies users whose email addresses do not match a specified domain pattern (e.g., external users) 
    and exports their details to an Excel file.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER PersonalAccessToken
    The Personal Access Token (PAT) for authenticating with the Azure DevOps API.

    .PARAMETER PatTokenOwnerName
    The username associated with the PAT token, typically an email.

    .PARAMETER DomainPattern
    The domain pattern to identify internal users (e.g., "@mycompany.com").

    .EXAMPLE
    .\NonDomainUsers.ps1 -Organization "myOrg" -PersonalAccessToken "myPAT" -PatTokenOwnerName "Ben John" -DomainPattern "@mycompany.com"
#>

param (
    [Parameter(Mandatory)]
    [System.String] $Organization,
    [Parameter(Mandatory)]
    [System.String] $PersonalAccessToken,
    [Parameter(Mandatory)]
    [System.String] $PatTokenOwnerName,
    [Parameter(Mandatory)]
    [System.String] $DomainPattern
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

# Process each user entitlement
foreach ($user in $userEntitlements) {
    # Check for non-domain users
    if ($user.user.principalName -notmatch [regex]::Escape($DomainPattern)) {
        # Add non-domain user to report
        $report += [PSCustomObject]@{
            User = $user.user.principalName
        }
    }
}

# Exit if no non-domain users found
if ($report.Count -eq 0) {
    Write-Host "[No non-domain users found.]" -ForegroundColor Yellow
    Write-Debug "No users matched the non-domain pattern for [$DomainPattern]. Total users: [$($userEntitlements.Count)]"
    exit 
}

# Call the export function
Export-ToExcel -Report $report -ExportFileName "NonDomainUsersReport.xlsx" -WorksheetName "NonDomainUsers"