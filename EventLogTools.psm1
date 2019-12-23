function Write-StreamToEventLog {
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
        [switch]$BreakOnWarning,
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