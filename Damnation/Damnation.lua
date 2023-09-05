local addonName, addon = ...
addon.Damnation = LibStub("AceAddon-3.0"):NewAddon("Damnation", "AceEvent-3.0")

local Damnation = addon.Damnation

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
    self.className = select(2, UnitClass("player"))
    self.canTank = self.className == "WARRIOR" or self.className == "DRUID" or self.className == "PALADIN"
    self:SetMode(self.db.profile.mode)
end

function Damnation:OnDisable()
end

function Damnation:SetMode(mode)
    self:UnregisterEvent("UNIT_AURA")
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    if mode == "on" or (mode == "auto" and self.canTank) then
        self:RegisterEvent("UNIT_AURA")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:ManageBuffs()
    end
end

function Damnation:IsTanking()
    if not self.canTank then
        return false
    end

    if self.className == "WARRIOR" then
        local _, tanking = GetShapeshiftFormInfo(2) -- Defensive Stance
        return tanking
    elseif self.className == "DRUID" then
        local _, tanking = GetShapeshiftFormInfo(1) -- Bear/Dire Bear Form
        return tanking
    elseif self.className == "PALADIN" then
        self:GetActiveBuffs()
        return self.activeBuffs[25780] ~= nil -- Righteous Fury
    end

    return false
end

function Damnation:GetActiveBuffs()
    if self.activeBuffs == nil then
        self.activeBuffs = {}
        for i=1,256 do
            local name, _, _, _, _, _, _, _, _, spellID = UnitBuff("player", i)
            if name == nil or spellID == nil then
                break
            end
            self.activeBuffs[spellID] = {name = name, index = i}
        end
    end
end

function Damnation:RemoveBuff(spellID)
    if InCombatLockdown() then
        self.activeBuffs = nil
        return false
    end

    self:GetActiveBuffs()
    local activeBuff = self.activeBuffs[spellID]
    if activeBuff ~= nil then
        CancelUnitBuff("player", activeBuff.index)
        if self.db.profile.announce then
            print(COLOR_GOLD..self:GetName()..COLOR_RESET.." has removed "..activeBuff.name..".")
        end
    end
    return true
end

function Damnation:ManageBuffs()
    if InCombatLockdown() then
        self.activeBuffs = nil
        return
    end

    if self.db.profile.mode == "on" or (self.db.profile.mode == "auto" and self:IsTanking()) then
        -- Remove Salvation
        for k,v in ipairs(self.SalvationSpellIDs) do
            if self:RemoveBuff(v) == false then
                break
            end
        end

        -- Remove Intellect
        if self.db.profile.intellect then
            for k,v in ipairs(self.IntellectSpellIDs) do
                if self:RemoveBuff(v) == false then
                    break
                end
            end
        end

        -- Remove Spirit
        if self.db.profile.spirit then
            for k,v in ipairs(self.SpiritSpellIDs) do
                if self:RemoveBuff(v) == false then
                    break
                end
            end
        end

        -- Remove Wisdom
        if self.db.profile.wisdom then
            for k,v in ipairs(self.WisdomSpellIDs) do
                if self:RemoveBuff(v) == false then
                    break
                end
            end
        end
    end

    self.activeBuffs = nil
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
