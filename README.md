# EventLogTools
As a function runs, it may output several verbose, information, warning, or error messages. 
Write-StreamToEventLog takes each output message and logs it to the Windows event log.

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

In my functions I've been following the below structure to stop on the first error and pass that error down the pipeline into Write-StreamToEventLog.  
If you have found a better way of doing this let me know!

```powershell
Function MyFunction {
    [CmdletBinding()]
    Param()

    $Verbose = $VerbosePreference -ne 'SilentlyContinue' #checks if MyFunction was called with Verbose switch

    Try {
        $ErrorActionPreference = 'Stop'
        Command1 -Verbose:$Verbose #if MyFunction was called with Verbose switch, we want verbose output from this as well
        Command2 #this command generates a lot of misc verbose output, so we exclude it.
        Command3 -Verbose:$Verbose
    }
    Catch {
        $ErrorActionPreference = 'Continue' #allows error to be passed down the pipeline
        $PSCmdlet.WriteError($_)
        Break
    }
}
```