
function Clear-ShoutOutRedirect {
    param(
        [Parameter(HelpMessage="Mesage Type to remove redirection of.")]
        [string]$msgType
    )

    $_ShoutOutSettings.LogFileRedirection.Remove($msgType)
}