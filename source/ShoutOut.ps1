# ShoutOut.ps1

# First-things first: Logging function (is the realest, push the message and let the harddrive feel it.)

<#
.SYNOPSIS
Pushes a message of the given $MessageType to the appropriate log handlers.
.DESCRIPTION
Logging function, used to push a message to a corresponding log handlers.

The default log handler type is a Record handler, in thich The message is prepended with meta data about
the invocation to shoutOut as:

<MessageType>|<Computer name>|<PID>|<calling Context>|<Date & time>|<Message object type>|<$Message as a string>

The other types of log handlers are 'Message' (just receives the raw message object) and 'Details' (the raw message
along with the same metadata that is summarized for the 'Record' type).

If an ErrorRecord or Exception object is passed to shoutout, will attempt to expand the object
to make the output of 'Record' type handlers more detailed.

The default values for the parameters can be set using the Set-ShoutOutConfig,
Set-ShoutOutDefaultLog, Set-ShotOutRedirect and Add-ShoutOutLog functions.

.PARAMETER Message
Message object to log.

.PARAMETER MessageType
The type of message to log. By default ShoutOut is intended to handle the following types:
 - Success: Indicating a positive outcome.
 - Error: Indicating that the message is or is related to an Error (typically an [ErrorRecord] object). Comparable with Write-Error.
 - Exception: Indicates that the message is or is related to an Exception.
 - Warning: Indicates that the message relates to a non-fatal irregularity in the system.
 - Info: Indicates that the message is purely informational. This is the standard default message type. Comparable with Write-Host.
 - Result: Indicates that the message is related to an output value from an operation. Comparable with write output.

 Each of these types have standard output color presets.
 
 In practice ShoutOut will accept any given string.

.PARAMETER Log
Overrides the standard log-selection process and forces shoutout to use the provided log.

If this parameter is a string it will be interpreted as the path to a file where log records
should be written.

If this is a ScriptBlock, it should have one of the accepted parameters:
- Message
- Details 
- Record

See the overall ShoutOut README.md for details on Log Handlers.

.PARAMETER ContextLevel
The number of steps to climb up the callstack when reporting context.

0: Include the call to shoutout.
1: Include the callstack from the call to the context where shoutout was called.

Default is 1.

When using a Record-type log handler the last element in the stack will be reported as the calling context.

.PARAMETER LogContext
If set to $false, no context information will be included in the log (no 'Callstack' for Details, no calling context for Record handlers).

.PARAMETER NoNewLine
Omits the newline when writing to console/host.

.PARAMETER Quiet
Disables all writing to console/host.

