# ShoutOut.ps1

# First-things first: Logging function (is the realest, push the message and let the harddrive feel it.)

<#
.SYNOPSIS
Pushes a message of the given $MsgType to the given $Log file with attached invocation metadata.
.DESCRIPTION
Logging function, used to push a message to a corresponding log-file.
The message is prepended with meta data about the invocation to shoutOut as:
<MessageType>|<Computer name>|<PID>|<calling Context>|<Date & time>|$Message

The default values for the parameters can be set using the Set-ShoutOutConfig,
Set-ShoutOutDefaultLog, and Set-ShotOutRedirect functions.

#>
function shoutOut {
    [CmdletBinding()]
	param(
        [parameter(Mandatory=$false,  position=1, ValueFromPipeline=$true, ParameterSetName="Message")]
        [Object]$Message,
        [Alias("ForegroundColor")]
		[parameter(Mandatory=$false, position=2)][String]$MsgType=$null,
		[parameter(Mandatory=$false, position=3)]$Log=$null,
		[parameter(Mandatory=$false, position=4)][Int32]$ContextLevel=1, # The number of levels to proceed up the call
                                                                         # stack when reporting the calling script.
        [parameter(Mandatory=$false)] [bool] $LogContext=$true,
        [parameter(Mandatory=$false)] [Switch] $NoNewline,
        [parameter(Mandatory=$false)] [Switch] $Quiet
	)
    
    begin {

        $settings = $_ShoutOutSettings

        # If shoutOut is disabled, return to caller.
        if ($settings.ContainsKey("Disabled") -and ($settings.Disabled)) {
            Write-Debug "Call to Shoutout, but Shoutout is disabled. Turn back on with 'Set-ShoutOutConfig -Disabled `$false'."
            return
        }

        <# Applying global variables #>
        
        if (!$Log -and $settings.containsKey("DefaultLog")) {
            $Log = $settings.DefaultLog
        }

        if (!$PSBoundParameters.ContainsKey('LogContext') -and $_ShoutOutSettings.ContainsKey("LogContext")) {
            $LogContext = $_ShoutOutSettings.LogContext
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
        
        if ( (-not $PSBoundParameters.ContainsKey("MsgType")) -or ($null -eq $PSBoundParameters["MsgType"]) ) {
            
            switch ($details.ObjectType) {

                "ErrorRecord" {
                    $MsgType = "Error"
                }

                default {
                    if ([System.Exception].IsAssignableFrom($msgObjectType)) {
                        $MsgType = "Exception"
                    } else {
                        $MsgType = $script:_ShoutOutSettings.DefaultMsgType
                    }
                }
            }
        }

        $details.MessageType = $MsgType

        if ($settings.LogFileRedirection.ContainsKey($details.MessageType)) {
            $Log = $settings.LogFileRedirection[$details.MessageType]
        }

        # Hard-coded defaults just in case.
        if (!$Log) {
            $Log = ".\shoutout.log"
        }
        
        # If the log is  a string, assume that it is a file path:
        $logHandler = Switch ($log.GetType().NAme) {
            String {
                _buildBasicFileLogger $Log
            }
            ScriptBlock {
                $Log
            }
        }

        $recurseArgs = @{}
        $PSBoundParameters.Keys | Where-Object { $_ -notin "Message", "MsgType" } | ForEach-Object {
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
                    shoutOut -Message $details.Message.Exception -MsgType Exception @recurseArgs
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

        try {

            $handlerArgs = @{}

            $LogHandler.Ast.ParamBlock.Parameters | ForEach-Object {
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

            & $LogHandler @handlerArgs

        } catch {
            "Failed to log: {0}" -f ($handlerArgs | Out-String) | Write-Error
            "using log handler: {0}" -f $logHandler | Write-Error
            $_ | Out-string | Write-Error
        }
        
    }
}