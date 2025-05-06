---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Pipelines.Settings.DisableInBoxTasksVar.md  
---

# Azure.DevOps.Organization.Pipelines.Settings.DisableInBoxTasksVar

## SYNOPSIS

In-box task variables should be disabled in organization settings.

## DESCRIPTION

Disabling in-box task variables in organization settings prevents the use of potentially outdated or insecure tasks, encouraging the use of maintained tasks. This rule checks that the `disableInBoxTasksVar` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Disable in-box task variables" in Azure DevOps organization settings.

## LINKS

- [Secure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/security/secure-pipelines)
