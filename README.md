# shoutout
Powershell module for the ShoutOut, a Powershell based logger.

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
<Msgtype>|<COMPUTERNAME>|<PID>|[<Stack depth>]<scriptfile>:<line number>|<datetime-parsable string>|<datatype of the message>|<message>
````

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
#### Clear-ShoutOutRedirect $MsgType
Removes all logger redirections for the given $MsgType, all messages will be passed to the default logger.

#### Get-ShoutOutConfig
Returns the current configuration hashtable.

#### Get-ShoutOutDefaultLog
Returns the current default logger, this can be the path to a file or a scriptblock.

#### Get-shoutOutRedirect $MsgType
Returns the logger for the given $MsgType, returns $null if $MsgType is handled by the default logger.

#### Set-ShoutOutConfig
Managed way of setting ShoutOut settings.

#### Set-ShoutOutDefaultLog ($LogFilePath|$LogFile|$LogHandler)
Sets the default log handler that should receive records by default.

#### Set-ShoutOutRedirect $MsgType ($LogFile|$LogHandler)
Sets the log handler that should receive records of the given $MsgType.

#### ShoutOut
The core Cmdlet used to log messages.


## Log handlers
There are 2 general types of log handlers:
* Files
* Scriptblocks

ShoutOut always has 1 default log handler, however each MsgType may be redirected to a separate log handler.

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
  
  # Do something with the message.
}
````

In this case the $Message variable will hold the original object passed as message to shoutOut.

The following parameters are recognized by shoutOut
  - Message: The original object
  - Details: A hashtable containing the follwing keys:
    - Message: The original message.
    - MessageString: A string representation of Message (this is what shoutOut writes to host).
    - MessageType: The Message type used.
    - PID: The process ID of the originating process.
    - Computer: The name of the originating computer.
    - LogTime: Datetime indicating when ShoutOut was called.
    - Caller: String indicating where the call originated.
    - ObjectType: String name for the object type of message, or 'NULL' if message is $null.
  - Record: See the description in the introduction.

You can use any combination of these parameters, but at least one must be specified.

## Configuration
The following settings are available to modify the behavior of ShoutOut.

All settings are available through the hashtable returneed by "Get-ShoutOutConfig", howevere most settigns (with the exception of MsgStyles) have dedicated Cmdlets.

#### [string] DefaultMsgType (Set using "Set-ShoutOutConfig")
The default message type to use if none is specified in the ShoutOut call. Defaults to "Info".

#### [bool] LogContext (Set using "Set-ShoutOutConfig")
Determine wether the record should contain stack information (field nr 4: current script file, line number, stack depth).

#### ([string]|[scriptblock]) DefaultLog (Set using "Set-ShoutOutDefaultLog" or "Set-ShoutOutConfig")
The default log handler.

#### [hashtable] MsgStyles (Only available via the hashtable returned using "Get-ShoutOutConfig")
Hashtable containing information about how to style the message when outputting it to console.

Writing to Console is current performed using the Write-Host Cmdlet, however "ForegroundColor" and "BackgroundColor" are the only parameters currently accepted in MsgStyles.

#### [bool] Disabled (Set using "Set-ShoutOutConfig")
Used to turn off logging if necessary.

#### [hashtable] LogFileRedirection (Set using "Set-ShoutOutRedirect" and Get using "Get-ShoutOUtRedirect")
See the "Log Handlers" section.

