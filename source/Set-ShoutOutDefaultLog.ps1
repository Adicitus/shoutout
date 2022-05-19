function Set-ShoutOutDefaultLog {
    param(
        [parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1, ParameterSetName="LogFilePath")][String]$LogFilePath,
        [parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1, ParameterSetName="LogFile")][System.IO.FileInfo]$LogFile,
        [parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1, ParameterSetName="LogHandler")][scriptblock]$LogHandler,
        [Parameter(Mandatory=$false)][switch]$Global
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