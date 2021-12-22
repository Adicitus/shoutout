function Set-ShoutOutRedirect {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true, Position=1, HelpMessage="Message type to redirect.")][string]$MsgType,
        [Parameter(ParameterSetName="FilePath", ValueFromPipeline=$true, Mandatory=$true, Position=2, HelpMessage="Path to log file.")][string]$LogFilePath,
        [Parameter(ParameterSetName="FileInfo", ValueFromPipeline=$true, Mandatory=$true, Position=2, HelpMessage="FileInfo object.")][System.IO.FileInfo]$LogFile,
        [Parameter(ParameterSetName="Scriptblock", ValueFromPipeline=$true, Mandatory=$true, Position=2, HelpMessage="ScriptBlock to use as log handler.")][scriptblock]$LogHandler
    )

    switch ($PSCmdlet.ParameterSetName) {
        "FileInfo" {
            try {
                _ensureShoutOutLogFile $LogFile.FullName $msgType | Out-Null
                $LogHandler = _buildBasicFileLogger $LogFile.FullName
            } catch {
                return $_
            }

            $log = $LogFile.FullName
        }
        "FilePath" {
            try {
                _ensureShoutOutLogFile $LogFilePath $msgType | Out-Null
                $LogHandler = _buildBasicFileLogger $LogFilePath
            } catch {
                return $_
            }
        }
    }

    try {
        $_ShoutOutSettings.LogFileRedirection[$msgType] = _ensureshoutOutLogHandler $LogHandler $MsgType
    } catch {
        return $_
    }
}