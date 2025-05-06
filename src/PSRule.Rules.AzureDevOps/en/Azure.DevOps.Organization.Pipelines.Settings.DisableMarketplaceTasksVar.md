---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Pipelines.Settings.DisableMarketplaceTasksVar.md  
---

# Azure.DevOps.Organization.Pipelines.Settings.DisableMarketplaceTasksVar

## SYNOPSIS

Marketplace task variables should be disabled in organization settings.

## DESCRIPTION

Disabling marketplace task variables in organization settings reduces the risk of using unverified or malicious tasks from the marketplace. This rule checks that the `disableMarketplaceTasksVar` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Disable marketplace task variables" in Azure DevOps organization settings.

## LINKS

- [Secure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/security/secure-pipelines)
