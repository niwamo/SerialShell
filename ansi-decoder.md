| Sequence           | Meaning                                                                        |
| ------------------ | ------------------------------------------------------------------------------ |
| ^[?2004l           | turn off bracketed paste mode                                                  |
| ^[?2004h           | turn on bracketed paste mode                                                   |
| ^[K                | backspace                                                                      |
| ^[<line>;<column>H | move cursor                                                                    |
| ^[?1004h           | enable reporting focus (request msgs when terminal is or is not top of screen) |
| ^[?1004l           | disable reporting focus                                                        |
| ^[?1049h           | enable alternative screen buffer                                               |
| ^[?1002h           | enable mouse reporting (request mouse reports)                                 |
| ^[?1002l           | disable mouse reporting                                                        |
| ^[?1006;1000h      | combined cmd of 1006h and 1000h                                                |
| ^[?1006h           | enable extended mouse mode                                                     |
| ^[?1000h           | enable mouse click reporting                                                   |
| ^[22;0;0t          | unclear... put window icon and title on stack                                  |
| ^[>4;2m            | > = DCS cmd; sets cursor color                                                 |
| ^[>4;m             | reset whatever the first one did                                               |
| ^[?1h              | enable application cursor key mode                                             |
| ^[?1l              | disable application cursor key mode                                            |
| ^[1;24r            | sets scrolling region from lines 1 to 24                                       |
| ^[r                | reset scrolling region                                                         |
| ^[?12h             | enable cursor blinking                                                         |
| ^[?12l             | disable cursor blinking                                                        |
| ^[22;2t            | put window title on stack                                                      |
| ^[22;1t            | put icon title on stack                                                        |
| ^[27m              | reset inverse/reverse mode                                                     |
| ^[23m              | reset italic mode                                                              |
| ^[29m              | reset strikethrough mode                                                       |
| ^[m                | clear/reset all text attributes                                                |
| ^[H                | move cursor to home position                                                   |
| ^[2J               | clear the entire terminal screen                                               |
| ^[6n               | request the cursor position                                                    |
| ^[>c               | request terminal type                                                          |
| ^]10;?             | Operating System Command (OSC) sequence requesting terminal info               |
| ^]11;?             | OSC request for terminal window title                                          |
| ^[11C              | move cursor forward 11 columns                                                 |
| ^[?25h             | make cursor visible                                                            |
| ^[?25l             | hides the cursor                                                               |
| ^[?4m              | set the cursor to underline style                                              |
| ^[>0;10;1c         | response to DSC request; indicates VT100 emulation and 132-col mode            |
| ^[3;1R             | reports cursor position                                                        |
| ^[23;2t            | restore window title from stack                                                |
| ^[23;1t            | restore icon title from stack                                                  |
| ^[23;0;0t          | unclear... restore window and icon titles?                                     |

# Notes

- `agetty` does not support ANSI escape sequences
- `stty size` returns current pty size
- `stty columns <c> rows <r>` sets pty size
