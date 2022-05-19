function Add-ShoutOutLog {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true, Position=1, HelpMessage="Message type to redirect.")]
        [Alias('MsgType')]
        [string]$MessageType,
        [Parameter(ParameterSetName="FilePath", ValueFromPipeline=$true, Mandatory=$true, Position=2, HelpMessage="Path to log file.")]
        [string]$LogFilePath,
        [Parameter(ParameterSetName="FileInfo", ValueFromPipeline=$true, Mandatory=$true, Position=2, HelpMessage="FileInfo object.")]
        [System.IO.FileInfo]$LogFile,
        [Parameter(ParameterSetName="Scriptblock", ValueFromPipeline=$true, Mandatory=$true, Position=2, HelpMessage="ScriptBlock to use as log handler.")]
        [scriptblock]$LogHandler,
        [Parameter(Mandatory=$false)]
        [switch]$Global,
        [Parameter(Mandatory=$false)]
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