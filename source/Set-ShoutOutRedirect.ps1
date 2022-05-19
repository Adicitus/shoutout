function Set-ShoutOutRedirect {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true, Position=1, HelpMessage="Message type to redirect.")][string]$MsgType,
        [Parameter(ParameterSetName="FilePath", ValueFromPipeline=$true, Mandatory=$true, Position=2, HelpMessage="Path to log file.")][string]$LogFilePath,
        [Parameter(ParameterSetName="FileInfo", ValueFromPipeline=$true, Mandatory=$true, Position=2, HelpMessage="FileInfo object.")][System.IO.FileInfo]$LogFile,
        [Parameter(ParameterSetName="Scriptblock", ValueFromPipeline=$true, Mandatory=$true, Position=2, HelpMessage="ScriptBlock to use as log handler.")][scriptblock]$LogHandler,
        [Parameter(Mandatory=$false)][switch]$Global
    )

    $redirectArgs = @{
        Reset   = $true
    }

    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        $redirectArgs[$_.Key] = $_.Value 
    }

    return Add-ShoutOutLog @redirectArgs
}