# Azure DevOps organization General Overview settings rules

# Synopsis: Organization description should be set
Rule 'Azure.DevOps.Organization.GeneralOverview.DescriptionSet' `
    -Ref 'ADO-OGO-001' `
    -Type 'Azure.DevOps.Organization.GeneralOverview' `
    -Tag @{ release = 'GA' } `
    -Level Warning {
        # Description: Setting an organization description helps provide context and clarity for the organization's purpose.
        Reason 'The organization description is not set.'
        Recommend 'Set a meaningful description in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/settings/organization-overview?view=azure-devops
        $Assert.HasField($TargetObject, "description", $true)
        $Assert.HasFieldValue($TargetObject, "description", "Not Set") -eq $false
}

# Synopsis: Organization time zone should be set to CET
Rule 'Azure.DevOps.Organization.GeneralOverview.TimeZoneSet' `
    -Ref 'ADO-OGO-002' `
    -Type 'Azure.DevOps.Organization.GeneralOverview' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Setting the organization time zone to CET ensures that timestamps and schedules are accurate for Central European Time.
        Reason 'The organization time zone is not set to CET.'
        Recommend 'Set the time zone to CET (e.g., "(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna") in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/settings/organization-overview?view=azure-devops
        $Assert.HasField($TargetObject, "timeZone", $true)
        $Assert.HasFieldValue($TargetObject, "timeZone", "(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna")
}

# Synopsis: Organization geography should be set to Europe
Rule 'Azure.DevOps.Organization.GeneralOverview.GeographySet' `
    -Ref 'ADO-OGO-003' `
    -Type 'Azure.DevOps.Organization.GeneralOverview' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Setting the organization geography to Europe ensures compliance with regional data residency requirements for European organizations.
        Reason 'The organization geography is not set to Europe.'
        Recommend 'Set the geography to Europe in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/settings/organization-overview?view=azure-devops
        $Assert.HasField($TargetObject, "geography", $true)
        $Assert.HasFieldValue($TargetObject, "geography", "Europe")
}

# Synopsis: Organization owner should be set
Rule 'Azure.DevOps.Organization.GeneralOverview.OwnerSet' `
    -Ref 'ADO-OGO-004' `
    -Type 'Azure.DevOps.Organization.GeneralOverview' `
    -Tag @{ release = 'GA' } `
    -Level Error {
        # Description: Setting the organization owner ensures accountability and proper management of the organization.
        Reason 'The organization owner is not set.'
        Recommend 'Set an owner in Azure DevOps organization settings.'
        # Links: https://learn.microsoft.com/en-us/azure/devops/organizations/settings/organization-overview?view=azure-devops
        $Assert.HasField($TargetObject, "owner", $true)
        $Assert.HasFieldValue($TargetObject, "owner")
}