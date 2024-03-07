function New-PS5EventLog {
<#
.DESCRIPTION
Command to idempotent create a new event log

.PARAMETER Logname
The log name.

.PARAMETER Source
The log source.

.EXAMPLE
New-PS5EventLog -LogName 'Application' -Source 'Testing'
idempotent creation of Event Log Source 'Testing' in 'Application'

.EXAMPLE
New-PS5EventLog -LogName 'Application' -Source 'Testing' -WhatIf
shows what would happen if the command were run
#>

    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [string]$LogName,
        [string]$Source
    )

    if (
        $PSCmdlet.ShouldProcess(
            "LogName: $LogName, Source: $Source",
            "New-EventLog"
        )
    ) {

        $WinPS = (Get-Command -Name 'powershell.exe').Source

        $Command = @"
Try {
    New-EventLog -LogName '$LogName' -Source '$Source' -ErrorAction 'Stop'
}
Catch {
    if (`$PSItem.Exception.Message -notmatch 'already registered') {
        throw
    }
}
"@

        & $WinPS -Command "$Command"
        Write-Information "Created eventlog $Source in $LogName"

    }
}