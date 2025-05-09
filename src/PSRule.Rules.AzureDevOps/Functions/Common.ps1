    <#
    .SYNOPSIS
        Connects to an Azure DevOps organization for use with PSRule.Rules.AzureDevOps cmdlets.

    .DESCRIPTION
        The Connect-AzDevOps function establishes a connection to an Azure DevOps organization using one of several authentication methods: Personal Access Token (PAT), Service Principal, Managed Identity, or Bearer token. The connection details are stored in a script-level variable for use by other cmdlets in the PSRule.Rules.AzureDevOps module.

    .PARAMETER Organization
        The name of the Azure DevOps organization to connect to.

    .PARAMETER PAT
        A Personal Access Token (PAT) used to authenticate to Azure DevOps. Used with the 'Pat' parameter set.

    .PARAMETER TenantId
        The Microsoft Entra ID tenant ID for Service Principal authentication. Used with the 'ServicePrincipal' parameter set.

    .PARAMETER ClientId
        The client ID of the Service Principal. Used with the 'ServicePrincipal' parameter set.

    .PARAMETER ClientSecret
        The client secret of the Service Principal. Used with the 'ServicePrincipal' parameter set.

    .PARAMETER ManagedIdentity
        Specifies that a Managed Identity should be used for authentication. Used with the 'ManagedIdentity' parameter set.

    .PARAMETER AccessToken
        A Bearer token (e.g., OAuth 2.0 access token from Microsoft Entra ID) used to authenticate to Azure DevOps. Used with the 'Bearer' parameter set.

    .EXAMPLE
        Connect-AzDevOps -Organization "MyOrg" -PAT "abc123"
        Connects to the "MyOrg" organization using a Personal Access Token.

    .EXAMPLE
        Connect-AzDevOps -Organization "MyOrg" -AccessToken "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ik..."
        Connects to the "MyOrg" organization using a Bearer token.

    .EXAMPLE
        Connect-AzDevOps -Organization "MyOrg" -TenantId "00000000-0000-0000-0000-000000000000" -ClientId "11111111-1111-1111-1111-111111111111" -ClientSecret "secret"
        Connects to the "MyOrg" organization using a Service Principal.

    .EXAMPLE
        Connect-AzDevOps -Organization "MyOrg" -ManagedIdentity
        Connects to the "MyOrg" organization using a Managed Identity.

    .NOTES
        - The Bearer token must have appropriate permissions for Azure DevOps APIs (e.g., read access to projects and settings).
        - Bearer tokens typically expire after 1 hour; re-run Connect-AzDevOps with a new token if expired.
        - The connection is stored in a script-level variable and persists for the session.

    .LINK
        https://docs.microsoft.com/en-us/rest/api/azure/devops/
    #>
    function Connect-AzDevOps {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Organization,

        [Parameter(Mandatory = $true)]
        [string]
        $OrganizationId,

        [Parameter(Mandatory = $true, ParameterSetName = 'Pat')]
        [string]
        $PAT,

        [Parameter(Mandatory = $true, ParameterSetName = 'ServicePrincipal')]
        [string]
        $TenantId,

        [Parameter(Mandatory = $true, ParameterSetName = 'ServicePrincipal')]
        [string]
        $ClientId,

        [Parameter(Mandatory = $true, ParameterSetName = 'ServicePrincipal')]
        [string]
        $ClientSecret,

        [Parameter(Mandatory = $true, ParameterSetName = 'ManagedIdentity')]
        [switch]
        $ManagedIdentity,

        [Parameter(Mandatory = $true, ParameterSetName = 'Bearer')]
        [string]
        $AccessToken
    )

    switch ($PSCmdlet.ParameterSetName) {
        'Pat' {
            $script:connection = [AzureDevOpsConnection]::new($Organization, $PAT)
        }
        'ServicePrincipal' {
            $script:connection = [AzureDevOpsConnection]::new($Organization, $ClientId, $ClientSecret, $TenantId)
        }
        'ManagedIdentity' {
            $script:connection = [AzureDevOpsConnection]::new($Organization)
        }
        'Bearer' {
            $script:connection = [AzureDevOpsConnection]::new($Organization, $OrganizationId, $AccessToken, 'FullAccess', $true)
        }
    }

    # Verify connection with a simple API call
    try {
        $uri = "https://dev.azure.com/$Organization/_apis/projects?api-version=7.0"
        Invoke-RestMethod -Uri $uri -Method Get -Headers $script:connection.GetHeader() | Out-Null
        Write-Verbose "Successfully connected to Azure DevOps organization: $Organization"
    }
    catch {
        throw "Failed to connect to Azure DevOps: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function Connect-AzDevOps

<#
    .SYNOPSIS
    Disconnect from Azure DevOps

    .DESCRIPTION
    Disconnect from Azure DevOps and remove the connection object

    .EXAMPLE
    Disconnect-AzDevOps
#>
Function Disconnect-AzDevOps {
    [CmdletBinding()]
    param ()
    Clear-Variable connection -Scope Script -ErrorAction SilentlyContinue
    Remove-Variable connection -Scope Script -ErrorAction SilentlyContinue
    $script:connection = ""
    $script:connection = $null
}
# End of Function Disconnect-AzDevOps

<#
    .SYNOPSIS
    Get all Azure DevOps projects for an organization

    .DESCRIPTION
    Get all Azure DevOps projects for an organization using Azure DevOps Rest API

    .EXAMPLE
    Get-AzDevOpsProject
#>
function Get-AzDevOpsProject {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Project = ""
    )
    if ($null -eq $script:connection) {
        throw "Not connected to Azure DevOps. Run Connect-AzDevOps first"
    }
    $header = $script:connection.GetHeader()
    $Organization = $script:connection.Organization
    Write-Verbose "Getting projects for organization $Organization"
    if([string]::IsNullOrEmpty($Project) -eq $false) {
        $uri = "https://dev.azure.com/$Organization/_apis/projects/$($Project)?api-version=7.2-preview.4"
    } else {
        $uri = "https://dev.azure.com/$Organization/_apis/projects?api-version=7.2-preview.4"
    }
    Write-Verbose "URI: $uri"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $header
        # If the response is not an object but a string, the authentication failed
        if ($response -is [string]) {
            throw "Authentication failed or organization not found"
        }
    }
    catch {
        throw "Failed to get projects from Azure DevOps"
    }
    if($response.value) {
        return $response.value
    } else {
        return $response
    }
}
# End of Function Get-AzDevOpsProject

