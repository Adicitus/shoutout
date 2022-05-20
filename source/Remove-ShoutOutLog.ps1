function Remove-ShoutOutLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=1, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true, HelpMessage="Id of the log handler to remove")]
        [guid[]]$LogId
    )

    process {
        foreach ($id in $logId) {
            foreach ($context in $script:logRegistry.Keys) {

                $context | Write-Host -Fore Magenta

                $handlers = $script:logRegistry[$context]

                foreach ($handler in $handlers) {

                    if ($handler.id -eq $id) {
                        $handlers.remove($handler)
                        break
                    }
                }
            }
        }
    }
}