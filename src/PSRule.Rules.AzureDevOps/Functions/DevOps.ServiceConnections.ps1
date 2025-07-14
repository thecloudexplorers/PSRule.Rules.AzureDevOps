<#
    .SYNOPSIS
    Get all Azure Resource Manager service connections from Azure DevOps project

    .DESCRIPTION
    Get all Azure Resource Manager service connections from Azure DevOps project using Azure DevOps Rest API

    .PARAMETER Project
    Project name for Azure DevOps

    .EXAMPLE
    Get-AzDevOpsServiceConnections -Project $Project
#>
function Get-AzDevOpsServiceConnections {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Project
    )
    if ($null -eq $script:connection) {
        throw "Not connected to Azure DevOps. Run Connect-AzDevOps first"
    }
    $Organization = $script:connection.Organization
    $header = $script:connection.GetHeader()
    $uri = "https://dev.azure.com/$Organization/$Project/_apis/serviceendpoint/endpoints?api-version=6.0-preview.4&includeDetails=True"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $header
        # If the response is not an object but a string, the authentication failed
        if ($response -is [string]) {
            throw "Authentication failed or project not found"
        }
    }
    catch {
        throw $_.Exception.Message
    }

    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $header
    return $response.value
}
Export-ModuleMember -Function Get-AzDevOpsServiceConnections
# End of Function Get-AzDevOpsServiceConnections

<#
    .SYNOPSIS
    Get all Checks for service connections from Azure DevOps project

    .DESCRIPTION
    Get all Checks for service connections from Azure DevOps project using Azure DevOps Rest API

    .PARAMETER Project
    Project name for Azure DevOps

    .PARAMETER ServiceConnectionId
    Service connection id for Azure DevOps

    .EXAMPLE
    Get-AzDevOpsServiceConnectionChecks -Project $Project -ServiceConnectionId $ServiceConnectionId

    .LINK
    https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/list?view=azure-devops-rest-7.2&tabs=HTTP
#>
function Get-AzDevOpsServiceConnectionChecks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Project,
        [Parameter(Mandatory)]
        [string]
        $ServiceConnectionId
    )
    if ($null -eq $script:connection) {
        throw "Not connected to Azure DevOps. Run Connect-AzDevOps first"
    }
    $Organization = $script:connection.Organization
    $header = $script:connection.GetHeader()
    $uri = "https://dev.azure.com/$Organization/$Project/_apis/pipelines/checks/configurations?api-version=7.2-preview.1&resourceType=endpoint&resourceId=$ServiceConnectionId&`$expand=settings"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $header
        # If the response is not an object but a string, the authentication failed
        if ($response -is [string]) {
            throw "Authentication failed or project not found"
        }
    }
    catch {
        throw $_.Exception.Message
    }
    return $response.value
}
Export-ModuleMember -Function Get-AzDevOpsServiceConnectionChecks
# End of Function Get-AzDevOpsServiceConnectionChecks

<#
    .SYNOPSIS
    Get the Acls for an service connection from Azure DevOps project

    .DESCRIPTION
    Get the Acls for an service connection from Azure DevOps project using Azure DevOps Rest API

    .PARAMETER ProjectId
    Project Id for Azure DevOps

    .PARAMETER ServiceConnectionId
    Service connection id for Azure DevOps

    .EXAMPLE
    Get-AzDevOpsServiceConnectionAcls -ProjectId $ProjectId -ServiceConnectionId $ServiceConnectionId
#>
function Get-AzDevOpsServiceConnectionAcls {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $ProjectId,
        [Parameter(Mandatory)]
        [string]
        $ServiceConnectionId
    )
    if ($null -eq $script:connection) {
        throw "Not connected to Azure DevOps. Run Connect-AzDevOps first"
    }
    $Organization = $script:connection.Organization
    $header = $script:connection.GetHeader()
    $uri = "https://dev.azure.com/{0}/_apis/accesscontrollists/49b48001-ca20-4adc-8111-5b60c903a50c?api-version=7.2-preview.1&token=endpoints/{1}/{2}" -f $Organization, $ProjectId, $ServiceConnectionId
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $header
        # If the response is not an object but a string, the authentication failed
        if ($response -is [string]) {
            throw "Authentication failed or project not found"
        }
    }
    catch {
        throw $_.Exception.Message
    }
    return @($response.value)
}
Export-ModuleMember -Function Get-AzDevOpsServiceConnectionAcls

<#
    .SYNOPSIS
    Export all Azure Resource Manager service connections from Azure DevOps project with checks as nested objects

    .DESCRIPTION
    Export all Azure Resource Manager service connections from Azure DevOps project with checks as nested objects using Azure DevOps Rest API

    .PARAMETER Project
    Project name for Azure DevOps

    .PARAMETER OutputPath
    Output path for JSON files

    .PARAMETER PassThru
    Return the exported service connections as objects to the pipeline instead of writing to a file

    .EXAMPLE
    Export-AzDevOpsServiceConnections -Project $Project -OutputPath $OutputPath

    .LINK
    https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/list?view=azure-devops-rest-7.2&tabs=HTTP
