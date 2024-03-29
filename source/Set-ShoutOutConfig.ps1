function Set-ShoutOutConfig {
    param(
        [Parameter(HelpMessage="The default Message Type that ShoutOut should apply to messages.")]
        [string]$DefaultMsgType,
        [Parameter(HelpMessage="Enable/Disable Context logging.")]
        [Alias("LogContext")]
        [bool]$EnableContextLogging,
        [Parameter(HelpMessage="Disable/Enable ShoutOut.")]
        [Alias("Disabled")]
        [bool]$DisableLogging,
        [Parameter(HelpMessage="Disable/Enable console logging.")]
        [Alias("Silent")]
        [bool]$Quiet
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
    
    if ($PSBoundParameters.ContainsKey("Quiet")) {
        $_shoutOutSettings.Quiet = $Quiet
    }

}