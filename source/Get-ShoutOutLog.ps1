
function Get-ShoutOutLog {
    param(
        [Parameter(Mandatory=$false, HelpMessage="Message Type to retrieve redirection information for.")]
        [Alias('MsgType')]
        [string]$MessageType
    )

    

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