#!/usr/bin/env bash

set -euo pipefail

KERNEL_DIR=~/Werkbank/Hobbys/Linux-Kernel/linux/
WIFI_DIR=~/Werkbank/Hobbys/rtl88x2bu
rm -f "$KERNEL_DIR/.config"
yes "" | make -C "$KERNEL_DIR" localmodconfig > /dev/null || true
make -C "$KERNEL_DIR" -j4 dir-pkg
make -C "$WIFI_DIR" KBASE=/home/mgoerner/Werkbank/Hobbys/Linux-Kernel/linux -j4
