<#
.SYNOPSIS
Scans the current callstack for ShoutOut log handers macthing the provided MessageType (wildcard expression).
#>
function _resolveLogHandler {
    [CmdletBinding(DefaultParameterSetName="All")]
    param(
        [Parameter(Mandatory=$false)]
        [string]$MessageType,
        [Parameter(Mandatory=$false, ParameterSetName="TargetFrame")]
        [System.Management.Automation.CallStackFrame]$TargetFrame
    )

    # $PSCmdlet.ParameterSetName | Write-Host -ForegroundColor DarkYellow

    # $script:logRegistry | Out-String | Write-Host -ForegroundColor DarkGreen

    $callstack = if ($TargetFrame) {
        @($TargetFrame)
    } else {
        Get-PSCallStack
    }
    
    $foundHandlers = New-Object System.Collections.Queue
    $liveHashes = new-Object System.Collections.ArrayList
    $liveHashes.Add('global') | Out-Null

    foreach($frame in $callstack){
        # "-" * 80 | Write-Host -ForegroundColor Magenta
        $fv = $frame.GetFrameVariables()
        # $fv | Out-String | Write-Host
        if (-not $fv.ContainsKey($script:hashCodeAttribute)) {
            continue
        }
        $hash = $fv.$script:hashCodeAttribute.value.getHashCode()
        $liveHashes.Add($hash) | Out-Null
        # "Looking for handler on frame '{0}'..." -f $hash | Write-Host -ForegroundColor Gray
        
        if ($handlers = $script:logRegistry[$hash]) {
            foreach ($handler in $handlers) {
                if (($null -eq $Messagetype) -or ($MessageType -like $handler.MessageType)) {
                    # "Found handler {1} on frame '{0}'" -f $hash, $handler.Id | Write-Host -ForegroundColor Green
                    $foundHandlers.Enqueue($handler)

                    if ($handler.StopPropagation) {
                        return $foundHandlers
                    }
                }
            }
        }
    }

    if (-not $PSBoundParameters.containsKey('TargetFrame')) {
        foreach($handler in $script:logRegistry['global']) {
            # "{0} -like {1} => {2}" -f $MessageType, $handler.MessageType, ($MessageType -like $handler.MessageType) | Write-Host
            if (($null -eq $Messagetype) -or ($MessageType -like $handler.MessageType)) {
                # "Found handler {1} on frame '{0}'" -f $hash, $handler.Id | Write-Host -ForegroundColor Green
                $foundHandlers.Enqueue($handler)

                if ($handler.StopPropagation) {
                    return $foundHandlers
                }
            }
        }
    }

    if ($PSCmdlet.ParameterSetName -eq 'All') {
        # Garbage collection
        $hashes = [array]$script:logRegistry.Keys
        foreach ($hash in $hashes) {
            if ($hash -notin $liveHashes) {
                $script:logRegistry.remove($hash)
            }
        }
    }

    return $foundHandlers
}