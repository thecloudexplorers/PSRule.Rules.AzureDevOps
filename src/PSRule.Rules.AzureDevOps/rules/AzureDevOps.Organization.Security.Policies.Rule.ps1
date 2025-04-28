# Azure DevOps organization Security Policies rules

# Synopsis: Debug rule to confirm target object type and properties
Rule 'Azure.DevOps.Organization.Security.Policies.Debug' `
    -Ref 'ADO-OSP-DEBUG' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Information {
        # Description: Verifies that the target object has the expected type and properties.
        Reason 'Debug rule failed to verify target object properties.'
        Recommend 'Ensure the input JSON contains the correct ObjectType and properties.'
        try {
            Write-Verbose "Debug: TargetObject Type: $($TargetObject.ObjectType)"
            Write-Verbose "Debug: TargetObject Properties: $($TargetObject | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name })"
            Write-Verbose "Debug: Raw Policy Values:"
            Write-Verbose "  disallowSecureShell: $($TargetObject.'policy.disallowSecureShell')"
            Write-Verbose "  allowRequestAccessToken: $($TargetObject.'policy.allowRequestAccessToken')"
            Write-Verbose "  allowTeamAdminsInvitationsAccessToken: $($TargetObject.'policy.allowTeamAdminsInvitationsAccessToken')"
            Write-Verbose "  allowFeedbackCollection: $($TargetObject.'policy.allowFeedbackCollection')"
            Write-Verbose "  enforceAADConditionalAccess: $($TargetObject.'policy.enforceAADConditionalAccess')"
            Write-Verbose "  disallowOAuthAuthentication: $($TargetObject.'policy.disallowOAuthAuthentication')"
            Write-Verbose "  logAuditEvents: $($TargetObject.'policy.logAuditEvents')"
            Write-Verbose "  artifactsExternalPackageProtectionToken: $($TargetObject.'policy.artifactsExternalPackageProtectionToken')"
            Write-Verbose "  allowAnonymousAccess: $($TargetObject.'policy.allowAnonymousAccess')"
            Write-Verbose "  disallowAadGuestUserAccess: $($TargetObject.'policy.disallowAadGuestUserAccess')"
            $Assert.Pass()
        }
        catch {
            Write-Error "Debug rule exception: $_"
            $Assert.Fail("Debug rule failed due to an exception.")
        }
}

# Synopsis: Secure Shell (SSH) authentication should be disabled
Rule 'Azure.DevOps.Organization.Security.Policies.DisallowSecureShell' `
    -Ref 'ADO-OSP-001' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Disabling SSH authentication enhances security by limiting access methods.
        Reason 'SSH authentication is not disabled.'
        Recommend 'Disable SSH authentication in Azure DevOps organization security settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices
        try {
            Write-Verbose "Checking policy.disallowSecureShell: $($TargetObject.'policy.disallowSecureShell')"
            if ($TargetObject.'policy.disallowSecureShell' -eq $true) {
                $Assert.Pass()
            } else {
                $Assert.Fail('SSH authentication is not disabled.')
            }
        }
        catch {
            Write-Error "Rule ADO-OSP-001 exception: $_"
            $Assert.Fail("Rule failed due to an exception.")
        }
}

# Synopsis: Request access token should be disabled
Rule 'Azure.DevOps.Organization.Security.Policies.DisallowRequestAccessToken' `
    -Ref 'ADO-OSP-002' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Disabling request access tokens prevents unauthorized access requests.
        Reason 'Request access token is not disabled.'
        Recommend 'Disable request access token in Azure DevOps organization security settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/manage-personal-access-tokens
        try {
            Write-Verbose "Checking policy.allowRequestAccessToken: $($TargetObject.'policy.allowRequestAccessToken')"
            if ($TargetObject.'policy.allowRequestAccessToken' -eq $false) {
                $Assert.Pass()
            } else {
                $Assert.Fail('Request access token is not disabled.')
            }
        }
        catch {
            Write-Error "Rule ADO-OSP-002 exception: $_"
            $Assert.Fail("Rule failed due to an exception.")
        }
}

# Synopsis: Team admins should not manage invitations
Rule 'Azure.DevOps.Organization.Security.Policies.DisallowTeamAdminsInvitations' `
    -Ref 'ADO-OSP-003' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Preventing team admins from managing invitations centralizes user management.
        Reason 'Team admins are allowed to manage invitations.'
        Recommend 'Disable team admin invitation management in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/permissions
        try {
            Write-Verbose "Checking policy.allowTeamAdminsInvitationsAccessToken: $($TargetObject.'policy.allowTeamAdminsInvitationsAccessToken')"
            if ($TargetObject.'policy.allowTeamAdminsInvitationsAccessToken' -eq $false) {
                $Assert.Pass()
            } else {
                $Assert.Fail('Team admins are allowed to manage invitations.')
            }
        }
        catch {
            Write-Error "Rule ADO-OSP-003 exception: $_"
            $Assert.Fail("Rule failed due to an exception.")
        }
}

