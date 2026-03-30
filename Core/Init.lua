HunterLib = HunterLib or {}
HunterLib.Modules = HunterLib.Modules or {}
HunterLib.UI = HunterLib.UI or {}
HunterLib.Util = HunterLib.Util or {}

HunterLib.Const = {
    MAX_AURAS = 16,
    RELOAD_OFFSET = 0.50,
    RELOAD_GUARD = 0.05,
}

HunterLib.Auto = {
    isShooting = false,
    isReloading = false,
    isCasting = false,
    currentCast = nil,
    castStart = 0,
    castTimeout = 0,
    reloadStart = 0,
    reloadDuration = 0,
}

HunterLib.SpeedWatch = {
    lastRangedSpeed = nil,
}

HunterLib.State = {
    configOpen = nil,
    activeTab = "steady",
}
