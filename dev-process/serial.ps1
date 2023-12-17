function Start-SerialConnection {
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
        --Action {
            Write-Host $port.ReadExisting() -NoNewline
        } 

    try {
        $port.Open()
    } catch {
        throw "Failed to open serial port"
    }
    # get prompt
    $port.WriteLine("")

    $userInput = ""
    while ($true) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey()
            if ($key.Key -eq "Enter") {
                if ($userInput -eq "quit-console") {
                    Write-Host 
                    break
                } else {
                    Write-Host
                    $port.WriteLine($userInput)
                    $userInput = ""
                }
            } elseif ($key.Key -eq "Escape") {
                $port.Write($key.KeyChar)
            } else {
                $userInput += $key.KeyChar
            }
        }
        Start-Sleep -Milliseconds 1
    }

    # Cleanup
    Get-EventSubscriber | Where-Object SourceObject -eq $port | Unregister-Event
    $job.Dispose()
    $port.Close()

}

Start-SerialConnection -COMPort 5 -BaudRate 115200 -Parity None -DataBits 8 -StopBits one
