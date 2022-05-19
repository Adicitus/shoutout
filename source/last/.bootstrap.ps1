
# Setting up default logging:
$defaultLogFilename = "{0}.{1}.{2:yyyyMMddHHmmss}.log" -f $env:COMPUTERNAME, $pid, [datetime]::Now
$defaultLogFile     = "{0}\AppData\local\ShoutOut\{1}" -f $env:USERPROFILE, $defaultLogFilename
$script:DefaultLog = _buildBasicFileLogger $defaultLogFile

Set-ShoutOutDefaultLog -LogHandler $script:DefaultLog -Global

# $script:logRegistry.values | Out-String | Write-Host