function Get-Id {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet('MD5','RIPEMD160','SHA1','SHA256','SHA384','SHA512')]
        [string]$HashName='MD5'
    )

    #Get Hash of Message
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Message)
    $Hash = ([System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash($Bytes) -join '').ToString()
    $HashLength = $Hash.Length

    #Max event ID cannot be higher than 65535, which is uint16 max value
    $MaxIDValue = ([uint16]::MaxValue).ToString()
    $MaxIDValueLength = $MaxIDValue.Length

    #Loop through the number until we find a number lower than 65535
    for ($i=0;$i -lt ($HashLength - $MaxIDValueLength);$i++) {
        $Output = $Hash.SubString($i,$MaxIDValueLength)
        if ($Output -lt $MaxIDValue) {
            return $Output
        }
    }
}