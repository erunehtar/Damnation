-- MIT License

-- Copyright (c) 2026 Erunehtar

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local addonName, addon = ... --- @cast addon Damnation
local KnownGroups = addon.KnownGroups
LibStub("AceAddon-3.0"):NewAddon(addon, addonName, "AceConsole-3.0", "AceEvent-3.0")

--- @class Damnation : AceAddon, AceConsole-3.0, AceEvent-3.0
--- @field version string
--- @field db Damnation.DB
--- @field className string
--- @field canTank boolean
--- @field spells table<Damnation.SpellID, Damnation.GroupName>
--- @field enabled table<Damnation.GroupName, boolean>
--- @field OnInitialize fun(self: Damnation)
--- @field OnEnable fun(self: Damnation)
--- @field GetOptionsTable fun(self: Damnation): AceConfig.OptionsTable
--- @field SetMode fun(self: Damnation, mode: OperatingMode)
--- @field IsActive fun(self: Damnation): boolean
--- @field IsTanking fun(self: Damnation): boolean
--- @field TryRemoveBuff fun(self: Damnation, spellId: Damnation.SpellID): boolean
--- @field ManageBuffs fun(self: Damnation, updateInfo: UnitAuraUpdateInfo?)
--- @field Serialize fun(self: Damnation)
--- @field Deserialize fun(self: Damnation)

--- @class Damnation.DB : AceDBObject-3.0
--- @field profile Damnation.DefaultProfile

-- Lua functions
local pcall = pcall
local format = format
local tostringall = tostringall
local strupper = strupper
local select = select
local pairs = pairs
local ipairs = ipairs

-- WoW API functions
local GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local UnitClass = UnitClass
local GetShapeshiftFormInfo = GetShapeshiftFormInfo
local InCombatLockdown = InCombatLockdown
local GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID
local CancelSpellByID = C_Spell.CancelSpellByID

--- @enum Color
local Color = { --- @class Color.*
    White = "ffffffff",
    Red = "ffff0000",
}

--- @enum OperatingMode
local OperatingMode = { --- @class OperatingMode.*
    On = "on",
    Auto = "auto",
    Off = "off",
}

--- @class Damnation.DefaultProfile
--- @field showWelcome boolean
--- @field mode OperatingMode
--- @field announceRemoved boolean
--- @field announceCannotRemove boolean
--- @field groups table<Damnation.GroupName, Damnation.SpellID[]>
--- @field enabled table<Damnation.GroupName, boolean>

-- Declare defaults to be used in the DB
local defaults = { --- @type AceDB.Schema
    profile = {    --- @type Damnation.DefaultProfile
        showWelcome = true,
        mode = OperatingMode.Auto,
        --announce = false, -- deprecated
        announceRemoved = false,
        announceCannotRemove = true,
        --intellect = false, -- deprecated
        --spirit = false, -- deprecated
        --wisdom = false, -- deprecated
        groups = {},
        enabled = {
            [KnownGroups.Salvation] = true,
            [KnownGroups.Wisdom] = false,
            [KnownGroups.Intellect] = false,
            [KnownGroups.Spirit] = false,
        },
    }
}

--- Format text with color codes.
--- @param color Color The color code to use.
--- @param fmt string The format string.
--- @param ... any Arguments to format into the string.
--- @return string result The colored formatted string.
local function C(color, fmt, ...)
    local success, text = pcall(format, fmt, tostringall(...))
    if not success then
        text = fmt
    end
    return "|c" .. color .. text .. "|r"
end

--- Called directly after the addon code is fully loaded.
function addon:OnInitialize()
    self.version = GetAddOnMetadata(addonName, "version")
    ---@diagnostic disable-next-line: assign-type-mismatch
    self.db = LibStub("AceDB-3.0"):New(addonName .. "DB", defaults, true)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, self:GetOptionsTable(), { "dmn", "damnation" })

    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    AceConfigDialog:AddToBlizOptions(addonName, addonName, nil, "general")
    AceConfigDialog:AddToBlizOptions(addonName, "Profiles", addonName, "profiles")
end

