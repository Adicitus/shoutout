
# Default Configuration:
$script:_ShoutOutSettings = @{
    DefaultMsgType="Info"
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

$script:logRegistry = @{
    global = New-Object System.Collections.ArrayList
}
$script:hashCodeAttribute = 'MyInvocation'

New-Alias 'Get-ShoutOutRedirect' -Value 'Get-ShoutOutLog'

# Setting up default logging:
$defaultLogFilename = "{0}.{1}.{2:yyyyMMddHHmmss}.log" -f $env:COMPUTERNAME, $pid, [datetime]::Now
$defaultLogFile     = "{0}\AppData\local\ShoutOut\{1}" -f $env:USERPROFILE, $defaultLogFilename
$script:DefaultLog = _buildBasicFileLogger $defaultLogFile

Set-ShoutOutDefaultLog -LogHandler $script:DefaultLog -Global

# $script:logRegistry.values | Out-String | Write-Host