if ( !(Get-variable "_ShoutOutSettings" -ErrorAction SilentlyContinue) -or $script:_ShoutOutSettings -isnot [hashtable]) {
    $script:_ShoutOutSettings = @{
        DefaultMsgType="Info"
        DefaultLog="C:\temp\shoutOut.{0}.{1}.{2:yyyyMMddHHmmss}.log" -f $env:COMPUTERNAME, $pid, [datetime]::Now
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


. "$PSScriptRoot\_ensureShoutOutLogFile.ps1"
. "$PSScriptRoot\_ensureShoutOutLogHandler.ps1"
. "$PSSCriptRoot\Set-ShoutOutConfig.ps1"
. "$PSSCriptRoot\Get-ShoutOutConfig.ps1"
. "$PSSCriptRoot\Set-ShoutOutDefaultLog.ps1"
. "$PSSCriptRoot\Get-ShoutOutDefaultLog.ps1"
. "$PSSCriptRoot\Set-ShoutOutRedirect.ps1"
. "$PSSCriptRoot\Get-ShoutOutRedirect.ps1"
. "$PSSCriptRoot\Clear-ShoutOutRedirect.ps1"
. "$PSSCriptRoot\ShoutOut.ps1"