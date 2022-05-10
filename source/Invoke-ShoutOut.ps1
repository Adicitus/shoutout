
<#
.WISHLIST
    - Update so that that output is fed to shoutOut as it is generated rather than using the result output.
      The goal is to generate logging data continuously so that it's clear whether the script has hung or not.
      [Done]
.SYNOPSIS
    Helper function to execute commands (strings or blocks) with error-handling/reporting.
.DESCRIPTION
    Helper function to execute commands (strings or blocks) with error-handling/reporting.
If a scriptblock is passed as the operation, the function will attempt make any variables referenced by the
scriptblock available to the scriptblock when it is resolved (using variables available in the scope that
called Run-Operation).

The variables used in the command are identified using [scriptblock].Ast.FindAll method, and are imported
from the parent scope using $PSCmdlet.SessionState.PSVariable.Get.

The following variable-names are restricted and may cause errors if they are used in the operation:
 - $__thisOperation: The operation being run.
 - $__inputVariables: List of the variables being imported to run the operation.

.NOTES
   - Transforms ScriptBlocks to Strings prior to execution because of a quirk in iex where it will not allow the
     evaluation of ScriptBlocks without an input (a 'param' statement in the block). iex is used because it yields
     output as each line is evaluated, rather than waiting for the entire $OPeration to complete as would be the
     case with <ScriptBlock>.Invoke().
#>
function Invoke-ShoutOut {
    param(
        [parameter(ValueFromPipeline=$true, position=1)] $Operation,
        [parameter()][Switch] $OutNull,
        [parameter()][Switch] $NotStrict,
        [parameter()][Switch] $LogErrorsOnly,
        [parameter()][Switch] $Quiet
    )
    $shoutOutArgs = @{
        Quiet = $PSBoundParameters.ContainsKey('Quiet')
    }
    
    if (!$NotStrict) {
        # Switch error action preference to catch any errors that might pop up.
        # Works so long as the internal operation doesn't also change the preference.
        $OldErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
    }

    if ($Operation -is [string]) {
        $Operation = [scriptblock]::create($Operation)
    }

    if (!$LogErrorsOnly) {
        $msg = "Running '$Operation'..."
        $msg | shoutOut -MsgType Invocation -ContextLevel 1 @shoutOutArgs
    }

    $r = try {
        
        # Step 1: Get any variables in the parent scope that are referenced by the operation.
        if ($Operation -is [scriptblock]) {
            $variableNames = $Operation.Ast.FindAll(
                {param($o) $o -is [System.Management.Automation.Language.VariableExpressionAst]},
                $true
            ) | ForEach-Object {
                $_.VariablePath.UserPath
            }

            $variables = foreach ($vn in $variableNames) {
                $PSCmdlet.SessionState.PSVariable.Get($vn)
            }
        }

        # Step 2: Convert the scriptblock if necessary.
        if ($Operation -is [scriptblock]) {
            # Under certain circumstances the iex cmdlet will not allow
            # the evaluation of ScriptBlocks without an input. However it will evaluate strings
            # just fine so we perform the transformation before evaluation.
            $Operation = $Operation.ToString()
        }

        # Step 3: inject the operation and the variables into a new isolated scope and resolve
        # the operation there.
        & {
            param(
                $thisOperation,
                $inputVariables
            )

            $__thisOperation = $thisOperation
            $__inputVariables = $inputVariables

            Remove-Variable "thisOperation"
            Remove-Variable "inputVariables"

            $__ = $null

            foreach ( $__ in $__inputVariables ) {
                if ($null -ne $__) {
                    if ($v = Get-Variable -Name $__.Name -Scope 0 -ea SilentlyContinue) {
                        if (-not $v.Options.HasFlag([System.Management.Automation.ScopedItemOptions]::Constant)) {
                            Set-Variable $__.Name $__.Value
                        }
                    } else {
                        Set-Variable $__.Name $__.Value
                    }
                }
            }

            Remove-Variable "__"

            # Invoke-Expression allows us to receive
            # and handle output as it is generated,
            # rather than wait for the operation to finish
            # as opposed to <[scriptblock]>.invoke().
            Invoke-Expression $__thisOperation | ForEach-Object {
                if (!$LogErrorsOnly) {
                    shoutOut "`t| $_" "Result" -ContextLevel 1 @shoutOutArgs
                }
                return $_
            }
        } $Operation $variables

    } catch {
        "An error occured while executing the operation:" | shoutOUt -MsgType Error -ContextLevel 1 @shoutOutArgs
        $_ | shoutOut -MsgType Error -ContextLevel 1 @shoutOutArgs
        <#
        $_.Exception, $_.CategoryInfo, $_.InvocationInfo, $_.ScriptStackTrace | Out-string | ForEach-Object {
            $_.Split("`n`r", [System.StringSplitOptions]::RemoveEmptyEntries).TrimEnd("`n`r")
        } | ForEach-Object {
            "`t| $_"
        } | shoutOut -MsgType 'Error' -ContextLevel 1 @shoutOutArgs
        #>
        
        $_
    }

    if (!$NotStrict) {
        $ErrorActionPreference = $OldErrorActionPreference
    }

    if ($OutNull) {
        return
    }
    return $r
}