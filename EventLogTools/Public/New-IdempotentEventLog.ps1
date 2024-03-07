function New-IdempotentEventLog {
<#
.DESCRIPTION
simple function to swallow the exception that occurs when a log already exists

creating the log requires admin rights, so we make it a public function
so that if a user prefers, they can run this function first to create the log
before using Write-StreamToEventLog

if Write-StreamToEventLog is being run in a script under the admin context,
then the log will be created automatically and running this function
separately is not necessary
#>
    Param(
        [string]$LogName,
        [string]$Source
    )

    Try {
        New-EventLog -LogName $LogName -Source $Source -ErrorAction 'Stop'
    }
    Catch {
        if (
            $_.Exception -and
            $_.Exception.Message -and
            $_.Exception.Message -notmatch 'already registered'
        ) {
            throw $_
        }
    }
}
