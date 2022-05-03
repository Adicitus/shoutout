function _validateShoutOutLogHandler {
    param(
        [scriptblock]$LogHandler,
        [string]$msgType = "*"
    )

    # Valid/recognizable parameters and their expected typing:
    $validParams = @{
        '$Message' = [Object]
        '$Record'  = [String]
        '$details' = [hashtable]
    }

    $params = $LogHandler.Ast.ParamBlock.Parameters

    if ($params.count -eq 0) {
        "Invalid handler, no parameters found: {0}" -f $LogHandler | shoutOut -MsgType Error
        "Messages marked with '{0}' will not be redirected using this handler." -f $msgType | shoutOut -MsgType Error
        throw "No parameters declared by the given handler."
    }

    $recognizedParams = $params | Where-Object { $_.Name.Extent.Text -in $validParams.Keys }

    if ($null -eq $recognizedParams) {
        "Invalid handler, none of the expeted parameters found (expected any of {0}): {1}" -f ($paramNames -join ', '), $LogHandler | shoutOut -MsgType Error
        "Messages marked with '{0}' will not be redirected using this handler." -f $msgType | shoutOut -MsgType Error
        throw ("None of {0} parameters declared by the given handler." -f ($paramNames -join ', '))
    }

    foreach ($param in $recognizedParams) {
        $paramType = $validParams[$param.Name.Extent.Text]
        if (($t = $param.StaticType) -and !($t.IsAssignableFrom($paramType)) ) {
            "Invalid handler, the '{0}' parameter should accept values of type '{1}' (found '{2}' which is not assignable from '{1}')." -f $param.Name, $paramType.Name, $t.Name | shoutOut -MsgType Error
            "Messages marked with '{0}' will not be redirected using this handler." -f $msgType | shoutOut -MsgType Error
            throw ("'{0}' parameter on the given handler is of invalid type (not assignable from [string])." -f $paramNames)
        }
    }

    return $LogHandler
}