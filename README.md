# EventLogTools

As a function runs, it may output messages of type verbose, information,
warning, error, etc.

Write-StreamToEventLog gives us a way to pipe these messages to the Windows Event
log and if selected, automatically generate an event id.

The below table outlines the Stream to Entry Type mapping:

| Stream # | Stream Name    | Object Type                                      | Resulting Windows Event Entry Type |
|:---------|:---------------|:-------------------------------------------------|:-----------------------------------|
| 1        | Output/Success | Whatever the type of the object being output is  | Information                        |
| 2        | Error          | [System.Management.Automation.ErrorRecord]       | Error                              |
| 3        | Warning        | [System.Management.Automation.WarningRecord]     | Warning                            |
| 4        | Verbose        | [System.Management.Automation.VerboseRecord]     | Information                        |
| 5        | Debug          | [System.Management.Automation.DebugRecord]       | Information                        |
| 6        | Information    | [System.Management.Automation.InformationRecord] | Information                        |

## Important changes between EventLogTools version 4 and 5

It seems that event log cmdlets now work directly with powershell 7.4, and so
in version 5.0.0.0 of EventLogTools, the code has been updated to call cmdlets
such as New-EventLog and Write-EventLog directly.

In version 4.0.0.0 the code was passing EventLog cmdlets through powershell.exe.

In addition, the new version 5.0.0.0 has simplified to use a single function,
Write-StreamToEventLog.

To create a new event log source, you will need to run this function first as an admin:

```pwsh
#run as admin first time
Write-Information 'creating new event log source' |
Write-StreamToEventLog -LogName Application -Source MyProgram -ID 1000
```

On future uses it should work as a regular user. If you always run your script with
an account with administrative rights, this should not be an issue.

## Installation

```powershell
Install-PsResource -name 'EventLogTools' -Repository 'PSGallery'
```

## Inline Help

```powershell
Get-Command -Module EventLogTools
Get-Help -Command <command> -Full
```

## Important Note

The first time you run Write-StreamToEventLog, you will need to run it as an administrator
to create the event log source. After that, you can run it as a regular user.

## Write-StreamToEventLog Examples

### Example with manually specifying Event ID

This example writes the result of MyFunction to the eventlog Application\Powershell with an event ID of 1000

```powershell
MyFunction *>&1 | Write-StreamToEventLog -LogName Application -Source Powershell -ID 1000
```

### Example with auto incrementing Event ID

This example writes the result of MyFunction to the eventlog Application\Powershell.
The id is simply incremented as it comes in. Not recommended for code that runs on loop because eventually
it will exceed the maximum event ID of 65535

```powershell
MyFunction *>&1 | Write-StreamToEventLog -Logname Application -Source Powershell -AutoID Increment
```

### Example with Event ID based on Hash of Stream Message and Entry Type

This example writes the result of MyFunction to the eventlog Application\Powershell.
The id is auto generated based on a MD5 hash (default) of the message being sent to Stream and the EntryType.
The result is the ID number will be unique and repeatable.
The range of Event IDs is 0-65535 , so when hashing to a 5 digit number, there is a chance of collision, however with
a simple script/module that generates a handful of messages, the chance of collision should be pretty low.

```powershell
MyFunction *>&1 | Write-StreamToEventLog -Logname Application -Source Powershell -AutoID Hash
```
