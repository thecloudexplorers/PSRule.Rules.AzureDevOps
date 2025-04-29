# Azure DevOps organization Pipelines settings rules

# Synopsis: Anonymous access to organization pipeline status badges should be disabled
Rule 'Azure.DevOps.Organization.Pipelines.Settings.DisableAnonymousBadgeAccess' `
    -Ref 'ADO-OPS-001' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Anonymous access to organization pipeline status badges should be disabled to prevent unauthorized access to pipeline status.
        Reason 'Anonymous access to organization pipeline status badges is enabled.'
        Recommend 'Enable `Disable anonymous access to badges` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-overview?view=azure-devops
        $Assert.HasField($TargetObject, "statusBadgesArePrivate", $true)
        $Assert.HasFieldValue($TargetObject, "statusBadgesArePrivate", $true)
}

# Synopsis: Variables settable at queue time should be limited in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.LimitSettableVariables' `
    -Ref 'ADO-OPS-002' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Limiting variables that can be set at queue time in organization settings prevents unauthorized changes to pipeline behavior.
        Reason 'Variables that can be set at queue time are not limited in organization settings.'
        Recommend 'Enable `Limit variables that can be set at queue time` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-overview?view=azure-devops
        $Assert.HasField($TargetObject, "enforceSettableVar", $true)
        $Assert.HasFieldValue($TargetObject, "enforceSettableVar", $true)
}

# Synopsis: Job authorization scope for non-release pipelines should be limited in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeNonRelease' `
    -Ref 'ADO-OPS-003' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Limiting job authorization scope for non-release pipelines in organization settings reduces the risk of unauthorized access to resources.
        Reason 'Job authorization scope for non-release pipelines is not limited in organization settings.'
        Recommend 'Enable `Limit job authorization scope` for non-release pipelines in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-overview?view=azure-devops
        $Assert.HasField($TargetObject, "enforceJobAuthScope", $true)
        $Assert.HasFieldValue($TargetObject, "enforceJobAuthScope", $true)
}

# Synopsis: Job authorization scope for release pipelines should be limited in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeRelease' `
    -Ref 'ADO-OPS-004' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Limiting job authorization scope for release pipelines in organization settings reduces the risk of unauthorized access to resources.
        Reason 'Job authorization scope for release pipelines is not limited in organization settings.'
        Recommend 'Enable `Limit job authorization scope` for release pipelines in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-overview?view=azure-devops
        $Assert.HasField($TargetObject, "enforceJobAuthScopeForReleases", $true)
        $Assert.HasFieldValue($TargetObject, "enforceJobAuthScopeForReleases", $true)
}

# Synopsis: Access to repositories in YAML pipelines should be protected in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.ProtectRepoAccessInYaml' `
    -Ref 'ADO-OPS-005' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Protecting access to repositories in YAML pipelines in organization settings ensures that only authorized repositories are used.
        Reason 'Access to repositories in YAML pipelines is not protected in organization settings.'
        Recommend 'Enable `Protect access to repositories in YAML pipelines` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-overview?view=azure-devops
        $Assert.HasField($TargetObject, "enforceReferencedRepoScopedToken", $true)
        $Assert.HasFieldValue($TargetObject, "enforceReferencedRepoScopedToken", $true)
}

# Synopsis: Creation of classic build pipelines should be disabled in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.DisableClassicBuildPipelines' `
    -Ref 'ADO-OPS-006' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Disabling classic build pipelines in organization settings encourages the use of YAML pipelines, which are more secure and maintainable.
        Reason 'Creation of classic build pipelines is enabled in organization settings.'
        Recommend 'Enable `Disable creation of classic build pipelines` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-overview?view=azure-devops
        $Assert.HasField($TargetObject, "disableClassicBuildPipelineCreation", $true)
        $Assert.HasFieldValue($TargetObject, "disableClassicBuildPipelineCreation", $true)
}

# Synopsis: Creation of classic release pipelines should be disabled in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.DisableClassicReleasePipelines' `
    -Ref 'ADO-OPS-007' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Disabling classic release pipelines in organization settings encourages the use of YAML pipelines, which are more secure and maintainable.
        Reason 'Creation of classic release pipelines is enabled in organization settings.'
        Recommend 'Enable `Disable creation of classic release pipelines` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-overview?view=azure-devops
        $Assert.HasField($TargetObject, "disableClassicReleasePipelineCreation", $true)
        $Assert.HasFieldValue($TargetObject, "disableClassicReleasePipelineCreation", $true)
}

# Synopsis: Pull requests from forks should be limited in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.LimitPRsFromForks' `
    -Ref 'ADO-OPS-008' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Limiting pull requests from forks in organization settings prevents unauthorized code execution in pipelines.
        Reason 'Pull requests from forks are not limited in organization settings.'
        Recommend 'Enable `Limit pull requests from forks` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops#protecting-branches-in-forks
        $Assert.HasField($TargetObject, "forkProtectionEnabled", $true)
        $Assert.HasFieldValue($TargetObject, "forkProtectionEnabled", $true)
}

