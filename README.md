```PowerShell
# New-SerialSession -COMPort 5 -BaudRate 115200 -Parity None -DataBits 8 -StopBits one
<#
while ($true) { 
    $k = [console]::readkey($true)
    if ( $k.keychar -eq "q" ) {
        break
    }
    write-host "$([byte]$k.keychar), $($k.key)" 
}
#>
```