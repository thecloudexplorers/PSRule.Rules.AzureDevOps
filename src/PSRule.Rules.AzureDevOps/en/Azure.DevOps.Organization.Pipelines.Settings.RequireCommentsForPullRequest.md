---
category: Microsoft Azure DevOps Organization  
severity: Moderate  
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForPullRequest.md  
---

# Azure.DevOps.Organization.Pipelines.Settings.RequireCommentsForPullRequest

## SYNOPSIS

Comments should be required for pull requests in organization settings.

## DESCRIPTION

Requiring comments for pull requests in organization settings ensures that changes are reviewed and documented, improving code quality and traceability. This rule checks that the `isCommentRequiredForPullRequest` setting is enabled in Azure DevOps organization settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable "Require comments for pull requests" in Azure DevOps organization settings.

## LINKS

- [Require Reviewers](https://learn.microsoft.com/en-us/azure/devops/organizations/security/require-reviewers)
