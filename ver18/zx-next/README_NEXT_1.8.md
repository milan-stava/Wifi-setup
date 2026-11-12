# WiFi Setup 1.8 for ZX Next

This is the standalone ZX Next port, with BIOS 2.1 and Terminal 1.1 embedded unchanged.

## Outputs and startup

| File in runable/ | Bytes |
|---|---:|
| wifi_setup_next18.tap | 16396 |
| wifi_setup_next18.bin | 16316 |

The TAP contains a BASIC loader and CODE block. The BIN is the same code for address C000 (49152), not an MB flash image.

Start in 48 BASIC / USR 0 with the standard ULA display and available 48K ROM printing routines. The loader performs CLEAR 27647, LOAD CODE, and RANDOMIZE USR 49152. This is not a .NEX file.

Run assembly.bat with SjASMPlus 1.20.3. build.ps1 copies verified outputs to runable/. This setup builds without errors or warnings.

## Next backend

- BIOS 2.1 is 698 B; Terminal 1.1 is 5314 B.
- Active CPU, GMT, RTC, and exit paths use Next interfaces rather than MB/eLeMeNt hardware.
- Startup saves NextReg 07 and selects nominal 3.5 MHz for the original polling timeouts. Exit restores CPU speed, SP, IX, IY, and alternate HL, and enables interrupts. Actual clock also depends on video timing.
- Fifteen BIOS indices 0..14 cover 2400..2000000 baud. Index 7 is the 115200 baseline. Higher MB rates are not offered.
- Baud indices 13 and 14 no longer trigger the inherited EL/MB unsupported-speed warning. The second line shows max speed index=14.
- Since the BIOS cannot read the prescaler back, the setup caches successfully written indices. Baud queries use the BIOS information mode without rewriting UART.
- Returning from the terminal invalidates the cache and verifies/scans communication again.
- There is no W power-off option. ESP remains powered on exit; no ESP or expansion-bus reset is performed on exit. The explicit WiFi restart command still uses AT+RST.
- The centered title identifies WiFi Setup 1.8 ZX Next, Hood, 11/2026.

## RTC and SNTP

For successful RTC time and date synchronization, the ESP module must run AT firmware 1.4.0.0 or newer with SNTP support.

S first asks for a GMT offset from -12 to +14. Examples: 1 for standard time, 2 for daylight-saving time, or -1. A leading plus sign is allowed. Invalid input is requested again; EDIT cancels and returns to the menu. Daylight-saving changes are not automatic.

The offset is sent in AT+CIPSNTPCFG and the returned AT+CIPSNTPTIME value is parsed. Seven date/time registers are written to a DS1307 at I2C address 68 through ports 103B/113B. The ZX signature used by RTC.SYS is written at 3E/3F after a successful clock write; other RTC RAM is preserved.

Missing hardware, NACK, and stuck lines produce RTC missing / I2C error and terminate the transaction with STOP. Other setup functions remain usable without RTC hardware. Both successful and failed clock-setting results wait for a key.

The inherited SNTP activation check now searches the bounded 255-byte response instead of its first 13 bytes, allowing leading CR/LF and echo. The same zero-growth operand fix is included in EL/MB.

## Retained features and AP recovery

AP selection, empty passwords, password masking, fallback to Default AP, PING, module naming, modes, auto-connect, baud selection, and firmware menus are retained.

Default AP recovery has its own 500-unit budget rather than 3000; normal joins keep their original budget. GOT IP waiting is bounded to roughly ten seconds at 50 Hz, with bytes also consuming the budget. Restart/control commands take additional time. Recovery may temporarily use 115200 and attempts to restore the saved rate.

The later EL/MB change that routes post-AP acknowledgement through st1 has not been ported to this Next build. That remains a known difference.

The terminal provides 1 KB history, editing, a scrolling viewport, two bottom editor rows, SS+W, immediate Y/N history confirmation via SS+Q, SS+E, and help. The setup uses its original custom 64-column four-pixel font, not native NextBASIC 64/80-column mode.

## Memory

Code occupies C000..FFBB, leaving 68 bytes to the end of RAM, including bootstrap stack space. Runtime SP is 63E0. The terminal is copied to 30000; AP storage begins at 35314. Editor scratch uses 6C00..6E4F and history uses 7000..73FF.

CLEAR 27647 protects scratch/history from BASIC variables and stack. Next does not need the MB boot-block limit, but the current C000 layout still requires the code to fit its address space. Larger builds need a different layout.

## Verification

- 152 assembled-code AT scenarios cover joins, recovery, replies/errors, empty inputs, escaping, scans, PING, and SNTP bounds.
- 213 Next backend scenarios cover startup/exit at all four CPU speeds, registers/stack, terminal copying, all 120 rate/timing combinations, baud caching and query-only behavior, full 15-rate scans, GMT parsing/cancellation, RTC bytes/signature/NACK/STOP, missing/stuck hardware, full SNTP-to-I2C paths, prompts, title/menu rendering, and speed selection.
- verify_release.ps1 checks TAP blocks/checksums, CODE/BIN equality, loader, memory/stack limits, title/centering, embedded components, and runable copies.

Run test_ap_recovery.ps1, test_next_setup.ps1, and verify_release.ps1 with powershell -NoProfile -ExecutionPolicy Bypass -File.

Tests use a CPU model and simulated ports, not full FPGA emulation. Hardware checks are not exhaustive. Real UART throughput, ESP speeds, SNTP services, and RTC variants still need broader testing.

Standard memory/display mapping and enabled UART ports are assumed. Do not route ESP UART to joystick pins or let other code switch it to Pi.

## References

- https://wiki.specnext.dev/UART_Control
- https://wiki.specnext.dev/UART_Frame
- https://wiki.specnext.dev/UART_TX
- https://wiki.specnext.dev/UART_RX
- https://gitlab.com/SpectrumNext/ZX_Spectrum_Next_FPGA/-/raw/master/cores/zxnext/nextreg.txt
- https://wiki.specnext.dev/RTC
- https://gitlab.com/thesmog358/tbblue/-/blob/master/src/asm/rtc/time.asm
- https://gitlab.com/thesmog358/tbblue/-/blob/master/src/asm/rtc/date.asm

The compact I2C writer is local code; addresses and RTC.SYS signature were checked against the referenced TIME/DATE sources.