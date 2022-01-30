#!/usr/bin/env bash

set -euo pipefail

UPPER_BOUND_CFG=upper-bound-config
CFG_CANDIDATE=candidate.config
KERNEL_DIR=~/Werkbank/Hobbys/Linux-Kernel/linux
KCONFIG="$KERNEL_DIR/.config"
WIFI_DIR=~/Werkbank/Hobbys/rtl88x2bu

function shrink-config() {
    local SOURCE_F="$1"
    local DEST_F="$2"
    local OPTION="$3"
    if [[ "$SOURCE_F" = "$DEST_F" ]]
    then
        echo Source and destination must differ! >&2
        exit 1
    fi
    sed "s/$OPTION=y/$OPTION=n/" "$SOURCE_F" > "$DEST_F"
}

function enabled-config-options() {
    local SOURCE_F="$1"
    grep -F '=y' "$SOURCE_F" | \
    while read -r option_line
    do
        local option=${option_line:0:-2}
        echo "$option"
    done
}

# cp "$(ls -1 /boot/config-5.10.0-* | sort -n | tail -n1)" "$KCONFIG"
# "$KERNEL_DIR/scripts/config" --file "$KCONFIG" \
#     --disable SYSTEM_TRUSTED_KEYS \
#     --enable OF_OVERLAY
# yes "" | make -C "$KERNEL_DIR" localmodconfig || true

enabled-config-options "$UPPER_BOUND_CFG" | \
shuf | \
while read -r option
do
    shrink-config "$UPPER_BOUND_CFG" "$CFG_CANDIDATE" "$option"
    diff upper-bound-config "$CFG_CANDIDATE" || true
    cp "$CFG_CANDIDATE" "$KCONFIG"
    if ! make -C "$KERNEL_DIR" -j4 dir-pkg
    then
        continue
    fi
    if make -C "$WIFI_DIR" KBASE="$KERNEL_DIR" -j4
    then
        cp "$CFG_CANDIDATE" upper-bound-config
    fi
done
