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

        $LogName = "Application"
        $Source = "EventLogToolsPesterTest"
    }

    Context "When writing to event log with manual ID" {
        BeforeEach {
            #wait before each test so that when we get the
            #latest entry, it is the correct entry for each test
            Start-Sleep -Seconds 2
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
            $WarningPreference = 'Continue'
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
            $ErrorActionPreference = 'Continue'
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
        BeforeEach {
            Start-Sleep -Seconds 2
        }

        It 'Should write info stream to event log' {
            $Msg = 'Hello this is an info test using hash generated ID'
            Write-Information $Msg *>&1 |
            Write-StreamToEventLog -LogName $LogName -Source $Source -AutoID 'Hash'

            #get the latest entry
            $LatestEntry = Get-EventLog -LogName $LogName -Source $Source |
            Sort-Object TimeGenerated |
            Select-Object -Last 1

            #assertion checks on latest entry
            $LatestEntry.EventID | Should -BeGreaterThan 0
            $LatestEntry.Message | Should -Be $Msg
            $LatestEntry.EntryType | Should -Be 'Information'
        }

        It 'Should write info stream with a lot of special characters to event log' {
            $Msg = "(This (( is a test message with )) \/special characters: !@#$%^&*()_+{}|:<>?`-=[]\;',./)"
            Write-Information $Msg *>&1 |
            Write-StreamToEventLog -LogName $LogName -Source $Source -AutoID 'Hash'

            #get the latest entry
            $LatestEntry = Get-EventLog -LogName $LogName -Source $Source |
            Sort-Object TimeGenerated |
            Select-Object -Last 1

            #assertion checks on latest entry
            $LatestEntry.EventID | Should -BeGreaterThan 0
            $LatestEntry.Message | Should -Be $Msg
            $LatestEntry.EntryType | Should -Be 'Information'
        }
    }

    Context "When writing to event log with auto-incremented ID" {
        BeforeEach {
            Start-Sleep -Seconds 2
        }

        It 'Should write info stream to event log' {
            function SimulatedProgramOutput {
                Write-Information "increment test info 1"
                Start-Sleep -Seconds 1
                Write-Warning "increment test warning 1"
                Start-Sleep -Seconds 1
                Write-Warning "increment test warning 2"
                Start-Sleep -Seconds 1
                Write-Error "increment test error 1" -ErrorAction 'Continue'
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
            $Latest4Entries[0].Message | Should -Be 'increment test info 1'

            $Latest4Entries[1].EventID | Should -Be 2
            $Latest4Entries[1].EntryType | Should -Be 'Warning'
            $Latest4Entries[1].Message | Should -Be 'increment test warning 1'

            $Latest4Entries[2].EventID | Should -Be 3
            $Latest4Entries[2].EntryType | Should -Be 'Warning'
            $Latest4Entries[2].Message | Should -Be 'increment test warning 2'

            $Latest4Entries[3].EventID | Should -Be 4
            $Latest4Entries[3].EntryType | Should -Be 'Error'
            $Latest4Entries[3].Message | Should -Be 'increment test error 1'
        }
    }
}
