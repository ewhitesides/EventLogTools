# EventLogTools
As a function runs, it may output several verbose, information, warning, or error messages.  

Write-StreamToEventLog takes each output message and passes it down to the Windows Event logname and source.

This is useful when you are trying to run a custom cmdlet on a schedule, and you use a logging utility to parse the windows event log for warnings/errors.

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
New-LongAndComplexCmdlet *>&1 | % {$i++;Write-StreamToEventLog -Stream $_ -ID $i -Logname 'Application' -Source 'Powershell'}
```

In your cmdlet, for begin,process, and end blocks, you may need to do something like the following to 
allow the error messages to pass down the pipeline into Write-StreamToEventLog.

```powershell
Function MyFunction {
    [CmdletBinding()]
    Param()

    $Verbose = $VerbosePreference -ne 'SilentlyContinue' #figures out if MyFunction was called with Verbose switch

    Try {
        $ErrorActionPreference = 'Stop'
        Command1 -Verbose:$Verbose
        Command2 -Verbose:$Verbose
        Command3 -Verbose:$Verbose
    }
    Catch {
        $ErrorActionPreference = 'Continue' #allows error to be passed down the pipeline
        $PSCmdlet.WriteError($_)
        Break
    }
}
```