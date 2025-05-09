<#
    .SYNOPSIS
    Creates a well-formatted Azure DevOps authentication header.

    .DESCRIPTION
    This function formats an Azure DevOps authentication header for REST API calls. It supports either a Personal Access Token (PAT) for Basic Authentication or a Bearer token (e.g., OAuth 2.0 access token from Microsoft Entra ID). For PAT, the PAT token owner name (username) is required, typically an email. For Bearer token, only the token is needed.

    .PARAMETER PersonalAccessToken
    The Personal Access Token (PAT) generated in Azure DevOps. Required for PAT-based authentication. Also accepts the alias 'PatToken'.

    .PARAMETER PatTokenOwnerName
    The username associated with the PAT token, typically an email. Required for PAT-based authentication.

    .PARAMETER AccessToken
    A Bearer token (e.g., OAuth 2.0 access token from Microsoft Entra ID) for Bearer authentication. If provided, PAT parameters are ignored.

    .EXAMPLE
    # Using PAT
    $adoAuthHeader = New-AdoAuthenticationHeader -PersonalAccessToken "yourPatTokenHere" -PatTokenOwnerName "Ben John"
    Invoke-RestMethod -Uri "https://dev.azure.com/organization/_apis/projects" -Headers $adoAuthHeader -Method Get

    .EXAMPLE
    # Using Bearer token
    $adoAuthHeader = New-AdoAuthenticationHeader -AccessToken "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ik..."
    Invoke-RestMethod -Uri "https://dev.azure.com/organization/_apis/projects" -Headers $adoAuthHeader -Method Get
#>

function New-AdoAuthenticationHeader {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Pat')]
        [ValidateNotNullOrEmpty()]
        [Alias('PatToken')]
        [System.String] $PersonalAccessToken,

        [Parameter(Mandatory = $true, ParameterSetName = 'Pat')]
        [ValidateNotNullOrEmpty()]
        [System.String] $PatTokenOwnerName,

        [Parameter(Mandatory = $true, ParameterSetName = 'Bearer')]
        [ValidateNotNullOrEmpty()]
        [System.String] $AccessToken
    )

    # Construct the authentication header hashtable
    [System.Collections.Hashtable]$adoAuthenticationHeader = @{
        'Content-Type' = 'application/json'
    }

    switch ($PSCmdlet.ParameterSetName) {
        'Pat' {
            # Trim the PAT token and owner name to remove any accidental whitespace
            $PersonalAccessToken = $PersonalAccessToken.Trim()
            $PatTokenOwnerName = $PatTokenOwnerName.Trim()

            # Format the authentication string in the format "username:patToken"
            Write-Debug -Message "Combining PatTokenOwnerName and PatToken into a single string: [$PatTokenOwnerName]:[$PersonalAccessToken]"
            $authString = "{0}:{1}" -f $PatTokenOwnerName, $PersonalAccessToken

            # Encode the authentication string to UTF-8 bytes and then to Base64
            Write-Debug -Message "Encoding the authentication string to Base64"
            $utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($authString)
            $base64Auth = [System.Convert]::ToBase64String($utf8Bytes)

            # Add Basic Authentication header
            Write-Debug -Message "Constructing Basic Authentication header"
            $adoAuthenticationHeader['Authorization'] = "Basic $base64Auth"
        }
        'Bearer' {
            # Trim the Bearer token to remove any accidental whitespace
            $AccessToken = $AccessToken.Trim()

            # Add Bearer Authentication header
            Write-Debug -Message "Constructing Bearer Authentication header"
            $adoAuthenticationHeader['Authorization'] = "Bearer $AccessToken"
        }
    }

    return $adoAuthenticationHeader
}