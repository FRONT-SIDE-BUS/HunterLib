function HunterLib.Debug(msg)
    local db = HunterLib.GetDB()
    if db.debug and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffHL:|r " .. tostring(msg))
    end
end
