# Modern Missile Mod

**ACE COMBAT 8: Wings of Theve — air-to-air and air-to-ground missile overhaul**

Version 1.0.0 · Single-player / offline · UE4SS Lua

---

## Overview

Missiles are one of the signature features of the Ace Combat series. The series has always tuned
them for arcade pacing — short acquisition ranges, capable but tightly bounded seekers, generous
magazines — and that tuning is a deliberate design choice that works well in the third-person
view and at the pace the missions are built around.

Modern Missile Mod offers an alternative tuning for cockpit flying, especially with a HOTAS: it
brings the missile envelope closer to modern air-combat practice without changing the arcade
flow of a mission. The vanilla balance is not replaced or corrected — this is simply a second
option for a different way of playing.

The design goals are longer acquisition ranges, realistic seeker gimbal limits,
proportional-navigation lead, higher turn rates, warheads that matter against large targets, and
magazines that let a sortie fight with missiles instead of conserving them.

## Design intent

Real BVR engagement distances are enormous compared with the scale of an Ace Combat mission.
Rather than transplant real-world figures directly, every range in this mod is a **compressed
BVR figure**: long enough that an F-pole fight is possible, short enough that the mission still
fits inside the map and the player still has to fly the jet.

The result is a layered envelope:

- **Within visual range** — dogfight missiles acquire early, track through high off-boresight
  angles and are hard to defeat with a single break turn.
- **Beyond visual range** — medium- and long-range stores reward altitude, speed and target
  discipline; their flight times are extended so the lock range is actually reachable.
- **Stand-off** — cruise missiles and anti-ship missiles can be released from outside the
  defended area, at the cost of a long time of flight.

## What the mod changes

| System | Behaviour |
| --- | --- |
| Lock-on | Acquisition range (`LockonRange`) and lock cone (`LockonAngle`) per store |
| Seeker | Field of view (`MaxHomingAngle`), tracking turn rate (`MaxRotationAngle`), proportional lead (`HomingForesightAmount`) |
| Kinematics | Maximum speed and acceleration for the two speed-rated stores (LASM, LAGM) |
| Endurance | Flight life time automatically extended to cover the new lock range |
| Lethality | Warhead damage and blast radius per store |
| Logistics | Special-weapon magazine capacity per aircraft and per upgrade level |

Target set: **player weapons only**. Enemy missiles are driven by a separate data table and are
left untouched, so the threat picture stays the same.

## Requirements

