#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="$("$ROOT_DIR/scripts/build_app.sh" | tail -n 1)"
TARGET_PATH="/Applications/Copy Tools.app"

rm -rf "$TARGET_PATH"
cp -R "$APP_PATH" "$TARGET_PATH"

if command -v xattr >/dev/null 2>&1; then
  xattr -dr com.apple.quarantine "$TARGET_PATH" 2>/dev/null || true
fi

echo "$TARGET_PATH"
