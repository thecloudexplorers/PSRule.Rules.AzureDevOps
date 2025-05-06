---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Pipelines.Settings.DisableImpliedYAMLCiTrigger.md  
---

# Azure.DevOps.Organization.Pipelines.Settings.DisableImpliedYAMLCiTrigger

## SYNOPSIS

Implied YAML CI triggers should be disabled in organization settings.

## DESCRIPTION

Disabling implied YAML CI triggers in organization settings prevents automatic pipeline runs for unverified changes, improving security. This rule checks that the `disableImpliedYAMLCiTrigger` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Disable implied YAML CI triggers" in Azure DevOps organization settings.

## LINKS

- [Secure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/security/secure-pipelines)