--- Called during the PLAYER_LOGIN event, when most of the data provided by the game is already present.
function addon:OnEnable()
    self.className = strupper(select(2, UnitClass("player")))
    self.canTank = self.className == "WARRIOR" or self.className == "DRUID" or self.className == "PALADIN"

    self:Deserialize()
    self:SetMode(self.db.profile.mode)

    self:RegisterEvent("PLAYER_ENTERING_WORLD", function() self:ManageBuffs() end)
    self:RegisterEvent("PLAYER_LEAVING_WORLD", function() self:Serialize() end)
    self:RegisterEvent("UNIT_AURA", function(event, unitTarget, updateInfo) self:ManageBuffs(updateInfo) end)
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function() self:ManageBuffs() end)
    self:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN", function() self:ManageBuffs() end)

    if self.db.profile.showWelcome then
        self:Printf("v%s loaded.", self.version)
    end
end

--- Set the operating mode of the addon.
--- @param mode OperatingMode The operating mode to set.
function addon:SetMode(mode)
    self.db.profile.mode = mode
    self:ManageBuffs()
end

--- Determine if the buffs management is currently active based on the operating mode.
--- @return boolean isActive True if the buffs management is active, false otherwise.
function addon:IsActive()
    return self.db.profile.mode == OperatingMode.On or (self.db.profile.mode == OperatingMode.Auto and self:IsTanking())
end

--- Determine if the player is currently in tanking role.
--- @return boolean isTanking True if the player is tanking, false otherwise.
function addon:IsTanking()
    if not self.canTank then
        return false
    end

    if self.className == "WARRIOR" then
        -- Defensive Stance
        return (select(2, GetShapeshiftFormInfo(2)))
    elseif self.className == "DRUID" then
        -- Bear/Dire Bear Form
        return (select(2, GetShapeshiftFormInfo(1)))
    elseif self.className == "PALADIN" then
        -- Righteous Fury
        return GetPlayerAuraBySpellID(addon.righteousFury) ~= nil
    end

    return false
end

--- Try to remove a buff by its spell ID.
--- @param spellId integer The spell ID of the buff to remove.
--- @return boolean success True if the buff was removed, false otherwise.
function addon:TryRemoveBuff(spellId)
    local auraData = GetPlayerAuraBySpellID(spellId)
    if not auraData then
        return false
    end

    if InCombatLockdown() then
        if self.db.profile.announceCannotRemove then
            self:Printf(C(Color.Red, "%s cannot be removed in combat!", strupper(auraData.name)))
        end
        return false
    end

    CancelSpellByID(spellId)

    if self.db.profile.announceRemoved then
        self:Printf(C(Color.White, "%s removed.", strupper(auraData.name)))
    end

    return true
end

--- Manage buffs based on the current mode and update information.
--- @param updateInfo UnitAuraUpdateInfo? Information about aura updates, if available.
function addon:ManageBuffs(updateInfo)
    if not self:IsActive() then
        return
    end

    if updateInfo then
        -- Remove added buffs in enabled groups
        for _, addedAura in ipairs(updateInfo.addedAuras or {}) do
            local groupName = self.spells[addedAura.spellId]
            if groupName and self.enabled[groupName] then
                self:TryRemoveBuff(addedAura.spellId)
            end
        end
    else
        -- Remove first found buff in all enabled groups
        for groupName, spellIds in pairs(self.groups) do
            if self.enabled[groupName] then
                for _, spellId in ipairs(spellIds) do
                    if self:TryRemoveBuff(spellId) then
                        break -- if we removed one rank, no need to check other ranks
                    end
                end
            end
        end
    end
end

--- Serialize custom groups and enabled settings to the database.
function addon:Serialize()
    -- Serialize custom groups to the database
    self.db.profile.groups = {}
    for groupName, spellIds in pairs(self.groups or {}) do
        if not self.isKnownGroup[groupName] then
            local group = {}
            for _, spellId in ipairs(spellIds) do
                tinsert(group, spellId)
            end
            if #group > 0 then
                self.db.profile.groups[groupName] = group
            end
        end
    end

    -- Serialize enabled settings
    self.db.profile.enabled = {}
    for groupName, enabled in pairs(self.enabled or {}) do
        self.db.profile.enabled[groupName] = enabled
    end
end

