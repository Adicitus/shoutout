function Set-ShoutOutRedirect {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true, Position=1, HelpMessage="Message type to redirect.")][string]$MsgType,
        [Parameter(ParameterSetName="FilePath", ValueFromPipeline=$true, Mandatory=$true, Position=2, HelpMessage="Path to log file.")][string]$LogFilePath,
        [Parameter(ParameterSetName="FileInfo", ValueFromPipeline=$true, Mandatory=$true, Position=2, HelpMessage="FileInfo object.")][System.IO.FileInfo]$LogFile,
        [Parameter(ParameterSetName="Scriptblock", ValueFromPipeline=$true, Mandatory=$true, Position=2, HelpMessage="ScriptBlock to use as log handler.")][scriptblock]$LogHandler
    )


    $log = $null
    switch ($PSCmdlet.ParameterSetName) {
    "Scriptblock" {
            try {
                _ensureshoutOutLogHandler $LogHandler $msgType | Out-Null
            } catch {
                return $_
            }
            $log = $LogHandler
            break
        }
    "FileInfo" {
            try {
                _ensureShoutOutLogFile $LogFile.FullName $msgType | Out-Null
                $_shoutOutSettings.DefaultLog = $LogFile.FullName
            } catch {
                return $_
            }

            $log = $LogFile.FullName
        }
    "FilePath" {
            try {
                _ensureShoutOutLogFile $LogFilePath $msgType | Out-Null
            } catch {
                return $_
            }

            $log = $LogFilePath
        }
    }

    $oldLog = $_ShoutOutSettings.DefaultLog
    if ($_ShoutOutSettings.LogFileRedirection.ContainsKey($msgType)) {
        $oldLog = $_ShoutOutSettings.LogFileRedirection[$msgType]
    }
    "Redirecting messages of type '{0}' to '{1}'." -f $msgType, $log | shoutOut -MsgType Info
    $_ShoutOutSettings.LogFileRedirection[$msgType] = $log
    "Messages of type '{0}' have been redirected to '{1}'." -f $msgType, $log | shoutOut -MsgType Info
    "Previous log: '{1}'." -f $msgType, $oldLog | shoutOut -MsgType Info
}