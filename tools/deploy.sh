#!/usr/bin/env bash
# Copy the mod sources into a local ACE COMBAT 8 installation.
#
#   tools/deploy.sh                       uses the default Steam path
#   AC8_DIR="/c/Games/ACE COMBAT 8" tools/deploy.sh
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
DEV="$(cd "$HERE/.." && pwd)"
GAME="${AC8_DIR:-D:/Steam/steamapps/common/ACE COMBAT 8}"
DEST="$GAME/Game/Binaries/Win64/ue4ss/Mods"

if [ ! -d "$GAME/Game/Binaries/Win64" ]; then
    echo "game folder not found: $GAME" >&2
    echo "set AC8_DIR to your ACE COMBAT 8 installation" >&2
    exit 1
fi
if [ ! -d "$DEST" ]; then
    echo "UE4SS is not installed (missing $DEST)" >&2
    exit 1
fi

rm -rf "$DEST/ModernMissileMod"
cp -r "$DEV/src/ModernMissileMod" "$DEST/ModernMissileMod"
echo "deployed ModernMissileMod -> $DEST"