# Synopsis: Builds from forks should be disabled in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.DisableBuildsFromForks' `
    -Ref 'ADO-OPS-009' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Disabling builds from forks in organization settings reduces the risk of executing untrusted code.
        Reason 'Builds from forks are enabled in organization settings.'
        Recommend 'Disable `Allow builds from forks` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops#protecting-branches-in-forks
        $Assert.HasField($TargetObject, "buildsEnabledForForks", $true)
        $Assert.HasFieldValue($TargetObject, "buildsEnabledForForks", $false)
}

# Synopsis: Shell task arguments should be sanitized in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.SanitizeShellTaskArguments' `
    -Ref 'ADO-OPS-010' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Sanitizing shell task arguments in organization settings prevents injection attacks in pipeline scripts.
        Reason 'Shell task arguments are not sanitized in organization settings.'
        Recommend 'Enable `Sanitize shell task arguments` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-overview?view=azure-devops#tasks
        $Assert.HasField($TargetObject, "enableShellTasksArgsSanitizing", $true)
        $Assert.HasFieldValue($TargetObject, "enableShellTasksArgsSanitizing", $true)
}

# Synopsis: Stage chooser should be disabled in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.DisableStageChooser' `
    -Ref 'ADO-OPS-011' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Disabling the stage chooser in organization settings prevents users from manually selecting stages during pipeline runs, reducing the risk of unintended deployments.
        Reason 'Stage chooser is enabled in organization settings.'
        Recommend 'Enable `Disable stage chooser` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/pipelines/security/secure-pipelines?view=azure-devops
        $Assert.HasField($TargetObject, "disableStageChooser", $true)
        $Assert.HasFieldValue($TargetObject, "disableStageChooser", $true)
}

# Synopsis: In-box task variables should be disabled in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.DisableInBoxTasksVar' `
    -Ref 'ADO-OPS-012' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Disabling in-box task variables in organization settings prevents the use of potentially outdated or insecure tasks, encouraging the use of maintained tasks.
        Reason 'In-box task variables are enabled in organization settings.'
        Recommend 'Enable `Disable in-box task variables` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/pipelines/security/secure-pipelines?view=azure-devops#tasks
        $Assert.HasField($TargetObject, "disableInBoxTasksVar", $true)
        $Assert.HasFieldValue($TargetObject, "disableInBoxTasksVar", $true)
}

# Synopsis: Marketplace task variables should be disabled in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.DisableMarketplaceTasksVar' `
    -Ref 'ADO-OPS-013' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Disabling marketplace task variables in organization settings reduces the risk of using unverified or malicious tasks from the marketplace.
        Reason 'Marketplace task variables are enabled in organization settings.'
        Recommend 'Enable `Disable marketplace task variables` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/pipelines/security/secure-pipelines?view=azure-devops#tasks
        $Assert.HasField($TargetObject, "disableMarketplaceTasksVar", $true)
        $Assert.HasFieldValue($TargetObject, "disableMarketplaceTasksVar", $true)
}

# Synopsis: Node 6 tasks should be disabled in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.DisableNode6TasksVar' `
    -Ref 'ADO-OPS-014' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Disabling Node 6 tasks in organization settings prevents the use of deprecated and potentially insecure tasks that rely on Node 6.
        Reason 'Node 6 tasks are enabled in organization settings.'
        Recommend 'Enable `Disable Node 6 tasks` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/pipelines/security/secure-pipelines?view=azure-devops#tasks
        $Assert.HasField($TargetObject, "disableNode6TasksVar", $true)
        $Assert.HasFieldValue($TargetObject, "disableNode6TasksVar", $true)
}

# Synopsis: Job authorization scope for forks should be limited in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeForForks' `
    -Ref 'ADO-OPS-015' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Limiting job authorization scope for forks in organization settings reduces the risk of unauthorized access to resources from forked repositories.
        Reason 'Job authorization scope for forks is not limited in organization settings.'
        Recommend 'Enable `Limit job authorization scope for forks` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops#protecting-branches-in-forks
        $Assert.HasField($TargetObject, "enforceJobAuthScopeForForks", $true)
        $Assert.HasFieldValue($TargetObject, "enforceJobAuthScopeForForks", $true)
}

# Synopsis: Access to secrets from forks should be disabled in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.DisableSecretsFromForks' `
    -Ref 'ADO-OPS-016' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Disabling access to secrets from forks in organization settings prevents untrusted code from accessing sensitive information.
        Reason 'Access to secrets from forks is enabled in organization settings.'
        Recommend 'Enable `Disable access to secrets from forks` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops#protecting-branches-in-forks
        $Assert.HasField($TargetObject, "enforceNoAccessToSecretsFromForks", $true)
        $Assert.HasFieldValue($TargetObject, "enforceNoAccessToSecretsFromForks", $true)
}

