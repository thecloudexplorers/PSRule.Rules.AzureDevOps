---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Security.Policies.DisallowFeedbackCollection.md  
---

# Azure.DevOps.Organization.Security.Policies.DisallowFeedbackCollection

## SYNOPSIS

Feedback collection should be disabled.

## DESCRIPTION

Disabling feedback collection protects user privacy. This rule checks that the `policy.allowFeedbackCollection` setting is disabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Disable feedback collection in Azure DevOps organization settings.

## LINKS

- [Privacy Settings](https://learn.microsoft.com/en-us/azure/devops/organizations/security/privacy-settings)
