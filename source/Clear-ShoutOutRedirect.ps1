
function Clear-ShoutOutLog {
    param(
        [Parameter(HelpMessage="Mesage Type to remove redirection of.")]
        [string]$msgType
    )

    _resolveLogHandler -MessageType $msgType | ForEach-Object {
        _removeLogHandler $_.Id
    }
}