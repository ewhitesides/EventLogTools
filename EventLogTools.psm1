function Write-StreamToEventLog {
<#
.DESCRIPTION
Takes output from a command and sends to EventLog

.PARAMETER Stream
The output stream should go to this parameter

.PARAMETER ID
The event log ID you want to use

.PARAMETER Logname
The log name

.PARAMETER Source
The log source

.PARAMETER BreakOnError
Causes the pipeline to break when an error message is sent to Stream

.PARAMETER BreakOnWarning
Causes the pipeline to break when a warning message is sent to Stream 

.EXAMPLE
MyCommand -Verbose *>&1 | % {$i++;Write-StreamToEventLog -Stream $_ -ID $i -Logname 'Application' -Source 'Powershell'
This example takes the result messages from MyCommand and writes to the Application\Powershell log.
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $Stream,

        [Parameter(Mandatory=$true)]
        [int]$ID,

        [Parameter(Mandatory=$true)]
        [string]$LogName,

        [Parameter(Mandatory=$false)]
        [string]$Source,

        [Parameter(Mandatory=$false)]
        [switch]$BreakOnError,

        [Parameter(Mandatory=$false)]
        [switch]$BreakOnWarning
    )

    $EntryType = switch ($Stream.GetType().FullName) {
        'System.Management.Automation.ErrorRecord'   {'Error'}
        'System.Management.Automation.WarningRecord' {'Warning'}
        default                                      {'Information'}
    }

    Write-Eventlog -LogName $LogName -Source $Source -Entrytype $EntryType -EventId $ID -Message $Stream

    if ($EntryType -eq 'Error' -and $BreakOnError)     {Break}
    if ($EntryType -eq 'Warning' -and $BreakOnWarning) {Break}
}