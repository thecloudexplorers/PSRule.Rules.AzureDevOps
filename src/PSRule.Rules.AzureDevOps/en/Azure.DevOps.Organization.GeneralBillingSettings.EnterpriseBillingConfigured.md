---
category: Microsoft Azure DevOps Organization
severity: Moderate
online version: https://github.com/thecloudexplorers/PSRule.Rules.AzureDevOps/tree/main/src/PSRule.Rules.AzureDevOps/en/Azure.DevOps.Organization.GeneralBillingSettings.EnterpriseBillingConfigured.md
---

# Azure.DevOps.Organization.GeneralBillingSettings.EnterpriseBillingConfigured

## SYNOPSIS

Enterprise billing should be explicitly configured.

## DESCRIPTION

Enterprise billing should be explicitly enabled or disabled based on organizational needs. This rule checks that the `isEnterpriseBillingEnabled` setting is explicitly configured in Azure DevOps billing settings.

Minimum TokenType: `FullAccess`

## RECOMMENDATION

Review and configure enterprise billing in Azure DevOps billing settings based on organizational requirements.

## LINKS

- [Enterprise Billing](https://learn.microsoft.com/en-us/azure/devops/organizations/billing/overview)
