---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeRelease.md  
---

# Azure.DevOps.Organization.Pipelines.Settings.LimitJobAuthScopeRelease

## SYNOPSIS

Job authorization scope for release pipelines should be limited in organization settings.

## DESCRIPTION

Limiting job authorization scope for release pipelines in organization settings reduces the risk of unauthorized access to resources. This rule checks that the `enforceJobAuthScopeForReleases` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Limit job authorization scope for release pipelines" in Azure DevOps organization settings.

## LINKS

- [Security Overview](https://docs.microsoft.com/en-us/azure/devops/organizations/security/security-overview)
