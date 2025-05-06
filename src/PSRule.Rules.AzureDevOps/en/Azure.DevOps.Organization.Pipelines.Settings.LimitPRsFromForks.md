---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Pipelines.Settings.LimitPRsFromForks.md  
---

# Azure.DevOps.Organization.Pipelines.Settings.LimitPRsFromForks

## SYNOPSIS

Pull requests from forks should be limited in organization settings.

## DESCRIPTION

Limiting pull requests from forks in organization settings prevents unauthorized code execution in pipelines. This rule checks that the `forkProtectionEnabled` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Limit pull requests from forks" in Azure DevOps organization settings.

## LINKS

- [Protecting Branches in Forks](https://docs.microsoft.com/en-us/azure/devops/pipelines/repos/branches/fork-protection)
