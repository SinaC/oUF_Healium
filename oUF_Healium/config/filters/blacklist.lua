local H, C, L, oUF = unpack(select(2, ...))

C["blacklist"] = { -- see debuffFilter
	--6788,	-- Weakened Soul
	--57724,	-- Berserk
	57723,	-- Time Warp
	80354,	-- Ancient Hysteria
	--36032,	-- Arcane Blast
	95223,	-- Recently Mass Resurrected
	26013,	-- Deserter
	71041,	-- Dungeon Deserter
	99413,	-- Deserter
	97821,	-- Void-Touched
}