#>
function Export-AzDevOpsServiceConnections {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Project,
        [Parameter(ParameterSetName = 'JsonFile')]
        [string]
        $OutputPath,
        [Parameter(ParameterSetName = 'PassThru')]
        [switch]
        $PassThru
    )
    if ($null -eq $script:connection) {
        throw "Not connected to Azure DevOps. Run Connect-AzDevOps first"
    }
    $Organization = $script:connection.Organization
    # Get all service connections
    $serviceConnections = Get-AzDevOpsServiceConnections -Project $Project
    $serviceConnections | ForEach-Object {
        $serviceConnection = $_
        # Set JSON ObjectType field to Azure.DevOps.ServiceConnection
        $serviceConnection | Add-Member -MemberType NoteProperty -Name ObjectType -Value 'Azure.DevOps.ServiceConnection'
        # Set JSON ObjectName field to organiztion.project.service connection name
        $serviceConnection | Add-Member -MemberType NoteProperty -Name ObjectName -Value "$Organization.$Project.$($serviceConnection.name)"

        # Get checks for service connection
        $serviceConnectionChecks = @(Get-AzDevOpsServiceConnectionChecks -Project $Project -ServiceConnectionId $serviceConnection.id)
        $serviceConnection | Add-Member -MemberType NoteProperty -Name Checks -Value $serviceConnectionChecks
        # Get acls for service connection
        $serviceConnectionAcls = @(Get-AzDevOpsServiceConnectionAcls -ProjectId $serviceConnection.serviceEndpointProjectReferences[0].projectReference.id -ServiceConnectionId $serviceConnection.id)
        $serviceConnection | Add-Member -MemberType NoteProperty -Name Acls -Value $serviceConnectionAcls

        # Set id field to a JSON object with originalId, project and organization
        $serviceConnection.id = @{
            originalId = $serviceConnection.id
            resourceName = $serviceConnection.name
            project = $Project
            organization = $Organization
        } | ConvertTo-Json -Depth 100
        if ($PassThru) {
            Write-Output $serviceConnection
        } else {
            Write-Verbose "Exporting service connection $($serviceConnection.name) as file $($serviceConnection.name).ado.sc.json"
            $serviceConnection | ConvertTo-Json -Depth 100 | Out-File "$OutputPath/$($serviceConnection.name.replace('/','')).ado.sc.json"
        }
    }
}
Export-ModuleMember -Function Export-AzDevOpsServiceConnections
# End of Function Export-AzDevOpsServiceConnections

<#
    .SYNOPSIS
    Get the execution history for a service connection from Azure DevOps project

    .DESCRIPTION
    Get the execution history for a service connection from Azure DevOps project using Azure DevOps Rest API.
    This provides details about when and how the service connection was used in pipelines.

    .PARAMETER Project
    Project name for Azure DevOps

    .PARAMETER ServiceConnectionId
    Service connection id for Azure DevOps

    .PARAMETER Top
    Number of execution records to retrieve. Default is 100.

    .PARAMETER ContinuationToken
    A continuation token, returned by a previous call to this method, that can be used to return the next set of records

    .EXAMPLE
    Get-AzDevOpsServiceConnectionExecutionHistory -Project $Project -ServiceConnectionId $ServiceConnectionId

    .EXAMPLE
    Get-AzDevOpsServiceConnectionExecutionHistory -Project $Project -ServiceConnectionId $ServiceConnectionId -Top 10

    .EXAMPLE
    Get-AzDevOpsServiceConnectionExecutionHistory -Project $Project -ServiceConnectionId $ServiceConnectionId -ContinuationToken $ContinuationToken

    .LINK
    https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/executionhistory/list?view=azure-devops-rest-7.1&tabs=HTTP
#>
function Get-AzDevOpsServiceConnectionExecutionHistory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Project,

        [Parameter(Mandatory)]
        [string]
        $ServiceConnectionId,

        [Parameter()]
        [int]
        $Top = 100,

        [Parameter()]
        [int64]
        $ContinuationToken
    )
    if ($null -eq $script:connection) {
        throw "Not connected to Azure DevOps. Run Connect-AzDevOps first"
    }

    $Organization = $script:connection.Organization
    $header = $script:connection.GetHeader()

    # Construct the base URI
    $uri = "https://dev.azure.com/$Organization/$Project/_apis/serviceendpoint/$ServiceConnectionId/executionhistory?api-version=7.1"


    # Add optional parameters if provided
    if ($Top -gt 0) {
        $uri += "&top=$Top"
    }

    if ($ContinuationToken) {
        $uri += "&continuationToken=$ContinuationToken"
    }

    Write-Verbose "URI: $uri"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $header
        # If the response is not an object but a string, the authentication failed
        if ($response -is [string]) {
            throw "Authentication failed or project not found"
        }
    }
    catch {
        throw $_.Exception.Message
    }

    return $response.value
}
Export-ModuleMember -Function Get-AzDevOpsServiceConnectionExecutionHistory
# End of Function Get-AzDevOpsServiceConnectionExecutionHistory

