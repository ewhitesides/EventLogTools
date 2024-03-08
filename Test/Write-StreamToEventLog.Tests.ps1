#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.5.0'}

#Supress the following PSScriptAnalyzer warnings
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
Param()

Describe "Write-StreamToEventLog" {

    BeforeAll {
        if (
            -NOT (
                [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
            ).IsInRole(
                [Security.Principal.WindowsBuiltInRole] "Administrator"
            )
        ) {
            Throw "This test must be run as Administrator in order to create the event log for the first time"
        }

        . "$PSScriptRoot/../EventLogTools/Private/Get-Id.ps1"
        . "$PSScriptRoot/../EventLogTools/Public/Write-StreamToEventLog.ps1"
    }

    Context "When writing to event log with manual ID" {
        BeforeAll {
            $LogName = "Application"
            $Source = "EventLogToolsPesterTest"
        }

        It 'Should write info stream to event log' {
            #'*>&1' is used to redirect the stream to the output stream
            #so it can be piped to Write-StreamToEventLog
            $Msg = 'Hello this is an info test'
            $Id = '1111'
            Write-Information $Msg *>&1 |
            Write-StreamToEventLog -ID $Id -LogName $LogName -Source $Source

            $LatestEntry = Get-EventLog -LogName $LogName -Source $Source |
            Sort-Object TimeGenerated |
            Select-Object -Last 1

            $LatestEntry.EventID | Should -Be $Id
            $LatestEntry.Message | Should -Be $Msg
            $LatestEntry.EntryType | Should -Be 'Information'
        }

        It 'Should write verbose stream to event log' {
            #wait so timegenerated for the entry is different
            Start-Sleep -Seconds 1

            $VerbosePreference = 'Continue'
            $Msg = 'Hello this is a verbose test'
            $Id = '1112'
            Write-Verbose $Msg *>&1 |
            Write-StreamToEventLog -ID $Id -LogName $LogName -Source $Source

            $LatestEntry = Get-EventLog -LogName $LogName -Source $Source |
            Sort-Object TimeGenerated |
            Select-Object -Last 1

            $LatestEntry.EventID | Should -Be $Id
            $LatestEntry.Message | Should -Be $Msg
            $LatestEntry.EntryType | Should -Be 'Information'
        }

        It 'Should write debug stream to event log' {
            #wait so timegenerated for the entry is different
            Start-Sleep -Seconds 1

            $DebugPreference = 'Continue'
            $Msg = 'Hello this is a debug test'
            $Id = '1113'
            Write-Debug $Msg *>&1 |
            Write-StreamToEventLog -ID $Id -LogName $LogName -Source $Source

            $LatestEntry = Get-EventLog -LogName $LogName -Source $Source |
            Sort-Object TimeGenerated |
            Select-Object -Last 1

            $LatestEntry.EventID | Should -Be $Id
            $LatestEntry.Message | Should -Be $Msg
            $LatestEntry.EntryType | Should -Be 'Information'
        }

        It 'Should write warning stream to event log' {
            #wait so timegenerated for the entry is different
            Start-Sleep -Seconds 1

            #assumes warningpreference set to default continue
            $Msg = 'Hello this is a warning test'
            $Id = '1114'
            Write-Warning $Msg *>&1 |
            Write-StreamToEventLog -ID $Id -LogName $LogName -Source $Source

            $LatestEntry = Get-EventLog -LogName $LogName -Source $Source |
            Sort-Object TimeGenerated |
            Select-Object -Last 1

            $LatestEntry.EventID | Should -Be $Id
            $LatestEntry.Message | Should -Be $Msg
            $LatestEntry.EntryType | Should -Be 'Warning'
        }

        It 'Should write error stream to event log' {
            #wait so timegenerated for the entry is different
            Start-Sleep -Seconds 1

            #set eap to silentlycontinue so error does not break the test
            $ErrorActionPreference = 'SilentlyContinue'
            $Msg = 'Hello this is an error test'
            $Id = '1115'
            Write-Error $Msg *>&1 |
            Write-StreamToEventLog -ID $Id -LogName $LogName -Source $Source

            $LatestEntry = Get-EventLog -LogName $LogName -Source $Source |
            Sort-Object TimeGenerated |
            Select-Object -Last 1

            $LatestEntry.EventID | Should -Be $Id
            $LatestEntry.Message | Should -Be $Msg
            $LatestEntry.EntryType | Should -Be 'Error'
        }
    }

    Context "When writing to event log with auto-generated ID using hash" {
        BeforeAll {
            $LogName = "Application"
            $Source = "EventLogToolsPesterTest"
        }

        BeforeEach {
            #generate a random string for the message
            $Msg = -join ((65..90) + (97..122) |
            Get-Random -Count 10 |
            ForEach-Object {[char]$_})
        }

        It 'Should write info stream to event log' {
            Write-Information $Msg *>&1 |
            Write-StreamToEventLog -LogName $LogName -Source $Source -AutoID 'Hash'

            #get the latest entry
            $LatestEntry = Get-EventLog -LogName $LogName -Source $Source |
            Sort-Object TimeGenerated |
            Select-Object -Last 1

            #assertion checks on latest entry
            $LatestEntry.Message | Should -Be $Msg
            $LatestEntry.EntryType | Should -Be 'Information'
        }

        It 'Should write info stream with a lot of special characters to event log' {
            $Msg = "(This (( is a test message with )) special characters: !@#$%^&*()_+{}|:<>?`-=[]\;',./)"
            Write-Information $Msg *>&1 |
            Write-StreamToEventLog -LogName $LogName -Source $Source -AutoID 'Hash'

            #get the latest entry
            $LatestEntry = Get-EventLog -LogName $LogName -Source $Source |
            Sort-Object TimeGenerated |
            Select-Object -Last 1

            #assertion checks on latest entry
            $LatestEntry.Message | Should -Be $Msg
            $LatestEntry.EntryType | Should -Be 'Information'
        }
    }

    Context "When writing to event log with auto-incremented ID" {
        BeforeAll {
            $LogName = "Application"
            $Source = "EventLogToolsPesterTest"
        }

        It 'Should write info stream to event log' {
            function SimulatedProgramOutput {
                Write-Information "Info 1"
                Start-Sleep -Seconds 1
                Write-Warning "Warning 1"
                Start-Sleep -Seconds 1
                Write-Warning "Warning 2"
                Start-Sleep -Seconds 1
                Write-Error "Error 1"
            }

            SimulatedProgramOutput *>&1 |
            Write-StreamToEventLog -LogName $LogName -Source $Source -AutoID 'Increment'

            #Get latest 4 entries
            $Latest4Entries = Get-EventLog -LogName $LogName -Source $Source |
            Sort-Object TimeGenerated |
            Select-Object -Last 4

            #assertion checks on latest 4 entries
            $Latest4Entries[0].EventID | Should -Be 1
            $Latest4Entries[0].EntryType | Should -Be 'Information'
            $Latest4Entries[0].Message | Should -Be 'Info 1'

            $Latest4Entries[1].EventID | Should -Be 2
            $Latest4Entries[1].EntryType | Should -Be 'Warning'
            $Latest4Entries[1].Message | Should -Be 'Warning 1'

            $Latest4Entries[2].EventID | Should -Be 3
            $Latest4Entries[2].EntryType | Should -Be 'Warning'
            $Latest4Entries[2].Message | Should -Be 'Warning 2'

            $Latest4Entries[3].EventID | Should -Be 4
            $Latest4Entries[3].EntryType | Should -Be 'Error'
            $Latest4Entries[3].Message | Should -Be 'Error 1'
        }
    }
}
