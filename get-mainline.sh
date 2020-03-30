#!/usr/bin/env bash

set -euo pipefail

KVER="$1"
BASE_URL="https://kernel.ubuntu.com/~kernel-ppa/mainline/v${KVER}"

curl -s "${BASE_URL}/" |
egrep -A 7 'Build for amd64' |
egrep -o 'linux[^"]+deb' |
sort -u |
egrep -v lowlatency |
while read deb
do
  echo About to download "$deb".
  curl -s "$BASE_URL/$deb" > $deb
done
