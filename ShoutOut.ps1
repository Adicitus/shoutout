# ShoutOut.ps1

# First-things first: Logging function (is the realest, push the message and let the harddrive feel it.)
function shoutOut {
	param(
        [parameter(Mandatory=$false,  position=1, ValueFromPipeline=$true)] [Object]$Message,
        [Alias("ForegroundColor")]
		[parameter(Mandatory=$false, position=2)][String]$MsgType=$null,
		[parameter(Mandatory=$false, position=3)]$Log=$null,
		[parameter(Mandatory=$false, position=4)][Int32]$ContextLevel=1, # The number of levels to proceed up the call
                                                                         # stack when reporting the calling script.
        [parameter(Mandatory=$false)] [bool] $LogContext = (
            !$_ShoutOutSettings.ContainsKey("LogContext") -or ($_ShoutOutSettings.ContainsKey("LogContext") -and $_ShoutOutSettings.LogContext)
        ),
        [parameter(Mandatory=$false)] [Switch] $NoNewline,
        [parameter(Mandatory=$false)] [Switch] $Quiet
	)
    
    process {
        $defaultLogHandler = { param($msg) $msg | Out-File $Log -Encoding utf8 -Append }

        # Apply global settings.
        if ( ( $settingsV = Get-Variable "_ShoutOutSettings" ) -and ($settingsV.Value -is [hashtable]) ) {
            $settings = $settingsV.Value
            if (!$MsgType -and $settings.containsKey("DefaultMsgType")) { $MsgType = $settings.DefaultMsgType }
            if (!$Log -and $settings.containsKey("DefaultLog")) { $Log = $settings.DefaultLog }
            if ($settings.LogFileRedirection.ContainsKey($MsgType)) { $Log = $settings.LogFileRedirection[$MsgType] }
            
            if ($settings.containsKey("MsgStyles") -and ($settings.MsgStyles -is [hashtable]) -and $settings.MsgStyles.containsKey($MsgType)) {
                $msgStyle = $settings.MsgStyles[$MsgType]
            }
        }

        # Hard-coded defaults just in case.
        if (!$MsgType) { $MsgType = "Information" }
        if (!$Log) { $Log = ".\setup.log" }
        
        if (!$msgStyle) {
            if ($MsgType -in [enum]::GetNames([System.ConsoleColor])) {
                $msgStyle = @{ ForegroundColor=$MsgType }
            } else {
                $msgStyle = @{ ForegroundColor="White" }
            }
        }
        
        # Apply formatting to make output more readable.
        if ($Message -isnot [String]) {
            $message = $message | Out-String
        }

	    if ([Environment]::UserInteractive -and !$Quiet) {
            $p = @{
                Object = $Message
                NoNewline = $NoNewline
            }
            if ($msgStyle.ForegroundColor) { $p.ForegroundColor = $msgStyle.ForegroundColor }
            if ($msgStyle.BAckgroundColor) { $p.BackgroundColor = $msgStyle.BackgroundColor }

            Write-Host @p
        }
        
        $parentContext = if ($LogContext) {
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
            param($m)
            "{0}|{1}|{2}|{3}|{4:yyyyMMdd-HH:mm:ss}|{5}" -f $MsgType, $env:COMPUTERNAME, $pid, $parentContext, [datetime]::Now, $m
        }

        $record = . $createRecord $Message

        if ($log -is [scriptblock])  {
            try {
                . $Log -Message $record
            } catch {
                $errorMsgRecord1 = . $createRecord ("An error occurred while trying to log a message to '{0}'" -f ( $Log | Out-String))
                $errorMsgRecord2 = . $createRecord "The following is the record that would have been written:"
                $Log = "{0}\shoutOut.error.{1}.{2}.{3:yyyyMMddHHmmss}.log" -f $env:APPDATA, $env:COMPUTERNAME, $pid, [datetime]::Now
                $errorRecord = . $createRecord ($_ | Out-String)
                . $defaultLogHandler $errorMsgRecord1
                . $defaultLogHandler $errorRecord
                . $defaultLogHandler $errorMsgRecord2
                . $defaultLogHandler $record
            }
        } else {
            . $defaultLogHandler $record
        }
        
    }
}