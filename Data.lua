local addonName, addon = ... --- @cast addon Damnation

--- @alias Damnation.SpellID integer
--- @alias Damnation.GroupName string

--- @class Damnation
--- @field KnownGroups Damnation.KnownGroups.*
--- @field righteousFury Damnation.SpellID
--- @field groups table<Damnation.GroupName, Damnation.SpellID[]>
--- @field isKnownGroup table<Damnation.GroupName, boolean>

--- @enum Damnation.KnownGroups
local KnownGroups = { --- @class Damnation.KnownGroups.*
    Salvation = "Blessing of Salvation",
    Wisdom = "Blessing of Wisdom",
    Intellect = "Arcane Intellect",
    Spirit = "Divine Spirit",
}
addon.KnownGroups = KnownGroups

addon.isKnownGroup = {}
for _, groupName in pairs(KnownGroups) do
    addon.isKnownGroup[groupName] = true
end

addon.groups = {}

if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    addon.righteousFury = 25780 -- Righteous Fury

    addon.groups[KnownGroups.Salvation] = {
        1038,  -- Blessing Of Salvation
        25895, -- Greater Blessing Of Salvation
    }

    addon.groups[KnownGroups.Wisdom] = {
        19742, -- Blessing of Wisdom (Rank 1)
        19850, -- Blessing of Wisdom (Rank 2)
        19852, -- Blessing of Wisdom (Rank 3)
        19853, -- Blessing of Wisdom (Rank 4)
        19854, -- Blessing of Wisdom (Rank 5)
        25290, -- Blessing of Wisdom (Rank 6)
        25894, -- Greater Blessing of Wisdom (Rank 1)
        25918, -- Greater Blessing of Wisdom (Rank 2)
    }

    addon.groups[KnownGroups.Intellect] = {
        1459,  -- Arcane Intellect (Rank 1)
        1460,  -- Arcane Intellect (Rank 2)
        1461,  -- Arcane Intellect (Rank 3)
        10156, -- Arcane Intellect (Rank 4)
        10157, -- Arcane Intellect (Rank 5)
        23028, -- Arcane Brilliance
    }

    addon.groups[KnownGroups.Spirit] = {
        14752, -- Divine Spirit (Rank 1)
        14818, -- Divine Spirit (Rank 2)
        14819, -- Divine Spirit (Rank 3)
        27841, -- Divine Spirit (Rank 4)
        27681, -- Prayer of Spirit
    }
elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
    addon.righteousFury = 25780 -- Righteous Fury

    addon.groups[KnownGroups.Salvation] = {
        1038,  -- Blessing Of Salvation
        25895, -- Greater Blessing Of Salvation
    }

    addon.groups[KnownGroups.Wisdom] = {
        19742, -- Blessing of Wisdom (Rank 1)
        19850, -- Blessing of Wisdom (Rank 2)
        19852, -- Blessing of Wisdom (Rank 3)
        19853, -- Blessing of Wisdom (Rank 4)
        19854, -- Blessing of Wisdom (Rank 5)
        25290, -- Blessing of Wisdom (Rank 6)
        27142, -- Blessing of Wisdom (Rank 7)
        25894, -- Greater Blessing of Wisdom (Rank 1)
        25918, -- Greater Blessing of Wisdom (Rank 2)
        27143, -- Greater Blessing of Wisdom (Rank 3)
    }

    addon.groups[KnownGroups.Intellect] = {
        1459,  -- Arcane Intellect (Rank 1)
        1460,  -- Arcane Intellect (Rank 2)
        1461,  -- Arcane Intellect (Rank 3)
        10156, -- Arcane Intellect (Rank 4)
        10157, -- Arcane Intellect (Rank 5)
        27126, -- Arcane Intellect (Rank 6)
        23028, -- Arcane Brilliance (Rank 1)
        27127, -- Arcane Brilliance (Rank 2)
    }

    addon.groups[KnownGroups.Spirit] = {
        14752, -- Divine Spirit (Rank 1)
        14818, -- Divine Spirit (Rank 2)
        14819, -- Divine Spirit (Rank 3)
        27841, -- Divine Spirit (Rank 4)
        25312, -- Divine Spirit (Rank 5)
        27681, -- Prayer of Spirit (Rank 1)
        32999, -- Prayer of Spirit (Rank 2)
    }
else
    error("Unsupported WOW_PROJECT_ID: " .. tostring(WOW_PROJECT_ID))
end
