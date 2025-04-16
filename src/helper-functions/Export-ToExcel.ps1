#Requires -Modules ImportExcel

<#
    .SYNOPSIS
    Exports a report to an Excel file with predefined formatting.

    .DESCRIPTION
    Exports the provided report data to an Excel file in the C:\Temp directory with formatting options 
    such as autosizing columns, freezing the top row, and bolding the top row.

    .PARAMETER Report
    The data to export to Excel, typically an array of PSObjects.

    .PARAMETER ExportFileName
    The name of the Excel file (e.g., "Report.xlsx"). The file will be saved in C:\Temp.

    .PARAMETER WorksheetName
    The name of the worksheet in the Excel file.

    .EXAMPLE
    Export-ToExcel -Report $reportData -ExportFileName "Report.xlsx" -WorksheetName "ReportData"
#>

function Export-ToExcel {
    param (
        [Parameter(Mandatory)]
        [System.Object[]] $Report,

        [Parameter(Mandatory)]
        [System.String] $ExportFileName,

        [Parameter(Mandatory)]
        [System.String] $WorksheetName
    )

    # Define the base directory for all exports
    [System.String] $baseDirectory = "C:\Temp"
    # Construct the full export path
    [System.String] $exportPath = Join-Path -Path $baseDirectory -ChildPath $ExportFileName

    # Verify output directory
    if (-not (Test-Path -Path $baseDirectory)) {
        Write-Host "Directory [$baseDirectory] does not exist. It will be created during export." -ForegroundColor Yellow
    }

    # Define Excel export parameters
    [System.Collections.Hashtable] $excelParams = @{
        Path          = $exportPath
        WorksheetName = $WorksheetName
        AutoSize      = $true
        FreezeTopRow  = $true
        BoldTopRow    = $true
    }

    try {
        # Ensure output directory exists
        if (-not (Test-Path -Path $baseDirectory)) {
            New-Item -Path $baseDirectory -ItemType Directory -Force | Out-Null
            Write-Host "Created directory: [$baseDirectory]" -ForegroundColor Green
        }

        # Export data to Excel
        $Report | Export-Excel @excelParams
        Write-Host "Report generated at: [$exportPath]" -ForegroundColor Green
    }
    # Catch errors and exit to report export issues
    catch {
        Write-Error "Export failed: [$($_.Exception.Message)]"
        exit
    }
}