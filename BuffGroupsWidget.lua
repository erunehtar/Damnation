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

local addonName, addon = ...
local KnownGroups = addon.KnownGroups
local AceGUI = LibStub("AceGUI-3.0")

local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local tinsert = table.insert
local tconcat = table.concat
local strlower = string.lower
local gmatch = string.gmatch

--[[
AceGUI Widget: Damnation_BuffGroupsWidget
This widget will be used as the dynamic buff group editor in the options panel.
]]

local Type = "Damnation_BuffGroupsWidget"
local Version = 5

local function OnAcquire(self)
    --self:SetWidth(600)
    self:SetHeight(250)
    self:SetLayout("Fill")
    if addon and addon.InjectBuffGroupsAceGUI then
        addon:InjectBuffGroupsAceGUI(self)
    end
end

local function OnRelease(self)
    self:ReleaseChildren()
end

-- Required by AceConfigDialog for custom controls
local function SetText(self, text)
    -- No-op, required for AceConfigDialog compatibility
end

local function SetLabel(self, text)
    -- No-op, required for AceConfigDialog compatibility
end

local function SetDisabled(self, disabled)
    -- No-op, required for AceConfigDialog compatibility
end

local function SetFontObject(self, font)
    -- No-op, required for AceConfigDialog compatibility
end

local Widget = {
    type = Type,
    OnAcquire = OnAcquire,
    OnRelease = OnRelease,
    SetText = SetText,
    SetLabel = SetLabel,
    SetDisabled = SetDisabled,
    SetFontObject = SetFontObject,
}

AceGUI:RegisterWidgetType(Type, function()
    local frame = AceGUI:Create("InlineGroup")
    for k, v in pairs(Widget) do
        frame[k] = v
    end
    return frame
end, Version)

-- Helper: Is known group
local function IsKnownGroup(groupName)
    return addon.isKnownGroup and addon.isKnownGroup[groupName]
end

-- Helper: Convert spell ID list to string
local function SpellIdsToString(spellIds)
    local t = {}
    for _, id in ipairs(spellIds) do
        tinsert(t, tostring(id))
    end
    return tconcat(t, ", ")
end

-- Helper: Validate group name
local function ValidateGroupName(name, currentName)
    if not name or name == "" then
        return false, "Group name required"
    end
    for k, _ in pairs(addon.groups or {}) do
        if k ~= currentName and k == name then
            return false, "Duplicate group name"
        end
    end
    return true
end

-- Helper: Validate spell IDs
local function ValidateSpellIds(str)
    if not str or str == "" then return false, "Spell IDs required" end
    local t = {}
    for s in gmatch(str, "[^,%s]+") do
        local n = tonumber(s)
        if not n or n < 1 or n % 1 ~= 0 then
            return false, "Spell IDs must be integers > 0"
        end
        tinsert(t, n)
    end
    if #t == 0 then return false, "No valid spell IDs" end
    return true, t
end

