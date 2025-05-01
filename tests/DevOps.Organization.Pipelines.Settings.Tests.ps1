BeforeAll {
    $rootPath = $PWD;
    Import-Module -Name (Join-Path -Path $rootPath -ChildPath '/src/PSRule.Rules.AzureDevOps/PSRule.Rules.AzureDevOps.psd1') -Force;
}

Describe "Functions: DevOps.OrganizationPipelinesSettings" {
    Context " Read-AdoOrganizationPipelinesSettings without a connection" {
        It " should throw an error" {
            { 
                Disconnect-AzDevOps
                Read-AdoOrganizationPipelinesSettings -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN
            } | Should -Throw "Not connected to Azure DevOps. Run Connect-AzDevOps first"
        }
    }
    Context " Read-AdoOrganizationPipelinesSettings on an organization" {
        BeforeAll {
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN
            $settings = Read-AdoOrganizationPipelinesSettings -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN
        }

        It " should return organization pipeline settings" {
            $settings | Should -Not -BeNullOrEmpty
        }

        It " should return organization pipeline settings that are of type PSObject" {
            $settings | Should -BeOfType [PSCustomObject]
        }
    }

    Context " Read-AdoOrganizationPipelinesSettings with wrong parameters" {
        It " should throw an error with a wrong AccessToken" {
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -AccessToken "wrong-token"
            { Read-AdoOrganizationPipelinesSettings -Organization $env:ADO_ORGANIZATION -AccessToken "wrong-token" -ErrorAction Stop } | Should -Throw
        }

        It " should throw a 404 error with a wrong organization" {
            Connect-AzDevOps -Organization 'wrong-org' -AccessToken $env:ADO_ACCESS_TOKEN
            { Read-AdoOrganizationPipelinesSettings -Organization 'wrong-org' -AccessToken $env:ADO_ACCESS_TOKEN -ErrorAction Stop } | Should -Throw
        }
    }

    Context " Export-AdoOrganizationPipelinesSettings without a connection" {
        It " should throw an error" {
            { 
                Disconnect-AzDevOps
                Export-AdoOrganizationPipelinesSettings -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN -OutputPath $env:ADO_EXPORT_DIR
            } | Should -Throw "Not connected to Azure DevOps. Run Connect-AzDevOps first"
        }
    }

    Context " Export-AdoOrganizationPipelinesSettings" {        
        BeforeAll {
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN
            Export-AdoOrganizationPipelinesSettings -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN -OutputPath $env:ADO_EXPORT_DIR
        }

        It " should export the pipeline settings to a .ado.json file" {
            $file = Get-ChildItem -Path $env:ADO_EXPORT_DIR -Filter 'OrganizationpipelineSettings.ado.json' -Recurse
            $file | Should -Not -BeNullOrEmpty
        }

        It " should export the pipeline settings as parsable JSON" {
            $file = Get-ChildItem -Path $env:ADO_EXPORT_DIR -Filter 'OrganizationpipelineSettings.ado.json' -Recurse
            $json = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $json | Should -Not -BeNullOrEmpty
        }

        It " should export an object with an ObjectType of Azure.DevOps.Organization.Pipelines.Settings" {
            $file = Get-ChildItem -Path $env:ADO_EXPORT_DIR -Filter 'OrganizationpipelineSettings.ado.json' -Recurse | Select-Object -First 1
            $json = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $json.ObjectType | Should -Be "Azure.DevOps.Organization.Pipelines.Settings"
        }
    }

    Context " Export-AdoOrganizationPipelinesSettings -PassThru" {
        BeforeAll {
            Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN
            $settings = Export-AdoOrganizationPipelinesSettings -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN -PassThru
            $ruleResult = $settings | Invoke-PSRule -Module @('PSRule.Rules.AzureDevOps') -Culture en
        }

        It " should return organization pipeline settings" {
            $settings | Should -Not -BeNullOrEmpty
        }

        It " should return organization pipeline settings that are of type PSObject" {
            $settings | Should -BeOfType [PSCustomObject]
        }

        It " should return organization pipeline settings with an ObjectType of Azure.DevOps.Organization.Pipelines.Settings" {
            $settings.ObjectType | Should -Be "Azure.DevOps.Organization.Pipelines.Settings"
        }

        It " should return organization pipeline settings with an ObjectName of {Organization}.OrganizationPipelineSettings" {
            $settings.ObjectName | Should -Be ("{0}.OrganizationPipelineSettings" -f $env:ADO_ORGANIZATION)
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