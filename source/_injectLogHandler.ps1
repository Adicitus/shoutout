<#
.SYNOPSIS
Injects a log handler into the callstack at the specified scope
#>
function _injectLogHandler {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$Handler,
        [Parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [System.Management.Automation.CallStackFrame]$InjectionFrame,
        [Parameter(Mandatory=$false)]
        [String]$MessageType="*",
        [Parameter(Mandatory=$false)]
        [bool]$StopPropagation=$false
    )

    # $script:logRegistry | Out-String | Write-Host -ForegroundColor DarkRed
<#
    $callStack = Get-PSCallStack

    $callStack | Write-Host -ForegroundColor DarkCyan

    $InjectionFrame = $callStack | Where-Object {
        "-" * 80 | Write-Host -ForegroundColor DarkGreen
        $_.GetFrameVariables().Keys | Sort-Object | Write-Host -ForegroundColor Magenta
        $_.GetFrameVariables().ContainsKey($script:hashCodeAttribute)
    } | Select-Object -First 1

    $InjectionFrame | Write-Host -ForegroundColor Cyan
#>
    # Generate GUID $logId
    $logid = [guid]::newGuid().guid

    # Generate a record $logRecord of the handler:
    $record = @{
        Id = $logId
        Handler = $Handler
        MessageType = $MessageType
        StopPropagation = $StopPropagation
    }

    if ($InjectionFrame) {
        $hash = $InjectionFrame.GetFrameVariables().$script:hashCodeAttribute.value.getHashCode()
    } else {
        $hash = 'global'
    }

    $record.frame = $hash

    if (-not $script:logRegistry.containsKey($hash)) {
        $script:logRegistry[$hash] = New-Object System.Collections.ArrayList
    }

    # "Adding handler {0} for frame {1}" -f $logId, $hash | Write-Host -ForegroundColor Cyan

    $script:logRegistry[$hash].Add($record) | Out-Null

    return $logId
}