---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Pipelines.Settings.DisableClassicReleasePipelines.md  
---

# Azure.DevOps.Organization.Pipelines.Settings.DisableClassicReleasePipelines

## SYNOPSIS

Creation of classic release pipelines should be disabled in organization settings.

## DESCRIPTION

Disabling classic release pipelines in organization settings encourages the use of YAML pipelines, which are more secure and maintainable. This rule checks that the `disableClassicReleasePipelineCreation` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Disable creation of classic release pipelines" in Azure DevOps organization settings.

## LINKS

- [Security Overview](https://docs.microsoft.com/en-us/azure/devops/organizations/security/security-overview)