-- Main: Inject dynamic group rows
function addon:InjectBuffGroupsAceGUI(container)
    container:ReleaseChildren()
    local scrollFrame = AceGUI:Create("ScrollFrame") --[[@as AceGUIScrollFrame]]
    scrollFrame:SetLayout("List")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    container:AddChild(scrollFrame)

    -- Header row
    local header = AceGUI:Create("SimpleGroup") --[[@as AceGUISimpleGroup]]
    header:SetLayout("Flow")
    header:SetFullWidth(true)

    local headerWidth = 600
    local groupNameWidth = 150
    local enabledWidth = 70
    local deleteWidth = 70
    local spellIdsWidth = headerWidth - groupNameWidth - enabledWidth - deleteWidth

    local spacer1 = AceGUI:Create("Label") --[[@as AceGUILabel]]
    spacer1:SetWidth(4)
    header:AddChild(spacer1)

    local nameHeader = AceGUI:Create("Label") --[[@as AceGUILabel]]
    nameHeader:SetText("Group Name")
    nameHeader:SetWidth(groupNameWidth)
    header:AddChild(nameHeader)

    local spellHeader = AceGUI:Create("Label") --[[@as AceGUILabel]]
    spellHeader:SetText("Spell IDs")
    spellHeader:SetWidth(spellIdsWidth)
    header:AddChild(spellHeader)

    local enabledHeader = AceGUI:Create("Label") --[[@as AceGUILabel]]
    enabledHeader:SetText("Enabled")
    enabledHeader:SetWidth(enabledWidth)
    header:AddChild(enabledHeader)

    local deleteHeader = AceGUI:Create("Label") --[[@as AceGUILabel]]
    deleteHeader:SetText("Delete")
    deleteHeader:SetWidth(deleteWidth)

    header:AddChild(deleteHeader)
    scrollFrame:AddChild(header)

    local sortedGroups = {}
    tinsert(sortedGroups, KnownGroups.Salvation)
    tinsert(sortedGroups, KnownGroups.Wisdom)
    tinsert(sortedGroups, KnownGroups.Intellect)
    tinsert(sortedGroups, KnownGroups.Spirit)

    local customGroups = {}
    for groupName, _ in pairs(self.groups or {}) do
        if not IsKnownGroup(groupName) then
            tinsert(customGroups, groupName)
        end
    end
    table.sort(customGroups, function(a, b)
        return strlower(a) < strlower(b)
    end)

    for _, groupName in ipairs(customGroups) do
        tinsert(sortedGroups, groupName)
    end

    for _, groupName in ipairs(sortedGroups) do
        local spellIds = self.groups[groupName]
        local row = AceGUI:Create("SimpleGroup") --[[@as AceGUISimpleGroup]]
        row:SetLayout("Flow")
        row:SetFullWidth(true)
        row:SetAutoAdjustHeight(true)

        -- Group Name EditBox
        local nameBox = AceGUI:Create("EditBox") --[[@as AceGUIEditBox]]
        nameBox:SetLabel("")
        nameBox:SetText(groupName)
        nameBox:SetWidth(groupNameWidth)
        nameBox:SetDisabled(IsKnownGroup(groupName))
        nameBox:SetCallback("OnEnterPressed", function(widget, event, text)
            if not text or text == "" then
                widget:SetText(groupName)
                return
            end
            local ok, err = ValidateGroupName(text, groupName)
            if ok then
                if text ~= groupName then
                    addon.groups[text] = addon.groups[groupName]
                    addon.groups[groupName] = nil
                    addon.enabled[text] = addon.enabled[groupName]
                    addon.enabled[groupName] = nil
                    addon:Serialize()
                    addon:Deserialize()
                    self:InjectBuffGroupsAceGUI(container)
                end
            else
                widget:SetText(groupName)
            end
        end)
        row:AddChild(nameBox)

        -- Spell IDs EditBox
        local spellBox = AceGUI:Create("EditBox") --[[@as AceGUIEditBox]]
        spellBox:SetLabel("")
        spellBox:SetText(SpellIdsToString(spellIds))
        spellBox:SetWidth(spellIdsWidth)
        spellBox:SetDisabled(IsKnownGroup(groupName))
        spellBox:SetCallback("OnEnterPressed", function(widget, event, text)
            if not text or text == "" then
                widget:SetText(SpellIdsToString(spellIds))
                return
            end
            local ok, result = ValidateSpellIds(text)
            if ok then
                addon.groups[groupName] = result
                addon:Serialize()
                addon:Deserialize()
                self:InjectBuffGroupsAceGUI(container)
            else
                widget:SetText(SpellIdsToString(spellIds))
            end
        end)
        row:AddChild(spellBox)

        local spacerWidth = 13
        local spacer = AceGUI:Create("Label") --[[@as AceGUILabel]]
        spacer:SetWidth(spacerWidth)
        row:AddChild(spacer)

        -- Enable/disable checkbox
        local enableBox = AceGUI:Create("CheckBox") --[[@as AceGUICheckBox]]
        enableBox:SetLabel("")
        enableBox:SetValue(self.enabled[groupName])
        enableBox:SetWidth(enabledWidth - spacerWidth)
        enableBox:SetCallback("OnValueChanged", function(widget, event, value)
            addon.enabled[groupName] = value
            addon:Serialize()
            addon:Deserialize()
            self:InjectBuffGroupsAceGUI(container)
        end)
        row:AddChild(enableBox)

        -- Delete button
        local deleteBtn = AceGUI:Create("Button") --[[@as AceGUIButton]]
        deleteBtn:SetText("Delete")
        deleteBtn:SetWidth(deleteWidth)
        deleteBtn:SetDisabled(IsKnownGroup(groupName))
        deleteBtn:SetCallback("OnClick", function()
            addon.groups[groupName] = nil
            addon.enabled[groupName] = nil
            addon:Serialize()
            addon:Deserialize()
            self:InjectBuffGroupsAceGUI(container)
        end)
        row:AddChild(deleteBtn)

        scrollFrame:AddChild(row)
    end

    -- Add Group button
    local addBtn = AceGUI:Create("Button") --[[@as AceGUIButton]]
    addBtn:SetText("Add Group")
    addBtn:SetWidth(100)
    addBtn:SetCallback("OnClick", function()
        -- Find a unique default name
        local base = "NewGroup"
        local idx = 1
        local name = base
        while addon.groups and addon.groups[name] do
            idx = idx + 1
            name = base .. idx
        end
        addon.groups[name] = { 1 }
        addon.enabled[name] = true
        addon:Serialize()
        addon:Deserialize()
        self:InjectBuffGroupsAceGUI(container)
    end)
    container:AddChild(addBtn)
end
