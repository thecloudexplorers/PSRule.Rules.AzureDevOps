---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeForForks.md  
---

# Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeForForks

## SYNOPSIS

Job authorization scope for forks should be limited in organization settings.

## DESCRIPTION

Limiting job authorization scope for forks in organization settings reduces the risk of unauthorized access to resources from forked repositories. This rule checks that the `enforceJobAuthScopeForForks` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Limit job authorization scope for forks" in Azure DevOps organization settings.

## LINKS

- [Protecting Branches in Forks](https://learn.microsoft.com/en-us/azure/devops/pipelines/repos/branches/fork-protection)
