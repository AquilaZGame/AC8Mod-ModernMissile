-- Modern Missile Mod - ACE COMBAT 8 (UE4SS Lua)
--
-- Rewrites the flight parameters of the player's missiles: lock-on range and angle, seeker
-- field of view / turn rate / lead, life time, speed, blast radius and damage, plus the
-- special-weapon load count in the aircraft parameter tables.
--
-- Where the data lives (verified with a read-only probe on this build):
--   * Flight / seeker / lock-on values: the weapon class default object (CDO)
--     /Game/Blueprints/Weapons/MSL/Player/<type>/BP_plwp_<type>_a0.Default__..._C
--     Fields: LockonRange (cm), LockonAngle (deg), MaxHomingAngle, MaxRotationAngle,
--     HomingForesightAmount, LifeTime (s), SpeedMaximum (cm/s), damage, ExplosionRadius,
--     MaxLoadedCount (salvo size; never touched).
--   * Special weapon load counts: /Game/Datatables/Player/Parameter/DT_PlayerParameter_<plane>
--     Row -> SpWeaponID1..4 are that aircraft's four special weapons; LevelParameter[level]
--     -> SPWeaponInfo<k>.SpWeaponLoadCount1/2 is the load of weapon k in the SP1 / SP2 slot.
--
-- Single-player / offline only, as with every UE4SS weapon mod.

local TAG = '[ModernMissileMod] '
local VERSION = '1.0.0'

local SRC = debug.getinfo(1, 'S').source
local DIR = SRC:match('^@(.*[/\\])[^/\\]*$') or '.\\'
local MOD_ROOT = DIR:gsub('[/\\]+$', ''):gsub('[/\\]Scripts$', '')
local LOG_PATH = MOD_ROOT .. '\\ModernMissileMod.log'

local function log(fmt, ...)
    local ok, line = pcall(string.format, fmt, ...)
    if not ok then line = tostring(fmt) end
    local f = io.open(LOG_PATH, 'a')
    if f then f:write(os.date('%H:%M:%S '), line, '\n'); f:close() end
    print(TAG .. line .. '\n')
end

local function try(fn, ...)
    local ok, v = pcall(fn, ...)
    if ok then return v end
    return nil
end

local function valid(o)
    if o == nil then return false end
    local ok, v = pcall(function() return o:IsValid() end)
    return ok and v == true
end

local function nameOf(o)
    if o == nil then return 'nil' end
    local ok, s = pcall(function() return o:GetFullName() end)
    if ok and type(s) == 'string' then return s end
    return tostring(o)
end

local function readNumber(o, field)
    local ok, v = pcall(function() return o[field] end)
    if not ok then return nil end
    if type(v) == 'number' then return v end
    -- enums and some reflected structs come back as a wrapper
    if type(v) == 'userdata' then
        local n = try(function() return v:get() end)
        if type(n) == 'number' then return n end
        local s = try(function() return v:ToString() end)
        if type(s) == 'string' then return tonumber(s) end
    end
    return nil
end

local function readBool(o, field)
    local ok, v = pcall(function() return o[field] end)
    if ok and type(v) == 'boolean' then return v end
    return nil
end

local function closeTo(a, b)
    if type(a) ~= 'number' or type(b) ~= 'number' then return a == b end
    return math.abs(a - b) <= math.max(1.0, math.abs(b)) * 1e-5
end

local function writeNumber(o, field, target)
    local cur = readNumber(o, field)
    if cur ~= nil and closeTo(cur, target) then return false, 'unchanged' end
    local ok, err = pcall(function() o[field] = target end)
    if not ok then return false, 'write error: ' .. tostring(err) end
    local back = readNumber(o, field)
    if back == nil or not closeTo(back, target) then
        return false, string.format('readback %s (wanted %.6g)', tostring(back), target)
    end
    return true, cur
end

-- ============================================================================
-- configuration
-- ============================================================================
local okCfg, Config = pcall(dofile, DIR .. 'config.lua')
if not okCfg or type(Config) ~= 'table' then
    log('DISABLED: config.lua could not be read: %s', tostring(Config))
    return
