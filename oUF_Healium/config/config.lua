local H, C, L, oUF = unpack(select(2, ...))

C["general"] = {
	debug = 10000,						-- debug mode

	showsolo = true,					-- show raid frame when solo [T]
	showplayerinparty = true,			-- show my player frame in party [T]
}

C["unitframes"] = {
	-- from Tukui config
	aggro = true,						-- show aggro on all raids layouts [T]
	showsymbols = true,	 				-- show symbol [T]
	showrange = true,					-- show range opacity on raidframes [T]
	raidalphaoor = 0.3,					-- alpha of unitframes when unit is out of range [T]
	showsmooth = true,					-- enable smooth bar [T]
	healcomm = true,					-- enable healprediction support [T]

	-- from Tukui_Raid_Healium config
	width = 120,				-- 150
	height = 28,				-- 32
	showBuff = true,					-- display buff castable by configured spells
	showDebuff = true,					-- display debuff
	-- DISPELLABLE: show only dispellable debuff
	-- BLACKLIST: exclude non-dispellable debuff from list
	-- WHITELIST: include non-dispellable debuff from list
	-- NONE: show every non-dispellable debuff
	debuffFilter = "BLACKLIST",
	highlightDispel = true,				-- highlight dispel button when debuff is dispellable (no matter they are shown or not)
	playSoundOnDispel = true,			-- play a sound when a debuff is dispellable (no matter they are shown or not)
	-- FLASH: flash button
	-- FADEOUT: fadeout/fadein button
	-- NONE: no flash
	flashStyle = "NONE", -- flash/fadeout dispel button when debuff is dispellable (no matter they are shown or not)
	showPercentage = true,				-- show health percentage instead of health value
	showButtonTooltip = true,			-- display heal buttons tooltip
	showBuffDebuffTooltip = true,		-- display buff and debuff tooltip
	showOOM = true,						-- color heal button in blue when OOM
	showOOR = false,					-- very time consuming and not really useful (OOR is already managed for each unitframe)
}

C["tanks"] = {
	enable = true
}

C["pets"] = {
	enable = true
}

C["namelist"] = {
	enable = true,
	list = "Yoog,Sweetlight,Mirabillis"
}