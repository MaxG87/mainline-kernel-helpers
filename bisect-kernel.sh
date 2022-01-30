#!/usr/bin/env bash

set -euo pipefail

KERNEL_DIR=~/Werkbank/Hobbys/Linux-Kernel/linux/
KCONFIG="$KERNEL_DIR/.config"
WIFI_DIR=~/Werkbank/Hobbys/rtl88x2bu

rm -f "$KCONFIG"
cp "$(ls -1 /boot/config-5.10.0-* | sort -n | tail -n1)" "$KCONFIG"
"$KERNEL_DIR/scripts/config" --file "$KCONFIG" \
    --disable SYSTEM_TRUSTED_KEYS \
    --enable OF_OVERLAY
yes "" | make -C "$KERNEL_DIR" localmodconfig || true
# "$KERNEL_DIR/scripts/config" --file "$KERNEL_DIR/.config" \
#     --enable CONFIG_MODULES \
#     --enable CONFIG_WLAN \
#     --enable CONFIG_WIRELESS \
#     --enable CONFIG_CFG80211 \
#     --enable CONFIG_USB

make -C "$KERNEL_DIR" -j4 dir-pkg
make -C "$WIFI_DIR" KBASE=/home/mgoerner/Werkbank/Hobbys/Linux-Kernel/linux -j4
