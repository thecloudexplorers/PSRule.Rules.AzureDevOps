#Requires -Modules Az.Accounts, Az.OperationalInsights

<#
    .SYNOPSIS
    Reports on audit streams in Azure Log Analytics workspaces.

    .DESCRIPTION
    Checks all Log Analytics workspaces in Azure subscriptions for audit stream configurations and 
    exports the count per subscription to an Excel file.

    .PARAMETER Organization
    The name of the Azure DevOps organization (used for context, not API calls here).

    .EXAMPLE
    .\AuditStreams.ps1 -Organization "myOrg"
#>

param (
    [Parameter(Mandatory)]
    [System.String] $Organization
)

# Source the external function to export to Excel
. ".\src\helper-functions\Export-ToExcel.ps1"

# Note: This script uses Azure PowerShell (Az modules) and does not directly use the Azure DevOps API,

# Initialize report array
[System.Object[]] $report = @()

# Fetch all Azure subscriptions
$subscriptions = Get-AzSubscription
# Process each subscription
foreach ($sub in $subscriptions) {
    # Set context to current subscription
    Set-AzContext -SubscriptionId $sub.Id
    # Retrieve all Log Analytics workspaces
    $workspaces = Get-AzOperationalInsightsWorkspace
    # Initialize audit stream counter
    [System.Int32] $auditCount = 0
    # Check each workspace for audit streams
    foreach ($workspace in $workspaces) {
        try {
            # Fetch diagnostic settings for workspace
            $settings = Get-AzDiagnosticSetting -ResourceId $workspace.ResourceId
            # Count settings with "audit" in name
            $auditCount += ($settings | Where-Object { $_.Name -like "*audit*" }).Count
        }
        # Catch errors and log without breaking to continue processing workspaces
        catch {
            Write-Warning "Failed to fetch diagnostic settings for workspace [$($workspace.Name)] in subscription [$($sub.Name)]: [$($_.Exception.Message)]"
        }
    }
    # Add subscription stats to report
    $report += [PSCustomObject]@{
        SubscriptionName   = $sub.Name
        SubscriptionId     = $sub.Id
        AuditStreamsCount  = $auditCount
    }
}

# Exit if no audit streams were found
if ($report.Count -eq 0) {
    Write-Host "[No audit streams found.]" -ForegroundColor Yellow
    exit 
}

# Call the export function
Export-ToExcel -Report $report -ExportFileName "AuditStreamResults.xlsx" -WorksheetName "AuditStreams"