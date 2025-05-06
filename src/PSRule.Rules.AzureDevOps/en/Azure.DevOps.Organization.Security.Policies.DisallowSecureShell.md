---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Security.Policies.DisallowSecureShell.md  
---

# Azure.DevOps.Organization.Security.Policies.DisallowSecureShell

## SYNOPSIS

Secure Shell (SSH) authentication should be disabled.

## DESCRIPTION

Disabling SSH authentication enhances security by limiting access methods. This rule checks that the `policy.disallowSecureShell` setting is enabled in Azure DevOps organization security settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Disable SSH authentication in Azure DevOps organization security settings.

## LINKS

- [Security Best Practices](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices)
