# EventLogTools
Powershell Module that takes output as it comes out of a cmdlet and passes it down pipeline into Windows EventLog.
For example, as your custom cmdlet runs, it may output several verbose, information, warning, or error messages.  
Write-StreamToEventLog takes each message and passes it down to the Windows Event logname and Source of your choice.

## Usage Example
```powershell
New-Item -ItemType File -Path C:\testme.txt -Verbose *>&1 | % {$i++;Write-StreamToEventLog -Stream $_ -ID $i -Logname 'Application' -Source 'NewItemCmd'}
```