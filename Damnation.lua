local Damnation = LibStub("AceAddon-3.0"):NewAddon("Damnation", "AceEvent-3.0")

local COLOR_RED = "|cFFFF0000"
local COLOR_GREEN = "|cFF1EFF00"
local COLOR_BLUE = "|cFF0070DD"
local COLOR_GOLD = "|cFFE6CC80"
local COLOR_RESET = "|r"

-- declare defaults to be used in the DB
local defaults = {
    profile = {
        showWelcome = true,
        mode = "auto",
        announce = false,
        intellect = false,
        spirit = false,
        wisdom = false
    }
}

local SalvationSpellIds = {
    1038, -- Blessing of Salvation
    25895 -- Greater Blessing of Salvation
}

local IntellectSpellIds = {
    1459, -- Arcane Intellect (Rank 1)
    1460, -- Arcane Intellect (Rank 2)
    1461, -- Arcane Intellect (Rank 3)
    10156, -- Arcane Intellect (Rank 4)
    10157, -- Arcane Intellect (Rank 5)
    23028 -- Arcane Brilliance
}

local SpiritSpellIds = {
    14752, -- Divine Spirit (Rank 1)
    14818, -- Divine Spirit (Rank 2)
    14819, -- Divine Spirit (Rank 3)
    27841, -- Divine Spirit (Rank 4)
    27681 -- Prayer of Spirit
}

local WisdomSpellIds = {
    19742, -- Blessing of Wisdom (Rank 1)
    19850, -- Blessing of Wisdom (Rank 2)
    19852, -- Blessing of Wisdom (Rank 3)
    19853, -- Blessing of Wisdom (Rank 4)
    19854, -- Blessing of Wisdom (Rank 5)
    25290, -- Blessing of Wisdom (Rank 6)
    25894, -- Greater Blessing of Wisdom (Rank 1)
    25918 -- Greater Blessing of Wisdom (Rank 2)
}

function Damnation:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New(self:GetName().."DB", defaults, true)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(self:GetName(), self:GetOptionsTable(), {"dmn", "damnation"})

    local ACD = LibStub("AceConfigDialog-3.0")
    ACD:AddToBlizOptions(self:GetName(), self:GetName(), nil, "general")
    ACD:AddToBlizOptions(self:GetName(), "Profiles", self:GetName(), "profiles")

    if self.db.profile.showWelcome then
        print(COLOR_GOLD..self:GetName()..COLOR_RESET.." v"..GetAddOnMetadata(self:GetName(), "version").." loaded")
    end
end

function Damnation:OnEnable()
    self:SetMode(self.db.profile.mode)
end

function Damnation:OnDisable()
end

function Damnation:SetMode(mode)
    self:UnregisterEvent("UNIT_AURA")
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    if mode == "on" or (mode == "auto" and self:CanTank()) then
        self:RegisterEvent("UNIT_AURA")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:ManageBuffs()
    end
end

function Damnation:CanTank()
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

function Damnation:IsTanking()
    local canTank, className = self:CanTank()
    if not canTank then
        return false
    end

    if className == "WARRIOR" then
        local _, tanking = GetShapeshiftFormInfo(2) -- Defensive Stance
        return tanking
    elseif className == "DRUID" then
        local _, tanking = GetShapeshiftFormInfo(1) -- Bear/Dire Bear Form
        return tanking
    elseif className == "PALADIN" then
        return self:HasBuff(25780) -- Righteous Fury
    end
    return false
end

function Damnation:HasBuff(spellId)
    for i=1,40 do
        local name, _, _, _, _, _, _, _, _, id = UnitBuff("player", i)
        if id == spellId then
            return true, name, i
        end
    end
    return false, nil, nil
end

function Damnation:RemoveBuff(spellId)
    local hasBuff, name, index = self:HasBuff(spellId)
    if hasBuff then
        CancelUnitBuff("player", index)
        if self.db.profile.announce then
            print(COLOR_GOLD..self:GetName()..COLOR_RESET.." has removed "..name..".")
        end
    end
end