<#
    .SYNOPSIS
    Export service connection execution history from Azure DevOps project

    .DESCRIPTION
    Export service connection execution history from Azure DevOps project using Azure DevOps Rest API

    .PARAMETER Project
    Project name for Azure DevOps

    .PARAMETER ServiceConnectionId
    Optional. Service connection id for Azure DevOps. If not provided, will get history for all service connections.

    .PARAMETER OutputPath
    Output path for JSON files

    .PARAMETER PassThru
    Return the exported execution history as objects to the pipeline instead of writing to a file

    .EXAMPLE
    Export-AzDevOpsServiceConnectionExecutionHistory -Project $Project -OutputPath $OutputPath

    .LINK
    https://learn.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/executionhistory/list?view=azure-devops-rest-7.1&tabs=HTTP
#>
function Export-AzDevOpsServiceConnectionExecutionHistory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Project,

        [Parameter()]
        [string]
        $ServiceConnectionId,

        [Parameter(ParameterSetName = 'JsonFile')]
        [string]
        $OutputPath,

        [Parameter(ParameterSetName = 'PassThru')]
        [switch]
        $PassThru
    )
    if ($null -eq $script:connection) {
        throw "Not connected to Azure DevOps. Run Connect-AzDevOps first"
    }

    $Organization = $script:connection.Organization

    # If no specific ServiceConnectionId is provided, get all service connections
    if ([string]::IsNullOrEmpty($ServiceConnectionId)) {
        $serviceConnections = Get-AzDevOpsServiceConnections -Project $Project

        # Create an array to hold all execution histories
        $allExecutionHistories = @()

        # Get execution history for each service connection
        foreach ($connection in $serviceConnections) {
            $executionHistory = Get-AzDevOpsServiceConnectionExecutionHistory -Project $Project -ServiceConnectionId $connection.id

            if ($executionHistory.Count -gt 0) {
                # Add metadata to each execution history item
                foreach ($historyItem in $executionHistory) {
                    $historyItem | Add-Member -MemberType NoteProperty -Name "ServiceConnectionName" -Value $connection.name
                    $historyItem | Add-Member -MemberType NoteProperty -Name "ObjectType" -Value "Azure.DevOps.ServiceConnectionExecution"
                    $historyItem | Add-Member -MemberType NoteProperty -Name "ObjectName" -Value "$Organization.$Project.$($connection.name).Execution.$($historyItem.data.id)"
                }

                $allExecutionHistories += $executionHistory
            }
        }

        # Return or export the execution histories
        if ($PassThru) {
            return $allExecutionHistories
        } else {
            if ($allExecutionHistories.Count -gt 0) {
                $outputFileName = "ServiceConnectionExecutionHistory.ado.json"
                Write-Verbose "Exporting service connection execution history to $OutputPath/$outputFileName"
                $allExecutionHistories | ConvertTo-Json -Depth 100 | Out-File "$OutputPath/$outputFileName"
            } else {
                Write-Verbose "No service connection execution history found"
            }
        }
    } else {
        # Get execution history for a specific service connection
        $serviceConnection = Get-AzDevOpsServiceConnections -Project $Project | Where-Object { $_.id -eq $ServiceConnectionId }
        if ($null -eq $serviceConnection) {
            Write-Warning "Service connection with ID $ServiceConnectionId not found"
            return
        }

        $executionHistory = Get-AzDevOpsServiceConnectionExecutionHistory -Project $Project -ServiceConnectionId $ServiceConnectionId

        if ($executionHistory.Count -gt 0) {
            # Add metadata to each execution history item
            foreach ($historyItem in $executionHistory) {
                $historyItem | Add-Member -MemberType NoteProperty -Name "ServiceConnectionName" -Value $serviceConnection.name
                $historyItem | Add-Member -MemberType NoteProperty -Name "ObjectType" -Value "Azure.DevOps.ServiceConnectionExecution"
                $historyItem | Add-Member -MemberType NoteProperty -Name "ObjectName" -Value "$Organization.$Project.$($serviceConnection.name).Execution.$($historyItem.data.id)"
            }

            # Return or export the execution history
            if ($PassThru) {
                return $executionHistory
            } else {
                $outputFileName = "$($serviceConnection.name.replace('/',''))_ExecutionHistory.ado.json"
                Write-Verbose "Exporting service connection execution history to $OutputPath/$outputFileName"
                $executionHistory | ConvertTo-Json -Depth 100 | Out-File "$OutputPath/$outputFileName"
            }
        } else {
            Write-Verbose "No execution history found for service connection $($serviceConnection.name)"
        }
    }
}
Export-ModuleMember -Function Export-AzDevOpsServiceConnectionExecutionHistory
# End of Function Export-AzDevOpsServiceConnectionExecutionHistory
