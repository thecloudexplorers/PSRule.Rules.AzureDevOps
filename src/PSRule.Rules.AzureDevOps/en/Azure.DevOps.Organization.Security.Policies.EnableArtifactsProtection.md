---
category: Microsoft Azure DevOps Organization  
severity: Severe  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Security.Policies.EnableArtifactsProtection.md  
---

# Azure.DevOps.Organization.Security.Policies.EnableArtifactsProtection

## SYNOPSIS

External package protection for artifacts should be enabled.

## DESCRIPTION

Enabling external package protection ensures secure artifact management. This rule checks that the `policy.artifactsExternalPackageProtectionToken` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable external package protection in Azure DevOps organization settings.

## LINKS

- [Artifacts Security](https://docs.microsoft.com/en-us/azure/devops/organizations/security/artifacts-security)
