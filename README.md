# EventLogTools
As a cmdlet runs, it may output several verbose, information, warning, or error messages. 

Write-StreamToEventLog takes each output message and passes it down to the Windows Event logname and source.

This is useful when you are trying to run a custom cmdlet on a schedule, and you use a logging utility to notify you of errors in the windows event log.

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
Try {
    $ErrorActionPreference = 'Stop'
    Command1
    Command2
    Command3
}
Catch {
    $ErrorActionPreference = 'Continue' #allows error to be passed down the pipeline
    $PSCmdlet.WriteError($_)
    Break
}
```