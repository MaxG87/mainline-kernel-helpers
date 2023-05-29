#!/bin/bash

set -eu
BUILDTARGET_DEFAULT=bindeb-pkg
CONFIGTARGET_DEFAULT=oldconfig

function print_usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [--config-target] [--build-target]

Configure and build Linux-Kernel

Note that values for --build-target and --config-target will be passed through
to \`make\` without further checks. If used maliciously, a whole compilation
could be started in the configuration phase already.

Available options:

-h, --help       Print this help and exit
-v, --verbose    Print script debug info
--build-target   Compilation target. Will be passed through to \`make\`. Defaults to "$BUILDTARGET_DEFAULT".
--config-target  Configuration target. Will be passed through to \`make\`. Defaults to "$CONFIGTARGET_DEFAULT".
EOF
    exit
}


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

BUILDTARGET="$BUILDTARGET_DEFAULT"
CONFIGTARGET="$CONFIGTARGET_DEFAULT"
MAKE_VERBOSITY="-s"
while [[ $# -gt 0 ]]
do
    case "${1-}" in
        -h | --help) print_usage ;;
        -v | --verbose) MAKE_VERBOSITY= ;;
        --build-target)
            BUILDTARGET="${2-}"
            shift
            ;;
        --config-target)
            CONFIGTARGET="${2-}"
            shift
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done



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
