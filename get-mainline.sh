#!/usr/bin/env bash

set -euo pipefail

KVER="$1"
BASE_URL="https://kernel.ubuntu.com/~kernel-ppa/mainline/v${KVER}"

curl -s "${BASE_URL}/" |
grep -EA 7 '(Build for amd64|Test amd64/build) succeeded' |
grep -Eo 'linux[^"]+deb' |
sort -u |
grep -v lowlatency |
while read -r deb
do
  echo About to download "$deb".
  curl -s "$BASE_URL/$deb" > "$deb"
done
