#!/usr/bin/env bash
# Check Lark international's official API for the latest .deb and rewrite
# lark.nix in-place if a newer version is available.
#
# Exit codes:
#   0 — success (file may or may not have been updated)
#   1 — error
set -euo pipefail

cd "$(dirname "$0")"

API_URL="https://www.larksuite.com/api/package_info?platform=10"

echo ">> querying $API_URL"
info=$(curl -fsSL "$API_URL")

signed_url=$(echo "$info" | jq -r '.data.download_link')
version=$(echo "$info" | jq -r '.data.version_number' | sed -n 's/.*@V//p')

if [ -z "$version" ] || [ -z "$signed_url" ]; then
  echo "!! could not parse API response"
  echo "$info"
  exit 1
fi

# Rewrite the signed CDN URL to the unsigned static CDN that serves the same
# object — the signed host requires query-string credentials that expire, so
# we can't pin it in a Nix derivation.
new_url=$(echo "$signed_url" \
  | sed -E 's|^https://[^/]+/obj/lark-version-sg|https://sf16-sg.larksuitecdn.com/obj/lark-version-sg|' \
  | sed -E 's/\?.*$//')

current_version=$(grep -oE 'version = "[^"]+"' lark.nix | head -1 | sed -E 's/version = "([^"]+)"/\1/')

echo ">> current: $current_version"
echo ">> latest:  $version"
echo ">> url:     $new_url"

if [ "$current_version" = "$version" ]; then
  echo ">> already up to date"
  exit 0
fi

echo ">> prefetching to compute sha256..."
hash=$(nix-prefetch-url --type sha256 "$new_url")
sri=$(nix --extra-experimental-features nix-command hash convert --hash-algo sha256 --to sri "$hash")

echo ">> sha256:  $sri"

# In-place rewrite. Three independent lines, each unique in lark.nix:
#   version = "X.Y.Z";
#   url = "https://sf16-sg.larksuitecdn.com/obj/lark-version-sg/.../Lark-linux_x64-X.Y.Z.deb";
#   sha256 = "sha256-...";
sed -i -E "s|version = \"[0-9.]+\";|version = \"$version\";|" lark.nix
sed -i -E "s|url = \"https://sf16-sg\\.larksuitecdn\\.com/obj/lark-version-sg/[^\"]+\";|url = \"$new_url\";|" lark.nix
sed -i -E "s|sha256 = \"sha256-[^\"]+\";|sha256 = \"$sri\";|" lark.nix

echo ">> lark.nix updated $current_version -> $version"
