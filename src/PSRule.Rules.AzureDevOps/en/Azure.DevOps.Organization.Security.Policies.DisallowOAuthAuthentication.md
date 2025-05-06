---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Security.Policies.DisallowOAuthAuthentication.md  
---

# Azure.DevOps.Organization.Security.Policies.DisallowOAuthAuthentication

## SYNOPSIS

OAuth authentication should be disabled.

## DESCRIPTION

Disabling OAuth authentication reduces the risk of unauthorized access via third-party applications. This rule checks that the `policy.disallowOAuthAuthentication` setting is enabled in Azure DevOps organization security settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Disable OAuth authentication in Azure DevOps organization security settings.

## LINKS

- [Security Best Practices](https://docs.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices)
