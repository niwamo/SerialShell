class myCursor {
    [int]$internal = 0
    left() {
        if ($this.internal -gt 0) {
            $this.internal -= 1
            [Console]::CursorLeft -= 1
        }
    }
    right([int]$max) {
        if ($this.internal -lt $max) {
            $this.internal += 1
            if ([Console]::CursorLeft -lt ([Console]::WindowWidth)-1) {
                [Console]::CursorLeft += 1
            }
        }
    }
    home() {
        [Console]::CursorLeft -= $this.internal
        $this.internal = 0
    }
    moveEnd([int]$max) {
        $diff = $max - $this.internal
        [Console]::CursorLeft += $diff
        $this.internal += $diff
    }
}

function New-InputWrapper {
    param(
        [scriptblock]$LineHandler,
        [scriptblock]$ControlHandler
    )

    [Console]::TreatControlCAsInput = $true

    $userInput = [Collections.Generic.List[Collections.Generic.List[char]]]::new()
    $userInput.Add([Collections.Generic.List[char]]::new())
    $inputIndex = -1
    $cursor = New-Object myCursor
    $cmd = $false

    $inputHelpers = [ `
        Collections.Generic.Dictionary[
            ConsoleKey,
            Management.Automation.ScriptBlock
        ] `
    ]::new()
    @{
        "Home" = { $cursor.home() }
        "End" =  { $cursor.moveEnd($userInput[-1].Count) }
        "LeftArrow" =  { $cursor.left() }
        "RightArrow" =  { $cursor.right($userInput[-1].Count) }
        "UpArrow" =  { 
            $inputIndex = [Math]::Max($inputIndex - 1, -($userInput.Count))
            $userInput[-1] = $userInput[$inputIndex] 
            $cursor.moveEnd($userInput[-1].Count)
        }
        "DownArrow" =   { 
            $inputIndex = [Math]::Min($inputIndex + 1, -1)
            if ($inputIndex -eq -1) {
                $userInput[-1] = [Collections.Generic.List[char]]::new()
            } else {
                $userInput[-1] = $userInput[$inputIndex] 
            }
            $cursor.moveEnd($userInput[-1].Count)
        }
        "Delete" =  { 
            if ($userInput[-1].Count -gt $cursor.internal) {
                $userInput[-1].RemoveAt($cursor.internal) 
            }
        }
        "Backspace" = {
            if ($userInput[-1].Count -gt 0) {
                $cursor.left()
                $userInput[-1].RemoveAt($cursor.internal)
            }
        }
        "Tab" = {
            Invoke-Command -ScriptBlock $ControlHandler `
                -ArgumentList $($userInput[-1] -join '')
            Invoke-Command -ScriptBlock $ControlHandler `
                -ArgumentList $key.KeyChar
            $userInput.Add([Collections.Generic.List[char]]::new())
            $inputIndex = -1
            [Console]::CursorLeft -= $cursor.internal
            $cursor.internal = 0
        }
    }.GetEnumerator() | ForEach-Object {
        $inputHelpers.Add($_.Key, $_.Value) 
    }

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
                if ([byte]$char -ge 32 -and [byte]$char -le 126) {
                    # handle ascii printable characters
                    $userInput[-1].Insert($cursor.internal, $key.KeyChar)
                    $cursor.right($userInput[-1].Count)
                } else {
                    if ($key.Key -eq "Enter") {
                        # handle lines
                        Invoke-Command -ScriptBlock $LineHandler `
                            -ArgumentList $($userInput[-1] -join '')
                        $userInput.Add([Collections.Generic.List[char]]::new())
                        $inputIndex = -1
                        $cursor.internal, [Console]::CursorLeft = 0, 0
                    } elseif ($inputHelpers.Keys.Contains($key.Key)) {
                        Invoke-Command -ScriptBlock $inputHelpers[$key.Key] -NoNewScope
                    } else {
                        if ([byte]$key.KeyChar -eq 1) {
                            $cmd = $true
                        } else {
                            Invoke-Command -ScriptBlock $ControlHandler `
                                -ArgumentList $key.KeyChar
                        }
                    }
                }
            }
            $pos = [Console]::CursorLeft
            $start = $pos - $cursor.internal
            [Console]::CursorLeft = [Math]::Max(0, $start)
            Write-Host $(" " * ([Console]::WindowWidth - $start)) -NoNewline
            [Console]::CursorLeft = [Math]::Max(0, $start)
            Write-Host $($userInput[-1] -join '') -NoNewline
            [Console]::CursorLeft = $pos
        }
        Start-Sleep -Milliseconds 1
    }
}

function New-SerialSession {
    param(
        [int]$COMPort,
        [int]$BaudRate,
        [System.IO.Ports.Parity]$Parity,
        [int]$DataBits,
        [System.IO.Ports.StopBits]$StopBits
    )

    $global:port = [System.IO.Ports.SerialPort]::new(
        "COM$COMPort", 
        $BaudRate, 
        $Parity, 
        $DataBits, 
        $StopBits
    )

    $job = Register-ObjectEvent `
        -InputObject $port `
        -EventName DataReceived `
        -MessageData $port `
        -Action {
            $data = $port.ReadExisting()
            Write-Host $data -NoNewline
        } 
    
    try {
        $port.Open()
    } catch {
        throw "Failed to open serial port"
    }
    # get prompt
    $port.WriteLine("")

    New-InputWrapper `
        -LineHandler {
            param([string]$str)
            $port.WriteLine($str)
            Write-Host
        } `
        -ControlHandler {
            param($ctrl)
            $port.Write($ctrl)
        } `
        -NoNewScope

    # Cleanup
    Get-EventSubscriber | Where-Object SourceObject -eq $port | Unregister-Event
    $job.Dispose()
    $port.Close()
}

New-SerialSession -COMPort 5 -BaudRate 115200 -Parity None -DataBits 8 -StopBits one