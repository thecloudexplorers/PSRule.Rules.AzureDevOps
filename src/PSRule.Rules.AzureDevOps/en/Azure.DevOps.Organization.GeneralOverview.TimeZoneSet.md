---
category: Microsoft Azure DevOps Organization
severity: Severe
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.GeneralOverview.TimeZoneSet.md
---

# Azure.DevOps.Organization.GeneralOverview.TimeZoneSet

## SYNOPSIS

Organization time zone should be set to CET.

## DESCRIPTION

Setting the organization time zone to CET ensures that timestamps and schedules are accurate for Central European Time. This rule checks that the `timeZone` setting is set to `"(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna"` in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Set the time zone to CET (e.g., `"(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna"`) in Azure DevOps organization settings.

## LINKS

- [Organization Overview](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/organization-overview)
