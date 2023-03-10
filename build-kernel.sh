#!/bin/bash

set -eu

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
scripts/config --disable DEBUG_INFO
scripts/config --disable SYSTEM_TRUSTED_KEYS
yes "" | make oldconfig
KCFLAGS="-march=native -O2 -pipe" KCPPFLAGS="-march=native -O2 -pipe" make -j "$(nproc)" bindeb-pkg
