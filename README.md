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
