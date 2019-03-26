function _ensureshoutOutLogHandler {
    param(
        [scriptblock]$logHandler,
        [string]$msgType = "*"
    )

    $params = $logHandler.Ast.ParamBlock.Parameters

    if ($params.count -eq 0) {
        "Invalid handler, no parameters found: {0}" -f $logHandler | shoutOut -MsgType Error
        "Messages marked with '{0}' will not be redirected using this handler." -f $msgType | shoutOut -MsgType Error
        throw "No parameters declared by the given handler."
    }

    $paramName = '$message'
    $param = $params | ? { $_.Name.Extent.Text -eq $paramName }

    if (!$param) {
        "Invalid handler, no '{0}' parameter found" -f $paramName | shoutOut -MsgType Error
        "Messages marked with '{0}' will not be redirected using this handler." -f $msgType | shoutOut -MsgType Error
        throw ("No '{0}' parameter declared by the given handler." -f $paramName)
    }

    if (($t = $param.StaticType) -and !($t.IsAssignableFrom([String])) ) {
        "Invalid handler, the '{0}' parameter should accept values of type [String]." -f $paramName | shoutOut -MsgType Error
        "Messages marked with '{0}' will not be redirected using this handler." -f $msgType | shoutOut -MsgType Error
        throw ("'{0}' parameter on the given handler is of invalid type (not assignable from [string])." -f $paramName)
    }

    return $logHandler
}