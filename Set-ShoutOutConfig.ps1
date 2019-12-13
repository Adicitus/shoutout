function Set-ShoutOutConfig {
    param(
        [string]$DefaultMsgType,
        [Alias("LogFile")]
        $Log,
        [boolean]$LogContext,
        [boolean]$Disabled
    )

    if ($PSBoundParameters.ContainsKey("DefaultMsgType")) {
        $_shoutOutSettings.DefaultMsgType = $DefaultMsgType
    }

    if ($PSBoundParameters.ContainsKey("Log")) {
        Set-ShoutOutDefaultLog $Log | Out-Null
    }

    if ($PSBoundParameters.ContainsKey("LogContext")) {
        $_shoutOutSettings.LogContext = $LogContext
    }
    
    if ($PSBoundParameters.ContainsKey("Disabled")) {
        $_shoutOutSettings.Disabled = $Disabled
    }

}