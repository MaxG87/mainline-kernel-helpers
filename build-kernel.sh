#!/bin/bash

set -eu

function deactivate-debug-info() {
    scripts/config --undefine DEBUG_INFO
    scripts/config --undefine DEBUG_INFO_COMPRESSED
    scripts/config --undefine DEBUG_INFO_REDUCED
    scripts/config --undefine DEBUG_INFO_SPLIT
    scripts/config --undefine GDB_SCRIPTS
    scripts/config --disable DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
    scripts/config --set-val  DEBUG_INFO_DWARF5 n
    scripts/config --set-val  DEBUG_INFO_NONE y
}

function deactivate-signing() {
    scripts/config --disable SYSTEM_REVOCATION_KEYS
    scripts/config --disable SYSTEM_TRUSTED_KEYS
}

function configure-kernel() {
    PREIMAGE_CONFIG="$(fdfind 'config-\d\.\d+\.\d+-\d+-.*' /boot --max-depth=1 --type f | sort | tail -n1)"
    cp "$PREIMAGE_CONFIG" .config
    yes "" | make -j "$(nproc)" oldconfig

    deactivate-debug-info
    deactivate-signing
    yes "" | make -j "$(nproc)" oldconfig
}

if [[ ! -f README || "$(head -1 README)" != "Linux kernel" ]]
then
    echo "Falsches Verzeichnis" >&2
    exit 1
fi

# Must remove all linux-* files. The target bindeb-pkg creates non-deb-files too.
rm -f ../linux-*.{buildinfo,changes,deb,dsc,diff.gz,tar.gz}
rm -f .config
rm -rf "../linux.orig"

configure-kernel

KCFLAGS="-march=native -O2 -pipe" KCPPFLAGS="-march=native -O2 -pipe" make -j "$(nproc)" bindeb-pkg
