---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Pipelines.Settings.DisableNode6TasksVar.md  
---

# Azure.DevOps.Organization.Pipelines.Settings.DisableNode6TasksVar

## SYNOPSIS

Node 6 tasks should be disabled in organization settings.

## DESCRIPTION

Disabling Node 6 tasks in organization settings prevents the use of deprecated and potentially insecure tasks that rely on Node 6. This rule checks that the `disableNode6TasksVar` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Disable Node 6 tasks" in Azure DevOps organization settings.

## LINKS

- [Secure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/security/secure-pipelines)
