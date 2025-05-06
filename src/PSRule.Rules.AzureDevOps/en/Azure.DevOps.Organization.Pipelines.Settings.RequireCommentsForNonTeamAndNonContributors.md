---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForNonTeamAndNonContributors.md  
---

# Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForNonTeamAndNonContributors

## SYNOPSIS

Comments should be required for non-team members and non-contributors in organization settings.

## DESCRIPTION

Requiring comments for non-team members and non-contributors in organization settings ensures that external changes are well-documented. This rule checks that the `requireCommentsForNonTeamMemberAndNonContributors` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Require comments for non-team members and non-contributors" in Azure DevOps organization settings.

## LINKS

- [Require Reviewers](https://learn.microsoft.com/en-us/azure/devops/organizations/security/require-reviewers)
