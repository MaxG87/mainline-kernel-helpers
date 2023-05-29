#!/bin/bash

set -eu
BUILDTARGET_DEFAULT=bindeb-pkg
CONFIGTARGET_DEFAULT=oldconfig

function main() {
    local ncommits

    # cleanup
    parse-cli "$@"
    ncommits=$(extract-extra-version-number)
    set-extra-version-number "$ncommits"
    configure-kernel
    KCFLAGS="-march=native -O2 -pipe" \
        KCPPFLAGS="-march=native -O2 -pipe" \
        make -j "$(nproc)" "$BUILDTARGET"
}

function parse-cli() {
    BUILDTARGET="$BUILDTARGET_DEFAULT"
    CONFIGTARGET="$CONFIGTARGET_DEFAULT"
    while [[ $# -gt 0 ]]
    do
        case "${1-}" in
            -h | --help) print_usage ;;
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
}

function print_usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [--config-target] [--build-target]

Configure and build Linux-Kernel

Note that values for --build-target and --config-target will be passed through
to \`make\` without further checks. If used maliciously, a whole compilation
could be started in the configuration phase already.

Available options:

-h, --help       Print this help and exit
--build-target   Compilation target. Will be passed through to \`make\`. Defaults to "$BUILDTARGET_DEFAULT".
--config-target  Configuration target. Will be passed through to \`make\`. Defaults to "$CONFIGTARGET_DEFAULT".
EOF
    exit
}

function cleanup() {
    # Must remove all linux-* files. The target bindeb-pkg creates non-deb-files too.
    rm -f ../linux-*.{buildinfo,changes,deb,dsc,diff.gz,tar.gz}
    rm -rf "../linux.orig"
}

function extract-extra-version-number() {
    local rc_tag_prefix="^v[[:digit:]]\.[[:digit:]]+-rc[[:digit:]]"
    local version_tag_prefix="^v[[:digit:]]\.[[:digit:]]+\.[[:digit:]]+"
    local version_or_rc="(${version_tag_prefix}|${rc_tag_prefix})\$"
    local inbetween_suffix="-[[:digit:]]+-g[0-9a-f]+\$"
    local inbetween_rc="${rc_tag_prefix}${inbetween_suffix}"
    local inbetween_version="${version_tag_prefix}${inbetween_suffix}"

    local vnum
    vnum="$(git describe)"
    if [[ "$vnum" =~ $version_or_rc ]]
    then
        echo ""
    elif [[ "$vnum" =~ $inbetween_version ]]
    then
        echo "$vnum" | cut -f2 -d-
    elif [[ "$vnum" =~ $inbetween_rc ]]
    then
        echo "$vnum" | cut -f3 -d-
    fi
}

function set-extra-version-number() {
    local ncommits="$1"
    if [[ -z "$ncommits" ]]
    then
        return
    fi
    perl -pi -e 's/(^EXTRAVERSION =.*)/$1-'"$ncommits"'/' Makefile
}

function configure-kernel() {
    local PREIMAGE_CONFIG
    PREIMAGE_CONFIG="$(fdfind 'config-\d\.\d+\.\d+-\d+-.*' /boot --max-depth=1 --type f | sort | tail -n1)"
    cp "$PREIMAGE_CONFIG" .config
    yes "" | make -j "$(nproc)" "$CONFIGTARGET"

    deactivate-debug-info
    deactivate-signing
    yes "" | make -j "$(nproc)" "$CONFIGTARGET"
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

if [[ ! -f README || "$(head -1 README)" != "Linux kernel" ]]
then
    echo "Falsches Verzeichnis" >&2
    exit 1
fi

main "$@"
