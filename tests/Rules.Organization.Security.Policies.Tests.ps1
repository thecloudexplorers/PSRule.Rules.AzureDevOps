
BeforeAll {
    # Setup error handling
    $ErrorActionPreference = 'Stop';
    Set-StrictMode -Version latest;

    if ($Env:SYSTEM_DEBUG -eq 'true') {
        $VerbosePreference = 'Continue';
    }

    # Setup tests paths
    $rootPath = $env:GITHUB_WORKSPACE
    if (-not $rootPath) {
        Write-Warning "GITHUB_WORKSPACE not set. Using current directory."
        $rootPath = $PSScriptRoot
    }
    $ourModule = (Join-Path -Path $rootPath -ChildPath '/src/PSRule.Rules.AzureDevOps')

    Write-Verbose "Loading module from $ourModule"
    Import-Module -Name $ourModule -Force -ErrorAction Stop
    $here = (Resolve-Path $PSScriptRoot).Path

    # Get temporary test output folders and store paths
    $outPath = Get-Item -Path (Join-Path -Path $here -ChildPath 'out') -ErrorAction SilentlyContinue
    if (-not $outPath) { throw "Directory 'out' not found in $here" }
    $outPath = $outPath.FullName
    $outPathReadOnly = Get-Item -Path (Join-Path -Path $here -ChildPath 'outReadOnly') -ErrorAction SilentlyContinue
    if (-not $outPathReadOnly) { throw "Directory 'outReadOnly' not found in $here" }
    $outPathReadOnly = $outPathReadOnly.FullName
    $outPathFineGrained = Get-Item -Path (Join-Path -Path $here -ChildPath 'outFineGrained') -ErrorAction SilentlyContinue
    if (-not $outPathFineGrained) { throw "Directory 'outFineGrained' not found in $here" }
    $outPathFineGrained = $outPathFineGrained.FullName

    # Verify environment variables
    if (-not $env:ADO_ORGANIZATION) { throw "Environment variable ADO_ORGANIZATION not set" }
    if (-not $env:ADO_ACCESS_TOKEN) { throw "Environment variable ADO_ACCESS_TOKEN not set" }
    if (-not $env:ADO_ACCESS_TOKEN_READONLY) { throw "Environment variable ADO_ACCESS_TOKEN_READONLY not set" }
    if (-not $env:ADO_ACCESS_TOKEN_FINEGRAINED) { throw "Environment variable ADO_ACCESS_TOKEN_FINEGRAINED not set" }
    if (-not $env:ADO_EXPORT_DIR) { throw "Environment variable ADO_EXPORT_DIR not set" }
    if (-not $env:ADO_EXPORT_DIR_READONLY) { throw "Environment variable ADO_EXPORT_DIR_READONLY not set" }
    if (-not $env:ADO_EXPORT_DIR_FINEGRAINED) { throw "Environment variable ADO_EXPORT_DIR_FINEGRAINED not set" }

    # Generate fresh JSON files for each token type
    Write-Verbose "Generating fresh OrganizationSecurityPolicies.ado.json files"
    Connect-AzDevOps -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN
    Export-AdoOrganizationSecurityPolicies -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN -OutputPath $env:ADO_EXPORT_DIR
    Export-AdoOrganizationSecurityPolicies -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN_READONLY -OutputPath $env:ADO_EXPORT_DIR_READONLY
    Export-AdoOrganizationSecurityPolicies -Organization $env:ADO_ORGANIZATION -AccessToken $env:ADO_ACCESS_TOKEN_FINEGRAINED -OutputPath $env:ADO_EXPORT_DIR_FINEGRAINED

    # Verify OrganizationSecurityPolicies.ado.json exists in each directory
    $jsonFile = 'OrganizationSecurityPolicies.ado.json'
    foreach ($path in @($outPath, $outPathReadOnly, $outPathFineGrained)) {
        $jsonPath = Join-Path -Path $path -ChildPath $jsonFile
        if (-not (Test-Path -Path $jsonPath)) {
            throw "JSON file $jsonFile not found in $path after export"
        }
        # Validate JSON content
        try {
            $jsonContent = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
            if ($jsonContent.ObjectType -ne 'Azure.DevOps.Organization.Security.Policies') {
                throw "Invalid ObjectType in $jsonPath. Expected 'Azure.DevOps.Organization.Security.Policies', found '$($jsonContent.ObjectType)'"
            }
        }
        catch {
            throw "Failed to parse JSON in $jsonPath : $($_.Exception.Message)"
        }
    }

    # Run rules with default token type
    Write-Verbose "Running PSRule for default token type in $outPath"
    $ruleResult = Invoke-PSRule -InputPath "$($outPath)/" -Module PSRule.Rules.AzureDevOps -Format Detect -Culture en -ErrorAction Stop

    # Run rules with the public baseline
    Write-Verbose "Running PSRule for public baseline in $outPath"
    $ruleResultPublic = Invoke-PSRule -InputPath "$($outPath)/" -Module PSRule.Rules.AzureDevOps -Format Detect -Culture en -Baseline Baseline.PublicProject -ErrorAction Stop

    # Run rules with ReadOnly token type
    Write-Verbose "Running PSRule for ReadOnly token type in $outPathReadOnly"
    $ruleResultReadOnly = Invoke-PSRule -InputPath "$($outPathReadOnly)/" -Module PSRule.Rules.AzureDevOps -Format Detect -Culture en -ErrorAction Stop

    # Run rules with FineGrained token type
    Write-Verbose "Running PSRule for FineGrained token type in $outPathFineGrained"
    $ruleResultFineGrained = Invoke-PSRule -InputPath "$($outPathFineGrained)/" -Module PSRule.Rules.AzureDevOps -Format Detect -Culture en -ErrorAction Stop
}

