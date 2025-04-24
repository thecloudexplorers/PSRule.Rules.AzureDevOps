# Azure DevOps organization security policy rules

# Synopsis: Secure Shell (SSH) authentication should be disallowed
Rule 'Azure.DevOps.Organization.Security.Policies.DisallowSecureShell' `
    -Ref 'ADO-OSP-001' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Disallowing Secure Shell (SSH) authentication enhances security by limiting authentication methods to more controlled mechanisms.
        Reason 'Secure Shell (SSH) authentication is allowed.'
        Recommend 'Disabla `Secure Shell (SSH) authentication` in Azure DevOps organization security policy settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops
        $Assert.HasField($TargetObject, "policy.DisallowSecureShell", $true)
        $Assert.HasFieldValue($TargetObject, "policy.DisallowSecureShell", $true)
}

# Synopsis: External package protection token for artifacts should be enabled
Rule 'Azure.DevOps.Organization.Security.Policies.ArtifactsExternalPackageProtectionToken' `
    -Ref 'ADO-OSP-002' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Enabling external package protection tokens for artifacts ensures secure access to external packages.
        Reason 'External package protection token for artifacts is disabled.'
        Recommend 'Enable `Artifacts external package protection token` in Azure DevOps organization security policy settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops
        $Assert.HasField($TargetObject, "policy.ArtifactsExternalPackageProtectionToken", $true)
        $Assert.HasFieldValue($TargetObject, "policy.ArtifactsExternalPackageProtectionToken", $true)
}

# Synopsis: Azure Active Directory (AAD) guest user access should be disallowed
Rule 'Azure.DevOps.Organization.Security.Policies.DisallowAadGuestUserAccess' `
    -Ref 'ADO-OSP-003' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Disallowing AAD guest user access prevents external users from accessing organization resources, reducing security risks.
        Reason 'AAD guest user access is allowed.'
        Recommend 'Disable `External guest access` in Azure DevOps organization security policy settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops
        $Assert.HasField($TargetObject, "policy.DisallowAadGuestUserAccess", $true)
        $Assert.HasFieldValue($TargetObject, "policy.DisallowAadGuestUserAccess", $true)
}

# Synopsis: Anonymous access to the organization should be disallowed
Rule 'Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess' `
    -Ref 'ADO-OSP-004' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Disallowing anonymous access prevents unauthorized users from accessing organization resources.
        Reason 'Anonymous access to the organization is allowed.'
        Recommend 'Disable `Allow anonymous access` in Azure DevOps organization security policy settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops
        $Assert.HasField($TargetObject, "policy.AllowAnonymousAccess", $true)
        $Assert.HasFieldValue($TargetObject, "policy.AllowAnonymousAccess", $false)
}

# Synopsis: Team admins should not be allowed to send invitations using access token
Rule 'Azure.DevOps.Organization.Security.Policies.DisallowTeamAdminsInvitationsAccessToken' `
    -Ref 'ADO-OSP-005' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Disallowing team admins from sending invitations ensures centralized control over user access by organization admins.
        Reason 'Team admins are allowed to send invitations using access tokens.'
        Recommend 'Disable `Allow team admins invitations access token` in Azure DevOps organization security policy settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops
        $Assert.HasField($TargetObject, "policy.AllowTeamAdminsInvitationsAccessToken", $true)
        $Assert.HasFieldValue($TargetObject, "policy.AllowTeamAdminsInvitationsAccessToken", $false)
}

# Synopsis: Feedback collection should be disallowed for the organization
Rule 'Azure.DevOps.Organization.Security.Policies.DisallowFeedbackCollection' `
    -Ref 'ADO-OSP-006' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Disallowing feedback collection protects user privacy by preventing data sharing with Microsoft.
        Reason 'Feedback collection is allowed for the organization.'
        Recommend 'Disable `Allow feedback collection` in Azure DevOps organization security policy settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops
        $Assert.HasField($TargetObject, "policy.AllowFeedbackCollection", $true)
        $Assert.HasFieldValue($TargetObject, "policy.AllowFeedbackCollection", $false)
}

# Synopsis: Logging of audit events should be enabled
Rule 'Azure.DevOps.Organization.Security.Policies.EnableLogAuditEvents' `
    -Ref 'ADO-OSP-007' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Enabling audit event logging is critical for security monitoring and compliance with regulatory requirements.
        Reason 'Logging of audit events is disabled.'
        Recommend 'Enable `Log audit events` in Azure DevOps organization security policy settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops
        $Assert.HasField($TargetObject, "policy.LogAuditEvents", $true)
        $Assert.HasFieldValue($TargetObject, "policy.LogAuditEvents", $true)
}

# Synopsis: Request access token for authentication should be disallowed
Rule 'Azure.DevOps.Organization.Security.Policies.DisallowRequestAccessToken' `
    -Ref 'ADO-OSP-008' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Disallowing request access tokens reduces the risk of unauthorized access requests.
        Reason 'Request access token for authentication is allowed.'
        Recommend 'Disable `Allow request access token` in Azure DevOps organization security policy settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops
        $Assert.HasField($TargetObject, "policy.AllowRequestAccessToken", $true)
        $Assert.HasFieldValue($TargetObject, "policy.AllowRequestAccessToken", $false)
}

# Synopsis: OAuth authentication should be allowed
Rule 'Azure.DevOps.Organization.Security.Policies.AllowOAuthAuthentication' `
    -Ref 'ADO-OSP-009' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Allowing OAuth authentication supports integration with external services while maintaining security.
        Reason 'OAuth authentication is disallowed.'
        Recommend 'Disable `Disallow OAuth authentication` in Azure DevOps organization security policy settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops
        $Assert.HasField($TargetObject, "policy.DisallowOAuthAuthentication", $true)
        $Assert.HasFieldValue($TargetObject, "policy.DisallowOAuthAuthentication", $false)
}

# Synopsis: AAD conditional access enforcement should be enabled
Rule 'Azure.DevOps.Organization.Security.Policies.EnforceAADConditionalAccess' `
    -Ref 'ADO-OSP-010' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Enforcing AAD conditional access applies multifactor authentication and other security policies, enhancing authentication security.
        Reason 'AAD conditional access enforcement is disabled.'
        Recommend 'Enable `Enforce AAD conditional access` in Azure DevOps organization security policy settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices?view=azure-devops
        $Assert.HasField($TargetObject, "policy.EnforceAADConditionalAccess", $true)
        $Assert.HasFieldValue($TargetObject, "policy.EnforceAADConditionalAccess", $true)
}