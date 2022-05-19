function Get-ShoutOutDefaultLog {
    param()

    return Get-ShoutOutLog -MessageType '*'
}