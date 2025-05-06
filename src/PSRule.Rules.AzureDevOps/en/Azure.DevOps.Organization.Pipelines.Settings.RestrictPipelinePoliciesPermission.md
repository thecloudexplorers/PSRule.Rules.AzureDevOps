---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Pipelines.Settings.RestrictPipelinePoliciesPermission.md  
---

# Azure.DevOps.Organization.Pipelines.Settings.RestrictPipelinePoliciesPermission

## SYNOPSIS

Pipeline policies permission should be restricted in organization settings.

## DESCRIPTION

Restricting pipeline policies permission in organization settings ensures that only authorized users can modify pipeline configurations. This rule checks that the `hasManagePipelinePoliciesPermission` setting is disabled for non-administrators in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Disable "Manage pipeline policies permission" for non-administrators in Azure DevOps organization settings.

## LINKS

- [Permissions](https://learn.microsoft.com/en-us/azure/devops/organizations/security/permissions)
