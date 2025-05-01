# Connection class for Azure DevOps Rest API
#
# Path: src/PSRule.Rules.AzureDevOps/Functions/Connection.ps1
# This class contains methods to connect to Azure DevOps Rest API
# using a service principal, managed identity, personal access token (PAT),
# or Bearer token (OAuth 2.0 access token). It provides an authentication
# header which is refreshed automatically when it expires for supported auth types.
# --------------------------------------------------

class AzureDevOpsConnection {
    [string]$Organization
    [string]$OrganizationId
    [string]$PAT
    [string]$ClientId
    [string]$ClientSecret
    [string]$TenantId
    [string]$TokenEndpoint
    [string]$Token
    [System.DateTime]$TokenExpires
    [string]$AuthType
    [string]$TokenType

    # Constructor for Service Principal
    AzureDevOpsConnection(
        [string]$Organization,
        [string]$ClientId,
        [string]$ClientSecret,
        [string]$TenantId,
        [string]$TokenType = 'FullAccess'
    )
    {
        $this.Organization = $Organization
        $this.ClientId = $ClientId
        $this.ClientSecret = $ClientSecret
        $this.TenantId = $TenantId
        $this.TokenEndpoint = "https://login.microsoftonline.com/$($this.TenantId)/oauth2/v2.0/token"
        $this.Token = $null
        $this.TokenExpires = [System.DateTime]::MinValue
        $this.TokenType = $TokenType
        $this.AuthType = 'ServicePrincipal'

        # Get a token for the Azure DevOps REST API
        $this.GetServicePrincipalToken()
    }

    # Constructor for Managed Identity
    AzureDevOpsConnection(
        [string]$Organization,
        [string]$TokenType = 'FullAccess'
    )
    {
        $this.Organization = $Organization
        # Get the Managed Identity token endpoint for the Azure DevOps REST API
        if (-not $env:IDENTITY_ENDPOINT) {
            $env:IDENTITY_ENDPOINT = "http://169.254.169.254/metadata/identity/oauth2/token"
        }
        if ($env:ADO_MSI_CLIENT_ID) {
            $this.TokenEndpoint = "$($env:IDENTITY_ENDPOINT)?resource=499b84ac-1321-427f-aa17-267ca6975798&api-version=2019-08-01&client_id=$($env:ADO_MSI_CLIENT_ID)"
        }
        else {
            $this.TokenEndpoint = "$($env:IDENTITY_ENDPOINT)?resource=499b84ac-1321-427f-aa17-267ca6975798&api-version=2019-08-01"
        }
        $this.Token = $null
        $this.TokenExpires = [System.DateTime]::MinValue
        $this.TokenType = $TokenType
        $this.AuthType = 'ManagedIdentity'

        # Get a token for the Azure DevOps REST API
        $this.GetManagedIdentityToken()
    }

    # Constructor for Personal Access Token (PAT)
    AzureDevOpsConnection(
        [string]$Organization,
        [string]$PAT,
        [string]$TokenType = 'FullAccess'
    )
    {
        $this.Organization = $Organization
        $this.PAT = $PAT
        $this.Token = $null
        $this.TokenExpires = [System.DateTime]::MaxValue
        $this.TokenType = $TokenType
        $this.AuthType = 'PAT'

        # Get a token for the Azure DevOps REST API
        $this.GetPATToken()
    }

    # Constructor for Bearer Token
    AzureDevOpsConnection(
        [string]$Organization,
        [string]$OrganizationId,
        [string]$AccessToken,
        [string]$TokenType = 'FullAccess',
        [switch]$Bearer
    )
    {
        $this.Organization = $Organization
        $this.OrganizationId = $OrganizationId
        $this.Token = "Bearer $AccessToken"
        $this.TokenExpires = [System.DateTime]::Now.AddHours(1) # Default 1-hour expiry
        $this.TokenType = $TokenType
        $this.AuthType = 'Bearer'

        # Validate token format
        if (-not $AccessToken -or $AccessToken -notmatch "^[A-Za-z0-9._-]+\.[A-Za-z0-9._-]+\.[A-Za-z0-9._-]+$") {
            throw "Invalid Bearer token format. Ensure the token is a valid JWT."
        }
    }

    # Get a token for the Azure DevOps REST API using a service principal
    [void]GetServicePrincipalToken()
    {
        $body = @{
            grant_type    = "client_credentials"
            client_id     = $this.ClientId
            client_secret = $this.ClientSecret
            scope         = '499b84ac-1321-427f-aa17-267ca6975798/.default'
        }
        $header = @{
            'Content-Type' = 'application/x-www-form-urlencoded'
        }
        $response = Invoke-RestMethod -Uri $this.TokenEndpoint -Method Post -Body $body -ContentType 'application/x-www-form-urlencoded' -Headers $header
        $this.Token = "Bearer $($response.access_token)"
        $this.TokenExpires = [System.DateTime]::Now.AddSeconds($response.expires_in)
        $this.AuthType = 'ServicePrincipal'
    }

    # Get a token for the Azure DevOps REST API using a managed identity
    [void]GetManagedIdentityToken()
    {
        $header = @{}
        If ($env:IDENTITY_HEADER) {
            $header = @{ 'X-IDENTITY-HEADER' = "$env:IDENTITY_HEADER" ; Metadata = 'true' }
        }
        else {
            $header = @{ Metadata = 'true' }
        }
        $response = Invoke-RestMethod -Uri $this.TokenEndpoint -Method Get -Headers $header
        $this.Token = "Bearer $($response.access_token)"
        $this.TokenExpires = (Get-Date 01.01.1970).AddSeconds($response.expires_on)
        $this.AuthType = 'ManagedIdentity'
    }

    # Get a token for the Azure DevOps REST API using a personal access token (PAT)
    [void]GetPATToken()
    {
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((":$($this.PAT)")))
        $this.Token = 'Basic ' + $base64AuthInfo
        $this.AuthType = 'PAT'
    }

    # Get the up-to-date authentication header for the Azure DevOps REST API
    [System.Collections.Hashtable]GetHeader()
    {
        # If the token is expired, attempt to refresh (except for Bearer and PAT)
        if ($this.TokenExpires -lt [System.DateTime]::Now) {
            switch ($this.AuthType) {
                'ServicePrincipal' {
                    $this.GetServicePrincipalToken()
                }
                'ManagedIdentity' {
                    $this.GetManagedIdentityToken()
                }
                'PAT' {
                    # PAT tokens don't expire in this context
                }
                'Bearer' {
                    throw "Bearer token has expired. Please provide a new token via Connect-AzDevOps."
                }
            }
        }
        $header = @{
            Authorization = $this.Token
            'Content-Type' = 'application/json'
        }
        return $header
    }
}