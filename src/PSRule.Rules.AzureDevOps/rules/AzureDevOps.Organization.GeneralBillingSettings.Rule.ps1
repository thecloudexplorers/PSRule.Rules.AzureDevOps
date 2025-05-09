# Azure DevOps organization General Billing Settings rules

# Synopsis: Subscription status should be active
Rule 'Azure.DevOps.Organization.GeneralBillingSettings.SubscriptionActive' `
    -Ref 'ADO-OGB-001' `
    -Type 'Azure.DevOps.Organization.GeneralBillingSettings' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: An active subscription ensures uninterrupted access to Azure DevOps services.
        Reason 'The subscription status is not set to active.'
        Recommend 'Ensure the Azure DevOps organization subscription is active in the billing settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/billing/overview
        $Assert.HasField($TargetObject, "subscriptionStatus", $true)
        $Assert.HasFieldValue($TargetObject, "subscriptionStatus", "active")
}

# Synopsis: Enterprise billing should be explicitly configured
Rule 'Azure.DevOps.Organization.GeneralBillingSettings.EnterpriseBillingConfigured' `
    -Ref 'ADO-OGB-002' `
    -Type 'Azure.DevOps.Organization.GeneralBillingSettings' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Enterprise billing should be explicitly enabled or disabled based on organizational needs.
        Reason 'The enterprise billing setting is not explicitly configured.'
        Recommend 'Review and configure enterprise billing in Azure DevOps billing settings based on organizational requirements.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/billing/enterprise-billing
        $Assert.HasField($TargetObject, "isEnterpriseBillingEnabled", $true)
}

# Synopsis: Assignment-based billing should be enabled
Rule 'Azure.DevOps.Organization.GeneralBillingSettings.AssignmentBillingEnabled' `
    -Ref 'ADO-OGB-003' `
    -Type 'Azure.DevOps.Organization.GeneralBillingSettings' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Assignment-based billing allows flexible per-user billing and is recommended for modern Azure DevOps organizations.
        Reason 'Assignment-based billing is not enabled.'
        Recommend 'Enable assignment-based billing in Azure DevOps billing settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/billing/change-billing-model
        $Assert.HasField($TargetObject, "isAssignmentBillingEnabled", $true)
        $Assert.HasFieldValue($TargetObject, "isAssignmentBillingEnabled", $true)
}