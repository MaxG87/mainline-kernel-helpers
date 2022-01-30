#!/bin/bash

set -eu

if [[ ! -f README || "$(head -1 README)" != "Linux kernel" ]]
then
    echo "Falsches Verzeichnis" >&2
    exit 1
fi

if sudo lsmod | grep -q 88x2bu
then
    sudo rmmod 88x2bu
fi

rm -f ../linux-*
rm -f .config
rm -rf "../linux.orig"

cp "$(find /boot -maxdepth 1 -iname "config-5.10.0-*" | sort -n | tail -n1)" .config
scripts/config --disable SYSTEM_TRUSTED_KEYS
yes "" | make oldconfig
KCFLAGS="-march=native -O2 -pipe" KCPPFLAGS="-march=native -O2 -pipe" make -j "$(nproc)" deb-pkg