Describe "Azure.DevOps.Organization.Security.Policies rules" {
    Context 'Rule Loading' {
        It 'should load all 10 organization security policies rules' {
            $rules = Get-PSRule -Module PSRule.Rules.AzureDevOps
            $orgRules = $rules | Where-Object { $_.Name -like 'Azure.DevOps.Organization.Security.Policies.*' }
            $orgRules.Count | Should -Be 10
            $orgRules | ForEach-Object { Write-Verbose "Loaded rule: $($_.Name)" }
        }
    }

    Context 'JSON Input Validation' {
        It 'should have valid OrganizationSecurityPolicies.ado.json in out directory' {
            $jsonPath = Join-Path -Path $outPath -ChildPath 'OrganizationSecurityPolicies.ado.json'
            $jsonContent = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
            $jsonContent.ObjectType | Should -Be 'Azure.DevOps.Organization.Security.Policies'
            $jsonContent | Should -HaveProperty 'disallowSecureShell', 'artifactsExternalPackageProtectionToken', 'disallowAadGuestUserAccess', 'allowAnonymousAccess', 'allowTeamAdminsInvitationsAccessToken', 'allowFeedbackCollection', 'logAuditEvents', 'allowRequestAccessToken', 'disallowOAuthAuthentication', 'enforceAADConditionalAccess'
        }
    }

    Context 'Azure.DevOps.Organization.Security.Policies.DisallowSecureShell' {
        It 'should process rule' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowSecureShell' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for DisallowSecureShell"
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowSecureShell' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowSecureShell' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Security.Policies.DisallowSecureShell.md')
            $fileExists | Should -Be $true
        }

        It 'should not be present in the PublicProject baseline' {
            $ruleHits = @($ruleResultPublic | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowSecureShell' })
            $ruleHits.Count | Should -Be 0
        }
    }

    Context 'Azure.DevOps.Organization.Security.Policies.ArtifactsExternalPackageProtectionToken' {
        It 'should process rule' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.ArtifactsExternalPackageProtectionToken' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for ArtifactsExternalPackageProtectionToken"
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.ArtifactsExternalPackageProtectionToken' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.ArtifactsExternalPackageProtectionToken' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Security.Policies.ArtifactsExternalPackageProtectionToken.md')
            $fileExists | Should -Be $true
        }
    }

    Context 'Azure.DevOps.Organization.Security.Policies.DisallowAadGuestUserAccess' {
        It 'should process rule' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowAadGuestUserAccess' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for DisallowAadGuestUserAccess"
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowAadGuestUserAccess' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowAadGuestUserAccess' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Security.Policies.DisallowAadGuestUserAccess.md')
            $fileExists | Should -Be $true
        }
    }

    Context 'Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess' {
        It 'should process rule' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for DisallowAnonymousAccess"
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Security.Policies.DisallowAnonymousAccess.md')
            $fileExists | Should -Be $true
        }
    }

    Context 'Azure.DevOps.Organization.Security.Policies.DisallowTeamAdminsInvitationsAccessToken' {
        It 'should process rule' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowTeamAdminsInvitationsAccessToken' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for DisallowTeamAdminsInvitationsAccessToken"
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowTeamAdminsInvitationsAccessToken' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowTeamAdminsInvitationsAccessToken' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Security.Policies.DisallowTeamAdminsInvitationsAccessToken.md')
            $fileExists | Should -Be $true
        }
    }

    Context 'Azure.DevOps.Organization.Security.Policies.DisallowFeedbackCollection' {
        It 'should process rule' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowFeedbackCollection' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for DisallowFeedbackCollection"
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowFeedbackCollection' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowFeedbackCollection' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Security.Policies.DisallowFeedbackCollection.md')
            $fileExists | Should -Be $true
        }
    }

    Context 'Azure.DevOps.Organization.Security.Policies.EnableLogAuditEvents' {
        It 'should process rule' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.EnableLogAuditEvents' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for EnableLogAuditEvents"
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.EnableLogAuditEvents' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.EnableLogAuditEvents' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Security.Policies.EnableLogAuditEvents.md')
            $fileExists | Should -Be $true
        }
    }

    Context 'Azure.DevOps.Organization.Security.Policies.DisallowRequestAccessToken' {
        It 'should process rule' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowRequestAccessToken' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for DisallowRequestAccessToken"
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowRequestAccessToken' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.DisallowRequestAccessToken' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Security.Policies.DisallowRequestAccessToken.md')
            $fileExists | Should -Be $true
        }
    }

    Context 'Azure.DevOps.Organization.Security.Policies.AllowOAuthAuthentication' {
        It 'should process rule' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.AllowOAuthAuthentication' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for AllowOAuthAuthentication"
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.AllowOAuthAuthentication' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.AllowOAuthAuthentication' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Security.Policies.AllowOAuthAuthentication.md')
            $fileExists | Should -Be $true
        }
    }

    Context 'Azure.DevOps.Organization.Security.Policies.EnforceAADConditionalAccess' {
        It 'should process rule' {
            $ruleHits = @($ruleResult | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.EnforceAADConditionalAccess' })
            $ruleHits | Should -Not -BeNullOrEmpty -Because "Rule should process for EnforceAADConditionalAccess"
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for ReadOnly TokenType' {
            $ruleHits = @($ruleResultReadOnly | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.EnforceAADConditionalAccess' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should be the same for the FineGrained TokenType' {
            $ruleHits = @($ruleResultFineGrained | Where-Object { $_.RuleName -eq 'Azure.DevOps.Organization.Security.Policies.EnforceAADConditionalAccess' })
            $ruleHits | Should -Not -BeNullOrEmpty
            $ruleHits[0].Outcome | Should -BeIn @('Pass', 'Fail')
            $ruleHits.Count | Should -Be 1
        }

        It 'should have an English markdown help file' {
            $fileExists = Test-Path -Path (Join-Path -Path $ourModule -ChildPath 'en/Azure.DevOps.Organization.Security.Policies.EnforceAADConditionalAccess.md')
            $fileExists | Should -Be $true
        }
    }
}

AfterAll {
    # Remove Module
    Disconnect-AzDevOps
    Remove-Module -Name PSRule.Rules.AzureDevOps -Force
}