- **ACE COMBAT 8: Wings of Theve** (Steam), single-player / offline
- **UE4SS 3.0.1** (or a newer build) installed in `Game\Binaries\Win64\`
- **No-EAC offline launcher** (any equivalent) — the mod is a Lua script and does not patch the
  executable, but it must run without EasyAntiCheat
- No other weapon-parameter mod active at the same time

HOTAS is **not** required. The mod is fully usable on keyboard and gamepad.

## Changed values

Ranges in kilometres. "Lock cone" is the HUD acquisition cone; "Seeker FOV" is the missile's own
gimbal limit after launch. Vanilla values in brackets.

### Air-to-air

| Store | Analogue | Lock-on range | Lock cone | Seeker FOV | Turn rate | Lead | Capacity | Damage |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MSL | AIM-9X | 2.0 → **5.0** | 32.5° → **40°** | 75° → **100°** | 40 → **80 °/s** | 0 → **0.60** | ×1 | ×2.5 |
| 2AAM | IRIS-T | 3.0 → **8.0** | 32.5° → **40°** | 90° → **100°** | 50 → **80 °/s** | 0 → **0.60** | ×1 | ×2.5 |
| QAAM | PL-10 | 2.4 → **5.0** | 120° → **160°** | 120° → **160°** | 75 → **110 °/s** | 0.40 → **0.95** | ×2 | ×2.5 |
| SASM | Python-5 | 2.4 → **8.0** | native (45°) | 75° → **100°** | 40 → **80 °/s** | 0 → **0.60** | ×2 | ×2.5 |
| 4AAM | AIM-120D | 4.0 → **10.0** | native | 65° → **90°** | 45 → **65 °/s** | 0 → **0.50** | ×2 | ×2.5 |
| 6AAM | AIM-120D | 5.0 → **10.0** | native | 67.5° → **90°** | 45 → **65 °/s** | 0 → **0.50** | ×2 | ×2.5 |
| HCAA | MBDA Meteor | 2.2 → **10.0** | native | 75° → **90°** | 50 → **65 °/s** | 0 → **0.50** | ×2 | ×2.5 |
| SAAM | AIM-7P | 6.0 → **12.0** | native | 150° → **180°** | 150 → **180 °/s** | 0.10 → **0.30** | ×2 | ×2.5 |
| HPAA | PL-12 | 3.75 → **12.0** | native | 65° → **90°** | 45 → **65 °/s** | 0 → **0.50** | ×2 | ×2.5 |
| HVAA | PL-15 | 5.0 → **40.0** | native | 65° → **110°** | 55 → **80 °/s** | 0 → **0.90** | ×2 | ×2.5 |
| LAAM | PL-17 | 10.0 → **60.0** | native | 90° → **110°** | 150 °/s | 0 → **0.90** | ×2 | ×5 |

SASM also receives a **×2 blast radius** (50 m → 100 m), keeping its native high-explosive
character. SAAM keeps its native blast radius.

### Air-to-ground

| Store | Analogue | Lock-on range | Capacity | Damage | Blast | Speed |
| --- | --- | --- | --- | --- | --- | --- |
| 4AGM | AGM-65 | 3.0 → **10.0** | ×3 | ×1 | native | native |
| 6AGM | AGM-65 | 3.5 → **10.0** | ×3 | ×1 | native | native |
| 8AGM | AGM-65 | 4.0 → **10.0** | ×3 | ×1 | native | native |
| LASM | AGM-84 | 6.0 → **100.0** | ×2 | ×5 | native | **×2** |
| LAGM | AKF-98A | 6.0 → **100.0** | ×2 | ×3 | native | **×1.5** |
| LACM | AGM-158B | 10.0 → **150.0** | ×2 | ×3 | 145 → **290 m** | native |

Flight life time is not listed: it is derived at runtime from the new lock-on range and the
store's maximum speed, so a missile can always reach the distance it can lock at.

## File structure

```
ue4ss\Mods\ModernMissileMod\
├── enabled.txt
├── README.txt
├── ModernMissileMod.log          (created at runtime)
└── Scripts\
    ├── main.lua                  (patcher: lock-on, guidance, warhead, magazine)
    └── config.lua                (every value in the tables above)
```

## Installation

1. Make sure UE4SS is installed in `ACE COMBAT 8\Game\Binaries\Win64\`
   (`ue4ss\UE4SS.dll` plus its proxy DLL).
2. Copy the `ModernMissileMod` folder into `ACE COMBAT 8\Game\Binaries\Win64\ue4ss\Mods\`.
3. Start the game in offline / no-EAC mode and load a mission.

Uninstalling is a folder delete — nothing is written to the save file.

## Notes

- **One weapon switch per sortie.** The HUD lock ring reads the weapon's acquisition range when
  the store is selected; after entering a mission, cycle the weapon once to refresh the ring.
- **Per-mission re-application.** The game rebuilds the weapon classes for every sortie. The mod
  rewrites them during the first seconds of each mission load, then goes completely idle — no
  polling, no per-frame work.
- **Map-aware.** Menu, hangar, briefing and transition maps are skipped; only `Maps/Ingame/...`
  is touched.
- **Enemy weapons unchanged.** Same threat as vanilla.
- **Attribution.** Values are the mod's own balance choices, not claims of real-world fidelity.

## Compatibility

- Single-player only.
- Not compatible with other mods that rewrite the same weapon class defaults or the per-aircraft
  parameter tables (other missile rebalances, ammo multipliers). Load one at a time.
- Works alongside cockpit/HOTAS, camera, sound and skin mods.

## Roadmap

- Bomb and rocket parameters
- Real-world missile names in the weapon list
- Free per-aircraft missile selection

## Credits and licence

Developed with AI assistance (the "Big Fat Fish" model, DeepSeek V4.1 Flash), with human
testing and review.

MIT licence — use, modify and redistribute freely. See `LICENSE`.
