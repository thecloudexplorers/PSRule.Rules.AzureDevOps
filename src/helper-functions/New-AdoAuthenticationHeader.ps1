<#
    .SYNOPSIS
    Creates a well-formatted Azure DevOps authentication header.

    .DESCRIPTION
    This function formats an Azure DevOps Personal Access Token (PAT) into a Basic Authentication header that can be used in REST API calls. 
    The PAT token owner name (username) is required and should be the username associated with the PAT token, typically an email.

    .PARAMETER PatToken
    The Personal Access Token (PAT) generated in Azure DevOps.

    .PARAMETER PatTokenOwnerName
    The username associated with the PAT token, typically an email.

    .EXAMPLE
    $adoAuthHeader = New-AdoAuthenticationHeader -PatToken "yourPatTokenHere" -PatTokenOwnerName "Ben John"
    Invoke-RestMethod -Uri "https://dev.azure.com/organization/_apis/projects" -Headers $adoAuthHeader -Method Get
#>

function New-AdoAuthenticationHeader {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $PatToken,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $PatTokenOwnerName
    )

    # Trim the PAT token to remove any accidental whitespace
    $PatToken = $PatToken.Trim()

    # Trim the PatTokenOwnerName to remove any accidental whitespace
    $PatTokenOwnerName = $PatTokenOwnerName.Trim()

    # Format the authentication string in the format "username:patToken"
    Write-Debug -Message "Combining PatTokenOwnerName and PatToken into a single string: [$PatTokenOwnerName]:[$PatToken]"
    $authString = "{0}:{1}" -f $PatTokenOwnerName, $PatToken

    # Encode the authentication string to UTF-8 bytes and then to Base64
    Write-Debug -Message "Encoding the authentication string to Base64"
    $utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($authString)
    $base64Auth = [System.Convert]::ToBase64String($utf8Bytes)

    # Construct the authentication header hashtable
    Write-Debug -Message "Constructing the authentication header hashtable"
    [System.Collections.Hashtable]$adoAuthenticationHeader = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Basic $base64Auth"
    }

    return $adoAuthenticationHeader
}