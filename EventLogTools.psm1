function Write-StreamToEventLog {
<#
.DESCRIPTION
Takes output from a command and sends to EventLog.

.PARAMETER Stream
The output stream should go to this parameter.

.PARAMETER ID
The event ID you want to use.

.PARAMETER Logname
The log name.

.PARAMETER Source
The log source.

.EXAMPLE
New-Item -Verbose *>&1 | Write-StreamToEventLog -LogName Application -Source Powershell -ID 1000
This example writes the result of the New-Item command to the eventlog Application\Powershell with an event ID of 1000

.EXAMPLE
MyCommand -Verbose *>&1 | Write-StreamToEventLog -Logname Application -Source Powershell -AutoID Increment
This example writes the result of MyCommand to the eventlog Application\Powershell.
The id is simply incremented as it comes in. The ids are not unique to the stream message.

.EXAMPLE
MyCommand -Verbose *>&1 | Write-StreamToEventLog -Logname Application -Source Powershell -AutoID Hash
This example writes the result of MyCommand to the eventlog Application\Powershell.
The id is auto generated based on a MD5 hash of the message being sent to Stream and the EntryType.
The result is the ID number will be unique and repeatable.
The range of Event IDs is 0-65535 , so when hashing to a 5 digit number, there is a chance of collision, however with
a simple script/module that generates a handful of messages, the chance of collision should be pretty low.
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Object[]]$Stream,

        [Parameter(Mandatory=$true,ParameterSetName='Manual')]
        [ValidateRange(0,[uint16]::MaxValue)]
        [int]$ID,

        [Parameter(Mandatory=$true,ParameterSetName='Auto')]
        [ValidateSet('Hash','Increment')]
        [string]$AutoID,

        [Parameter(Mandatory=$true)]
        [string]$LogName,

        [Parameter(Mandatory=$false)]
        [string]$Source
    )

    BEGIN {
        #Load in variables
        $WinPS=(Get-Command -Name 'powershell.exe').source

        #Load in functions
        function Get-IDFromMessage {
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
                if ($Output -lt $MaxIDValue) {return $Output}
            }
        }
    }

    PROCESS {

        ForEach ($StreamItem in $Stream) {

            $EntryType = switch ($StreamItem.GetType().FullName) {
                'System.Management.Automation.ErrorRecord'   {'Error'}
                'System.Management.Automation.WarningRecord' {'Warning'}
                default                                      {'Information'}
            }

            #Get ID Number - If ID was not specified, generate one (default is to Hash)
            if ($AutoID) {
                switch ($AutoID) {
                    'Hash'      {$ID = Get-IDFromMessage -Message ($EntryType+$StreamItem)}
                    'Increment' {$ID++}
                }
            }

            #Write to Log
            $WriteCmd = "Write-EventLog -LogName $LogName -Source $Source -EntryType $EntryType -EventId $ID -Message '$StreamItem'"
            & $WinPS -Command "$WriteCmd"
        }
    }
}
