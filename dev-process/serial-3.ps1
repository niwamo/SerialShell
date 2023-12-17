class QueueConsumer {
    [byte]$TerminatingCharacter = 10
    [Collections.Concurrent.BlockingCollection[byte[]]]$queue
    [Collections.Generic.List[byte]]$bytes
    QueueConsumer ([Collections.Concurrent.BlockingCollection[byte[]]]$queue) {
        $this.queue = $queue
    }
    Start () {
        foreach ($item in $this.queue.GetConsumingEnumerable()) {
            $this.ProcessInput($item)
        }
    }
    ProcessInput ([byte[]]$item) {
        if ($null -eq $item -or $item.Length -eq 0) {
            return
        }
        if ($item[-1] -eq $this.TerminatingCharacter) {
            $output = [System.Text.Encoding]::Default.GetString($this.bytes)
            Write-Host $output -NoNewline
            $this.bytes.Clear()
        } else {
            $this.bytes.AddRange($item)
        }
    }
}

class StreamWrapper {
    [System.IO.Ports.SerialPort]$port
    [System.IO.Stream]$stream
    [byte[]]$buffer
    [scriptblock]$callback = {
        param([IAsyncResult]$ar)
        $bytesRead = $this.stream.EndRead($ar)
        $msg = [System.Text.Encoding]::Default.GetString(
            $this.buffer, 0, $bytesRead
        )
        Write-Host -NoNewline $msg
        Start-Sleep -Milliseconds 1
        $this.StartRead($this.callback)
    }
    StreamWrapper([System.IO.Ports.SerialPort]$port) {
        $this.port = $port
        $this.stream = $port.BaseStream
        $this.buffer = [byte[]]::new(4096)
    }
    StartRead([scriptblock]$callback) {
        $this.stream.BeginRead(
            $this.buffer, 0, $this.buffer.Length, $callback, $null
        )
    }
    Start() {
        try { 
            Get-Item -Path Variable:Host
        } catch {
            throw "Could not find the Host variable"
        }
        $this.StartRead($this.callback)
        $cmd = $false
        while ($true) {
            if ($global:Host.UI.RawUI.KeyAvailable) {
                $key = $global:Host.UI.RawUI.ReadKey(
                    'AllowCtrlC,NoEcho,IncludeKeyDown'
                )
                $char = $key.Character
                Write-Host $char
                if ($cmd) {
                    if ($char -eq "z") {
                        # exit
                        Write-Host
                        break
                    } 
                    $cmd = $false
                } else {
                    if ([byte]$char -eq 1) {
                        $cmd = $true
                    } else {
                        $this.stream.Write([byte[]]$char, 0, 1)
                        $this.stream.Flush()
                    }
                }
            }
            Start-Sleep -Milliseconds 1
        }
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

    $port = [System.IO.Ports.SerialPort]::new(
        "COM$COMPort", 
        $BaudRate, 
        $Parity, 
        $DataBits, 
        $StopBits
    )

    try {
        $port.Open()
    } catch {
        throw "Failed to open serial port"
    }

    $processor = [StreamWrapper]::new($port)

    # Start reading from the stream and writing to it from console input
    $processor.Start()

    $port.Close()
}

New-SerialSession -COMPort 5 -BaudRate 115200 -Parity None -DataBits 8 -StopBits one
