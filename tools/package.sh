#!/usr/bin/env bash
# Build the release archive: dist/ModernMissileMod-<version>.zip
# The archive extracts straight into  ACE COMBAT 8\Game\Binaries\Win64\
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
DEV="$(cd "$HERE/.." && pwd)"
VERSION="$(sed -n 's/^local VERSION *= *[\x27"]\([^\x27"]*\)[\x27"].*/\1/p' "$DEV/src/ModernMissileMod/Scripts/main.lua" | head -1)"
VERSION="${VERSION:-0.0.0}"
OUT="$DEV/dist"
NAME="ModernMissileMod-$VERSION"

rm -rf "$OUT/$NAME" "$OUT/$NAME.zip"
mkdir -p "$OUT/$NAME/ue4ss/Mods"
cp -r "$DEV/src/ModernMissileMod" "$OUT/$NAME/ue4ss/Mods/ModernMissileMod"

if command -v zip >/dev/null 2>&1; then
    ( cd "$OUT" && zip -qr "$NAME.zip" "$NAME" )
else
    # Windows: Git Bash usually has no zip, PowerShell does
    WOUT="$(cd "$OUT" && pwd -W 2>/dev/null || echo "$OUT")"
    powershell.exe -NoProfile -Command \
        "Compress-Archive -Path '$WOUT/$NAME/*' -DestinationPath '$WOUT/$NAME.zip' -Force" >/dev/null
fi

rm -rf "$OUT/$NAME"
echo "built $OUT/$NAME.zip"
