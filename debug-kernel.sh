#!/bin/bash

set -euo pipefail

DEVICE_NAME=wlx283b82cb5705
DRIVER_DIR=~/CodeUndDaten/DWA-182_Rev-D1/
KERNEL_SRC_DIR=~/CodeUndDaten/Linux-Kernel/linux
MODULE_NAME=88x2bu


function main() {
    if ! sudo -v
    then
        echo "Root privileges required but not available!"
        exit 1
    fi
    build_wlan_driver
    perform_bisect_step
    build_kernel
    systemctl poweroff
}


function build_wlan_driver() {
    cd "$DRIVER_DIR"
    make -j4
    sudo insmod "$MODULE_NAME.ko"
    cd -
}


function perform_bisect_step() {
    cd "$KERNEL_SRC_DIR"
    sleep 15s
    if iwconfig 2>&1 | grep -q "$DEVICE_NAME"
    then
        git bisect good
    else
        git bisect bad
    fi
}


function build_kernel() {
    cd "$KERNEL_SRC_DIR"
    clean_previous_kernel_build
    build_and_install
}


function clean_previous_kernel_build() {

    if lsmod | grep "$MODULE_NAME"  # adding -q breaks this check for unknonw reasons
    then
        sudo rmmod "$MODULE_NAME"
    fi

    rm -f ../linux-*
    rm -f .config
    rm -rf "../linux.orig"

    git clean -xdf
}


function build_and_install() {
    yes "" | make localmodconfig || true
    make -j4 deb-pkg
    sudo dpkg -i ../linux-*deb
}


main "$@"
