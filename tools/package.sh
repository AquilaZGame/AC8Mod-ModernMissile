#!/usr/bin/env bash
# Build both release archives:
#
#   dist/ModernMissileMod-<version>.zip         GitHub Release
#       README / LICENSE / CHANGELOG / docs + ue4ss\Mods\ModernMissileMod
#
#   dist/ModernMissileMod-<version>-Nexus.zip   NexusMods
#       only the mod itself (+ a short install note), extracts into Game\Binaries\Win64
#
# UE4SS and the no-EAC launcher are prerequisites, never bundled.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
DEV="$(cd "$HERE/.." && pwd)"
VERSION="$(sed -n 's/^local VERSION *= *[\x27"]\([^\x27"]*\)[\x27"].*/\1/p' "$DEV/src/ModernMissileMod/Scripts/main.lua" | head -1)"
VERSION="${VERSION:-0.0.0}"

OUT="$DEV/dist"
STAGE="$OUT/.stage"
rm -rf "$STAGE" "$OUT/ModernMissileMod-$VERSION.zip" "$OUT/ModernMissileMod-$VERSION-Nexus.zip"
mkdir -p "$STAGE"

zip_dir() { # $1 = folder to zip from, $2 = destination zip, $3 = "folder" | "contents"
    local src="$1" dst="$2" mode="$3"
    if command -v zip >/dev/null 2>&1; then
        if [ "$mode" = "folder" ]; then
            ( cd "$(dirname "$src")" && rm -f "$dst" && zip -qr "$dst" "$(basename "$src")" )
        else
            ( cd "$src" && rm -f "$dst" && zip -qr "$dst" . )
        fi
    else
        local wsrc wdst
        wsrc="$(cd "$src" && pwd -W 2>/dev/null || echo "$src")"
        wdst="$(cd "$(dirname "$dst")" && pwd -W 2>/dev/null || dirname "$dst")/$(basename "$dst")"
        if [ "$mode" = "folder" ]; then
            powershell.exe -NoProfile -Command \
                "Compress-Archive -Path '$wsrc' -DestinationPath '$wdst' -Force" >/dev/null
        else
            powershell.exe -NoProfile -Command \
                "Compress-Archive -Path '$wsrc/*' -DestinationPath '$wdst' -Force" >/dev/null
        fi
    fi
}

# ---------------------------------------------------------------- GitHub Release
GH="$STAGE/ModernMissileMod-$VERSION"
mkdir -p "$GH/ue4ss/Mods" "$GH/docs"
cp -r "$DEV/src/ModernMissileMod" "$GH/ue4ss/Mods/ModernMissileMod"
cp "$DEV/README.md" "$DEV/LICENSE" "$DEV/CHANGELOG.md" "$GH/"
cp "$DEV/docs/RELEASE_NOTES_EN.md" "$DEV/docs/RELEASE_NOTES_ZH.md" "$GH/docs/"
zip_dir "$GH" "$OUT/ModernMissileMod-$VERSION.zip" folder

# ---------------------------------------------------------------- NexusMods
NX="$STAGE/nexus"
mkdir -p "$NX/ue4ss/Mods"
cp -r "$DEV/src/ModernMissileMod" "$NX/ue4ss/Mods/ModernMissileMod"
cp "$DEV/docs/INSTALL_NEXUS.txt" "$NX/INSTALL.txt"
zip_dir "$NX" "$OUT/ModernMissileMod-$VERSION-Nexus.zip" contents

rm -rf "$STAGE"
echo "built:"
echo "  $OUT/ModernMissileMod-$VERSION.zip"
echo "  $OUT/ModernMissileMod-$VERSION-Nexus.zip"
