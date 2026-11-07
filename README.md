# WiFi Setup

Current release: **1.8**, with separate `ver18/el-mb` and `ver18/zx-next` variants.

Each variant includes sources, required binary components, build scripts, tests, and ready-to-use files in `runable/`. Both include BIOS 2.1 and Terminal 1.1.

The EL/MB package also includes flash and debug binaries. These intentionally contain identical code to allow NMI debugging.

The original `ver17` source archive is preserved unchanged. Development backups and intermediate files were moved to the separate local `Wifi Setup work/ver18` directory and are not included here. Sara is not part of this release.

Basic hardware checks and automated tests have been performed; testing is not exhaustive. On EL/MB, acknowledging an AP result follows the same initialization path as returning from the terminal. That particular change has not yet been ported to Next.