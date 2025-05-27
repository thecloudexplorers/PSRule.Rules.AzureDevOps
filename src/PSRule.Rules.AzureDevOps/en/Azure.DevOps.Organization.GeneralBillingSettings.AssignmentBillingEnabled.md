---
category: Microsoft Azure DevOps Organization
severity: Severe
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.GeneralBillingSettings.AssignmentBillingEnabled.md
---

# Azure.DevOps.Organization.GeneralBillingSettings.AssignmentBillingEnabled

## SYNOPSIS

Assignment-based billing should be enabled.

## DESCRIPTION

Assignment-based billing allows flexible per-user billing and is recommended for modern Azure DevOps organizations. This rule checks that the `isAssignmentBillingEnabled` setting is enabled in Azure DevOps billing settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Enable assignment-based billing in Azure DevOps billing settings.

## LINKS

- [Change Billing Model](https://learn.microsoft.com/en-us/azure/devops/organizations/billing/change-billing-model)
