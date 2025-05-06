---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Security.Policies.DisallowAadGuestUserAccess.md  
---

# Azure.DevOps.Organization.Security.Policies.DisallowAadGuestUserAccess

## SYNOPSIS

Azure AD guest user access should be disabled.

## DESCRIPTION

Disabling Azure AD guest user access restricts external users from accessing the organization. This rule checks that the `policy.disallowAadGuestUserAccess` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Disable Azure AD guest user access in Azure DevOps organization settings.

## LINKS

- [Guest Access](https://docs.microsoft.com/en-us/azure/active-directory/external-identities/what-is-b2b)
