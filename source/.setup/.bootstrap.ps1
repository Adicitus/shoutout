
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
New-Alias 'Clear-ShoutOutRedirect' -Value 'Clear-ShoutOutLog'

# Setting up default logging:
$defaultLogFolder = "{0}\AppData\local\ShoutOut" -f $env:USERPROFILE
$script:DefaultLog = _buildBasicDirectoryLogger $defaultLogFolder

Set-ShoutOutDefaultLog -LogHandler $script:DefaultLog -Global

# $script:logRegistry.values | Out-String | Write-Host