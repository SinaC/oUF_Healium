local H, C, L, oUF = unpack(select(2, ...))

C["DRUID"] = {
	[3] = { -- Restoration
		spells = {
			{ spellID = 774 }, -- Rejuvenation
			{ spellID = 33763 }, -- Lifebloom
			{ spellID = 50464 }, -- Nourish
			{ spellID = 8936 }, -- Regrowth
			{ spellID = 18562, buffs = { 774, 8936 } }, -- Swiftmend, castable only of affected by Rejuvenation or Regrowth
			{ macroName = "NSHT" }, -- Macro Nature Swiftness + Healing Touch
			{ spellID = 48438 }, -- Wild Growth
			{ spellID = 2782, dispels = { ["Poison"] = true, ["Curse"] = true, ["Magic"] = function() return select(5, GetTalentInfo(3,17)) > 0 end } }, -- Remove Corruption
			{ spellID = 20484, rez = true }, -- Rebirth
		},
	}
}