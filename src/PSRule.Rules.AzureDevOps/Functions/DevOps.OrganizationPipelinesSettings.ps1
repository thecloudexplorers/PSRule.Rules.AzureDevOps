<#
    .SYNOPSIS
    Retrieves Azure DevOps organization-level pipeline settings.

    .DESCRIPTION
    This function calls the internal Contribution HierarchyQuery endpoint used by the Azure DevOps portal
    to retrieve pipeline security, policy, and control settings for the entire organization.

    .PARAMETER Organization
    The name of your Azure DevOps organization (e.g. 'contoso').

    .PARAMETER AccessToken
    A valid Azure DevOps Bearer token with access to organization settings.

    .EXAMPLE
    Invoke-AdoPipelineSettingsQuery -Organization "MyOrg" -AccessToken $token
#>

function Read-AdoOrganizationPipelinesSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Organization,

        [Parameter(Mandatory = $true)]
        [string]
        $AccessToken
    )

    # Define endpoint for pipeline settings query
    $uri = "https://dev.azure.com/$Organization/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1"

    # Set headers for authentication
    $headers = @{
        Authorization  = $AccessToken
        "Content-Type" = "application/json"
    }

    # Build request body for settings query
    $body = @(
        @{
            contributionIds     = @("ms.vss-build-web.pipelines-org-settings-data-provider")
            dataProviderContext = @{
                properties = @{
                    sourcePage = @{
                        url         = "https://dev.azure.com/$Organization/_settings/pipelinessettings"
                        routeId     = "ms.vss-admin-web.collection-admin-hub-route"
                        routeValues = @{
                            adminPivot  = "pipelinessettings"
                            controller  = "ContributedPage"
                            action      = "Execute"
                            serviceHost = "00000000-0000-0000-0000-000000000000 ($Organization)"
                        }
                    }
                }
            }
        }
    ) | ConvertTo-Json -Depth 10

    try {
        # Invoke API to retrieve settings
        $rawResponse = Invoke-WebRequest -Uri $uri -Method Post -Headers $headers -Body $body -UseBasicParsing

        # Validate response for authentication errors
        if ($rawResponse.Content -match '<html' -or $rawResponse.RawContent -match 'Sign In') {
            throw "Access denied or token expired. Please verify your Bearer token is still valid."
        }

        # Parse response
        $response = $rawResponse.Content | ConvertFrom-Json
        $settings = $response.dataProviders.'ms.vss-build-web.pipelines-org-settings-data-provider'

        # Output settings to console (optional, retained for debugging)
        Write-Host ""
        Write-Host "===== Azure DevOps Pipeline Settings Assessment ====="
        Write-Host ""

        Write-Host "General:"
        Write-Host " - Disable anonymous access to badges:                        $($settings.statusBadgesArePrivate)"
        Write-Host " - Limit variables that can be set at queue time:             $($settings.enforceSettableVar)"
        Write-Host " - Limit job authorization (non-release):                     $($settings.enforceJobAuthScope)"
        Write-Host " - Limit job authorization (release):                         $($settings.enforceJobAuthScopeForReleases)"
        Write-Host " - Protect access to repositories in YAML pipelines:          $($settings.enforceReferencedRepoScopedToken)"
        Write-Host " - Disable stage chooser:                                     $($settings.disableStageChooser)"
        Write-Host " - Disable creation of classic build pipelines:               $($settings.disableClassicBuildPipelineCreation)"
        Write-Host " - Disable creation of classic release pipelines:             $($settings.disableClassicReleasePipelineCreation)"

        Write-Host "`nTask Restrictions:"
        Write-Host " - Disable built-in tasks:                                    $($settings.disableInBoxTasksVar)"
        Write-Host " - Disable Marketplace tasks:                                 $($settings.disableMarketplaceTasksVar)"
        Write-Host " - Disable Node 6 tasks:                                      $($settings.disableNode6TasksVar)"
        Write-Host " - Enable shell tasks arguments validation:                   $($settings.enableShellTasksArgsSanitizing)"

        Write-Host "`nTriggers:"
        Write-Host " - Limit PRs from forks (GitHub):                             $($settings.forkProtectionEnabled)"
        Write-Host " - Allow builds from forks:                                   $($settings.buildsEnabledForForks)"
        Write-Host " - Enforce job auth for forks:                                $($settings.enforceJobAuthScopeForForks)"
        Write-Host " - Block secrets access from forks:                           $($settings.enforceNoAccessToSecretsFromForks)"
        Write-Host " - Disable implied YAML CI trigger:                           $($settings.disableImpliedYAMLCiTrigger)"

        Write-Host "`nUnmapped / Diagnostic:"
        Write-Host " - Audit settable variable enforcement:                       $($settings.auditEnforceSettableVar)"
        Write-Host " - Task lockdown feature enabled:                             $($settings.isTaskLockdownFeatureEnabled)"
        Write-Host " - Has pipeline policies permission:                          $($settings.hasManagePipelinePoliciesPermission)"
        Write-Host " - Require comments for PRs:                                  $($settings.isCommentRequiredForPullRequest)"
        Write-Host " - Require comments (non-team members):                       $($settings.requireCommentsForNonTeamMembersOnly)"
        Write-Host " - Require comments (non-team/non-contributors):              $($settings.requireCommentsForNonTeamMemberAndNonContributors)"
        Write-Host " - Audit shell argument sanitization:                         $($settings.enableShellTasksArgsSanitizingAudit)"

        Write-Host ""
        Write-Host "Assessment complete."

        # Return the settings object
        return $settings
    }
    catch {
        throw "Failed to retrieve pipeline settings: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function Read-AdoOrganizationPipelinesSettings

<#
    .SYNOPSIS
        Exports Azure DevOps organization pipeline settings to a JSON file or returns them as an object.

    .DESCRIPTION
        The Export-AdoOrganizationPipelinesSettings function retrieves pipeline settings for a specified 
        Azure DevOps organization using the provided access token. It formats the settings with metadata 
        (e.g., ObjectType, ObjectName) and either saves them to a JSON file or returns them as an object, 
        depending on the parameters provided. Requires a prior connection to Azure DevOps via Connect-AzDevOps.

    .PARAMETER Organization
        The name of the Azure DevOps organization whose pipeline settings will be exported.

    .PARAMETER AccessToken
        The Bearer token used for authenticating API requests to Azure DevOps.

    .PARAMETER OutputPath
        The file path where the pipeline settings will be saved as a JSON file. 
        If not specified, the settings are not saved to a file. Mutually exclusive with -PassThru.

    .PARAMETER PassThru
        If specified, returns the pipeline settings as a PowerShell object instead of saving to a file.

    .EXAMPLE
        Export-AdoOrganizationPipelinesSettings -Organization "MyOrg" -AccessToken "abc123" -OutputPath "C:\Exports"
        Exports the pipeline settings for "MyOrg" to "C:\Exports\pipelineSettings.ado.json".

    .EXAMPLE
        Export-AdoOrganizationPipelinesSettings -Organization "MyOrg" -AccessToken "abc123" -PassThru
        Retrieves and returns the pipeline settings for "MyOrg" as a PowerShell object.

    .NOTES
        - Requires a prior call to Connect-AzDevOps to establish a connection.
        - The function depends on Read-AdoOrganizationPipelinesSettings to retrieve settings.
        - The output JSON file is named "pipelineSettings.ado.json" when using -OutputPath.

    .LINK
        https://docs.microsoft.com/en-us/rest/api/azure/devops/
    #>

function Export-AdoOrganizationPipelinesSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Organization,
    
        [Parameter(Mandatory = $true)]
        [string]
        $AccessToken,
    
        [Parameter(ParameterSetName = 'JsonFile')]
        [string]
        $OutputPath,
    
        [Parameter(ParameterSetName = 'PassThru')]
        [switch]
        $PassThru
    )
    
    # Check for active connection
    if ($null -eq $script:connection) {
        throw 'Not connected to Azure DevOps. Run Connect-AzDevOps first.'
    }
    
    # Retrieve pipeline settings
    try {
        $settings = Read-AdoOrganizationPipelinesSettings -Organization $Organization -AccessToken $AccessToken
        if ($null -eq $settings) {
            throw "No Organization pipeline settings returned from Read-AdoOrganizationPipelinesSettings."
        }
    }
    catch {
        throw "Failed to get Organization pipeline settings from Azure DevOps: $($_.Exception.Message)"
    }
    
    # Process settings into exportable format
    $settingsDetails = @()
    $settingsObject = [PSCustomObject]@{
        statusBadgesArePrivate                            = $settings.statusBadgesArePrivate
        enforceSettableVar                                = $settings.enforceSettableVar
        enforceJobAuthScope                               = $settings.enforceJobAuthScope
        enforceJobAuthScopeForReleases                    = $settings.enforceJobAuthScopeForReleases
        enforceReferencedRepoScopedToken                  = $settings.enforceReferencedRepoScopedToken
        disableStageChooser                               = $settings.disableStageChooser
        disableClassicBuildPipelineCreation               = $settings.disableClassicBuildPipelineCreation
        disableClassicReleasePipelineCreation             = $settings.disableClassicReleasePipelineCreation
        disableInBoxTasksVar                              = $settings.disableInBoxTasksVar
        disableMarketplaceTasksVar                        = $settings.disableMarketplaceTasksVar
        disableNode6TasksVar                              = $settings.disableNode6TasksVar
        enableShellTasksArgsSanitizing                    = $settings.enableShellTasksArgsSanitizing
        forkProtectionEnabled                             = $settings.forkProtectionEnabled
        buildsEnabledForForks                             = $settings.buildsEnabledForForks
        enforceJobAuthScopeForForks                       = $settings.enforceJobAuthScopeForForks
        enforceNoAccessToSecretsFromForks                 = $settings.enforceNoAccessToSecretsFromForks
        disableImpliedYAMLCiTrigger                       = $settings.disableImpliedYAMLCiTrigger
        auditEnforceSettableVar                           = $settings.auditEnforceSettableVar
        isTaskLockdownFeatureEnabled                      = $settings.isTaskLockdownFeatureEnabled
        hasManagePipelinePoliciesPermission               = $settings.hasManagePipelinePoliciesPermission
        isCommentRequiredForPullRequest                   = $settings.isCommentRequiredForPullRequest
        requireCommentsForNonTeamMembersOnly              = $settings.requireCommentsForNonTeamMembersOnly
        requireCommentsForNonTeamMemberAndNonContributors = $settings.requireCommentsForNonTeamMemberAndNonContributors
        enableShellTasksArgsSanitizingAudit               = $settings.enableShellTasksArgsSanitizingAudit
    }
    
    # Add metadata properties
    $settingsObject | Add-Member -MemberType NoteProperty -Name ObjectType -Value 'Azure.DevOps.Organization.Pipelines.Settings' -Force
    $settingsObject | Add-Member -MemberType NoteProperty -Name ObjectName -Value "$($script:connection.Organization).OrganizationPipelineSettings" -Force
    $settingsObject | Add-Member -MemberType NoteProperty -Name name -Value "OrganizationPipelineSettings" -Force
    
    # Create structured id object
    $id = @{
        originalId   = $null
        resourceName = "OrganizationPipelineSettings"
        organization = $script:connection.Organization
    } | ConvertTo-Json -Depth 100
    $settingsObject | Add-Member -MemberType NoteProperty -Name id -Value $id -Force
    
    $settingsDetails += $settingsObject
    
    # Output based on parameters
    if ($PassThru) {
        Write-Output $settingsDetails
    }
    else {
        $settingsDetails | ConvertTo-Json -Depth 100 | Out-File -FilePath "$OutputPath\OrganizationPipelineSettings.ado.json"
    }
}
    
Export-ModuleMember -Function Export-AdoOrganizationPipelinesSettings