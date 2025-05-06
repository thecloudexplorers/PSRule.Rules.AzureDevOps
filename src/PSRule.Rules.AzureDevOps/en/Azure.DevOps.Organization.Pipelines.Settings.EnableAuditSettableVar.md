---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Pipelines.Settings.EnableAuditSettableVar.md  
---

# Azure.DevOps.Organization.Pipelines.Settings.EnableAuditSettableVar

## SYNOPSIS

Auditing of settable variables should be enabled in organization settings.

## DESCRIPTION

Enabling auditing of settable variables in organization settings ensures that changes to pipeline variables are tracked for security and compliance. This rule checks that the `auditEnforceSettableVar` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Audit settable variables" in Azure DevOps organization settings.

## LINKS

- [Security Overview](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-overview)