<#
    .SYNOPSIS
    Get all Azure DevOps Project Acls

    .DESCRIPTION
    Get all Azure DevOps Project Acls using Azure DevOps Rest API

    .PARAMETER ProjectId
    Project Id for Azure DevOps

    .EXAMPLE
    Get-AzDevOpsProjectAcls -ProjectId $ProjectId
#>
function Get-AzDevOpsProjectAcls {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $ProjectId
    )
    if ($null -eq $script:connection) {
        throw "Not connected to Azure DevOps. Run Connect-AzDevOps first"
    }
    $Organization = $script:connection.Organization
    $header = $script:connection.GetHeader()
    $aclInfo = @{
        'Environments' = "https://dev.azure.com/$Organization/_apis/accesscontrollists/83d4c2e6-e57d-4d6e-892b-b87222b7ad20?api-version=7.2-preview.1&token=Environments/$ProjectId"
        'Pipelines' = "https://dev.azure.com/$Organization/_apis/accesscontrollists/33344d9c-fc72-4d6f-aba5-fa317101a7e9?api-version=7.2-preview.1&token=$ProjectId"
        'ReleaseDefinitions' = "https://dev.azure.com/$Organization/_apis/accesscontrollists/c788c23e-1b46-4162-8f5e-d7585343b5de?api-version=7.2-preview.1&token=$ProjectId"
        'Repositories' = "https://dev.azure.com/$Organization/_apis/accesscontrollists/2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87?api-version=7.2-preview.1&token=repoV2/$ProjectId"
        'ServiceConnections' = "https://dev.azure.com/$Organization/_apis/accesscontrollists/49b48001-ca20-4adc-8111-5b60c903a50c?api-version=7.2-preview.1&token=endpoints/$ProjectId"
        'VariableGroups' = "https://dev.azure.com/$Organization/_apis/accesscontrollists/b7e84409-6553-448a-bbb2-af228e07cbeb?api-version=7.2-preview.1&token=Library/$ProjectId"
    }
    $acls = @{}
    try {
        # Walk through the aclInfo hashtable and get the acls for each resource
        foreach($key in $aclInfo.Keys) {
            $aclUri = $aclInfo[$key]
            Write-Verbose "Getting $key ACLs for project $ProjectId"
            $aclResponse = Invoke-RestMethod -Uri $aclUri -Method Get -Headers $header
            # If the response is not an object but a string, the authentication failed
            if ($aclResponse -is [string] -or $null -eq $aclResponse.value) {
                throw "Authentication failed or project not found"
            }
            $acls.Add($key,$aclResponse.value)
        }
    }
    catch {
        throw $_.Exception.Message
    }
    return $acls
}

<#
    .SYNOPSIS
    Export the Azure DevOps Project

    .DESCRIPTION
    Export the Azure DevOps Project using Azure DevOps Rest API to a JSON file

    .PARAMETER Project
    Project name for Azure DevOps

    .PARAMETER OutputPath
    Output path for JSON files

    .PARAMETER PassThru
    Return the exported project as objects to the pipeline instead of writing to a file

    .EXAMPLE
    Export-AzDevOpsProject -Project $Project -OutputPath $OutputPath

    .NOTES
    The output file will be named $Project.prj.ado.json

#>
function Export-AzDevOpsProject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
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
    $header = $script:connection.GetHeader()
    $Organization = $script:connection.Organization
    Write-Verbose "Getting project $Project for organization $Organization"
   try {
        $response = Get-AzDevOpsProject -Project $Project
        $response | Add-Member -MemberType NoteProperty -Name ObjectType -Value "Azure.DevOps.Project"
        $response | Add-Member -MemberType NoteProperty -Name ObjectName -Value "$Organization.$Project"
        # Add the Project Acls to the response object
        $acls = Get-AzDevOpsProjectAcls -ProjectId $response.id
        $response | Add-Member -MemberType NoteProperty -Name ProjectAcls -Value $acls
        # Add a new id field to the response object
        $response.id = @{ 
            originalId      = $response.id;
            resourceName    = $response.name;
            project         = $Project;
            organization    = $Organization
        } | ConvertTo-Json -Depth 100
    }
    catch {
        throw $_.Exception.Message
    }
    if($PassThru) {
        Write-Output $response
    } else {
        Write-Verbose "Exporting project $Project as file $Project.prj.ado.json"
        $response | ConvertTo-Json -Depth 100 | Out-File -FilePath "$OutputPath/$Project.prj.ado.json"
    }
}
# End of Function Export-AzDevOpsProject
