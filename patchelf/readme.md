# patchelf

Goal: ship a dir like
```
app/
  mytool
  lib/
    ld-*.so
    libc*.so
    libm*.so
    ...
  run.sh

```

so ./app/run.sh runs on any compatible kernel without touching the host’s libs.

## plan
* Discover deps (dynamic linker + DT_NEEDED libraries).
* Copy those libs into app/lib/ (keep symlink chain).
* Rewrite the ELF: set the interpreter to the loader inside app/lib/
* Rewrite the ELF: set RPATH to $ORIGIN/lib (so the loader finds your copies)
* run.sh that sets LD_LIBRARY_PATH defensively and execs.

## (1) bundle-elf.sh

* DEPS: sudo apt-get install -y patchelf
* example:

```
./1_bundle-elf.sh /bin/ls ./app          
Bundled -> /data/embd/wolfLabGIT/patchelf/app
Run: /data/embd/wolfLabGIT/patchelf/app/run.sh [args...]

```

```
./app
├── lib
│   ├── ld-2.31.so
│   ├── ld-linux-x86-64.so.2 -> ld-2.31.so
│   ├── libc-2.31.so
│   ├── libc.so.6 -> libc-2.31.so
│   ├── libdl-2.31.so
│   ├── libdl.so.2 -> libdl-2.31.so
│   ├── libpcre2-8.so.0 -> libpcre2-8.so.0.9.0
│   ├── libpcre2-8.so.0.9.0
│   ├── libpthread-2.31.so
│   ├── libpthread.so.0 -> libpthread-2.31.so
│   └── libselinux.so.1
├── ls
└── run.sh

```

```
./app/run.sh                                      
==============
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
exec "$HERE/lib/ld-linux-x86-64.so.2" --library-path "$HERE/lib" "$HERE/ls" "$@"

```

```
./app/run.sh -l                
total 12
... running ok...

```