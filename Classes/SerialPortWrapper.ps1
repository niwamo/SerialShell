$script:inputHelpers = [Collections.Generic.Dictionary[ConsoleKey,String]]::new()
@{
    "UpArrow"       = $([char]27 + '[A')
    "DownArrow"     = $([char]27 + '[B')
    "RightArrow"    = $([char]27 + '[C')
    "LeftArrow"     = $([char]27 + '[D')
    "F1"            = $([char]27 + 'OP')
    "F2"            = $([char]27 + 'OQ')
    "F3"            = $([char]27 + 'OR')
    "F4"            = $([char]27 + 'OS')
    "F5"            = $([char]27 + '[15~')
    "F6"            = $([char]27 + '[17~')
    "F7"            = $([char]27 + '[18~')
    "F8"            = $([char]27 + '[19~')
    "F9"            = $([char]27 + '[20~')
    "F10"           = $([char]27 + '[21~')
    "F11"           = $([char]27 + '[23~')
    "F12"           = $([char]27 + '[24~')
    "Delete"        = $([char]127)
    "Home"          = $([char]27 + '[H')
    "End"           = $([char]27 + '[F')
    "PageUp"        = $([char]27 + '[5~')
    "PageDown"      = $([char]27 + '[6~')
    "Insert"        = $([char]27 + '[2~')
}.GetEnumerator() | ForEach-Object {
    $inputHelpers.Add($_.Key, $_.Value) 
}

class SerialPortWrapper {
    [System.IO.Ports.SerialPort]$port
    SerialPortWrapper ([System.IO.Ports.SerialPort]$port) {
        $this.port = $port
    }
    HandleInput ($ctrl) {
        $this.port.Write($ctrl)
    }
    StartSession () {
        # Register our 'DataReceived' Handler
        $job = Register-ObjectEvent `
            -InputObject $this.port `
            -EventName DataReceived `
            -MessageData $this.port `
            -Action {
                Write-Host $port.ReadExisting() -NoNewline
            }
        [Console]::TreatControlCAsInput = $true
        $cmd = $false
        # Write instructions
        Write-Host "Starting session. CTRL+A --> Z to exit"
        # get prompt
        $this.port.WriteLine("")
        while ($true) {
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                $char = $key.KeyChar
                if ($cmd) {
                    if ($char -eq "z") {
                        # exit
                        Write-Host
                        break
                    } 
                    $cmd = $false
                } else {
                    if ([byte]$key.KeyChar -eq 1) {
                        $cmd = $true
                    } elseif ($script:inputHelpers.Keys.Contains($key.Key)) {
                        $msg = $script:inputHelpers[$key.Key]
                        $this.HandleInput($msg)
                    } else {
                        $this.HandleInput($key.KeyChar)
                    }
                }
            }
            Start-Sleep -Milliseconds 1
        }
        # Cleanup
        Get-EventSubscriber | Where-Object SourceObject -eq $this.port | `
            Unregister-Event
        $job.Dispose()
    }
}