function Set-ShoutOutDefaultLog {
    param(
        [parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1, ParameterSetName="LogFilePath", HelpMessage="Path to log file.")]
        [String]$LogFilePath,
        [parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1, ParameterSetName="LogFile", HelpMessage="FileInfo object.")]
        [System.IO.FileInfo]$LogFile,
        [parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1, ParameterSetName="LogHandler", HelpMessage="ScriptBlock to use as log handler.")]
        [scriptblock]$LogHandler,
        [Parameter(Mandatory=$false, HelpMessage="Causes the log handler to be registered on the global frame.")]
        [switch]$Global
    )

    $redirectArgs = @{
        MsgType = '*'
        Reset   = $true
    }

    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        $redirectArgs[$_.Key] = $_.Value 
    }

    return Add-ShoutOutLog @redirectArgs
    
}