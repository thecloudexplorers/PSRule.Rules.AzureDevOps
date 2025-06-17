@{
    # Allow for Azure DevOps logging
    ExcludeRules = @('PSAvoidUsingWriteHost')
    Rules        = @{
        # Enforce strict casing, spacing, and formatting
        "PSAvoidUsingCmdletAliases"        = @{ Enable = $true }
        "PSUseCmdletCorrectCasing"         = @{ Enable = $true }
        "PSUseApprovedVerbs"               = @{ Enable = $true }
        # Allow for Azure DevOps logging
        "PSAvoidUsingWriteHost"            = @{ Enable = $false }
        "PSUseConsistentWhitespace"        = @{ Enable = $false }
        "PSUseConsistentIndentation"       = @{ Enable = $true }
        "PSAvoidTrailingWhitespace"        = @{ Enable = $true }
        "PSAvoidUsingBackticks"            = @{ Enable = $true }
        "PSUseCorrectCasing"               = @{ Enable = $true }
        "PSUseSingularNouns"               = @{ Enable = $true }
        "PSProvideCommentHelp"             = @{ Enable = $true; Options = @{ Required = "ExportedFunctions" } }
        "PSAvoidUsingPositionalParameters" = @{ Enable = $true }

        # Optional rules you may enable as stricter policies
        "PSAvoidLongLines"                 = @{ Enable = $true; Options = @{ MaximumLineLength = 120 } }
        "PSAvoidGlobalVars"                = @{ Enable = $true }
    }
}
