function Set-ShoutOutDefaultLog {
    param(
        [parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1, ParameterSetName="LogFilePath")][String]$LogFilePath,
        [parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1, ParameterSetName="LogFile")][System.IO.FileInfo]$LogFile,
        [parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1, ParameterSetName="LogHandler")][scriptblock]$LogHandler
    )

    switch ($PSCmdlet.ParameterSetName) {
        "LogFilePath" {
            try {
                _ensureShoutOutLogFile $LogFilePath -ErrorAction Stop | Out-Null
                $LogHandler = _buildBasicFileLogger $LogFilePath
            } catch {
                return $_
            }
        }
        "LogFile" {
            try {
                _ensureShoutOutLogFile $LogFile.FullName -ErrorAction Stop | Out-Null
                $LogHandler = _buildBasicFileLogger $LogFile.FullName
            } catch {
                return $_
            }
        }
    }

    try {
        $_shoutOutSettings.DefaultLog = _validateShoutOutLogHandler $LogHandler -ErrorAction Stop
    } catch {
        return $_
    }
    
}