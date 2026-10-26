-- Modern Missile Mod - parameter table.
--
-- Everything here is applied to the *original* values the game ships with (the mod remembers
-- them once per weapon class), so re-entering a mission never multiplies twice.
--
-- Units:
--   lockon      = Unreal centimetres (5 km = 500000)
--   lockangle   = degrees (the HUD lock cone)
--   damage      = multiplier of the original damage
--   ammo        = multiplier of the aircraft's original special-weapon load count
--   speed       = multiplier of SpeedMaximum (and Acceleration)
--   explosion   = multiplier of the original ExplosionRadius
--   homing      = absolute seeker values, only ever raised:
--                   angle = MaxHomingAngle  (seeker field of view, degrees)
--                   rot   = MaxRotationAngle (turn rate, degrees/second)
--                   lead  = HomingForesightAmount (0 = pure pursuit, 1 = full lead)
--   homing_factor = relative version of the same three values
--
-- Fields left out (or false) are not touched.

return {
    enabled = true,

    -- Missile life time in seconds. After the lock range and the speed are known, the mod sets
    --   LifeTime = max(original, lock_range / speed_max * lifetime_margin + lifetime_bonus)
    -- so a longer lock range always comes with a life time that can actually reach it.
    lifetime_margin = 1.30,
    lifetime_bonus = 2.0,

    -- Log the original values of every weapon the mod touches (useful when tuning).
    log_originals = true,

    weapons = {
        -- 格斗弹 -------------------------------------------------------------------------
        {
            key = 'msl', id = 2, label = 'AIM-9X',
            paths = { '/Game/Blueprints/Weapons/MSL/Player/Msl/BP_plwp_msl_a0' },
            lockon = 500000, lockangle = 40,
            damage = 2.5, ammo = 1,
            homing = { angle = 100, rot = 80, lead = 0.60 },
        },
        {
            key = '2aam', id = 3, label = 'IRIS-T',
            paths = { '/Game/Blueprints/Weapons/MSL/Player/2aam/BP_plwp_2aam_a0' },
            lockon = 800000, lockangle = 40,
            damage = 2.5, ammo = 1,
            homing = { angle = 100, rot = 80, lead = 0.60 },
        },
        {
            key = 'qaam', id = 21, label = 'PL-10',
            paths = { '/Game/Blueprints/Weapons/MSL/Player/Qaam/BP_plwp_qaam_a0' },
            lockon = 500000, lockangle = 160,
            damage = 2.5, ammo = 2,
            homing = { angle = 160, rot = 110, lead = 0.95 },
        },
        {
            key = 'sasm', id = 24, label = 'Python-5',
            paths = { '/Game/Blueprints/Weapons/MSL/Player/Sasm/BP_plwp_sasm_a0' },
            lockon = 800000, lockangle = 40,
            damage = 2.5, ammo = 2, explosion = 2.0,
            homing = { angle = 100, rot = 80, lead = 0.60 },
        },

        -- 中距弹 -------------------------------------------------------------------------
        {
            key = '4aam', id = 4, label = 'AIM-120D',
            paths = {
                '/Game/Blueprints/Weapons/MSL/Player/4aam/BP_plwp_4aam_a0',
                '/Game/Blueprints/Weapons/MSL/Player/4aam/BP_plwp_4aam_f0',
            },
            lockon = 1000000,
            damage = 2.5, ammo = 2,
            homing = { angle = 90, rot = 65, lead = 0.50 },
        },
        {
            key = '6aam', id = 6, label = 'AIM-120D (x6)',
            paths = {
                '/Game/Blueprints/Weapons/MSL/Player/6aam/BP_plwp_6aam_a0',
                '/Game/Blueprints/Weapons/MSL/Player/6aam/BP_plwp_6aam_r0',
            },
            lockon = 1000000,
            damage = 2.5, ammo = 2,
            homing = { angle = 90, rot = 65, lead = 0.50 },
        },
        {
            key = 'hcaa', id = 13, label = 'MBDA',
            paths = { '/Game/Blueprints/Weapons/MSL/Player/Hcaa/BP_plwp_hcaa_a0' },
            lockon = 1000000,
            damage = 2.5, ammo = 2,
            homing = { angle = 90, rot = 65, lead = 0.50 },
        },
        {
            key = 'saam', id = 23, label = 'AIM-7P',
            paths = { '/Game/Blueprints/Weapons/MSL/Player/Saam/BP_plwp_saam_a0' },
            lockon = 1200000,
            damage = 2.5, ammo = 2,
            homing_factor = { angle = 1.2, rot = 1.2, lead = 0.30 },
        },
        {
            key = 'hpaa', id = 14, label = 'PL-12',
            paths = { '/Game/Blueprints/Weapons/MSL/Player/Hpaa/BP_plwp_hpaa_a0' },
            lockon = 1200000,
            damage = 2.5, ammo = 2,
            homing = { angle = 90, rot = 65, lead = 0.50 },
        },

        -- 远距弹 -------------------------------------------------------------------------
        {
            key = 'hvaa', id = 15, label = 'PL-15',
            paths = { '/Game/Blueprints/Weapons/MSL/Player/Hvaa/BP_plwp_hvaa_a0' },
            lockon = 4000000,
            damage = 2.5, ammo = 2,
            homing = { angle = 110, rot = 80, lead = 0.90 },
        },
        {
            key = 'laam', id = 16, label = 'PL-17',
            paths = { '/Game/Blueprints/Weapons/MSL/Player/Laam/BP_plwp_laam_a0' },
            lockon = 6000000,
            damage = 5.0, ammo = 2,
            homing = { angle = 110, rot = 80, lead = 0.90 },
        },

        -- 空对地 -------------------------------------------------------------------------
        {
            key = '4agm', id = 5, label = 'AGM-65',
            paths = { '/Game/Blueprints/Weapons/MSL/Player/4agm/BP_plwp_4agm_a0' },
            lockon = 1000000,
            damage = 1.0, ammo = 3,
        },
        {
            key = '6agm', id = 7, label = 'AGM-65 (x6)',
            paths = { '/Game/Blueprints/Weapons/MSL/Player/6agm/BP_plwp_6agm_a0' },
            lockon = 1000000,
            damage = 1.0, ammo = 3,
        },
        {
            key = '8agm', id = 9, label = 'AGM-65 (x8)',
            paths = { '/Game/Blueprints/Weapons/MSL/Player/8agm/BP_plwp_8agm_a0' },
            lockon = 1000000,
            damage = 1.0, ammo = 3,
        },
        {
            key = 'lasm', id = 19, label = 'AGM-84',
            paths = { '/Game/Blueprints/Weapons/MSL/Player/Lasm/BP_plwp_lasm_a0' },
            lockon = 10000000,
            damage = 5.0, ammo = 2, speed = 2.0,
        },
        {
            key = 'lagm', id = 18, label = 'AKF-98A',
            paths = { '/Game/Blueprints/Weapons/MSL/Player/Lagm/BP_plwp_lagm_a0' },
            lockon = 10000000,
            damage = 3.0, ammo = 2, speed = 1.5,
        },
        {
            key = 'lacm', id = 17, label = 'AGM-158B',
            paths = { '/Game/Blueprints/Weapons/MSL/Player/Lacm/BP_plwp_lacm_a0' },
            lockon = 15000000,
            damage = 3.0, ammo = 2, explosion = 2.0,
        },
    },
}
