
function Get-ShoutOutRedirect {
    param(
        [Parameter(HelpMessage="Message Type to retrieve redirection information for.")]
        [string]$msgType
    )

    return $script:_ShoutOutSettings.LogFileRedirection[$msgType]
} 