function Set-ShoutOutConfig {
    param(
        [Parameter(HelpMessage="The default Message Type that ShoutOut should apply to messages.")]
        [string]$DefaultMsgType,
        [Parameter(HelpMessage="Enable/Disable Context logging.")]
        [Alias("LogContext")]
        [boolean]$EnableContextLogging,
        [Parameter(HelpMessage="Disable/Enable ShoutOut.")]
        [Alias("Disabled")]
        [boolean]$DisableLogging
    )

    if ($PSBoundParameters.ContainsKey("DefaultMsgType")) {
        $_shoutOutSettings.DefaultMsgType = $DefaultMsgType
    }

    if ($PSBoundParameters.ContainsKey("LogContext")) {
        $_shoutOutSettings.LogContext = $LogContext
    }
    
    if ($PSBoundParameters.ContainsKey("Disabled")) {
        $_shoutOutSettings.Disabled = $Disabled
    }

}