# Synopsis: Implied YAML CI triggers should be disabled in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.DisableImpliedYAMLCiTrigger' `
    -Ref 'ADO-OPS-017' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Disabling implied YAML CI triggers in organization settings prevents automatic pipeline runs for unverified changes, improving security.
        Reason 'Implied YAML CI triggers are enabled in organization settings.'
        Recommend 'Enable `Disable implied YAML CI triggers` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/pipelines/security/secure-pipelines?view=azure-devops#triggers
        $Assert.HasField($TargetObject, "disableImpliedYAMLCiTrigger", $true)
        $Assert.HasFieldValue($TargetObject, "disableImpliedYAMLCiTrigger", $true)
}

# Synopsis: Auditing of settable variables should be enabled in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.EnableAuditSettableVar' `
    -Ref 'ADO-OPS-018' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Enabling auditing of settable variables in organization settings ensures that changes to pipeline variables are tracked for security and compliance.
        Reason 'Auditing of settable variables is disabled in organization settings.'
        Recommend 'Enable `Audit settable variables` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-overview?view=azure-devops
        $Assert.HasField($TargetObject, "auditEnforceSettableVar", $true)
        $Assert.HasFieldValue($TargetObject, "auditEnforceSettableVar", $true)
}

# Synopsis: Task lockdown feature should be enabled in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.EnableTaskLockdown' `
    -Ref 'ADO-OPS-019' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Enabling the task lockdown feature in organization settings restricts the use of unauthorized tasks, enhancing pipeline security.
        Reason 'Task lockdown feature is disabled in organization settings.'
        Recommend 'Enable `Task lockdown feature` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/pipelines/security/secure-pipelines?view=azure-devops#tasks
        $Assert.HasField($TargetObject, "isTaskLockdownFeatureEnabled", $true)
        $Assert.HasFieldValue($TargetObject, "isTaskLockdownFeatureEnabled", $true)
}

# Synopsis: Pipeline policies permission should be restricted in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.RestrictPipelinePoliciesPermission' `
    -Ref 'ADO-OPS-020' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Restricting pipeline policies permission in organization settings ensures that only authorized users can modify pipeline configurations.
        Reason 'Pipeline policies permission is not restricted in organization settings.'
        Recommend 'Disable `Manage pipeline policies permission` for non-administrators in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/permissions?view=azure-devops
        $Assert.HasField($TargetObject, "hasManagePipelinePoliciesPermission", $true)
        $Assert.HasFieldValue($TargetObject, "hasManagePipelinePoliciesPermission", $false)
}

# Synopsis: Comments should be required for pull requests in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForPullRequest' `
    -Ref 'ADO-OPS-021' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Requiring comments for pull requests in organization settings ensures that changes are reviewed and documented, improving code quality and traceability.
        Reason 'Comments are not required for pull requests in organization settings.'
        Recommend 'Enable `Require comments for pull requests` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops#require-a-minimum-number-of-reviewers
        $Assert.HasField($TargetObject, "isCommentRequiredForPullRequest", $true)
        $Assert.HasFieldValue($TargetObject, "isCommentRequiredForPullRequest", $true)
}

# Synopsis: Comments should be required for non-team members in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForNonTeamMembers' `
    -Ref 'ADO-OPS-022' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Requiring comments for non-team members in organization settings ensures that external contributors provide context for their changes.
        Reason 'Comments are not required for non-team members in organization settings.'
        Recommend 'Enable `Require comments for non-team members` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops#require-a-minimum-number-of-reviewers
        $Assert.HasField($TargetObject, "requireCommentsForNonTeamMembersOnly", $true)
        $Assert.HasFieldValue($TargetObject, "requireCommentsForNonTeamMembersOnly", $true)
}

# Synopsis: Comments should be required for non-team members and non-contributors in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForNonTeamAndNonContributors' `
    -Ref 'ADO-OPS-023' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Requiring comments for non-team members and non-contributors in organization settings ensures that external changes are well-documented.
        Reason 'Comments are not required for non-team members and non-contributors in organization settings.'
        Recommend 'Enable `Require comments for non-team members and non-contributors` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops#require-a-minimum-number-of-reviewers
        $Assert.HasField($TargetObject, "requireCommentsForNonTeamMemberAndNonContributors", $true)
        $Assert.HasFieldValue($TargetObject, "requireCommentsForNonTeamMemberAndNonContributors", $true)
}

# Synopsis: Auditing of shell task arguments sanitization should be enabled in organization settings
Rule 'Azure.DevOps.Organization.Pipelines.Settings.EnableShellTasksArgsSanitizingAudit' `
    -Ref 'ADO-OPS-024' `
    -Type 'Azure.DevOps.Organization.Pipelines.Settings' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Enabling auditing of shell task arguments sanitization in organization settings ensures that sanitization activities are logged for security monitoring.
        Reason 'Auditing of shell task arguments sanitization is disabled in organization settings.'
        Recommend 'Enable `Audit shell task arguments sanitization` in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/pipelines/security/secure-pipelines?view=azure-devops#tasks
        $Assert.HasField($TargetObject, "enableShellTasksArgsSanitizingAudit", $true)
        $Assert.HasFieldValue($TargetObject, "enableShellTasksArgsSanitizingAudit", $true)
}