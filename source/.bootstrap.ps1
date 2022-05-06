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
$defaultLogFile     = "{0}\AppData\local\ShoutOut\{1}" -f $env:USERPROFILE, $defaultLogFilename

$script:_ShoutOutSettings.DefaultLog = _buildBasicFileLogger $defaultLogFile