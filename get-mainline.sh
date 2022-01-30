#!/usr/bin/env bash

set -euo pipefail

KVER="$1"
BASE_URL="https://kernel.ubuntu.com/~kernel-ppa/mainline/v${KVER}"

curl -s "${BASE_URL}/" |
grep -A 7 'Build for amd64' |
grep -Eo 'linux[^"]+deb' |
sort -u |
grep -v lowlatency |
while read -r deb
do
  echo About to download "$deb".
  curl -s "$BASE_URL/$deb" > "$deb"
done
