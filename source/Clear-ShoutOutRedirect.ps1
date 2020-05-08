
function Clear-ShoutOutRedirect {
    param(
        [string]$msgType
    )

    if ($_ShoutOutSettings.LogFileRedirection.ContainsKey($msgType)) {
        $l = $_ShoutOutSettings.LogFileRedirection[$msgType]
        "Removing message redirection for '{0}', messages of this type will be logged in the default log file ('{1}')." -f $msgType, $_ShoutOutSettings.DefaultLog | shoutOut -LogFile $l
        $_ShoutOutSettings.LogFileRedirection.Remove($msgType)
        "Removed message redirection for '{0}', previously messages were written to '{1}'." -f $msgType, $l | shoutOut
    }
}