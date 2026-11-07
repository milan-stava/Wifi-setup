# Wifi Setup\ver18\zx-next

Final release. Application sources are unchanged.
Build with assembly.bat (SjASMPlus 1.20.3). Set SJASMPLUS or put sjasmplus on PATH.
build.ps1 accepts -Assembler. Local D:\zx\Tools\SjasmPlus\sjasmplus.exe is a fallback.

Ready-to-use output: runable/

- wifi_setup_next18.tap - 16396 bytes
- wifi_setup_next18.bin - 16316 bytes

Tests simulate hardware; physical testing is not exhaustive.
ROM tests need user-supplied ROM/snapshot files (not included).

Includes BIOS 2.1 and Terminal 1.1. AP recovery restarts ESP and can use temporary 115200 baud.
Speed indices 0..14 selectable. GMT: -12..+14; EDIT cancels; RTC result waits for key. EL/MB AP-return change not yet ported to Next.
