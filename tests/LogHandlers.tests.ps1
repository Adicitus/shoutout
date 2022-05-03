BeforeAll {
    Set-ShoutOutDefaultLog { param($Message) $Message | Write-Host  }
}

Describe "Log Handler" {

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
                Set-ShoutOutRedirect -LogHandler { param($Details) $out.v = $Details } -MsgType $MsgType
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

            It 'ObjectType should be the type-name of message' {
                $out.v.ObjectType | Should -Be $srcMsg.GetType().Name
            }

            It 'ObjectType should be "NULL" if the message is $null' {
                shoutOut $null -MsgType $MsgType
                $out.v.ObjectType | Should -Be 'NULL'
            }
            
        }

        Context "Using Parameter 'Record'" {
            BeforeAll {
                $msgType = 'RecordHandler'
                $out = @{}
                Set-ShoutOutRedirect -LogHandler { param($Details, $Record)
                    $out.v = $Record;
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
                $out.v.split('|', 7)[3] | Should -Match '\[[0-9]+\].+'
            }

            It 'Fifth field should be the datetime that the message was issued' {
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