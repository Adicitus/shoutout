function Add-ShoutOutLog {
    [CmdletBinding(DefaultParameterSetName="DirectoryPath")]
    param(
        [parameter(Mandatory=$true, Position=1, HelpMessage="Message type to redirect.")]
        [Alias('MsgType')]
        [string]$MessageType,
        [Parameter(ParameterSetName="FilePath", ValueFromPipeline=$true, Mandatory=$true, Position=2, HelpMessage="Path to log file.")]
        [string]$LogFilePath,
        [Parameter(ParameterSetName="FileInfo", ValueFromPipeline=$true, Mandatory=$true, Position=2, HelpMessage="FileInfo object.")]
        [System.IO.FileInfo]$LogFile,
        [Parameter(ParameterSetName="DirectoryPath", ValueFromPipeline=$true, Mandatory=$true, Position=2, HelpMessage="Path to log file.")]
        [string]$LogDirectoryPath,
        [Parameter(ParameterSetName="DirectoryInfo", ValueFromPipeline=$true, Mandatory=$true, Position=2, HelpMessage="Path to log file.")]
        [System.IO.DirectoryInfo]$LogDirectory,
        [Parameter(ParameterSetName="Scriptblock", ValueFromPipeline=$true, Mandatory=$true, Position=2, HelpMessage="ScriptBlock to use as log handler.")]
        [scriptblock]$LogHandler,
        [Parameter(Mandatory=$false, HelpMessage="Causes the log handler to be registered on the global frame.")]
        [switch]$Global,
        [Parameter(Mandatory=$false, HelpMessage="Clear all log handlers for this message type on the current frame. If used with -Global this will remove all log handlers for the message type up to and including the global frame.")]
        [switch]$Reset
    )

    switch ($PSCmdlet.ParameterSetName) {
        "FileInfo" {
            try {
                _ensureShoutOutLogFile $LogFile.FullName $MessageType | Out-Null
                $LogHandler = _buildBasicFileLogger $LogFile.FullName
            } catch {
                return $_
            }
        }
        "FilePath" {
            try {
                _ensureShoutOutLogFile $LogFilePath $MessageType | Out-Null
                $LogHandler = _buildBasicFileLogger $LogFilePath
            } catch {
                return $_
            }
        }
        "DirectoryInfo" {
            try {
                $LogHandler = _buildBasicDirectoryLogger $LogDirectory.FullName
            } catch {
                return $_
            }
        }
        "DirectoryPath" {
            try {
                $LogHandler = _buildBasicDirectoryLogger $LogDirectoryPath
            } catch {
                return $_
            }
        }
    }

    try {
        $cs = Get-PSCallStack
        $logHandler = _validateShoutOutLogHandler $LogHandler $MessageType
        $injectArgs = @{
            InjectionFrame = $cs[1]
            MessageType = $MessageType
            Handler = $logHandler
        }
        if ((Get-PSCallStack)[1].Command -in 'Set-ShoutOutDefaultLog', 'Set-ShoutOutRedirect') {
            $injectArgs.InjectionFrame = $cs[2]
        }
        if ($PSBoundParameters.ContainsKey('Global')) {
            $injectArgs.remove('InjectionFrame')
        }
        if ($PSBoundParameters.ContainsKey('Reset')) {
            $handlers = Get-ShoutOutLog
            if (-not $PSBoundParameters.ContainsKey('Global')) {
                $hash = if ($InjectArgs.InjectionFrame) {
                    $InjectArgs.InjectionFrame.GetFrameVariables().$script:hashCodeAttribute.value.getHashCode()
                } else {
                    'global'
                }
                $handlers = $handlers | Where-Object { $_.frame -eq $hash }
            }
            $handlers | Where-Object { $_.MessageType -eq $MessageType } | ForEach-Object {
                _removeLogHandler $_.Id | Out-Null
            }
        }
        _injectLogHandler @injectArgs 
    } catch {
        return $_
    }
}