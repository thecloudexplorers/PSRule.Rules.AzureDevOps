---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess.md  
---

# Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess

## SYNOPSIS

Anonymous access should be disabled.

## DESCRIPTION

Disabling anonymous access prevents unauthorized users from viewing public projects. This rule checks that the `policy.allowAnonymousAccess` setting is disabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Disable anonymous access in Azure DevOps organization settings.

## LINKS

- [Permissions](https://docs.microsoft.com/en-us/azure/devops/organizations/security/permissions)
