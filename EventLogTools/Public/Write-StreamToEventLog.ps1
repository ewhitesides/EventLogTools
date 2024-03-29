function Write-StreamToEventLog {
<#
.DESCRIPTION
Takes output from a command and sends to EventLog.

.PARAMETER Stream
The output stream should go to this parameter.

.PARAMETER ID
The event ID you want to use if want to specify it manually.

.PARAMETER AutoID
The method to use to generate the event ID.  Options are 'Hash' and 'Increment'.

.PARAMETER Logname
The log name.

.PARAMETER Source
The log source.

.EXAMPLE
MyFunction *>&1 | Write-StreamToEventLog -LogName Application -Source Powershell -ID 1000
This example writes the result of MyFunction to the eventlog Application\Powershell with an event ID of 1000

.EXAMPLE
MyFunction *>&1 | Write-StreamToEventLog -Logname Application -Source Powershell -AutoID Increment
This example writes the result of MyFunction to the eventlog Application\Powershell.
The id is simply incremented as it comes in. Not recommended for code that runs on loop because eventually
it will exceed the maximum event ID of 65535.

.EXAMPLE
MyFunction *>&1 | Write-StreamToEventLog -Logname Application -Source Powershell -AutoID Hash
This example writes the result of MyFunction to the eventlog Application\Powershell.
The id is auto generated based on a MD5 hash (default) of the message being sent to Stream and the EntryType.
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
        Try {
            New-EventLog -LogName $LogName -Source $Source -ErrorAction 'Stop'
        }
        Catch {
            if (
                $_.Exception -and
                $_.Exception.Message -and
                $_.Exception.Message -notmatch 'already registered'
            ) {
                throw $_
            }
        }
    }

    PROCESS {
        ForEach ($StreamItem in $Stream) {
            $EntryType = switch ($StreamItem.GetType().FullName) {
                'System.Management.Automation.ErrorRecord' {'Error'}
                'System.Management.Automation.WarningRecord' {'Warning'}
                default {'Information'}
            }

            if ($AutoID) {
                switch ($AutoID) {
                    'Hash' {$ID = Get-Id -Message ($EntryType+$StreamItem)}
                    'Increment' {$ID++}
                }
            }

            $WriteEventLog = @{
                LogName   = $LogName
                Source    = $Source
                EntryType = $EntryType
                EventId   = $ID
                Message   = $StreamItem
            }
            Write-EventLog @WriteEventLog
        }
    }
}
