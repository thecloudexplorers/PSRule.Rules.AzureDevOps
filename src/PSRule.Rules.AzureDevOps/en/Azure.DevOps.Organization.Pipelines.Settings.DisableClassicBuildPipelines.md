---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Pipelines.Settings.DisableClassicBuildPipelines.md  
---

# Azure.DevOps.Organization.Pipelines.Settings.DisableClassicBuildPipelines

## SYNOPSIS

Creation of classic build pipelines should be disabled in organization settings.

## DESCRIPTION

Disabling classic build pipelines in organization settings encourages the use of YAML pipelines, which are more secure and maintainable. This rule checks that the `disableClassicBuildPipelineCreation` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Disable creation of classic build pipelines" in Azure DevOps organization settings.

## LINKS

- [Security Overview](https://docs.microsoft.com/en-us/azure/devops/organizations/security/security-overview)
