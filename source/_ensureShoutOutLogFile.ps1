function _ensureShoutOutLogFile {
    param(
        [string]$logFile,
        [string]$MsgType = "*"
    )

    if (!(Test-Path $logFile -PathType Leaf)) {
        try {
            return new-Item $logFile -ItemType File -Force -ErrorAction Stop
        } catch {
            "Unable to create log file '{0}' for '{1}'." -f $logFile, $msgType | shoutOut -MsgType Error
            "Messages marked with '{0}' will be redirected." -f $msgType | shoutOut -MsgType Error
            shoutOut $_ Error
            throw ("Unable to use log file '{0}', the file cannot be created." -f $logFile)
        }
    }

    return gi $logFile
}