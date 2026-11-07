# Wifi Setup\ver18\el-mb

Final release. Application sources are unchanged.
Build with assembly.bat (SjASMPlus 1.20.3). Set SJASMPLUS or put sjasmplus on PATH.
build.ps1 accepts -Assembler. Local D:\zx\Tools\SjasmPlus\sjasmplus.exe is a fallback.

Ready-to-use output: runable/

- wifi_setup_standalone18.tap - 16264 bytes
- wifi_setup_standalone18.bin - 16184 bytes
- wifi_setup_flash18.bin - 16228 bytes
- wifi_setup_flash18_debug.bin - 16228 bytes

Tests simulate hardware; physical testing is not exhaustive.
ROM tests need user-supplied ROM/snapshot files (not included).

Includes BIOS 2.1 and Terminal 1.1. AP recovery restarts ESP and can use temporary 115200 baud.
After acknowledging AP result: terminal return path st1. Flash/debug intentionally match for NMI debugging.
