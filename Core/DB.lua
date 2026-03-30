local defaults = {
    debug = false,
    minimap = {
        hide = nil,
        angle = 45,
    },
    config = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0,
        width = 840,
        height = 560,
        activeTab = "steady",
    },
    steady = {
        castTime = 1.40,
        safetyMargin = 0.40,
    },
    ui = {
        buffFilter = "all",
        exportText = "",
    },
    savedBuffs = {},
    capturedBuffs = {},
}

local function copyDefaults(dst, src)
    local k, v
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then
                dst[k] = {}
            end
            copyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

local function migrateLegacyKeys(db)
    if db.steadyCastTime ~= nil and (not db.steady or db.steady.castTime == nil) then
        db.steady = db.steady or {}
        db.steady.castTime = tonumber(db.steadyCastTime) or defaults.steady.castTime
    end

    if db.steadySafetyMargin ~= nil and (not db.steady or db.steady.safetyMargin == nil) then
        db.steady = db.steady or {}
        db.steady.safetyMargin = tonumber(db.steadySafetyMargin) or defaults.steady.safetyMargin
    end

    if db.minimapAngle ~= nil and (not db.minimap or db.minimap.angle == nil) then
        db.minimap = db.minimap or {}
        db.minimap.angle = tonumber(db.minimapAngle) or defaults.minimap.angle
    end

    if db.minimapHidden ~= nil and (not db.minimap or db.minimap.hide == nil) then
        db.minimap = db.minimap or {}
        db.minimap.hide = db.minimapHidden and 1 or nil
    end
end

function HunterLib.GetDB()
    if not HunterLibDB then
        HunterLibDB = {}
    end

    migrateLegacyKeys(HunterLibDB)
    copyDefaults(HunterLibDB, defaults)
    return HunterLibDB
end

function HunterLib.GetConfigValue(path1, path2)
    local db = HunterLib.GetDB()
    if path2 then
        return db[path1] and db[path1][path2]
    end
    return db[path1]
end

function HunterLib.SetConfigValue(path1, path2, value)
    local db = HunterLib.GetDB()
    if path2 then
        db[path1] = db[path1] or {}
        db[path1][path2] = value
    else
        db[path1] = value
    end
end

function HunterLib.ResetCapturedBuffs()
    HunterLib.GetDB().capturedBuffs = {}
end

function HunterLib.ResetSavedBuffs()
    HunterLib.GetDB().savedBuffs = {}
end
