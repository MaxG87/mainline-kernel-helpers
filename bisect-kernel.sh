#!/usr/bin/env bash

set -eu

CLEANUP_DEFAULT="true"

function print_usage() {
	cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Build Linux-Kernel and RTL88x2BU in conjunction.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
--[no-]cleanup  Enable or disable cleanup of build artefacts; defaults to $CLEANUP_DEFAULT
--full-build    Enable full build of Kernel; allows to get rid of missing symbols warning
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
CLEANUP=$CLEANUP_DEFAULT
FULL_BUILD="false"
while [[ $# -gt 0 ]]; do
	case "${1-}" in
	-h | --help) print_usage ;;
	-v | --verbose) MAKE_VERBOSITY= ;;
	--cleanup) CLEANUP="true" ;;
	--no-cleanup) CLEANUP="false" ;;
	--kernel-dir)
		KERNEL_DIR="${2-}"
		shift
		;;
	--full-build) FULL_BUILD="true" ;;
	--wifi-dir)
		WIFI_DIR="${2-}"
		shift
		;;
	*) die "Unknown option: $1" ;;
	esac
	shift
done

if ! [[ ${KERNEL_DIR:+1} && ${WIFI_DIR:+1} ]]; then
	die "Both KERNEL_DIR and WIFI_DIR must be set!"
fi

# shellcheck disable=SC2206
MAKE_OPTS=(-j "$(nproc)" $MAKE_VERBOSITY)
KCONFIG="$KERNEL_DIR/.config"

# Prepare Kernel Tree
rm -f "$KCONFIG"

if [[ "$FULL_BUILD" == "true" ]]; then
	yes "" | make -C "$KERNEL_DIR" "${MAKE_OPTS[@]}" localmodconfig >/dev/null
	make -C "$KERNEL_DIR" "${MAKE_OPTS[@]}" dir-pkg
else
	make -C "$KERNEL_DIR" "${MAKE_OPTS[@]}" allyesconfig >/dev/null
	make -C "$KERNEL_DIR" "${MAKE_OPTS[@]}" modules_prepare
fi

# Try to compile Wifi driver
build_log=$(mktemp)
make -C "$WIFI_DIR" KBASE="$KERNEL_DIR" "${MAKE_OPTS[@]}" |& tee "$build_log" || true
if grep -qE "Werror|error:" "$build_log"; then
	# Unfortunately, the exit code of `make` is always 1 due to missing
	# symbols. Therefore, we have to grep the output. If "error" appears in the
	# output, the build failed.
	exit_code=1
else
	exit_code=0
fi
rm "$build_log"

# Cleanup
if [[ "$CLEANUP" == "true" ]]; then
	make -C "$WIFI_DIR" KBASE="$KERNEL_DIR" "${MAKE_OPTS[@]}" clean
	make -C "$KERNEL_DIR" "${MAKE_OPTS[@]}" distclean
fi

# Exit with correct code
[[ $exit_code -eq 0 ]]
