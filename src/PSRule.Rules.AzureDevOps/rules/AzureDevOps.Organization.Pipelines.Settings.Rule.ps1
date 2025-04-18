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