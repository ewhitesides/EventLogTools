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
Get-Help -Command Write-StreamToEventLog -Full
```
## Usage Example with manually specifying Event ID
```powershell
New-Item -ItemType File -Path C:\testme.txt -Verbose *>&1 | Write-StreamToEventLog -Logname Application -Source Powershell -ID 1000
```
## Usage Example with auto incrementing Event ID
```powershell
MyCommand -Verbose *>&1 | Write-StreamToEventLog -Logname Application -Source Powershell -AutoID Increment
```
## Usage Example with Event ID based on Hash of Stream Message and Entry Type
```powershell
MyCommand -Verbose *>&1 | Write-StreamToEventLog -Logname Application -Source Powershell -AutoID Hash
```
## Example
Example structure for a function that stops operation on the first error, and then sends the error message down the pipeline.

```powershell
Function MyFunction {
    [CmdletBinding()]
    Param()

    $Verbose = $VerbosePreference -ne 'SilentlyContinue' #checks if MyFunction was called with Verbose switch

    Try {
        $ErrorActionPreference = 'Stop'
        Command1 -Verbose:$Verbose     #if MyFunction was called with Verbose switch, we want verbose output from this as well
        Command2                       #this command generates a lot of misc verbose output, so we exclude it.
        Write-Verbose 'this is a test' #if MyFunction was called with Verbose switch, then $VerbosePreference will equal 'Continue' and this message will be output
        ErrorCommand                   #this command generates an error
        Command3 -Verbose:$Verbose     #this command is never executed because of the above Error
    }
    Catch {
        $PSCmdlet.WriteError($_)            #Writes out the error message from ErrorCommand
        Break                               #stops MyFunction from continuing
    }
}
```