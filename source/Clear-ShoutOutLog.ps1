
<#
.SYNOPSIS
Removes all log handlers in the current scope for the given message type.

If the '-Global' switch is specified, all log handlers for the given message type will be removed 
#>
function Clear-ShoutOutLog {
    param(
        [Parameter(Mandatory=$true, Position=1, HelpMessage="Mesage Type to remove handlers for.")]
        [Alias('MsgType')]
        [string]$MessageType,
        [Parameter(Mandatory=$false)]
        [Switch]$Global
    )

    $resolveArgs = @{
        MessageType = $MessageType
    }

    if (-not $Global) {
        $resolveArgs.TargetFrame = (Get-PSCallStack)[1]
    }

    _resolveLogHandler @resolveArgs | ForEach-Object {
        _removeLogHandler $_.Id
    }

}