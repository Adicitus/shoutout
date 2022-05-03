function _buildBasicFileLogger {
    param(
        [string]$FilePath
    )

    return {
        param($Record)

        if (-not (Test-Path $FilePath -PathType Leaf)) {
            New-Item -Path $FilePath -ItemType File -Force -ErrorAction Stop | Out-Null
        }

        $Record | Out-File $FilePath -Encoding utf8 -Append -Force
    }.GetNewClosure()
}


$script:_ShoutOutSettings = @{
    DefaultMsgType="Info"
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

$defaultLogFilename = "{0}.{1}.{2:yyyyMMddHHmmss}.log" -f $env:COMPUTERNAME, $pid, [datetime]::Now

$defaultLogFile = switch ((whoami).split('\')[0]) {
    System  {
        "{0}\Logs\shoutOut\{1}" -f $env:windir, $defaultLogFilename
    }   
    default {
        "{0}\shoutOut\Logs\{1}" -f $env:APPDATA, $defaultLogFilename
    }
}

$script:_ShoutOutSettings.DefaultLog = _buildBasicFileLogger $defaultLogFile