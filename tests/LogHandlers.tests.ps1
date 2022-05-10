BeforeAll {
    Set-ShoutOutDefaultLog { param($Message) $Message | Write-Host  }
}

Describe "LogHandler" {

    Context "File" {
        Context "LogFilePath" {
            
            BeforeAll {
                $paths = @{
                    Root = "{0}\{1}" -f $env:TEMP, [guid]::NewGuid()
                }
            }

            BeforeEach {
                $paths.testFolder = "{0}\{1}" -f $paths.Root, [guid]::NewGuid()
            }

            AfterEach {
                if (Test-Path -Path $paths.testFolder -PathType Container) {
                    Remove-Item -Path $paths.testFolder -Recurse -Force
                }
            }

            AfterAll {
                if (Test-Path -Path $paths.Root -PathType Container) {
                    Remove-Item -Path $paths.Root -Recurse -Force
                }
            }

            It "ShouldCreateParentIfItDoesNotExist"  {
                $testLogFile = "{0}\shoutout.log" -f $paths.testFolder
                Test-Path -Path $paths.testFolder -PathType Container | Should -Be $false
                Set-ShoutOutDefaultLog -LogFilePath $testLogFile
                Test-Path -Path $paths.testFolder -PathType Container | Should -Be $true
            }
            
            It "ShouldAcceptParentIfItDoesExist"  {
                $testLogFile = "{0}\shoutout.log" -f $paths.testFolder
                $i = New-Item -Path $paths.testFolder -ItemType Directory -Force
                Set-ShoutOutDefaultLog -LogFilePath $testLogFile
                Test-Path -Path $paths.testFolder -PathType Container | Should -Be $true
                $i2 = Get-Item -Path $paths.testFolder
                $i2.LastWriteTime -eq $i.LastWriteTime | Should -Be $true
                $i2.FullName -eq $i.FullName | Should -Be $true
                $i2.Attributes -eq $i.Attributes | Should -Be $true
            }

            It "ShouldCreateFileIfItDoesNotExist"  {
                $testLogFile = "{0}\shoutout.log" -f $paths.testFolder
                Test-Path -Path $testLogFile -PathType Leaf | Should -Be $false
                Set-ShoutOutDefaultLog -LogFilePath $testLogFile
                Test-Path -Path $testLogFile -PathType Leaf | Should -Be $true
            }
            
            It "ShouldAcceptFileIfItDoesExist"  {
                $testLogFile = "{0}\shoutout.log" -f $paths.testFolder
                $i = New-Item -Path $testLogFile -ItemType File -Force
                Set-ShoutOutDefaultLog -LogFilePath $testLogFile
                Test-Path -Path $testLogFile -PathType Leaf | Should -Be $true
                $i2 = Get-Item -Path $testLogFile
                $i2.LastWriteTime | Should -Be $i.LastWriteTime
                $i2.FullName | Should -Be $i.FullName
                $i2.Attributes | Should -Be $i.Attributes
            }

            It "ShouldWriteRecordToFile" {
                $testLogFile = "{0}\shoutout.log" -f $paths.testFolder
                $msg = "Test"
                $msgType = "Info"
                Set-ShoutOutDefaultLog -LogFilePath $testLogFile
                shoutOut -Message $msg -MsgType $msgType
                $record = Get-Content -Path $testLogFile -Last 1
                $fields = $record.split('|')
                $fields.count | Should -Be 7
                $fields[0] | Should -Be $msgType
                $fields[1] | Should -Be $env:COMPUTERNAME
                $fields[2] | Should -Be $PID
                $fields[3] | Should -Match '^\[(?<depth>[1-9]+)\](?<file>.+):(?<line>[0-9]+)$'
                [datetime]::Parse($fields[4])
                $fields[5] | Should -Be $msg.GetType().Name
                $fields[6] | Should -Be $msg
            }
        }
    }

    Context "ScriptBlock" {

        Context "Using Parameter 'Message'" {
            It 'Should receive the object used as message.' {
                $out = @{}
                $srcMsg = [guid]::NewGuid()
                Set-ShoutOutRedirect -LogHandler { param($Message) $out.Msg = $Message } -MsgType MessageHandler
                shoutOut $srcMsg -MsgType MessageHandler -Quiet
                $out.Msg | Should -Not -Be $null
                $out.Msg | Should -BeOfType $srcMsg.GetType()
                $out.Msg -eq $srcMsg | Should -Be $true
            }
        }
        

        Context "Using Parameter 'Details'" {
            BeforeAll {
                $MsgType = "DetailsHandler"
                $out = @{}
                Set-ShoutOutRedirect -LogHandler { param($Details, $Record) $out.v = $Details; } -MsgType $MsgType
            }

            BeforeEach {
                $srcMsg = [guid]::NewGuid()
                shoutOut $srcMsg -MsgType $MsgType -Quiet
            }

            It 'Should receive a hashtable' {
                $out.v | Should -BeOfType [hashtable]
            }

            It 'Message should be the original message' {
                $out.v.Message | Should -Be $srcMsg
            }

            It 'PID should the ID of the current process' {
                $out.v.PID | Should -Be $PID
            }

            It 'Computer should be the name of the local machine' {
                $out.v.Computer | Should -Be $env:COMPUTERNAME
            }

            It 'Should set ObjectType to be the type-name of message object' {
                $out.v.ObjectType | Should -Be $srcMsg.GetType().Name
            }

            It 'Should set ObjectType be "NULL" if the message is $null' {
                shoutOut $null -MsgType $MsgType -Quiet
                $out.v.ObjectType | Should -Be 'NULL'
            }

            It 'Should calculate caller if $LogContext is $true (default)' {
                $cs = Get-PSCallStack
                shoutOut $SrcMsg -MsgType $MsgType -Quiet
                $callerPattern = '^\[(?<depth>[1-9]+)\](?<file>.+):(?<line>[0-9]+)$'
                $out.v.Caller   | Should -Match $callerPattern
                $out.v.Caller -match $callerPattern |Out-Null
                [int]::Parse($matches.depth)  | Should -Be $cs.Length
                $matches.file   | Should -Be $cs[0].ScriptName
            }

            It 'Should set Caller to be "[context logging disabled]" if $LogContext is $false' {
                shoutOut Test -LogContext $false -MsgType $MsgType -Quiet
                $out.v.Caller | Should -Be '[context logging disabled]'
            }

            It 'Should set CallStack to be an array of CallStackFrame objects' {
                $out.v.CallStack | Should -BeOfType [System.Management.Automation.CallStackFrame]
            }

            It 'Should set CallStack to be $null if $LogContext -eq $false.' {
                shoutOut Test -LogContext $false -MsgType $MsgType -Quiet
                $out.v.CallStack | Should -Be $null
            }
            
        }

        Context "Using Parameter 'Record'" {
            BeforeAll {
                $msgType = 'RecordHandler'
                $out = @{}
                Set-ShoutOutRedirect -LogHandler { param($Details, $Record)
                    $out.v = $Record
                    $out.d = $Details
                } -MsgType $msgType
            }

            BeforeEach {
                $srcMsg = [guid]::NewGuid()
                shoutOut $srcMsg -MsgType $msgType -Quiet
            }

            It 'Should receive a string' {
                $out.v | Should -BeOfType [string]
            }

            It 'First field should be the message type' {
                $out.v.split('|', 7)[0] | Should -Be $msgType
            }

            It 'Second field should be the computer name' {
                $out.v.split('|', 7)[1] | Should -Be $env:COMPUTERNAME
            }

            It 'Third field should be the process id' {
                $out.v.split('|', 7)[2] | Should -Be $PID
            }

            It 'Fourth field should be the stack depth and caller' {
                $out.v.split('|', 7)[3] | Should -Match '^\[[0-9]+\](\<No File\>|.+:[0-9]+)$'
            }

            It 'Fifth field should be the date & time that the message was issued' {
                [datetime]$out.v.split('|', 7)[4] | Should -Be $out.d.LogTime
            }

            It 'Sixth field should be the name for the type of object being used as the message' {
                $out.v.split('|', 7)[5] | Should -Be $SrcMsg.GetType().Name
            }

            It 'The remainder should be the message formatted as a string.' {
                $out.v.split('|', 7)[6] | Should -Be $out.d.MessageString
            }

        }

    }
}