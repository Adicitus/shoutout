
function Get-ShoutOutLog {
    [CmdletBinding(DefaultParameterSetName="MessageType")]
    param(
        [Parameter(Mandatory=$false, ParameterSetName="MessageType", HelpMessage="Message Type to retrieve log handlers for.")]
        [Alias('MsgType')]
        [string]$MessageType,
        [Parameter(Mandatory=$true, ParameterSetName="LogId", HelpMessage="ID of the log handler to retrieve")]
        [guid]$LogId
    )

    switch ($PSCmdlet.ParameterSetName) {
        MessageType {
            $foundHandlers = New-Object System.Collections.ArrayList

            foreach ($context in $script:logRegistry.Keys) {

                $handlers = $script:logRegistry[$context]

                $handlers | Where-Object {
                    ('' -eq $MessageType) -or ($_.MessageType -eq $MessageType)
                } | ForEach-Object {
                    $foundHandlers.Add($_) | Out-Null
                }
            }

            return $foundHandlers
        }

        LogId {
            foreach ($context in $script:logRegistry.Keys) {
                $handlers = $script:logRegistry[$context]

                $id = $LogId.Guid

                foreach ($handler in $handlers) {
                    if ($handler.id -eq $id) {
                        return $handlers[$id]
                    }
                }
            }
        }
    }
} 