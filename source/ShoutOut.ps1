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
        # Preprocessing of all variables that are not message-specific
        $defaultHandler = { param($msg, $logFile) $msg | Out-File $Log -Encoding utf8 -Append }

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

        $fields = @{
            Computer    = $env:COMPUTERNAME
            LogTime     = [datetime]::Now
            PID         = $pid
        }

        $msgObjectType = if ($null -ne $Message) {
            $Message.GetType()
        } else {
            $null
        }

        $fields.ObjectType = if ($null -ne $msgObjectType) {
            $msgObjectType.Name
        } else {
            "NULL"
        }
        
        if ( (-not $PSBoundParameters.ContainsKey("MsgType")) -or ($null -eq $PSBoundParameters["MsgType"]) ) {
            
            switch ($fields.ObjectType) {

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

        $fields.MessageType = $MsgType

        if ($settings.LogFileRedirection.ContainsKey($fields.MessageType)) {
            $Log = $settings.LogFileRedirection[$fields.MessageType]
        }

        # Hard-coded defaults just in case.
        if (!$Log) { $Log = ".\shoutout.log" }
        
        # Apply formatting to make output more readable.
        switch ($fields.ObjectType) {

            "String" {
                # No transformation necessary.
            }

            "NULL" {
                # No Transformation necessary.
            }

            "ErrorRecord" {
                if ($null -ne $message.Exception) {
                    shoutOut $message.Exception
                }

                if ($null -ne $message.InnerException) {
                    shoutOut $message.InnerException
                }

                $m = $message
                $Message = $m.Exception, $m.CategoryInfo, $m.InvocationInfo, $m.ScriptStackTrace | Out-string | ForEach-Object Split "`n`r" | Where-Object { $_ }
                $Message = $Message | Out-String | ForEach-Object TrimEnd "`n`r"
            }

            default {
                $message = $Message | Out-String | ForEach-Object TrimEnd "`n`r"
            }
        }

        $fields.Message = $Message

        # Print to console if necessary
	    if ([Environment]::UserInteractive -and !$Quiet) {

            if ($settings.containsKey("MsgStyles") -and ($settings.MsgStyles -is [hashtable]) -and $settings.MsgStyles.containsKey($fields.MessageType)) {
                $msgStyle = $settings.MsgStyles[$fields.MessageType]
            }
            
            if (!$msgStyle) {
                if ($fields.MessageType -in [enum]::GetNames([System.ConsoleColor])) {
                    $msgStyle = @{ ForegroundColor=$fields.MessageType }
                } else {
                    $msgStyle = @{ ForegroundColor="White" }
                }
            }

            $p = @{
                Object = $fields.Message
                NoNewline = $NoNewline
            }
            if ($msgStyle.ForegroundColor) { $p.ForegroundColor = $msgStyle.ForegroundColor }
            if ($msgStyle.BAckgroundColor) { $p.BackgroundColor = $msgStyle.BackgroundColor }

            Write-Host @p
        }
        
        # Calculate parent/calling context
        $fields.Caller = if ($LogContext) {
            $cs = Get-PSCallStack
            $csd = @($cs).Length
            # CallStack Depth, should always be greater than or equal to 2. 1 would indicate that we
            # are running the directly on the command line, but since we are inside the shoutOut
            # function there should always be at least one level to the callstack in addition to the
            # calling context.
            switch ($csd) {
                2 { "[{0}]<commandline>" -f $csd }
                
                default {
                    $parentCall = $cs[$ContextLevel]
                    if ($parentCall.ScriptName) {
                        "[{0}]{1}:{2}" -f $csd, $parentCall.ScriptName,$parentCall.ScriptLineNumber
                    } else {
                        for($i = $ContextLevel; $i -lt $cs.Length; $i++) {
                            $level = $cs[$i]
                            if ($level.ScriptName) {
                                break;
                            }
                        }

                        if ($level.ScriptName) {
                            "[{0}]{1}:{2}\<scriptblock>" -f $csd, $level.ScriptName,$level.ScriptLineNumber
                        } else {
                            "[{0}]<commandline>\<scriptblock>" -f $csd
                        }
                    }
                }
            }
        } else {
            "[context logging disabled]"
        }

        $createRecord = {
            param($fields)

            "{0}|{1}|{2}|{3}|{4}|{5}|{6}" -f @( 
                $fields.MessageType,
                $fields.Computer,
                $fields.PID,
                $fields.Caller,
                $fields.LogTime.toString('o'),
                $fields.ObjectType,
                $fields.Message
            )
        }

        $record = & $createRecord $fields

        if ($log -is [scriptblock])  {
            try {
                . $Log -Message $record
            } catch {
                $errorMsgRecord1 = . $createRecord ("An error occurred while trying to log a message to '{0}'" -f ( $Log | Out-String))
                $errorMsgRecord2 = . $createRecord "The following is the record that would have been written:"
                $Log = "{0}\shoutOut.error.{1}.{2}.{3:yyyyMMddHHmmss}.log" -f $env:APPDATA, $env:COMPUTERNAME, $pid, [datetime]::Now
                $errorRecord = . $createRecord ($_ | Out-String)
                . $defaultHandler $errorMsgRecord1
                . $defaultHandler $errorRecord
                . $defaultHandler $errorMsgRecord2
                . $defaultHandler $record
            }
        } else {
            . $defaultHandler $record
        }
        
    }
}