function Set-ShoutOutRedirect {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true, Position=1)][string]$msgType,
        [Parameter(ParameterSetName="StringPath", Mandatory=$true, Position=2)][string]$LogFile,
        [Parameter(ParameterSetName="Scriptblock", Mandatory=$true, Position=2)][scriptblock]$LogHandler
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
    "StringPath" {
            try {
                _ensureShoutOutLogFile $LogFile $msgType | Out-Null
            } catch {
                return $_
            }

            $log = $LogFile
        }
    }

    $oldLog = $_ShoutOutSettings.DefaultLog
    if ($_ShoutOutSettings.LogFileRedirection.ContainsKey($msgType)) {
        $oldLog = $_ShoutOutSettings.LogFileRedirection[$msgType]
    }
    "Redirecting messages of type '{0}' to '{1}'." -f $msgType, ($log | Out-String) | shoutOut -MsgType $msgType
    $_ShoutOutSettings.LogFileRedirection[$msgType] = $log
    "Messages of type '{0}' have been redirected to '{1}'." -f $msgType, $log | shoutOut -MsgType $msgType
}