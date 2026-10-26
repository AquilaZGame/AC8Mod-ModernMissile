# Changelog

All notable changes to this project are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/); versions follow SemVer.

## [1.0.0] — 2026-10-27

First release.

### Added

- Per-store lock-on range and lock-cone rewrite for all player missiles (MSL, 2AAM, 4AAM, 6AAM,
  QAAM, SASM, SAAM, HCAA, HPAA, HVAA, LAAM, 4/6/8AGM, LASM, LAGM, LACM).
- Seeker rewrite: field of view, tracking turn rate and proportional-navigation lead.
- Warhead rewrite: damage multipliers and blast-radius multipliers (SASM ×2, LACM ×2).
- Kinematics: maximum speed and acceleration multipliers for LASM (×2) and LAGM (×1.5).
- Flight life time derived from the new lock-on range and maximum speed.
- Magazine capacity multipliers applied to every aircraft and every upgrade level through
  `DT_PlayerParameter_<aircraft>`.

### Engineering

- Weapon classes are resolved by asset path and by every loaded mesh variant (`_a0`, `_a1`,
  `_f0`, `_r0`, …); vanilla values are cached per weapon type so an inherited variant cannot
  multiply the modifiers twice.
- Writes happen at four fixed moments during mission load, then the mod goes idle. No polling,
  no per-frame work.
- Menu, hangar, briefing and transition maps are skipped; only `Maps/Ingame/...` is patched.
- Player controllers are tracked through a construction notification instead of `FindAllOf`,
  which removes the periodic hitch caused by scanning the whole object array.
- Every write is verified by readback and reported in `ModernMissileMod.log`.
