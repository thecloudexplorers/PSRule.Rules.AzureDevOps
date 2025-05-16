---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Security.Policies.EnableLogAuditEvents.md  
---

# Azure.DevOps.Organization.Security.Policies.EnableLogAuditEvents

## SYNOPSIS

Audit event logging should be enabled.

## DESCRIPTION

Enabling audit event logging ensures that all actions are tracked for security and compliance. This rule checks that the `policy.logAuditEvents` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable audit event logging in Azure DevOps organization settings.

## LINKS

- [Auditing](https://docs.microsoft.com/en-us/azure/devops/organizations/security/auditing)
