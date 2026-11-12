# WiFi Setup 1.8 - changes from 1.7

For successful RTC time and date synchronization, the ESP module must run AT firmware 1.4.0.0 or newer with SNTP support.

1. Empty passwords are accepted, allowing connections to open WiFi networks.
2. PING is available through I to test reachability of an IP address or hostname.
3. AT communication, response handling, timeouts, parsing, escaping, and buffer handling were corrected. Trailing password spaces are preserved.
4. A failed connection to a new AP triggers an attempt to restore the saved Default AP. New credentials are tested with CUR and saved with DEF only after a successful join. The original failure reason remains visible.

Other changes include the third-row I-Ping menu item, title/underline alignment, the 11/2026 date, and corrected debug assembly.

## Included components and files

The release includes BIOS 2.1 for EL/MB (566 B, +22 B over 2.0) and the final Terminal 1.1 setup component (5256 B). A separate ZX Next setup is available in the sibling directory.

| Output | Bytes |
|---|---:|
| Standalone TAP | 16264 |
| Standalone CODE | 16184 |
| Flash BIN | 16228 |
| Debug BIN | 16228 |

Flash/debug are intentionally identical to permit NMI debugging. The largest raw output leaves 156 bytes below 16384. The loader uses CLEAR 27647 to protect editor scratch/history.

## Final AP recovery behavior

Recovery uses an independent budget of 500 rather than the normal 3000. Waiting for GOT IP takes at most roughly ten seconds with 50 Hz interrupts; received bytes also consume the budget. Restart and control commands are separate. Normal joins and other commands retain their original timeout.

Recovery temporarily aligns UART/ESP at 115200 before AT+RST. It remembers the previous rate and attempts to restore it after boot. If the exact ready line is missing, a bounded AT probe on the known baseline checks communication before restoration. The original Auto AP setting is preserved.

On acknowledging the result, control jumps to st1, the same initialization path used on return from the terminal. This redraws the setup and runs the existing speed-management routine before subsequent queries. The earlier direct return could leave index 7 displayed with a stale baud value or trigger later AT errors.

This final jump-target change costs no bytes. A temporary rate of 7 before the result key is expected. Physical testing has been basic, not exhaustive.

## Other fixes and verification

SNTP configuration detection now searches the bounded 255-byte receive buffer instead of just the first 13 bytes, allowing leading CR/LF and command echo. This changes only an operand and adds no bytes.

The current package passed 153 assembled-code AP scenarios, actual BIOS/UART-builder restoration tests in a CPU model, and checks of embedded components, memory layout, TAP blocks, checksums, loader, and payload equality. Automated tests use simulated UART and UI behavior.

Intermediate builds and backups remain in the separate working archive; they are not part of this release.