# Synopsis: Feedback collection should be disabled
Rule 'Azure.DevOps.Organization.Security.Policies.DisallowFeedbackCollection' `
    -Ref 'ADO-OSP-004' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Disabling feedback collection protects user privacy.
        Reason 'Feedback collection is not disabled.'
        Recommend 'Disable feedback collection in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/settings/privacy
        try {
            Write-Verbose "Checking policy.allowFeedbackCollection: $($TargetObject.'policy.allowFeedbackCollection')"
            if ($TargetObject.'policy.allowFeedbackCollection' -eq $false) {
                $Assert.Pass()
            } else {
                $Assert.Fail('Feedback collection is not disabled.')
            }
        }
        catch {
            Write-Error "Rule ADO-OSP-004 exception: $_"
            $Assert.Fail("Rule failed due to an exception.")
        }
}

# Synopsis: Azure AD conditional access should be enforced
Rule 'Azure.DevOps.Organization.Security.Policies.EnforceAADConditionalAccess' `
    -Ref 'ADO-OSP-005' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Enforcing Azure AD conditional access enhances security by requiring additional authentication checks.
        Reason 'Azure AD conditional access is not enforced.'
        Recommend 'Enable Azure AD conditional access in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/conditional-access
        try {
            Write-Verbose "Checking policy.enforceAADConditionalAccess: $($TargetObject.'policy.enforceAADConditionalAccess')"
            if ($TargetObject.'policy.enforceAADConditionalAccess' -eq $true) {
                $Assert.Pass()
            } else {
                $Assert.Fail('Azure AD conditional access is not enforced.')
            }
        }
        catch {
            Write-Error "Rule ADO-OSP-005 exception: $_"
            $Assert.Fail("Rule failed due to an exception.")
        }
}

# Synopsis: OAuth authentication should be disabled
Rule 'Azure.DevOps.Organization.Security.Policies.DisallowOAuthAuthentication' `
    -Ref 'ADO-OSP-006' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Disabling OAuth authentication reduces the risk of unauthorized access via third-party applications.
        Reason 'OAuth authentication is not disabled.'
        Recommend 'Disable OAuth authentication in Azure DevOps organization security settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices
        try {
            Write-Verbose "Checking policy.disallowOAuthAuthentication: $($TargetObject.'policy.disallowOAuthAuthentication')"
            if ($TargetObject.'policy.disallowOAuthAuthentication' -eq $true) {
                $Assert.Pass()
            } else {
                $Assert.Fail('OAuth authentication is not disabled.')
            }
        }
        catch {
            Write-Error "Rule ADO-OSP-006 exception: $_"
            $Assert.Fail("Rule failed due to an exception.")
        }
}

# Synopsis: Audit event logging should be enabled
Rule 'Azure.DevOps.Organization.Security.Policies.EnableLogAuditEvents' `
    -Ref 'ADO-OSP-007' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Enabling audit event logging ensures that all actions are tracked for security and compliance.
        Reason 'Audit event logging is not enabled.'
        Recommend 'Enable audit event logging in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/audit/auditing
        try {
            Write-Verbose "Checking policy.logAuditEvents: $($TargetObject.'policy.logAuditEvents')"
            if ($TargetObject.'policy.logAuditEvents' -eq $true) {
                $Assert.Pass()
            } else {
                $Assert.Fail('Audit event logging is not enabled.')
            }
        }
        catch {
            Write-Error "Rule ADO-OSP-007 exception: $_"
            $Assert.Fail("Rule failed due to an exception.")
        }
}

# Synopsis: External package protection for artifacts should be enabled
Rule 'Azure.DevOps.Organization.Security.Policies.EnableArtifactsProtection' `
    -Ref 'ADO-OSP-008' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Enabling external package protection ensures secure artifact management.
        Reason 'External package protection for artifacts is not enabled.'
        Recommend 'Enable external package protection in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/artifacts/security
        try {
            Write-Verbose "Checking policy.artifactsExternalPackageProtectionToken: $($TargetObject.'policy.artifactsExternalPackageProtectionToken')"
            if ($TargetObject.'policy.artifactsExternalPackageProtectionToken' -eq $true) {
                $Assert.Pass()
            } else {
                $Assert.Fail('External package protection for artifacts is not enabled.')
            }
        }
        catch {
            Write-Error "Rule ADO-OSP-008 exception: $_"
            $Assert.Fail("Rule failed due to an exception.")
        }
}

# Synopsis: Anonymous access should be disabled
Rule 'Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess' `
    -Ref 'ADO-OSP-009' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Disabling anonymous access prevents unauthorized users from viewing public projects.
        Reason 'Anonymous access is not disabled.'
        Recommend 'Disable anonymous access in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/permissions
        try {
            Write-Verbose "Checking policy.allowAnonymousAccess: $($TargetObject.'policy.allowAnonymousAccess')"
            if ($TargetObject.'policy.allowAnonymousAccess' -eq $false) {
                $Assert.Pass()
            } else {
                $Assert.Fail('Anonymous access is not disabled.')
            }
        }
        catch {
            Write-Error "Rule ADO-OSP-009 exception: $_"
            $Assert.Fail("Rule failed due to an exception.")
        }
}

# Synopsis: Azure AD guest user access should be disabled
Rule 'Azure.DevOps.Organization.Security.Policies.DisallowAadGuestUserAccess' `
    -Ref 'ADO-OSP-010' `
    -Type 'Azure.DevOps.Organization.Security.Policies' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Disabling Azure AD guest user access restricts external users from accessing the organization.
        Reason 'Azure AD guest user access is not disabled.'
        Recommend 'Disable Azure AD guest user access in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/security/guest-access
        try {
            Write-Verbose "Checking policy.disallowAadGuestUserAccess: $($TargetObject.'policy.disallowAadGuestUserAccess')"
            if ($TargetObject.'policy.disallowAadGuestUserAccess' -eq $true) {
                $Assert.Pass()
            } else {
                $Assert.Fail('Azure AD guest user access is not disabled.')
            }
        }
        catch {
            Write-Error "Rule ADO-OSP-010 exception: $_"
            $Assert.Fail("Rule failed due to an exception.")
        }
}