end
if Config.enabled == false then
    log('disabled by config.lua'); return
end

local SPEC_BY_ID = {}
local SPEC_BY_KEY = {}
local SPECS = {}
for _, spec in ipairs(Config.weapons or {}) do
    SPECS[#SPECS + 1] = spec
    if spec.id then SPEC_BY_ID[spec.id] = spec end
    if spec.key then SPEC_BY_KEY[spec.key:lower()] = spec end
end

-- ============================================================================
-- CDO patching
-- ============================================================================
local originals = {}      -- [cdo full name] = { field = original number }
local patched = {}        -- [cdo full name] = true
local attempt = {}        -- [spec.key] = attempts so far
local cdoSpec = {}        -- [cdo full name] = spec

local FIELDS = {
    'LockonRange', 'LockonAngle', 'MaxHomingAngle', 'MaxRotationAngle', 'HomingForesightAmount',
    'LifeTime', 'SpeedMaximum', 'Acceleration', 'damage', 'ExplosionRadius',
}

-- One snapshot per weapon type, not per class: a mesh variant can inherit from another
-- variant, and if the parent was already rewritten the child would inherit the *patched*
-- values and multiply them a second time. The first class seen for a spec is the pristine one.
local function captureOriginals(cdo, spec)
    local key = spec.key or nameOf(cdo)
    if originals[key] then return originals[key] end
    local snapshot = {}
    for _, f in ipairs(FIELDS) do
        local v = readNumber(cdo, f)
        if v ~= nil then snapshot[f] = v end
    end
    originals[key] = snapshot
    return snapshot
end

local function specForCDO(cdo)
    local name = nameOf(cdo):lower()
    for _, spec in ipairs(SPECS) do
        if name:find('bp_plwp_' .. spec.key .. '_', 1, true) then return spec end
    end
    return nil
end

local function patchCDO(cdo, spec, reason)
    if not valid(cdo) or not spec then return false end
    local name = nameOf(cdo)
    local firstTime = not patched[name]

    local orig = captureOriginals(cdo, spec)
    if not orig.damage or not orig.LockonRange then
        return false                                   -- not the missile class we think it is
    end
    cdoSpec[name] = spec

    local changes, failures = {}, {}

    local function set(field, target, why)
        if type(target) ~= 'number' then return end
        if not orig[field] then return end
        local changed, info = writeNumber(cdo, field, target)
        if changed then
            changes[#changes + 1] = string.format('%s %.6g->%.6g%s', field, info or orig[field], target, why or '')
        elseif info ~= 'unchanged' then
            failures[#failures + 1] = field .. ': ' .. tostring(info)
        end
    end

    -- lock-on ring
    if spec.lockon then
        local target = math.max(orig.LockonRange or 0, spec.lockon)
        set('LockonRange', target)
    end
    if spec.lockangle then
        set('LockonAngle', math.max(orig.LockonAngle or 0, spec.lockangle))
    elseif spec.lockangle_factor and orig.LockonAngle then
        set('LockonAngle', orig.LockonAngle * spec.lockangle_factor)
    end

    -- guidance
    if spec.homing then
        if spec.homing.angle then set('MaxHomingAngle', math.max(orig.MaxHomingAngle or 0, spec.homing.angle)) end
        if spec.homing.rot then set('MaxRotationAngle', math.max(orig.MaxRotationAngle or 0, spec.homing.rot)) end
        if spec.homing.lead then set('HomingForesightAmount', math.max(orig.HomingForesightAmount or 0, spec.homing.lead)) end
    end
    if spec.homing_factor then
        local f = spec.homing_factor
        if f.angle and orig.MaxHomingAngle then set('MaxHomingAngle', orig.MaxHomingAngle * f.angle) end
        if f.rot and orig.MaxRotationAngle then set('MaxRotationAngle', orig.MaxRotationAngle * f.rot) end
        if f.lead then set('HomingForesightAmount', math.max(orig.HomingForesightAmount or 0, f.lead)) end
    end

    -- speed (scales acceleration too, so time-to-top-speed keeps its feel)
    if spec.speed and spec.speed ~= 1 then
        if orig.SpeedMaximum then set('SpeedMaximum', orig.SpeedMaximum * spec.speed) end
        if orig.Acceleration then set('Acceleration', orig.Acceleration * spec.speed) end
    end

    -- damage / blast
    if spec.damage and spec.damage ~= 1 and orig.damage then
        set('damage', orig.damage * spec.damage)
    end
    if spec.explosion and spec.explosion ~= 1 and (orig.ExplosionRadius or 0) > 0 then
        set('ExplosionRadius', orig.ExplosionRadius * spec.explosion)
    end

    -- life time must be able to reach the new lock-on range
    do
        local range = readNumber(cdo, 'LockonRange') or orig.LockonRange
        local speed = readNumber(cdo, 'SpeedMaximum') or orig.SpeedMaximum
        if range and speed and speed > 0 then
            local need = range / speed * (Config.lifetime_margin or 1.3) + (Config.lifetime_bonus or 2.0)
            local current = readNumber(cdo, 'LifeTime') or 0
            local target = math.max(orig.LifeTime or 0, need)
            if target > current + 0.05 then
                set('LifeTime', target, string.format(' (needed %.1f s for %.0f km)', need, range / 100000))
            end
        end
    end

    patched[name] = true
    if firstTime and Config.log_originals then
        log('%s | %s {%s} | lock %.1f km / %.1f deg | dmg %.0f | life %.1f s | homing %.0f deg %.0f deg/s lead %.2f | vmax %.0f m/s | blast %.0f m',
            spec.label, name:match('Default__([%w_]+)_C') or name, reason or '',
            (orig.LockonRange or 0) / 100000, orig.LockonAngle or 0, orig.damage or 0, orig.LifeTime or 0,
            orig.MaxHomingAngle or 0, orig.MaxRotationAngle or 0, orig.HomingForesightAmount or 0,
            (orig.SpeedMaximum or 0) / 100, (orig.ExplosionRadius or 0) / 100)
    end
    if #changes > 0 then
        log('%s | %s | %d change(s)%s', spec.label, name:match('Default__([%w_]+)_C') or name, #changes,
            #failures > 0 and (' | FAILED: ' .. table.concat(failures, '; ')) or '')
        log('    ' .. table.concat(changes, ' | '))
    elseif #failures > 0 then
        log('%s | %s | FAILED: %s', spec.label, name:match('Default__([%w_]+)_C') or name, table.concat(failures, '; '))
    end
    return true
end

local function findCDO(path)
    local short = path:match('([^/]+)$')
    local full = path .. '.' .. short .. '_C'
    local class = try(function() return StaticFindObject(full) end)
    if not valid(class) then
        try(function() return LoadAsset(full) end)
        class = try(function() return StaticFindObject(full) end)
    end
    if not valid(class) then
        try(function() return LoadAsset(path) end)
        class = try(function() return StaticFindObject(full) end)
    end
    if not valid(class) then return nil end
    local cdo = try(function() return class:GetCDO() end)
    if valid(cdo) then return cdo end
    return nil
end

-- Patch every already-loaded player weapon class. The aircraft decides which mesh variant it
-- uses (_a0 for the F-22A, _a1 for the F-35C, ...), so a fixed path list can never cover them
-- all; this catches whatever the hangar / mission has already loaded.
local function patchLoadedClasses(reason)
    local found, patchedCount = 0, 0
    for _, cls in ipairs(try(function() return FindAllOf('BlueprintGeneratedClass') end) or {}) do
        if valid(cls) then
            local low = nameOf(cls):lower()
            if low:find('bp_plwp_', 1, true) then
                found = found + 1
                local spec = nil
                for _, s in ipairs(SPECS) do
                    if low:find('bp_plwp_' .. s.key .. '_', 1, true) then spec = s; break end
                end
                if spec then
                    local cdo = try(function() return cls:GetCDO() end)
                    if valid(cdo) and patchCDO(cdo, spec, reason) then patchedCount = patchedCount + 1 end
                end
            end
        end
    end
    return found, patchedCount
end

-- A weapon has one class per mesh variant (_a0, _a1, _f0, _r0 ...), and the aircraft decides
-- which one it uses. Force the common variants in during level load so they are rewritten
-- before the game builds the aircraft's weapons; patchLoadedClasses() then picks up the rest.
local VARIANT_SUFFIX = { 'a1', 'f0', 'f1', 'r0', 'r1' }
local variantTried = {}

local function loadVariants()
    local n = 0
    for _, spec in ipairs(SPECS) do
        local base = spec.paths and spec.paths[1]
        if base then
            local stem = base:gsub('_[%a]%d$', '')
            for _, suffix in ipairs(VARIANT_SUFFIX) do
                local path = stem .. '_' .. suffix
                if not variantTried[path] then
                    variantTried[path] = true
                    if findCDO(path) then
                        n = n + 1
                        spec.extraPaths = spec.extraPaths or {}
                        local dup = false
                        for _, p in ipairs(spec.extraPaths) do if p == path then dup = true end end
                        if not dup then spec.extraPaths[#spec.extraPaths + 1] = path end
                    end
                end
            end
        end
    end
    return n
end

local function allPaths(spec)
    local out = {}
    for _, p in ipairs(spec.paths or {}) do out[#out + 1] = p end
    for _, p in ipairs(spec.extraPaths or {}) do out[#out + 1] = p end
    return out
end

-- Verify (and repair) every class path on every pass. Cheap: a property read costs nothing,
-- and a value that is already right is never written again. This also puts the values back
-- if the game reloads a weapon class for a new level.
local function patchAll(reason)
    local done, missing = 0, 0
    for _, spec in ipairs(SPECS) do
        for _, path in ipairs(allPaths(spec)) do
            local cdo = findCDO(path)
            if cdo and patchCDO(cdo, spec, reason) then
                done = done + 1
            else
                missing = missing + 1
            end
        end
    end
    return done, missing
end

-- ============================================================================
-- special weapon load counts
-- ============================================================================
local ammoOriginal = {}   -- [table|level|slot|field] = vanilla number
local ammoTables = {}

local function resolveAmmoTables()
    if #ammoTables > 0 then return true end
    for _, dt in ipairs(try(function() return FindAllOf('DataTable') end) or {}) do
        if valid(dt) then
            local n = nameOf(dt):lower()
            if n:find('/datatables/player/parameter/dt_playerparameter_', 1, true) then
                ammoTables[#ammoTables + 1] = dt
            end
        end
    end
    return #ammoTables > 0
end

local function rowsOf(dt)
    local rows = try(function() return dt:GetAllRows() end)
    if type(rows) ~= 'table' then return nil end
    return rows
end

-- A row element struct may be handed out as a copy; write, re-read, and fall back to writing
-- the whole SPWeaponInfo struct when the single field did not reach the table.
local function setLoad(el, slotName, field, target, otherField, otherValue)
    local info = try(function() return el[slotName] end)
    if info == nil then return false, 'missing' end
    local cur = readNumber(info, field)
    if cur == nil then return false, 'unreadable' end
    if cur >= target then return false, 'ok' end

    pcall(function() info[field] = target end)
    local fresh = try(function() return el[slotName] end)
    local back = fresh ~= nil and readNumber(fresh, field) or nil
    if back == target then return true end

    -- whole-struct fallback
    local keep = (otherField and readNumber(fresh or info, otherField)) or otherValue or 0
    local payload = { [field] = target }
    if otherField then payload[otherField] = keep end
    pcall(function() el[slotName] = payload end)
    fresh = try(function() return el[slotName] end)
    back = fresh ~= nil and readNumber(fresh, field) or nil
    if back == target then return true, 'struct' end
    return false, 'write did not stick'
end

local function applyAmmo(reason)
    if not resolveAmmoTables() then
        log('ammo: no player parameter tables found (%s)', tostring(reason))
        return
    end
    local tables, values, failed = 0, 0, 0
    for _, dt in ipairs(ammoTables) do
        if valid(dt) then
            local rows = rowsOf(dt)
            local row = rows and (rows[1] or rows[next(rows)])
            local data = type(row) == 'table' and row.Data or nil
            if data then
                tables = tables + 1
                local ids = {}
                for k = 1, 4 do ids[k] = readNumber(data, 'SpWeaponID' .. k) end
                local arr = try(function() return data.LevelParameter end)
                local levels = arr and tonumber(try(function() return arr:GetArrayNum() end)) or nil
                local levelMax = levels or 31
                for k = 1, 4 do
                    local spec = ids[k] and SPEC_BY_ID[ids[k]] or nil
                    if spec and spec.ammo and spec.ammo ~= 1 then
                        for l = 1, math.min(levelMax, 200) do
                            local el = try(function() return arr[l] end)
                            if el then
                                local slot = 'SPWeaponInfo' .. k
                                local key = nameOf(dt) .. '|' .. l .. '|' .. slot
                                local info = try(function() return el[slot] end)
                                if info then
                                    local c1 = readNumber(info, 'SpWeaponLoadCount1')
                                    local c2 = readNumber(info, 'SpWeaponLoadCount2')
                                    if c1 and c1 > 0 then
                                        ammoOriginal[key .. '|1'] = ammoOriginal[key .. '|1'] or c1
                                        local changed, why = setLoad(el, slot, 'SpWeaponLoadCount1',
                                            math.floor(ammoOriginal[key .. '|1'] * spec.ammo + 0.5), 'SpWeaponLoadCount2', c2)
                                        if changed then values = values + 1 elseif why ~= 'ok' then failed = failed + 1 end
                                    end
                                    if c2 and c2 > 0 then
                                        ammoOriginal[key .. '|2'] = ammoOriginal[key .. '|2'] or c2
                                        local changed, why = setLoad(el, slot, 'SpWeaponLoadCount2',
                                            math.floor(ammoOriginal[key .. '|2'] * spec.ammo + 0.5), 'SpWeaponLoadCount1', c1)
                                        if changed then values = values + 1 elseif why ~= 'ok' then failed = failed + 1 end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    log('ammo (%s): %d aircraft table(s), %d load value(s) written, %d failed', tostring(reason), tables, values, failed)
end

-- ============================================================================
-- the player's aircraft
--
-- FindAllOf('PlayerController') walks the whole object array, so it must not run every second:
-- it is the classic source of a regular hitch. Keep the controller from a construction event and
-- read Pawn from it instead (cheap), exactly like the other AC8 Lua mods do.
-- ============================================================================
local controllers = {}
local seenPlane = nil

local function rememberController(pc)
    if valid(pc) then controllers[pc:GetAddress()] = pc end
end

local function localPC()
    for addr, pc in pairs(controllers) do
        if not valid(pc) then
            controllers[addr] = nil
        elseif try(function() return pc:IsLocalController() end) ~= false then
            return pc
        end
    end
    return nil
end

local function mapName()
    local pc = localPC()
    if not valid(pc) then return nil end
    local world = try(function() return pc:GetWorld() end)
    if not valid(world) then return nil end
    -- GetMapName() is not exposed by every UE4SS build; the world's full name always carries the
    -- map package path ("World /Game/Maps/Ingame/Mission009/PL_Mission009.PL_Mission009").
    local n = try(function() return world:GetFullName() end)
    if type(n) == 'string' and #n > 0 then return n end
    n = try(function() return world:GetMapName() end)
    if type(n) == 'string' then return n end
    return nil
end

local function scanPlane()
    local pc = localPC()
    if not valid(pc) then return end
    local pl = try(function() return pc.Pawn end)
    if not valid(pl) or not nameOf(pl):find('BP_PlayerPlane_', 1, true) then return end
    local addr = try(function() return pl:GetAddress() end)
    if not addr or addr == seenPlane then return end
    seenPlane = addr
    log('player plane: %s', nameOf(pl))
    -- safety net: a weapon class that only appeared together with the plane is rewritten here
    -- (too late for its own first setup, but the next sortie with it gets the values)
    local act = try(function() return pl.PlayerWeaponActivator end)
    local eq = valid(act) and try(function() return act.EquippedWeapons end) or nil
    local cfgs = valid(eq) and try(function() return eq.Configs end) or nil
    if cfgs then
        local n = try(function() return cfgs:GetArrayNum() end) or 0
        for i = 1, n do
            local e = try(function() return cfgs[i] end)
            local cdo = e and try(function() return e.WeaponClassDefaultObject end) or nil
            if valid(cdo) then
                local spec = specForCDO(cdo)
                if spec then pcall(patchCDO, cdo, spec, 'equipped') end
            end
        end
    end
end

-- ============================================================================
-- lifecycle
--
-- Weapon values are rewritten only while a mission map is loaded, and only at a few fixed
-- moments after the level load. AC8 fires the map hooks many times per transition (menu scenes,
-- loadout, mission) and it re-creates the weapon classes in between; rewriting them on every
-- pass is both a stutter source and a crash risk in the weapon-select screen.
-- ============================================================================
local generation = 0
local tick = 0
local passAt = {}          -- tick numbers of the remaining passes for this level
local passCount = 0

log('Modern Missile Mod %s loading (dir %s)', VERSION, MOD_ROOT)

local function isMissionMap()
    local name = mapName()
    if not name then return true end                     -- unknown: better to patch than not
    local low = name:lower()
    if low:find('menu', 1, true) or low:find('hangar', 1, true)
        or low:find('title', 1, true) or low:find('lobby', 1, true) then
        return false, name
    end
    return true, name
end

local function heavyPass(reason)
    local mission, name = isMissionMap()
    if not mission then
        log('%s: skipped, not a mission map (%s)', tostring(reason), tostring(name))
        return
    end
    if passCount == 1 then pcall(applyAmmo, reason) end
    local variants = loadVariants()
    local loaded, hit = patchLoadedClasses(reason)
    local done = select(1, patchAll(reason))
    log('%s: %d variant(s) forced, %d class(es) seen, %d patched, %d path(s) verified | %s',
        tostring(reason), variants, loaded, hit, done or 0, tostring(name or '?'))
end

local function newLevel(why)
    generation = generation + 1
    seenPlane = nil
    ammoTables = {}
    variantTried = {}
    passAt = {}
    passCount = 0
    log('--- level event (%s) #%d | map %s', tostring(why), generation, tostring(mapName() or '?'))
end

if type(RegisterLoadMapPostHook) == 'function' then
    pcall(RegisterLoadMapPostHook, function()
        newLevel('LoadMapPost')
        -- fixed passes: right away, then while the mission is still streaming its assets
        passAt = { tick + 1, tick + 4, tick + 10, tick + 20 }
    end)
end

if type(RegisterLoadMapPreHook) == 'function' then
    pcall(RegisterLoadMapPreHook, function()
        -- The level is being torn down/loaded: never touch game objects here.
        seenPlane = nil
    end)
end

if type(NotifyOnNewObject) == 'function' then
    pcall(NotifyOnNewObject, '/Script/Engine.PlayerController', function(pc)
        if type(ExecuteInGameThread) == 'function' then
            pcall(ExecuteInGameThread, function() rememberController(pc) end)
        else
            rememberController(pc)
        end
    end)
end

if type(LoopInGameThreadAfterFrames) == 'function' then
    LoopInGameThreadAfterFrames(30, function()
        tick = tick + 1
        local ok, err = pcall(function()
            scanPlane()
            if #passAt > 0 and tick >= passAt[1] then
                table.remove(passAt, 1)
                passCount = passCount + 1
                heavyPass('pass ' .. passCount)
            end
        end)
        if not ok then log('loop error: %s', tostring(err)) end
        return false
    end)
else
    log('LoopInGameThreadAfterFrames missing: the mod cannot run')
end

if type(ExecuteInGameThread) == 'function' then
    pcall(ExecuteInGameThread, function()
        for _, pc in ipairs(try(function() return FindAllOf('PlayerController') end) or {}) do
            rememberController(pc)
        end
        pcall(applyAmmo, 'startup')
    end)
else
    pcall(applyAmmo, 'startup')
end

log('ready: v%s, %d weapon definition(s); log file %s', VERSION, #SPECS, LOG_PATH)
