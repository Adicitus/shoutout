function _buildBasicFileLogger {
    param(
        [string]$FilePath
    )

    return {
        param($Record)

        if (-not (Test-Path $FilePath -PathType Leaf)) {
            New-Item -Path $FilePath -ItemType File -Force -ErrorAction Stop | Out-Null
        }

        $Record | Out-File $FilePath -Encoding utf8 -Append -Force
    }.GetNewClosure()
}