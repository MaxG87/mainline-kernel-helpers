#!/bin/bash

set -euo pipefail

if [[ $PWD != /home/mgoerner/Werkbank/Hobbys/Linux-Kernel/linux ]]
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

N_PROCS=$(grep -Ec "^processor +:" /proc/cpuinfo)
git clean -xdf
cp "$(find /boot -maxdepth 1 -iname "config-5.10.0-*" | sort -n | tail -n1)" .config
scripts/config --disable SYSTEM_TRUSTED_KEYS
yes "" | make oldconfig
KCFLAGS="-march=native -O2 -pipe" KCPPFLAGS="-march=native -O2 -pipe" make -j "$N_PROCS" deb-pkg
