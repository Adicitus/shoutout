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
                $_shoutOutSettings.DefaultLog = $LogFilePath
            } catch {
                return $_
            }
        }
        "LogFile" {
            try {
                _ensureShoutOutLogFile $LogFile.FullName -ErrorAction Stop | Out-Null
                $_shoutOutSettings.DefaultLog = $LogFile.FullName
            } catch {
                return $_
            }
        }
        "LogHandler" {
            try {
                _ensureshoutOutLogHandler $LogHandler -ErrorAction Stop | Out-Null
                $_shoutOutSettings.DefaultLog = $LogHandler
            } catch {
                return $_
            }
        }
    }
    
}