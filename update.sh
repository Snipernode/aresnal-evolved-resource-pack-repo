#!/usr/bin/env bash
#
# Checks and installs the latest Arsenal: Evolved artifacts for a Paper server.
#
# Usage (from the server root, i.e. the directory containing plugins/):
#   ./update.sh
#   ./update.sh --check
#
# Environment overrides:
#   PLUGIN_DIR   default ./plugins
#   PACK_DIR     default ./plugins/ArsenalEvolved/resourcepack
#   BRANCH       default main
#
set -euo pipefail

REPO="Snipernode/aresnal-evolved-resource-pack-repo"
BRANCH="${BRANCH:-main}"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
PLUGIN_DIR="${PLUGIN_DIR:-./plugins}"
PACK_DIR="${PACK_DIR:-./plugins/ArsenalEvolved/resourcepack}"
CHECK_ONLY=0

if [[ "${1:-}" == "--check" ]]; then
    CHECK_ONLY=1
elif [[ $# -gt 0 ]]; then
    echo "usage: $0 [--check]" >&2
    exit 2
fi

for tool in curl python3 sha256sum; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "error: '$tool' is required" >&2
        exit 1
    fi
done

WORK="$(mktemp -d "${TMPDIR:-/tmp}/arsenal-update.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

echo "Fetching ${BASE_URL}/manifest.json"
curl -fsSL "${BASE_URL}/manifest.json" -o "$WORK/manifest.json"

field() {
    python3 -c '
import json, sys
data = json.load(open(sys.argv[1]))
print(data["artifacts"][sys.argv[2]][sys.argv[3]])
' "$WORK/manifest.json" "$1" "$2"
}

install_artifact() {
    local kind="$1"
    local dest_dir="$2"
    local file sha current downloaded

    file="$(field "$kind" file)"
    sha="$(field "$kind" sha256)"
    mkdir -p "$dest_dir"
    local dest="${dest_dir}/${file}"

    current=""
    if [[ -f "$dest" ]]; then
        current="$(sha256sum "$dest" | awk '{print $1}')"
    fi

    if [[ "$current" == "$sha" ]]; then
        echo "UP-TO-DATE  $dest"
        return
    fi

    if [[ $CHECK_ONLY -eq 1 ]]; then
        echo "UPDATE AVAILABLE  $dest"
        return
    fi

    echo "Downloading $file"
    downloaded="$WORK/$file"
    curl -fsSL "${BASE_URL}/${file}" -o "$downloaded"

    local got
    got="$(sha256sum "$downloaded" | awk '{print $1}')"
    if [[ "$got" != "$sha" ]]; then
        echo "error: SHA-256 mismatch for $file (expected $sha, got $got)" >&2
        exit 1
    fi

    mv "$downloaded" "$dest"
    echo "INSTALLED   $dest"
}

install_artifact plugin "$PLUGIN_DIR"
install_artifact resourcepack "$PACK_DIR"

if [[ $CHECK_ONLY -eq 0 ]]; then
    pack_file="$(field resourcepack file)"
    pack_sha1="$(field resourcepack sha1)"
    printf '%s\n' "$pack_sha1" > "${PACK_DIR}/${pack_file}.sha1"
fi

echo "Done. Restart the server, or run /arsenal reload and /arsenal pack reload."
