while ($true) {
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        $char = $key.KeyChar
        if ($char -eq "z") {
            break
        } elseif ($char -eq "s") {
            # ESC[;;18t
            $msg = [string]::Join('', [char[]]@(27, 91, 59, 59, 49, 56, 116))
            Write-Host $msg -NoNewline
        }
        $msg = Get-Switcheroo -in $char
        $log = "Snt: " + $msg 
        Write-Host $log
    }
    Start-Sleep -Milliseconds 1
}

function Get-Switcheroo {
    param(
        [string]$in
    )
    $out = $in -replace [char]0, "NUL"
    $out = $out -replace [char]7, "BEL"
    $out = $out -replace [char]8, "BS"
    $out = $out -replace [char]9, "TAB"
    $out = $out -replace [char]10, "LF"
    $out = $out -replace [char]13, "CR"
    $out = $out -replace [char]27, "ESC"
    return $out
}