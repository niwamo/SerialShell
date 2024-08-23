# SerialShell

## Introduction

Windows does not have a native tool for console sessions over serial connections. Historically, that
gap has been filled with `putty`, which I have long considered obnoxious. 

*(There's nothing wrong with it, but I dislike both the need to download an executable and the need
to use a GUI for a CLI session - especially when native tools are perfectly capable of providing the
same functionality.)*

It's generally known that PowerShell (via .NET assemblies) is capable of providing this
functionality, and there are a large number of StackOverflow posts and code samples with rudimentary
serial session tools for PowerShell. These generally involve a while loop and a `Read-Host` command.
While this works in some scenarios, it prevents interactivity. 

## Benefits of SerialShell

- Pure PowerShell serial sessions - no `putty` necessary
- Fully-interactive serial sessions; Tab-complete, command history searching, and interactive
  terminal apps all work perfectly fine

Full interactivity is achieved by dispensing with blocking user input (e.g., `Read-Host`), sending
all key-presses to the remote host as soon as they are detected, and using a Background Job to
monitor for and handle data received from the remote host. 

## Usage

```PowerShell
New-SerialSession -COMPort 5 -BaudRate 115200 -Parity None -DataBits 8 -StopBits one
```

Note: `COMPort` and `BaudRate` are the only mandatory parameters.