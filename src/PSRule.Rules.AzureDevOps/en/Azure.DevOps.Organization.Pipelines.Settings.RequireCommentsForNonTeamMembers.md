---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForNonTeamMembers.md  
---

# Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForNonTeamMembers

## SYNOPSIS

Comments should be required for non-team members in organization settings.

## DESCRIPTION

Requiring comments for non-team members in organization settings ensures that external contributors provide context for their changes. This rule checks that the `requireCommentsForNonTeamMembersOnly` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Require comments for non-team members" in Azure DevOps organization settings.

## LINKS

- [Require Reviewers](https://learn.microsoft.com/en-us/azure/devops/organizations/security/require-reviewers)
