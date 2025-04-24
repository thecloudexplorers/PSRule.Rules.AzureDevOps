BeforeAll {
    $rootPath = $PWD;
    Import-Module -Name (Join-Path -Path $rootPath -ChildPath '/src/PSRule.Rules.AzureDevOps/PSRule.Rules.AzureDevOps.psd1') -Force;
}

Describe "Functions: DevOps.OrganizationSecurityPolicies" {
    Context " Read-AdoOrganizationSecurityPolicies without a connection" {
        It " should throw an error" {
            { 
                Disconnect-AzDevOps
                Read-AdoOrganizationSecurityPolicies -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN
            } | Should -Throw "Not connected to Azure DevOps. Run Connect-AzDevOps first"
        }
    }

    Context " Read-AdoOrganizationSecurityPolicies on an organization" {
        BeforeAll {
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN
            $policies = Read-AdoOrganizationSecurityPolicies -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN
        }

        It " should return organization security policies" {
            $policies | Should -Not -BeNullOrEmpty
        }

        It " should return organization security policies that are of type PSObject" {
            $policies | Should -BeOfType [PSCustomObject]
        }
    }

    Context " Read-AdoOrganizationSecurityPolicies with wrong parameters" {
        It " should throw an error with a wrong AccessToken" {
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -AccessToken "wrong-token"
            { Read-AdoOrganizationSecurityPolicies -Organization $env:ADO_ORGANIZATION -AccessToken "wrong-token" -ErrorAction Stop } | Should -Throw
        }

        It " should throw a 404 error with a wrong organization" {
            Connect-AzDevOps -Organization 'wrong-org' -AccessToken $env:ADO_ACCESS_TOKEN
            { Read-AdoOrganizationSecurityPolicies -Organization 'wrong-org' -AccessToken $env:ADO_ACCESS_TOKEN -ErrorAction Stop } | Should -Throw
        }
    }

    Context " Export-AdoOrganizationSecurityPolicies without a connection" {
        It " should throw an error" {
            { 
                Disconnect-AzDevOps
                Export-AdoOrganizationSecurityPolicies -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN -OutputPath $env:ADO_EXPORT_DIR
            } | Should -Throw "Not connected to Azure DevOps. Run Connect-AzDevOps first"
        }
    }

    Context " Export-AdoOrganizationSecurityPolicies" {        
        BeforeAll {
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN
            Export-AdoOrganizationSecurityPolicies -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN -OutputPath $env:ADO_EXPORT_DIR
        }

        It " should export the security policies to a .ado.json file" {
            $file = Get-ChildItem -Path $env:ADO_EXPORT_DIR -Filter 'OrganizationSecurityPolicies.ado.json' -Recurse
            $file | Should -Not -BeNullOrEmpty
        }

        It " should export the security policies as parsable JSON" {
            $file = Get-ChildItem -Path $env:ADO_EXPORT_DIR -Filter 'OrganizationSecurityPolicies.ado.json' -Recurse
            $json = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $json | Should -Not -BeNullOrEmpty
        }

        It " should export an object with an ObjectType of Azure.DevOps.Organization.Security.Policies" {
            $file = Get-ChildItem -Path $env:ADO_EXPORT_DIR -Filter 'OrganizationSecurityPolicies.ado.json' -Recurse | Select subj-Object -First 1
            $json = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $json.ObjectType | Should -Be "Azure.DevOps.Organization.Security.Policies"
        }
    }

    Context " Export-AdoOrganizationSecurityPolicies -PassThru" {
        BeforeAll {
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN
            $policies = Export-AdoOrganizationSecurityPolicies -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN -PassThru
            $ruleResult = $policies | Invoke-PSRule -Module @('PSRule.Rules.AzureDevOps') -Culture en
        }

        It " should return organization security policies" {
            $policies | Should -Not -BeNullOrEmpty
        }

        It " should return organization security policies that are of type PSObject" {
            $policies | Should -BeOfType [PSCustomObject]
        }

        It " should return organization security policies with an ObjectType of Azure.DevOps.Organization.Security.Policies" {
            $policies.ObjectType | Should -Be "Azure.DevOps.Organization.Security.Policies"
        }

        It " should return organization security policies with an ObjectName of {Organization}.OrganizationSecurityPolicies" {
            $policies.ObjectName | Should -Be ("{0}.OrganizationSecurityPolicies" -f $env:ADO_ORGANIZATION)
        }

        It " The output should have results with Invoke-PSRule" {
            $ruleResult | Should -Not -BeNullOrEmpty
        }

        It " The output should have results with Invoke-PSRule that are of type [PSRule.Rules.RuleRecord]" {
            $ruleResult[0] | Should -BeOfType [PSRule.Rules.RuleRecord]
        }
    }
}

AfterAll {
    Disconnect-AzDevOps
    Remove-Module -Name PSRule.Rules.AzureDevOps -Force;
}