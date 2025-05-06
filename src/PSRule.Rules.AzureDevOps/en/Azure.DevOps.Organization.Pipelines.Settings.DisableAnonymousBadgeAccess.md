---
category: Microsoft Azure DevOps Organization
severity: Severe
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Pipelines.Settings.DisableAnonymousBadgeAccess.md
---

# Azure.DevOps.Organization.Pipelines.Settings.DisableAnonymousBadgeAccess

## SYNOPSIS

Anonymous access to organization pipeline status badges should be disabled.

## DESCRIPTION

Disabling anonymous access to organization pipeline status badges prevents unauthorized access to pipeline status. This rule checks that the `statusBadgesArePrivate` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Disable anonymous access to badges" in Azure DevOps organization settings.

## LINKS

- [Security Overview](https://docs.microsoft.com/en-us/azure/devops/organizations/security/security-overview)
