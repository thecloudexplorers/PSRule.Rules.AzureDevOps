<#
    .SYNOPSIS
    Get the organization's policies from Azure DevOps

    .DESCRIPTION
    Get the organization's policies from Azure DevOps

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .EXAMPLE
    Get-AzDevOpsOrganizationPolicy -Organization $Organization
#>

Function Get-AzDevOpsOrganizationPolicy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Organization
    )
    if ($null -eq $script:connection) {
        throw "Not connected to Azure DevOps. Run Connect-AzDevOps first"
    }
    $header = $script:connection.GetHeader()
    $uri = "https://dev.azure.com/$Organization/_apis/policy/configurations?api-version=7.1-preview.1"
    Write-Verbose "URI: $uri"
    try {
        $policies = Invoke-RestMethod -Uri $uri -Method Get -Headers $header -ContentType 'application/json'
        if ($policies -is [string]) {
            throw "Authentication failed or policies not found"
        }
    }
    catch {
        throw $_.Exception.Message
    }
    return $policies
}
Export-ModuleMember -Function Get-AzDevOpsOrganizationPolicy

<#
    .SYNOPSIS
    Export the organization's policies from Azure DevOps to a JSON file

    .DESCRIPTION
    Export the organization's policies from Azure DevOps to a JSON file with .ado.orgpolicies.json extension

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .PARAMETER OutputPath
    Output path for JSON files

    .PARAMETER PassThru
    Return the exported policies as objects to the pipeline instead of writing to a file

    .EXAMPLE
    Export-AzDevOpsOrganizationPolicies -Organization $Organization -OutputPath $OutputPath
#>
function Export-AzDevOpsOrganizationPolicies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Organization,
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
    Write-Verbose "Getting organization policies from Azure DevOps"
    $policies = Get-AzDevOpsOrganizationPolicy -Organization $Organization
    $policies | Add-Member -MemberType NoteProperty -Name ObjectType -Value 'Azure.DevOps.Organization.Policies'
    $policies | Add-Member -MemberType NoteProperty -Name ObjectName -Value ("{0}.OrganizationPolicies" -f $script:connection.Organization)
    $policies | Add-Member -MemberType NoteProperty -Name Name -Value "OrganizationPolicies"
    $id = @{
        originalId = $null
        resourceName = 'OrganizationPolicies'
        organization = $script:connection.Organization
    } | ConvertTo-Json -Depth 100
    $policies | Add-Member -MemberType NoteProperty -Name id -Value $id
    if ($PassThru) {
        Write-Output $policies
    } else {
        $policies | ConvertTo-Json -Depth 10 | Out-File (Join-Path -Path $OutputPath -ChildPath "$Organization.ado.orgpolicies.json")
    }
}
Export-ModuleMember -Function Export-AzDevOpsOrganizationPolicies
