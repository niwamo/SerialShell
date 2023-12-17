function New-SerialSession {
    param(
        [int]$COMPort,
        [int]$BaudRate,
        [System.IO.Ports.Parity]$Parity = "None",
        [int]$DataBits = 8,
        [System.IO.Ports.StopBits]$StopBits = "one"
    )

    # Input Validation for args not validated with built-in types
    $validRates = @(9600,38400,115200)
    if (! $validRates.Contains($BaudRate)) {
        throw "Baud Rate invalid. Use one of the following: $validRates"
    }
    $portNames = [System.IO.Ports.SerialPort]::GetPortNames()
    if (! $portNames.Contains("COM$COMPort")) {
        throw "COM Port not available. Currently available ports: $portNames"
    }

    # Create the port
    $global:port = [System.IO.Ports.SerialPort]::new(
        "COM$COMPort", 
        $BaudRate, 
        $Parity, 
        $DataBits, 
        $StopBits
    )

    # open port, exit if it fails
    try {
        $port.Open()
    } catch {
        throw "Failed to open serial port"
    }

    # Create and start the SerialPortWrapper
    [SerialPortWrapper]::new($port).StartSession()

    # Cleanup
    $port.Close()
}