
function Get-ShoutOutRedirect {
    param(
        [string]$msgType
    )

    return $script:_ShoutOutSettings.LogFileRedirection[$msgType]
} 