function Damnation:ManageBuffs()
    if InCombatLockdown() then
        return
    end

    if self.db.profile.mode == "on" or (self.db.profile.mode == "auto" and self:IsTanking()) then
        for k,v in ipairs(SalvationSpellIds) do self:RemoveBuff(v) end
        if self.db.profile.intellect then
            for k,v in ipairs(IntellectSpellIds) do self:RemoveBuff(v) end
        end
        if self.db.profile.spirit then
            for k,v in ipairs(SpiritSpellIds) do self:RemoveBuff(v) end
        end
        if self.db.profile.wisdom then
            for k,v in ipairs(WisdomSpellIds) do self:RemoveBuff(v) end
        end
    end
end

function Damnation:UNIT_AURA(unit)
    self:ManageBuffs()
end

function Damnation:PLAYER_REGEN_ENABLED()
    self:ManageBuffs()
end

function Damnation:GetOptionsTable()
    return {
        type = "group",
        name = self:GetName().." v"..GetAddOnMetadata(self:GetName(), "version"),
        args = {
            general = {
                name = "General",
                order = 1,
                type = "group",
                args = {
                    showWelcome = {
                        type = "toggle",
                        name = "Show Welcome Message\n",
                        desc = "Toggle showing welcome message upon logging.",
                        order = 0,
                        width = 1.1,
                        get = function(info) return self.db.profile.showWelcome end,
                        set = function(info, value) self.db.profile.showWelcome = value end
                    },
                    spacing2 = {
                        type = "description",
                        name = "",
                        order = 1,
                    },
                    mode = {
                        type = "select",
                        name = "Operating Mode\n",
                        desc = "Select which operating mode the addon will use.",
                        order = 2,
                        width = 1.1,
                        style = "dropdown",
                        values = {
                            ["on"] = "Always",
                            ["auto"] = "When Tanking",
                            ["off"] = "Never"
                        },
                        sorting = {"on", "auto", "off"},
                        get = function(info) return self.db.profile.mode end,
                        set = function(info, value)
                            self.db.profile.mode = value
                            self:SetMode(value)
                        end
                    },
                    spacing3 = {
                        type = "description",
                        name = "",
                        order = 3
                    },
                    announce = {
                        type = "toggle",
                        name = "Announcements",
                        desc = "Toggle announcing when a buff is removed.",
                        order = 4,
                        get = function(info) return self.db.profile.announce end,
                        set = function(info, value) self.db.profile.announce = value end
                    },
                    spacing4 = {
                        type = "description",
                        name = "",
                        order = 5
                    },
                    additionalBuffsHeader = {
                        type = "header",
                        name = "Additional Buffs to Remove",
                        order = 6
                    },
                    intellect = {
                        type = "toggle",
                        name = "Arcane Intellect",
                        desc = "All ranks of Arcane Intellect and Arcane Brilliance.",
                        order = 7,
                        get = function(info) return self.db.profile.intellect end,
                        set = function(info, value)
                            self.db.profile.intellect = value
                            self:ManageBuffs()
                        end
                    },
                    spirit = {
                        type = "toggle",
                        name = "Divine Spirit",
                        desc = "All ranks of Divine Spirit and Prayer of Spirit.",
                        order = 8,
                        get = function(info) return self.db.profile.spirit end,
                        set = function(info, value)
                            self.db.profile.spirit = value
                            self:ManageBuffs()
                        end
                    },
                    wisdom = {
                        type = "toggle",
                        name = "Blessing of Wisdom",
                        desc = "All ranks of Blessing of Wisdom and Greater Blessing of Wisdom.",
                        order = 9,
                        get = function(info) return self.db.profile.wisdom end,
                        set = function(info, value)
                            self.db.profile.wisdom = value
                            self:ManageBuffs()
                        end
                    }
                }
            },
            profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
        }
    }
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         d = dump(v)
         if d == nil then
            d = "nil"
         end
         s = s .. '['..k..'] = ' .. d .. ','
      end
      print(s .. '} ')
   else
      print(tostring(o))
   end
end
