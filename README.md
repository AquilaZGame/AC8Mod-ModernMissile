# Modern Missile Mod

**ACE COMBAT 8: Wings of Theve — missile parameter overhaul** · v1.0.0

A UE4SS Lua mod that rebuilds the player's missile catalogue around modern air-combat practice:
longer acquisition ranges, realistic seeker gimbal limits, proportional-navigation lead, higher
turn rates, meaningful warheads and larger magazines.

- **Release notes (English):** [docs/RELEASE_NOTES_EN.md](docs/RELEASE_NOTES_EN.md)
- **发行说明（中文）：** [docs/RELEASE_NOTES_ZH.md](docs/RELEASE_NOTES_ZH.md)
- **Reverse-engineering notes (中文):** [docs/TECHNICAL_NOTES_ZH.md](docs/TECHNICAL_NOTES_ZH.md)

## Requirements

- ACE COMBAT 8 (Steam), single-player / offline
- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) 3.0.1 or newer in `Game\Binaries\Win64\`
- A no-EAC offline launcher

## Installation

Copy `src\ModernMissileMod` into `ACE COMBAT 8\Game\Binaries\Win64\ue4ss\Mods\`, then start the
game offline:

```
ue4ss\Mods\ModernMissileMod\
├── enabled.txt
├── README.txt
└── Scripts\
    ├── main.lua
    └── config.lua
```

Uninstall by deleting the folder. Nothing is written to the save file.

## Tuning

Every value lives in [`src/ModernMissileMod/Scripts/config.lua`](src/ModernMissileMod/Scripts/config.lua):
lock-on range, lock cone, seeker field of view, turn rate, lead, damage, blast radius, speed and
magazine multipliers, one block per store. Restart the game after editing.

## Repository layout

```
src/ModernMissileMod/   the mod itself (the only thing users install)
tools/deploy.sh         copy the mod into a local game installation
tools/package.sh        build a release zip for Nexus / GitHub Releases
docs/                   release notes and technical notes
local/                  internal documents (requirements, drafts) — not tracked by git
```

## Development

`tools/deploy.sh` expects the game at `D:\Steam\steamapps\common\ACE COMBAT 8` by default; point it
elsewhere with `AC8_DIR`:

```bash
AC8_DIR="/c/Games/ACE COMBAT 8" tools/deploy.sh
```

The mod writes `ModernMissileMod.log` next to its folder. Every weapon the patcher touches logs its
vanilla values and the applied deltas; `FAILED:` lines mean a write did not survive readback.

## Licence

MIT — see [LICENSE](LICENSE).
