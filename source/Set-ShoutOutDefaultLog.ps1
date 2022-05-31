function Set-ShoutOutDefaultLog {
    [CmdletBinding(DefaultParameterSetName="DirectoryPath")]
    param(
        [parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1, ParameterSetName="LogFilePath", HelpMessage="Path to log file.")]
        [String]$LogFilePath,
        [parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1, ParameterSetName="LogFile", HelpMessage="FileInfo object.")]
        [System.IO.FileInfo]$LogFile,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1, ParameterSetName="DirectoryPath", HelpMessage="Path to log file.")]
        [string]$LogDirectoryPath,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1, ParameterSetName="DirectoryInfo", HelpMessage="Path to log file.")]
        [System.IO.DirectoryInfo]$LogDirectory,
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