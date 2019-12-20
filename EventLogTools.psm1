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
        [switch]$BreakOnWarning
    )
    
    #1 (Success)     (whatever input type is provided).
    #2 (Error)       [System.Management.Automation.ErrorRecord]
    #3 (Warning)     [System.Management.Automation.WarningRecord]
    #4 (Verbose)     [System.Management.Automation.VerboseRecord]
    #5 (Debug)       [System.Management.Automation.DebugRecord]
    #6 (Information) [System.Management.Automation.InformationRecord]
    
    $EntryType = switch ($Stream.GetType().FullName) {
        'System.Management.Automation.ErrorRecord'   {'Error'}
        'System.Management.Automation.WarningRecord' {'Warning'}
        default                                      {'Information'}
    }
    
    Write-Eventlog -LogName $LogName -Source $Source -Entrytype $EntryType -EventId $ID -Message $Stream
    
    if ($EntryType -eq 'Error' -and $BreakOnError)     {Break}
    if ($EntryType -eq 'Warning' -and $BreakOnWarning) {Break}  
}