# EventLogTools
As a function runs, it may output several verbose, information, warning, or error messages. 
Write-StreamToEventLog takes each message and logs it to the Windows event log.

This is especially useful when you are trying to run a custom function on a schedule, 
and you use a logging utility to parse the windows event log for warnings/errors.

| Stream # | Stream Name    | Object Type                                      | Resulting Windows Event Entry Type |
|:---------|:---------------|:-------------------------------------------------|:-----------------------------------|
| 1        | Output/Success | Whatever the type of the object being output is  | Information                        | 
| 2        | Error          | [System.Management.Automation.ErrorRecord]       | Error                              |
| 3        | Warning        | [System.Management.Automation.WarningRecord]     | Warning                            |
| 4        | Verbose        | [System.Management.Automation.VerboseRecord]     | Information                        |
| 5        | Debug          | [System.Management.Automation.DebugRecord]       | Information                        |
| 6        | Information    | [System.Management.Automation.InformationRecord] | Information                        |

## Usage Example
```powershell
New-Item -ItemType File -Path C:\testme.txt -Verbose *>&1 | % {$i++;Write-StreamToEventLog -Stream $_ -ID $i -Logname 'Application' -Source 'Powershell'}
```

## Usage Example
```powershell
New-LongRunningCommand *>&1 | % {$i++;Write-StreamToEventLog -Stream $_ -ID $i -Logname 'Application' -Source 'Powershell'}
```

In my functions I've been following the below structure and it seems to work pretty well for diagnostic purposes.
In my eventlog, I will see the Verbose messages prior to the Error, and that will help clue me in to where the function failed.

```powershell
Function MyFunction {
    [CmdletBinding()]
    Param()

    $Verbose = $VerbosePreference -ne 'SilentlyContinue' #checks if MyFunction was called with Verbose switch

    Try {
        $ErrorActionPreference = 'Stop'
        Command1 -Verbose:$Verbose #if MyFunction was called with Verbose switch, we want verbose output from this as well
        Command2                   #this command generates a lot of misc verbose output, so we exclude it.
        ErrorCommand               #this command generates an error
        Command3 -Verbose:$Verbose #this command is never executed because of the above Error
    }
    Catch {
        $ErrorActionPreference = 'Continue' #allows error to be passed down the pipeline
        $PSCmdlet.WriteError($_)            #Writes out the error message from ErrorCommand
        Break                               #stops MyFunction from continuing
    }
}
```