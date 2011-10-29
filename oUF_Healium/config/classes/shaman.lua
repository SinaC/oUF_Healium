local H, C, L, oUF = unpack(select(2, ...))

C["SHAMAN"] = {
	[3] = { -- Restoration
		spells = {
			{ spellID = 974 }, -- Earth Shield
			{ spellID = 61295 }, -- Riptide
			{ spellID = 8004 }, -- Healing Surge
			{ spellID = 331 }, -- Healing Wave
			{ macroName = "NSHW" },  -- Macro Nature Swiftness + Greater Healing Wave
			{ spellID = 1064 }, -- Chain Heal
			{ spellID = 51886, dispels = { ["Curse"] = true, ["Magic"] = function() return select(5, GetTalentInfo(3,12)) > 0 end } }, -- Cleanse Spirit
		},
	}
}