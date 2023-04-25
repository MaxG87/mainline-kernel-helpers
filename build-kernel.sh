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

if [[ ! -f README || "$(head -1 README)" != "Linux kernel" ]]
then
    echo "Falsches Verzeichnis" >&2
    exit 1
fi

# Must remove all linux-* files. The target bindeb-pkg creates non-deb-files too.
rm -f ../linux-*.{buildinfo,changes,deb,dsc,diff.gz,tar.gz}
rm -f .config
rm -rf "../linux.orig"

cp "$(find /boot -maxdepth 1 -type f -name 'config-[0-9].[0-9].[0-9]-[0-9]-amd64' | tail -n1)" .config

deactivate-debug-info
yes "" | make -j "$(nproc)" oldconfig

KCFLAGS="-march=native -O2 -pipe" KCPPFLAGS="-march=native -O2 -pipe" make -j "$(nproc)" bindeb-pkg