#>
function shoutOut {
    [CmdletBinding()]
	param(
        [Alias('Msg')]
        [parameter(Mandatory=$false,  position=1, ValueFromPipeline=$true, ParameterSetName="Message", HelpMessage="Message object to log")]
        [Object]$Message,
        [Alias("ForegroundColor")]
        [Alias("MsgType")]
		[parameter(Mandatory=$false, position=2, HelpMessage="The type of message log. If this is not specified it will be calculated based on the input type and shoutout configuration.")]
        [String]$MessageType=$null,
		[parameter(Mandatory=$false, position=3, HelpMessage="Path to a file or a Scriptblock to use to log the message.")]
        $Log=$null,
		[parameter(Mandatory=$false, position=4, HelpMessage="How many levels to remove from the callstack when reporting the caller context. 0 will include the call to ShoutOut. Default is 1")]
        [Int32]$ContextLevel=1, # The number of levels to proceed up the call
                                # stack when reporting the calling script.
        [parameter(Mandatory=$false, HelpMessage="Determines if context information should be logged.")]
        [bool] $LogContext=$true,
        [parameter(Mandatory=$false, HelpMessage="If set, omits the newline when writing to console/host.")]
        [Switch] $NoNewline,
        [parameter(Mandatory=$false, HelpMessage="If set, no output will be printed to console/host.")]
        [Switch] $Quiet
	)
    
    begin {

        $settings = $_ShoutOutSettings

        # If shoutOut is disabled, return to caller.
        if ($settings.ContainsKey("Disabled") -and ($settings.Disabled)) {
            Write-Debug "Call to Shoutout, but Shoutout is disabled. Turn back on with 'Set-ShoutOutConfig -Disabled `$false'."
            return
        }

        <# Applying global variables #>

        if (!$PSBoundParameters.ContainsKey('LogContext') -and $_ShoutOutSettings.ContainsKey("LogContext")) {
            $LogContext = $_ShoutOutSettings.LogContext
        }
        if (!$PSBoundParameters.ContainsKey('Quiet') -and $_ShoutOutSettings.ContainsKey("Quiet")) {
            $Quiet = $_ShoutOutSettings.Quiet
        }
    }

    process {

        $details = @{
            Message    = $Message
            Computer    = $env:COMPUTERNAME
            LogTime     = [datetime]::Now
            PID         = $pid
        }

        $msgObjectType = if ($null -ne $Message) {
            $Message.GetType()
        } else {
            $null
        }

        $details.ObjectType = if ($null -ne $msgObjectType) {
            $msgObjectType.Name
        } else {
            "NULL"
        }
        
        if ( (-not $PSBoundParameters.ContainsKey("MessageType")) -or ($null -eq $PSBoundParameters["MessageType"]) ) {
            
            switch ($details.ObjectType) {

                "ErrorRecord" {
                    $MessageType = "Error"
                }

                default {
                    if ([System.Exception].IsAssignableFrom($msgObjectType)) {
                        $MessageType = "Exception"
                    } else {
                        $MessageType = $script:_ShoutOutSettings.DefaultMsgType
                    }
                }
            }
        }

        $details.MessageType = $MessageType

        $logHandlers = if ($null -eq $Log) {
            _resolveLogHandler -MessageType $MessageType | ForEach-Object Handler
        } else {
            Switch ($log.GetType().Name) {
                String {
                    @{ Handler = @(_buildBasicFileLogger $Log) }
                }
                ScriptBlock {
                    @{ Handler = $Log }
                }
            }
        }

        $recurseArgs = @{}
        $PSBoundParameters.Keys | Where-Object { $_ -notin "Message", "MsgType", "MessageType" } | ForEach-Object {
            $recurseArgs[$_] = $PSBoundParameters[$_]
        }
        if ($recurseArgs.ContainsKey('ContextLevel')) {
            $recurseArgs.ContextLevel += 1
        } else {
            $recurseArgs.ContextLevel = 2
        }

        $messageString = $null
        # Apply formatting to make output more readable.
        switch ($details.ObjectType) {

            "String" {
                # No transformation necessary.
                $messageString = $details.Message
            }

            "NULL" {
                # No Transformation necessary.
                $messageString = ""
            }

            "ErrorRecord" {
                if ($null -ne $details.Message.Exception) {
                    shoutOut -Message $details.Message.Exception @recurseArgs
                }

                $m = $details.Message
                $MessageString = 'Exception', 'CategoryInfo', 'InvocationInfo', 'ScriptStackTrace' | ForEach-Object { $m.$_ } | Out-string | ForEach-Object Split "`n`r" | Where-Object { $_ }
                $MessageString = $MessageString -join "`n"
            }

            default {
                $t = $details.Message.GetType()
                if ([System.Exception].IsAssignableFrom($t)) {
                    if ($null -ne $details.Message.InnerException) {
                        shoutOut $details.Message.InnerException @recurseArgs
                    }
                    $m = $details.Message
                    $MessageString = 'message', 'Source', 'Stacktrace', 'TargetSite' | ForEach-Object { $m.$_ } | Out-string | ForEach-Object Split "`n`r" | Where-Object { $_ }
                    $MessageString = $MessageString -join "`n`r"
                } else {
                    $messageString = $Message | Out-String | ForEach-Object TrimEnd "`n`r"
                }
            }
        }

        $details.MessageString = $MessageString

        # Print to console if necessary
	    if ([Environment]::UserInteractive -and !$Quiet) {

            if ($settings.containsKey("MsgStyles") -and ($settings.MsgStyles -is [hashtable]) -and $settings.MsgStyles.containsKey($details.MessageType)) {
                $msgStyle = $settings.MsgStyles[$details.MessageType]
            }
            
            if (!$msgStyle) {
                if ($details.MessageType -in [enum]::GetNames([System.ConsoleColor])) {
                    $msgStyle = @{ ForegroundColor=$details.MessageType }
                } else {
                    $msgStyle = @{ ForegroundColor="White" }
                }
            }

            $p = @{
                Object = $details.MessageString
                NoNewline = $NoNewline
            }
            if ($msgStyle.ForegroundColor) { $p.ForegroundColor = $msgStyle.ForegroundColor }
            if ($msgStyle.BAckgroundColor) { $p.BackgroundColor = $msgStyle.BackgroundColor }

            Write-Host @p
        }
        
        # Calculate parent/calling context
        $details.Caller = if ($LogContext) {

            
            # Calculate the callstack.

            $cs = Get-PSCallStack
            # Adjust ContextLevel if it is greater than the total size of the callstack:
            if ($cs.Length -le $ContextLevel) {
                $ContextLevel = $cs.Length - 1
            }
            $cs = $cs[$ContextLevel..($cs.length - 1)]

            # Record the callstack on details:
            $details.CallStack = $cs

            # Calculate caller context:
            $l  = if ($null -eq $cs[0].ScriptName) {
                "<No file>"
            } else {
                '{0}:{1}' -f $cs[0].ScriptName, $cs[0].ScriptLineNumber
            }
            "[{0}]{1}" -f ($cs.length), $l
        } else {
            "[context logging disabled]"
        }

        $createRecord = {
            param($details)

            "{0}|{1}|{2}|{3}|{4}|{5}|{6}" -f @( 
                $details.MessageType,
                $details.Computer,
                $details.PID,
                $details.Caller,
                $details.LogTime.toString('o'),
                $details.ObjectType,
                $details.MessageString
            )
        }

        foreach ($handler in $logHandlers) {
            try {
                $handlerArgs = @{}

                $handler.Ast.ParamBlock.Parameters | ForEach-Object {
                    $n = $_.Name.Extent.Text.TrimStart('$')
                    switch ($n) {
                        Message {
                            $handlerArgs.$n = $details.Message
                        }
                        Record {
                            $handlerArgs.$n = & $createRecord $details
                        }
                        Details {
                            $handlerArgs.$n = $details
                        }
                    }
                }

                & $handler @handlerArgs

            } catch {
                "Failed to log: {0}" -f ($handlerArgs | Out-String) | Write-Error
                "using log handler: '{0}'" -f $handler | Write-Error
                $_ | Out-string | Write-Error
            }
        }
    }
}