
# shoutout

ShoutOut is a PowerShell-native logging utility that is intended to be easy to get started with while also allowing for extension as necessary.

The "ShoutOut" command at it's most basic takes a message. That message to be displayed in the console and passed to a logger.

Each message can have an associated Meesage Type ("MsgType", defaults to "Info"), that will be included in the log record and may be used to determine

how the message is displayed in the console and which logger should handle the message.

By default messages are logged as Records like this:

````

Info|STOICAL01|4564|[3]C:\crm-scheduler\run.ps1:39|20200623-16:30:01|String|this is a message.

````

Where each field is separated by a "|".

The fields recorded by ShoutOut are:

````

<F1:Msgtype>|<F2:COMPUTERNAME>|<F3:PID>|[<F4a:Stack depth>]<F4b:scriptfile>:<F4c:line number>|<F5:time of the call>|<F6:datatype of the message object>|<F7:message>

````

Where:

- F1: MsgType, a string indicating the type of message being logged.

- F2: Computername, The computer where the message was logged.

- F3: PID, ID of the process that logged the message.

- F4: Context

- a: Stack depth at which the call to shoutOut was made.

- b: The file where the call to shoutout originated, or '<nofile>' if the call didn't originate from a script file.

- c: The line in the file where the call originated.

- F5: Round-trip formatted time when the call to shoutOut occurred. See [https://docs.microsoft.com/en-us/dotnet/standard/base-types/standard-date-and-time-format-strings#the-round-trip-o-o-format-specifier](https://docs.microsoft.com/en-us/dotnet/standard/base-types/standard-date-and-time-format-strings#the-round-trip-o-o-format-specifier).

- F6: Datatype name of the message object.

- F7: The message object converted to a string. ErrorRecords will be expanded include more details than standard.

Hovever custom log handlers can be defined by specifying LogHandler on Set-ShoutOUtDefaultLog and Set-ShoutOutRedirect.

Log handlers allow you to perform custom manipulation and storage of messages.

## Build instructions

This repository is in Module Project format, all scripts and assets that are to be included in the module are located under the "source directory".

Use the PSBuildModule (source: https://github.com/Adicitus/ps-build-module) module to produce a module from the project files.

You can also install ShoutOut from the Powershell Gallery ([https://www.powershellgallery.com/packages/ShoutOut](https://www.powershellgallery.com/packages/ShoutOut)):

```

Install-Module ShoutOut

```

## Commands

#### Add-ShoutOutLog [-MessageType] \<string> ([-LogFilePath] \<string>|[-LogFile] <System.IO.FileInfo>|[-LogHandler] \<ScriptBlock>) [-Global] [-Reset]

Adds a log handler for the given message type.

If the -Global switch is specified the handler will be added to the global context.

If the -Reset switch is specified all other log handlers in the current context will be removed. When combined with the -Global switch, all other log handlers will be removed across all contexts.

#### Clear-ShoutOutLog [-MessageType] \<string> [-Global]

Removes all log handlers for the given $MessageType at the current context.

If the '-Global' switch is specified, this will remove all log handlers for the given message type.

#### Get-ShoutOutConfig

Returns the current configuration hashtable.

#### Get-ShoutOutDefaultLog [-Global]

Returns all default log handlers (log handlers for messagetype '*').

#### Get-shoutOutLog ([[-MessageType] \<String>] |  -LogId \<guid>)

Returns all log handlers for the given message type, if no message type is specified, all handlers will be returned. If $logId is specified 

#### Invoke-ShoutOut [-Operation] (\<ScriptBlock>|\<string>) [-OutNull] [-NotStrict] [-LogErrorsOnly] [-Quiet]

Invokes a command (either a string or a ScriptBlock) in a separate scope, logging all output and errors from the command before returning them to the caller.

#### Set-ShoutOutConfig [-DefaultMsgType \<string>] [-EnableContextLogging <bool>] [-DisableLogging \<bool>]

Managed way of setting ShoutOut global settings.

#### Set-ShoutOutDefaultLog ([-LogFilePath] \<string>|[-LogFile] <System.IO.FileInfo>|[-LogHandler] \<ScriptBlock>) [-Global]

Sets the default log handler for the current context, removing any other log handlers for '*'.

If the -Global switch is specified, then the log handler will be added to the global context, and all other handlers for message type '*' will be removed.

#### Set-ShoutOutRedirect [-MessageType] \<string> ([-LogFilePath] \<string>|[-LogFile] <System.IO.FileInfo>|[-LogHandler] \<ScriptBlock>) [-Global]

Sets the log handler that should receive records of the given $MsgType on the current context. All other handlers for the message type will be removed.

If the -Global switch is specified, all other log handlers for the given message will be removed and the log handler will be added to the global context.

#### ShoutOut [-Message] \<Object> [[-MessageType] \<string>] [[-Log] (\<string>|\<scriptblock>)] [[-ContextLevel] \<int>] [[-LogContext] \<bool>] [-NoNewline] [-Quiet]

The core Cmdlet used to log messages.

## Log handlers

There are 2 general types of log handlers:

* Files
* Scriptblocks

By default, log handlers are associated with the latest frame on the callstack where they are defined.

Once the current context returns control back to the calling context, the handler is discarded.

If you want a handler that should be valid at any depth of the call stack, use the '-Global' switch.

When shoutout is called to log a message, it will traverse up the callstack to find any log handlers that should be used to handle the message, finally checking for global handlers.

### Files as log handlers

This is the default way to handle logging: a log file is specified, and each call to shoutOut writes the record to that file synchronously.

This has the upside of creating a comprehensive, plain-text file that can be consulted for audit without any special tools.

The downside is that the logged records cannot be made available to other processes or otherwise dsitributed: everything ends up in the file.

#### Output encoding

The records will be written to the log file as UTF8.

### ScriptBlocks as log handlers

Scriptblocks can be used to extend the logger with custom functionality (e.g. passing the message to a non-powershell based logger).

A scriptblock to use as handler should look something like this:

````
{
param([string]$Message)

<# Do something with the message. #>
}
````

In this case the $Message variable will hold the original object passed as message to shoutOut.

  

The following parameters are recognized by shoutOut

- Message: The original object

- Details: A hashtable containing the following keys:

  - Message: The original message.

  - MessageString: A string representation of Message (this is what shoutOut writes to host).

  - MessageType: The Message type used.

  - PID: The process ID of the originating process.

  - Computer: The name of the originating computer.

  - LogTime: Datetime indicating when ShoutOut was called.

  - Caller: String indicating where the call originated. This is the string that would be used to indicate context (field 4) the corresponding record. Affected by the $ContextLevel parameter (most recent $ContextLevel entries removed from the callstack). If $LogContext is $false, this will be the string '[Context logging disabled]'.

  - CallStack: The callstack at the point that shoutOut was called. This is affected by the $ContextLevel parameter (most recent $ContextLevel entries removed from the callstack). If $LogContext is $false, this key will not be included.

  - ObjectType: String name for the object type of message, or 'NULL' if message is $null.

- Record: See the description in the introduction.


You can use any combination of these parameters when creating a ScriptBlock handler, but at least one must be specified.

## Configuration

The following settings are available to modify the behavior of ShoutOut.

  

All settings are available through the hashtable returneed by "Get-ShoutOutConfig", howevere most settigns (with the exception of MsgStyles) have dedicated Cmdlets.

  

#### [string] DefaultMsgType (Set using "Set-ShoutOutConfig")

The default message type to use if none is specified in the ShoutOut call. Defaults to "Info".

#### [bool] EnableContextLogging (Set using "Set-ShoutOutConfig")

Determine wether the record should contain stack information (field nr 4: current script file, line number, stack depth).

#### [hashtable] MsgStyles (Only available via the hashtable returned using "Get-ShoutOutConfig")

Hashtable containing information about how to style the message when outputting it to console.

Writing to Console is current performed using the Write-Host Cmdlet, however "ForegroundColor" and "BackgroundColor" are the only parameters currently accepted in MsgStyles.

#### [bool] DisableLogging (Set using "Set-ShoutOutConfig")

Used to turn off logging if necessary.