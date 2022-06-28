# EventLogTools

As a function runs, it may output several verbose, information, warning, or error messages.
Write-StreamToEventLog takes each message and logs it to the Windows event log.

The below table outlines the Stream to Entry Type mapping:

| Stream # | Stream Name    | Object Type                                      | Resulting Windows Event Entry Type |
|:---------|:---------------|:-------------------------------------------------|:-----------------------------------|
| 1        | Output/Success | Whatever the type of the object being output is  | Information                        |
| 2        | Error          | [System.Management.Automation.ErrorRecord]       | Error                              |
| 3        | Warning        | [System.Management.Automation.WarningRecord]     | Warning                            |
| 4        | Verbose        | [System.Management.Automation.VerboseRecord]     | Information                        |
| 5        | Debug          | [System.Management.Automation.DebugRecord]       | Information                        |
| 6        | Information    | [System.Management.Automation.InformationRecord] | Information                        |

## Installation

```powershell
Install-Module EventLogTools
```

## Inline Help

```powershell
Get-Command -Module EventLogTools
Get-Help -Command <command> -Full
```

## New-PS5EventLog Example

### idempotent creation of Event Log Source 'Testing' in 'Application'

```powershell
New-PS5EventLog -LogName 'Application' -Source 'Testing'
```

## Write-StreamToEventLog Examples

### Example with manually specifying Event ID

```powershell
New-Item -ItemType File -Path C:\testme.txt -Verbose *>&1 | Write-StreamToEventLog -Logname 'Application' -Source 'Testing' -ID 1000
```

### Example with auto incrementing Event ID

```powershell
MyCommand -Verbose *>&1 | Write-StreamToEventLog -Logname 'Application' -Source 'Testing' -AutoID 'Increment'
```

### Example with Event ID based on Hash of Stream Message and Entry Type

```powershell
MyCommand -Verbose *>&1 | Write-StreamToEventLog -Logname 'Application' -Source 'Testing' -AutoID 'Hash'
```
