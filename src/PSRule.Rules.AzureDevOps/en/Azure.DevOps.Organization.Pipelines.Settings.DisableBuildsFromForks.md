---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Pipelines.Settings.DisableBuildsFromForks.md  
---

# Azure.DevOps.Organization.Pipelines.Settings.DisableBuildsFromForks

## SYNOPSIS

Builds from forks should be disabled in organization settings.

## DESCRIPTION

Disabling builds from forks in organization settings reduces the risk of executing untrusted code. This rule checks that the `buildsEnabledForForks` setting is disabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Disable "Allow builds from forks" in Azure DevOps organization settings.

## LINKS

- [Protecting Branches in Forks](https://docs.microsoft.com/en-us/azure/devops/pipelines/repos/branches/fork-protection)
