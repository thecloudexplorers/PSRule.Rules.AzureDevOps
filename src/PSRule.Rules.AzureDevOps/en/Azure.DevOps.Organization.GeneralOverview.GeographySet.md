---
category: Microsoft Azure DevOps Organization
severity: Severe
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.GeneralOverview.GeographySet.md
---

# Azure.DevOps.Organization.GeneralOverview.GeographySet

## SYNOPSIS

Organization geography should be set to Europe.

## DESCRIPTION

Setting the organization geography to Europe ensures compliance with regional data residency requirements for European organizations. This rule checks that the `geography` setting is set to `"Europe"` in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Set the geography to Europe in Azure DevOps organization settings.

## LINKS

- [Organization Overview](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/organization-overview)
