function Get-ShoutOutDefaultLog {
    param(
        [Parameter(HelpMessage="Specifies that log handlers in all context should be removed, instead of just the current context.")]
        [switch]$Global
    )

    $getArgs = @{
        MessageType = '*'
    }

    if ($Global) {
        $getArgs.Global = $true
    }

    return Get-ShoutOutLog @getArgs
}