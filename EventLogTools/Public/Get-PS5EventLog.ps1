function Get-PS5EventLog {
<#
.DESCRIPTION
Command to get eventlog through PS5
#>
    Param(
        [string]$LogName,
        [string]$Source
    )

    $WinPS = (Get-Command -Name 'powershell.exe').Source

    $Command = "Get-EventLog -LogName $LogName -Source $Source"

    & $WinPS -Command "$Command"

}
