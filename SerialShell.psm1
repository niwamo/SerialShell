$menu = @"
Menu:
z:  exit SerialShell

press any other key to resume
"@

function Invoke-AlternateBuffer {
    param(
        [int]$Lines = 10
    )
    # use ANSI escape sequences to invoke the alternate screen buffer,
    # set the scroll region, wipe the screen, and hide the cursor
    $ESC = [char]27
    $sequence = "$ESC[?1049h" + "$ESC[1;$($Lines)r" + "$ESC[2J" + "$ESC[?25l"
    Write-Host -NoNewline $sequence
}

function Invoke-PrimaryBuffer {
    # use ANSI escape sequences to invoke the primary screen buffer,
    # reset the scroll region, and show the cursor
    $ESC = [char]27
    $sequence = "$ESC[r" + "$ESC[?25h" + "$ESC[?1049l" 
    Write-Host -NoNewline $sequence
}

function Start-SerialSession {
    param(
        [System.IO.Ports.SerialPort]$Port
    )
    [Console]::TreatControlCAsInput = $true
    # inputHelpers = keys that must be converted to ANSI sequences 
    $inputHelpers = [Collections.Generic.Dictionary[ConsoleKey, String]]::new()
    @{
        "UpArrow"    = $([char]27 + '[A')
        "DownArrow"  = $([char]27 + '[B')
        "RightArrow" = $([char]27 + '[C')
        "LeftArrow"  = $([char]27 + '[D')
        "Delete"     = $([char]127)
        # NOTE: HOME and END worked as expected in testing over serial, 
        # but behave differently if used in a local console session
        "Home"       = $([char]27 + '[H')
        "End"        = $([char]27 + '[F')
        "PageUp"     = $([char]27 + '[5~')
        "PageDown"   = $([char]27 + '[6~')
        "Insert"     = $([char]27 + '[2~')
    }.GetEnumerator() | ForEach-Object {
        $inputHelpers.Add($_.Key, $_.Value) 
    }
    # Use a background job to monitor for and handle data received
    $job = Register-ObjectEvent `
        -InputObject $port `
        -EventName DataReceived `
        -MessageData $port `
        -Action {
            $data = $port.ReadExisting()
            Write-Host $data -NoNewline
        } 
    Write-Host (
        [char]27 + "[92m" + `
        "Starting Session. CTRL+A for command menu`n" + `
        [char]27 + "[32;3m" + `
        "We recommend using 'stty' to set your terminal size`n" + `
        "(Your terminal size is displayed in the command menu)`n" + `
        [char]27 + "[0m"
    )
    # output blank line as a way of requesting a prompt from remote system
    $port.WriteLine("")
    # intercept and handle input
    while ($true) {
        # constantly scan for user input
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            # if Ctrl+A, enter "command menu"
            if ([byte]$key.KeyChar -eq 1) {
                Invoke-AlternateBuffer
                $width = [Console]::WindowWidth
                $height = [Console]::WindowHeight
                Write-Host "Terminal Size: columns $width rows $height`n"
                Write-Host $menu
                $response = [Console]::ReadKey($true).KeyChar
                Invoke-PrimaryBuffer
                if ($response -eq "z") {
                    break   
                }
            }
            # convert to ANSI escape sequence if necessary
            elseif ($inputHelpers.Keys.Contains($key.Key)) {
                $msg = $inputHelpers[$key.Key]
                $port.Write($msg)
            }
            else {
                $port.Write($key.KeyChar)
            }
        }
        Start-Sleep -Milliseconds 1
    }
    # Cleanup
    Get-EventSubscriber | Where-Object SourceObject -eq $port | Unregister-Event
    $job.Dispose()
}

function New-SerialSession {
    param(
        [Parameter(mandatory=$true)]
        [int]$COMPort,
        [Parameter(mandatory=$true)]
        [int]$BaudRate,
        [System.IO.Ports.Parity]$Parity = "None",
        [int]$DataBits = 8,
        [System.IO.Ports.StopBits]$StopBits = "one"
    )
    Write-Warning (
        "No input validation for BaudRate. " + `
        "Please make sure your selection is supported by the target device"
    )
    # validate COM Port selection
    $portNames = [System.IO.Ports.SerialPort]::GetPortNames()
    if (! $portNames.Contains("COM$COMPort")) {
        throw "COM Port not available. Currently available ports: $portNames"
    }
    # Create the port object
    $global:port = [System.IO.Ports.SerialPort]::new(
        "COM$COMPort", 
        $BaudRate,
        $Parity, 
        $DataBits, 
        $StopBits
    )
    # try opening, exit if it fails
    try { $port.Open() } catch { throw "Failed to open serial port" }
    # start the interactive session
    Start-SerialSession -Port $port
    # Cleanup
    $port.Close()
}