--- Deserialize custom groups and enabled settings from the database.
function addon:Deserialize()
    -- Load custom groups from the database
    self.groups = self.groups or {}
    for groupName, spellIds in pairs(self.db.profile.groups or {}) do
        if type(groupName) == "string" and groupName ~= "" and type(spellIds) == "table" then
            local group = {}
            for _, spellId in ipairs(spellIds) do
                if type(spellId) == "number" and spellId % 1 == 0 and spellId > 0 then
                    tinsert(group, spellId)
                end
            end
            if #group > 0 then
                self.groups[groupName] = group
            end
        end
    end

    -- Build reverse lookup table for spells to groups
    self.spells = self.spells or {}
    for groupName, spellIds in pairs(self.groups) do
        for _, spellId in ipairs(spellIds) do
            self.spells[spellId] = groupName
        end
    end

    -- Load enabled settings
    self.enabled = self.enabled or {}
    for groupName, enabled in pairs(self.db.profile.enabled or {}) do
        if type(groupName) == "string" and groupName ~= "" and type(enabled) == "boolean" then
            self.enabled[groupName] = enabled
        end
    end

    -- Migrate deprecated settings
    if type(self.db.profile.announce) == "boolean" then
        self.db.profile.announceRemoved = self.db.profile.announce
        ---@diagnostic disable-next-line: inject-field
        self.db.profile.announce = nil
    end
    if type(self.db.profile.wisdom) == "boolean" then
        self.enabled[KnownGroups.Wisdom] = self.db.profile.wisdom
        ---@diagnostic disable-next-line: inject-field
        self.db.profile.wisdom = nil
    end
    if type(self.db.profile.intellect) == "boolean" then
        self.enabled[KnownGroups.Intellect] = self.db.profile.intellect
        ---@diagnostic disable-next-line: inject-field
        self.db.profile.intellect = nil
    end
    if type(self.db.profile.spirit) == "boolean" then
        self.enabled[KnownGroups.Spirit] = self.db.profile.spirit
        ---@diagnostic disable-next-line: inject-field
        self.db.profile.spirit = nil
    end
end

--- Get the options table for AceConfig.
--- @return AceConfig.OptionsTable options The options table.
function addon:GetOptionsTable()
    return {
        type = "group",
        name = addonName .. " v" .. self.version,
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
                        get = function(info)
                            return self.db.profile.showWelcome
                        end,
                        set = function(info, value)
                            self.db.profile.showWelcome = value
                        end
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
                            [OperatingMode.On] = "Always",
                            [OperatingMode.Auto] = "When Tanking",
                            [OperatingMode.Off] = "Never"
                        },
                        sorting = { OperatingMode.On, OperatingMode.Auto, OperatingMode.Off },
                        get = function(info)
                            return self.db.profile.mode
                        end,
                        set = function(info, value)
                            self:SetMode(value)
                        end
                    },
                    spacing3 = {
                        type = "description",
                        name = "",
                        order = 3
                    },
                    announceRemoved = {
                        type = "toggle",
                        name = "Announce Removed",
                        desc = "Toggle announcing when a buff is removed.",
                        order = 4,
                        get = function(info)
                            return self.db.profile.announceRemoved
                        end,
                        set = function(info, value)
                            self.db.profile.announceRemoved = value
                        end
                    },
                    announceCannotRemove = {
                        type = "toggle",
                        name = "Announce Gained",
                        desc = "Toggle announcing when a buff is gained in combat (cannot be removed by addon).",
                        order = 5,
                        get = function(info)
                            return self.db.profile.announceCannotRemove
                        end,
                        set = function(info, value)
                            self.db.profile.announceCannotRemove = value
                        end
                    },
                    spacing4 = {
                        type = "description",
                        name = "",
                        order = 6
                    },
                    additionalBuffsHeader = {
                        type = "header",
                        name = "Buff Groups To Remove",
                        order = 7
                    },
                    description = {
                        type = "description",
                        name = "When removing buffs, the addon checks every group and stops searching that group after removing the first buff it finds. For this reason, it is recommended to order spell IDs from highest to lowest priority.\n\nYou can add/remove, or enable/disable groups as needed.",
                        order = 8,
                    },
                    buffGroupsDynamic = {
                        type = "description",
                        name = "Buff Groups",
                        order = 9,
                        width = "full",
                        dialogControl = "Damnation_BuffGroupsWidget",
                    },
                }
            },
            profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
        }
    }
end
