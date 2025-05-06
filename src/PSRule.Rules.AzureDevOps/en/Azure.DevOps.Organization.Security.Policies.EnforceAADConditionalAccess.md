---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Security.Policies.EnforceAADConditionalAccess.md  
---

# Azure.DevOps.Organization.Security.Policies.EnforceAADConditionalAccess

## SYNOPSIS

Azure AD conditional access should be enforced.

## DESCRIPTION

Enforcing Azure AD conditional access enhances security by requiring additional authentication checks. This rule checks that the `policy.enforceAADConditionalAccess` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable Azure AD conditional access in Azure DevOps organization settings.

## LINKS

- [Conditional Access](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/overview)
