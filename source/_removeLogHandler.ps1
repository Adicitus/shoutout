<#
.SYNOPSIS
Attempts to remove the log handler with the specified Id from the callstack.

Returns $true if a handler was removed, $false otherwise.

#>
function _removeLogHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogId
    )

    foreach($handlers in $script:logRegistry.Values) {
        $handler = $handlers | Where-Object { $_.Id -eq $LogId }
        if ($null -ne $handler) {
            $handlers.remove($handler)
            return $true
        }
    }

    return $false
}