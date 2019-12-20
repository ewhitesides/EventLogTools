# EventLogTools
Powershell Module that takes output as it comes out of a cmdlet and passes it down pipeline into Windows EventLog

## Usage Example
```powershell
New-Item -ItemType File -Path C:\testme.txt -Verbose *>&1 | % {$i++;Write-StreamToEventLog -Stream $_ -ID $i -Logname 'Application' -Source 'NewItemCmd'}
```