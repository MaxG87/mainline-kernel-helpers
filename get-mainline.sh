#!/usr/bin/env bash

set -euo pipefail

KVER="$1"
BASE_URL="https://kernel.ubuntu.com/~kernel-ppa/mainline/v${KVER}"

begin='(Build for amd64|Test amd64\/build) succeeded'
end='(Build for|Test) .* succeeded'

curl -s "${BASE_URL}/" |
sed -nE "/${begin}/,/${end}/ {s/.*(linux[^\"]+\.deb).*/\1/p}" |
sort -u |
grep -v lowlatency |
while read -r deb
do
  echo About to download "$deb".
  curl -s "$BASE_URL/$deb" > "$deb"
done
