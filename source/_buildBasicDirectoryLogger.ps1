
function _buildBasicDirectoryLogger {
    param(
        [Parameter(Mandatory=$true, HelpMessage="Path to the direcory where log files should be created.")]
        [string]$DirectoryPath,
        [Parameter(Mandatory=$false, HelpMessage="Name prefix that will be used for log files craeted by this handler.")]
        [string]$name="shoutout",
        [Parameter(Mandatory=$false, HelpMessage="Minimum amount of time between cleanups of the log directory")]
        [timespan]$CleanupInterval = "0:15:0.0",
        [Parameter(Mandatory=$false, HelpMessage="Minimum amount of time that log files will be retained.")]
        [timespan]$RetentionTime = "14:0:0:0.0"
    )


    $filename = '{0}.{1}.{2}.{3}.log' -f $name, $env:USERNAME, $PID, [datetime]::Now.ToString('o').replace(':', '')
    $filePath = '{0}/{1}' -f $DirectoryPath, $filename

    $cleanupState = @{}

    $Cleanup = {
        param(
            $DirectoryPath,
            $RetentionTime
        )
        Get-Variable | Out-string > "~\tmp.txt"
        Get-ChildItem -Path $DirectoryPath -Filter *.log -File | Where-Object {
            ([datetime]::Now - $_.LastWriteTime) -gt $RetentionTime
        } | Remove-Item
    }

    $startCleanup = {
        $job = Start-Job -ScriptBlock $Cleanup -Name 'Cleanup' -ArgumentList $DirectoryPath, $RetentionTime
        
        Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
            Unregister-Event $EventSubscriber.SourceIdentifier
            Remove-Job $EventSubscriber.SourceIdentifier
            Remove-Job $EventSubscriber.SourceObject.Id
        } | Out-Null
        $cleanupState.LastCleanup = [datetime]::Now
    }.GetNewClosure()

    & $startCleanup

    return {
        param($Record)
        
        # Ensure that the directory exists:
        $item = Get-Item -Path $DirectoryPath -ErrorAction SilentlyContinue
        if ($item -isnot [System.IO.DirectoryInfo]) {
            $item = New-Item -Path $DirectoryPath -ItemType Directory -Force -ErrorAction SilentlyContinue
        
            if (($null -eq $item) -or ($item -isnot [System.IO.DirectoryInfo])) {
                # "Failed to log in directory {0}. Directory does not exist and we cannot create it." -f $DirectoryPath | shoutOut -MessageType Error
                return
            }
        }

        # Write record to file:
        $Record | Out-File -FilePath $filePath -Encoding utf8 -Append
        
        # Perform log directory cleanup:
        if (([datetime]::Now - $cleanupState.LastCleanup).TotalMinutes -ge $CleanupIntervalMinutes) {
            & $startCleanup
        }

    }.GetNewClosure()
 
}