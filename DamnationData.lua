local addonName, addon = ...
local Damnation = addon.Damnation

if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    Damnation.SalvationSpellIDs = {
        1038,  -- Blessing of Salvation
        25895, -- Greater Blessing of Salvation
    }
    Damnation.IntellectSpellIDs = {
        1459,  -- Arcane Intellect (Rank 1)
        1460,  -- Arcane Intellect (Rank 2)
        1461,  -- Arcane Intellect (Rank 3)
        10156, -- Arcane Intellect (Rank 4)
        10157, -- Arcane Intellect (Rank 5)
        23028, -- Arcane Brilliance
    }
    Damnation.SpiritSpellIDs = {
        14752, -- Divine Spirit (Rank 1)
        14818, -- Divine Spirit (Rank 2)
        14819, -- Divine Spirit (Rank 3)
        27841, -- Divine Spirit (Rank 4)
        27681, -- Prayer of Spirit
    }
    Damnation.WisdomSpellIDs = {
        19742, -- Blessing of Wisdom (Rank 1)
        19850, -- Blessing of Wisdom (Rank 2)
        19852, -- Blessing of Wisdom (Rank 3)
        19853, -- Blessing of Wisdom (Rank 4)
        19854, -- Blessing of Wisdom (Rank 5)
        25290, -- Blessing of Wisdom (Rank 6)
        25894, -- Greater Blessing of Wisdom (Rank 1)
        25918, -- Greater Blessing of Wisdom (Rank 2)
    }
elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
    Damnation.SalvationSpellIDs = {
        1038,  -- Blessing of Salvation
        25895, -- Greater Blessing of Salvation
    }
    Damnation.IntellectSpellIDs = {
        1459,  -- Arcane Intellect (Rank 1)
        1460,  -- Arcane Intellect (Rank 2)
        1461,  -- Arcane Intellect (Rank 3)
        10156, -- Arcane Intellect (Rank 4)
        10157, -- Arcane Intellect (Rank 5)
        27126, -- Arcane Intellect (Rank 6)
        23028, -- Arcane Brilliance (Rank 1)
        27127, -- Arcane Brilliance (Rank 2)
    }
    Damnation.SpiritSpellIDs = {
        14752, -- Divine Spirit (Rank 1)
        14818, -- Divine Spirit (Rank 2)
        14819, -- Divine Spirit (Rank 3)
        27841, -- Divine Spirit (Rank 4)
        25312, -- Divine Spirit (Rank 5)
        27681, -- Prayer of Spirit (Rank 1)
        32999, -- Prayer of Spirit (Rank 2)
    }
    Damnation.WisdomSpellIDs = {
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
end
