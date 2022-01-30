#!/usr/bin/env bash

set -euo pipefail


function print_usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Build Linux-Kernel and RTL88x2BU in conjunction.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
--kernel-dir    Directory of the Linux Kernel source code
--wifi-dir      Directory of the RTL88x2BU source code
EOF
    exit
}

msg() {
    echo >&2 -e "${1-}"
}

die() {
    local msg=$1
    local code=${2-1} # default exit status 1
    msg "$msg"
    exit "$code"
}

MAKE_VERBOSITY="-s"
while [[ $# -gt 0 ]]
do
    case "${1-}" in
        -h | --help) print_usage ;;
        -v | --verbose) MAKE_VERBOSITY= ;;
        --kernel-dir)
            KERNEL_DIR="${2-}"
            shift
            ;;
        --wifi-dir)
            WIFI_DIR="${2-}"
            shift
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

if ! [[ ${KERNEL_DIR:+1} && ${WIFI_DIR:+1} ]]
then
    die "Both KERNEL_DIR and WIFI_DIR must be set!"
fi

KCONFIG="$KERNEL_DIR/.config"

rm -f "$KCONFIG"
cp "$(find /boot -maxdepth 1 -iname "config-5.10.0-*" | sort -n | tail -n1)" "$KCONFIG"
"$KERNEL_DIR/scripts/config" --file "$KCONFIG" \
    --disable SYSTEM_TRUSTED_KEYS \
    --enable OF_OVERLAY
# Disable SC2086 because MAKE_VERBOSITY must expand to nothing if verbose is given
# shellcheck disable=SC2086
yes "" | make -C "$KERNEL_DIR" $MAKE_VERBOSITY localmodconfig || true
# "$KERNEL_DIR/scripts/config" --file "$KERNEL_DIR/.config" \
#     --enable CONFIG_MODULES \
#     --enable CONFIG_WLAN \
#     --enable CONFIG_WIRELESS \
#     --enable CONFIG_CFG80211 \
#     --enable CONFIG_USB

# shellcheck disable=SC2086
make -C "$KERNEL_DIR" -j "$(nproc)" $MAKE_VERBOSITY dir-pkg
# shellcheck disable=SC2086
make  -C "$WIFI_DIR" KBASE="$KERNEL_DIR" -j "$(nproc)" $MAKE_VERBOSITY
