#!/usr/bin/env bash

LK_BASE=~/Werkbank/Hobbys/Linux-Kernel

function get-major-versions() {
	git tag | grep -v rc | grep -E 'v6\.[0-9]+$' | sort -V
}

function get-latest-minor() {
	major="$1"
	git tag | grep -v rc | grep -E "${major}\.[0-9]+$" | sort -V | tail -n 1
}

function can-be-built() {
	minor="$1"
	git switch -d "$minor"
	! nice -n20 ${LK_BASE}/mainline-kernel-helpers/bisect-kernel.sh --kernel-dir ${LK_BASE}/linux-stable --wifi-dir ${LK_BASE}/rtl88x2bu/ |& grep -q 'error:'
}

function main() {
	get-major-versions | while read -r major; do
		latest_minor=$(get-latest-minor "$major")
		echo "$major" "$latest_minor"
		if ! can-be-built "$latest_minor"; then
			echo "Can't be built: $latest_minor"
			break
		else
			echo "Can be built: $latest_minor"
		fi
	done
}

main "$@"
