function _buildBasicFileLogger {
    param(
        [string]$FilePath
    )

    return {
        param($message)
        $message | Out-File $FilePath -Encoding utf8 -Append
    }.GetNewClosure()
}


if ( !(Get-variable "_ShoutOutSettings" -ErrorAction SilentlyContinue) -or $script:_ShoutOutSettings -isnot [hashtable]) {
    $script:_ShoutOutSettings = @{
        DefaultMsgType="Info"
        DefaultLog=_buildBasicFileLogger ("C:\temp\shoutOut.{0}.{1}.{2:yyyyMMddHHmmss}.log" -f $env:COMPUTERNAME, $pid, [datetime]::Now)
        LogFileRedirection=@{}
        MsgStyles=@{
            Success =       @{ ForegroundColor="Green" }
            Exception =     @{ ForegroundColor="Red"; BackgroundColor="Black" }
            Error =         @{ ForegroundColor="Red" }
            Warning =       @{ ForegroundColor="Yellow"; BackgroundColor="Black" }
            Info =          @{ ForegroundColor="Cyan" }
            Result =        @{ ForegroundColor="White" }
        }
        LogContext=$true
        Disabled=$false
    }
}