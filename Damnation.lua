Damnation_Options = {
    Mode = "auto",
    Announce = "off"
}

local _, namespace = ...
local COLOR_RED = "|cFFFF0000"
local COLOR_GREEN = "|cFF1EFF00"
local COLOR_BLUE = "|cFF0070DD"
local COLOR_GOLD = "|cFFE6CC80"
local COLOR_RESET = "|r"
local ADDON_NAME = COLOR_GOLD.."Damnation"..COLOR_RESET

-- Database of spell IDs
local SpellIds = {
    ["Blessing of Salvation"] = 1038,
    ["Greater Blessing of Salvation"] = 25895,
    ["Righteous Fury"] = 25780
}

-- List of spells to manage
local ManagedSpellIds = {
    SpellIds["Blessing of Salvation"],
    SpellIds["Greater Blessing of Salvation"]
}

local addon = CreateFrame("Frame")
addon:RegisterEvent("ADDON_LOADED")
addon:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, ...)
end)

function addon:ADDON_LOADED(name)
    if name ~= "Damnation" then
        return
    end

    self:RegisterSlashCommands()
    self:SetMode(Damnation_Options.Mode)
    self:UnregisterEvent("ADDON_LOADED")
    print(ADDON_NAME.." v1.2.2 loaded.")
end

function addon:UNIT_AURA(unit)
    self:ManageBuffs()
end

function addon:PLAYER_REGEN_ENABLED()
    self:ManageBuffs()
end

function addon:RegisterSlashCommands()
    SLASH_DAMNATION1 = "/damnation"
    SLASH_DAMNATION2 = "/dmn"
    SlashCmdList["DAMNATION"] = function (msg) self:SlashCommand(msg) end
end

function addon:ParseOption(text)
    if text == "on" then
        return "["..COLOR_GREEN..text..COLOR_RESET.."]"
    elseif text == "off" then
        return "["..COLOR_RED..text..COLOR_RESET.."]"
    elseif text == "auto" then
        return "["..COLOR_BLUE..text..COLOR_RESET.."]"
    else
        return text
    end
end

function addon:SlashCommand(arg)
    if arg == "on" then
        self:SetMode(arg)
        print(ADDON_NAME.." mode is set to "..self:ParseOption(Damnation_Options.Mode).." and will always remove Blessing of Salvation.")
    elseif arg == "auto" then
        self:SetMode(arg)
        print(ADDON_NAME.." mode is set to "..self:ParseOption(Damnation_Options.Mode).." and will only remove Blessing of Salvation when tanking.")
    elseif arg == "off" then
        self:SetMode(arg)
        print(ADDON_NAME.." mode is set to "..self:ParseOption(Damnation_Options.Mode).." and will never remove Blessing of Salvation.")
    elseif arg == "announce" then
        self:ToggleAnnounce()
        print(ADDON_NAME.." announcements are set to "..self:ParseOption(Damnation_Options.Announce)..".")
    else
        print(ADDON_NAME.." mode is set to "..self:ParseOption(Damnation_Options.Mode).." and announcements are set to "..self:ParseOption(Damnation_Options.Announce)..".\nOptions:\n  on - Always remove Blessing of Salvation\n  auto - Remove Blessing of Salvation only when tanking\n  off - Never remove Blessing of Salvation\n  announce - Toggle announcements on or off\n")
    end
end

function addon:SetMode(mode)
    if mode ~= "on" and mode ~= "auto" and mode ~= "off" then
       mode = "auto"
    end

    Damnation_Options.Mode = mode
    self:UnregisterEvent("UNIT_AURA")
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    if mode == "on" or (mode == "auto" and self:CanTank()) then
        self:RegisterEvent("UNIT_AURA")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:ManageBuffs()
    end
end

function addon:ToggleAnnounce()
    if (Damnation_Options.Announce == "on") then
        Damnation_Options.Announce = "off"
    else
        Damnation_Options.Announce = "on"
    end
end

function addon:CanTank()
    local _, className = UnitClass("player")
    if className == "WARRIOR" then
        return true, className
    elseif className == "DRUID" then
        return true, className
    elseif className == "PALADIN" then
        return true, className
    end
    return false, className
end

function addon:IsTanking()
    local canTank, className = self:CanTank()
    if not canTank then
        return false
    end

    if className == "WARRIOR" then
        _, tanking = GetShapeshiftFormInfo(2) -- Defensive Stance
        return tanking
    elseif className == "DRUID" then
        _, tanking = GetShapeshiftFormInfo(1) -- Bear/Dire Bear Form
        return tanking
    elseif className == "PALADIN" then
        return self:HasBuff(SpellIds["Righteous Fury"])
    end
    return false
end

function addon:HasBuff(spellId)
    for i=1,40 do
        local name, _, _, _, _, _, _, _, _, id = UnitBuff("player", i)
        if id == spellId then
            return true, name, i
        end
    end
    return false, nil, nil
end

function addon:RemoveBuff(spellId)
    local hasBuff, name, index = self:HasBuff(spellId)
    if hasBuff then
        CancelUnitBuff("player", index)
        if Damnation_Options.Announce == "on" then
            print(ADDON_NAME.." has removed ["..name.."]")
        end
    end
end

function addon:ManageBuffs()
    if InCombatLockdown() then
        return
    end

    if Damnation_Options.Mode == "on" or (Damnation_Options.Mode == "auto" and self:IsTanking()) then
        table.foreach(ManagedSpellIds, function(k, v) self:RemoveBuff(v) end)
    end
end
