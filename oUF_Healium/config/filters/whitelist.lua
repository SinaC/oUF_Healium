local H, C, L, oUF = unpack(select(2, ...))

C["whitelist"] = {
-- PVE
------
--MISC
	67479,	-- Impale
--CATA DEBUFFS
	--Baradin Hold
	95173,	-- Consuming Darkness
	88942,	-- Meteor Slash (Argaloth)

--Blackwing Descent
	--Magmaw
	91911,	-- Constricting Chains
	94679,	-- Parasitic Infection
	94617,	-- Mangle
	91923,	-- Infectious Vomit
	--Omnitron Defense System
	79835,	-- Poison Soaked Shell
	91433,	-- Lightning Conductor
	91521,	-- Incineration Security Measure
	92048,	-- Shadow Infusion
	--Maloriak
	77699,	-- Flash Freeze
	77786,	-- Consuming Flames
	77760,	-- Biting Chill
	--Atramedes
	92423,	-- Searing Flame
	92485,	-- Roaring Flame
	92407,	-- Sonic Breath
	--Chimaeron
	82881,	-- Break
	82705,	-- Finkle's Mixture
	89084,	-- Low Health
	--Nefarian
	92053,	-- Shadow Conductor
	--Sinestra
	92956,	--Wrack
--The Bastion of Twilight
	--Valiona & Theralion
	92878,	-- Blackout
	86840,	-- Devouring Flames
	95639,	-- Engulfing Magic
	92861,	-- Twilight Meteorite

	--Halfus Wyrmbreaker
	39171,	-- Malevolent Strikes

	--Twilight Ascendant Council
	92511,	-- Hydro Lance
	82762,	-- Waterlogged
	92505,	-- Frozen
	92518,	-- Flame Torrent
	83099,	-- Lightning Rod
	92075,	-- Gravity Core
	92488,	-- Gravity Crush
	82662,	-- Burning Blood
	82667,	-- Heart of Ice
	83500,	-- Swirling Winds
	83587,	-- Magnetic Pull

	--Cho'gall
	86028,	-- Cho's Blast
	86029,	-- Gall's Blast
	81836,	-- Corruption: Accelerated
	82125,	-- Corruption: Malformation
	82170,	-- Corruption: Absolute
	93200,	-- Corruption: Sickness

--Throne of the Four Winds
	--Conclave of Wind
		93123,	-- Wind Chill
		--Nezir <Lord of the North Wind>
		93131,	--Ice Patch
		--Anshal <Lord of the West Wind>
		86206,	--Soothing Breeze
		93122,	--Toxic Spores
		--Rohash <Lord of the East Wind>
		93058,	--Slicing Gale
	--Al'Akir
	87873,	-- Static Shock
	93260,	-- Ice Storm
	93295,	-- Lightning Rod
	93279,	-- Acid Rain

-- Firelands, thanks Kaelhan :)
	-- Beth'tilac
		99506,	-- Widows Kiss
		97202,	-- Fiery Web Spin
		49026,	-- Fixate
		97079,	-- Seeping Venom
	-- Lord Rhyolith
		98492,	-- Eruption
	-- Alysrazor
		101296,	-- Fieroblast
		100723,	-- Gushing Wound
		99389,	-- Imprinted
		101729,	-- Blazing Claw
		99461,	-- Blazing Power
		100029,	--  Alysra's Razor
	-- Shannox
		99840,	-- Magma Rupture
		99837,	-- Crystal Prison
		99936,	-- Jagged Tear
	-- Baleroc
		99256,	-- Torment
		99252,	-- Blaze of Glory
		99516,	-- Countdown
		99257,	-- Tormented
	-- Majordomo Staghelm
		98450,	-- Searing Seeds
		98451,	-- Burning Orbs
	-- Ragnaros
		99399,	-- Burning Wound
		100293,	-- Lava Wave
		98313,	-- Magma Blast
		100675,	-- Dreadflame
		100460,	-- Blazing Heat
-- PVP
------
-- Death Knight
	47481,	-- Gnaw (Ghoul)
	47476,	-- Strangulate
	45524,	-- Chains of Ice
	55741,	-- Desecration (no duration, lasts as long as you stand in it)
	58617,	-- Glyph of Heart Strike
	49203,	-- Hungering Cold
-- Druid
	33786,	-- Cyclone
	2637,	-- Hibernate
	5211,	-- Bash
	22570,	-- Maim
	9005,	-- Pounce
	339,	-- Entangling Roots
	45334,	-- Feral Charge Effect
	58179,	-- Infected Wounds
-- Hunter
	3355,	-- Freezing Trap Effect
	1513,	-- Scare Beast
	19503,	-- Scatter Shot
	50541,	-- Snatch (Bird of Prey)
	34490,	-- Silencing Shot
	24394,	-- Intimidation
	50519,	-- Sonic Blast (Bat)
	50518,	-- Ravage (Ravager)
	35101,	-- Concussive Barrage
	5116,	-- Concussive Shot
	13810,	-- Frost Trap Aura
	61394,	-- Glyph of Freezing Trap
	2974,	-- Wing Clip
	19306,	-- Counterattack
	19185,	-- Entrapment
	50245,	-- Pin (Crab)
	54706,	-- Venom Web Spray (Silithid)
	4167,	-- Web (Spider)
	92380,	-- Froststorm Breath (Chimera)
	50271,	-- Tendon Rip (Hyena)
-- Mage
	31661,	-- Dragon's Breath
	118,	-- Polymorph
	18469,	-- Silenced - Improved Counterspell
	44572,	-- Deep Freeze
	33395,	-- Freeze (Water Elemental)
	122,	-- Frost Nova
	55080,	-- Shattered Barrier
	6136,	-- Chilled
	120,	-- Cone of Cold
	31589,	-- Slow
-- Paladin
	20066,	-- Repentance
	10326,	-- Turn Evil
	63529,	-- Shield of the Templar
	853,	-- Hammer of Justice
	2812,	-- Holy Wrath
	20170,	-- Stun (Seal of Justice proc)
	31935,	-- Avenger's Shield
-- Priest
	64058,	-- Psychic Horror
	605,	-- Mind Control
	64044,	-- Psychic Horror
	8122,	-- Psychic Scream
	15487,	-- Silence
	15407,	-- Mind Flay
-- Rogue
	51722,	-- Dismantle
	2094,	-- Blind
	1776,	-- Gouge
	6770,	-- Sap
	1330,	-- Garrote - Silence
	18425,	-- Silenced - Improved Kick
	1833,	-- Cheap Shot
	408,	-- Kidney Shot
	31125,	-- Blade Twisting
	3409,	-- Crippling Poison
	26679,	-- Deadly Throw
-- Shaman
	51514,	-- Hex
	64695,	-- Earthgrab
	63685,	-- Freeze
	39796,	-- Stoneclaw Stun
	3600,	-- Earthbind
	8056,	-- Frost Shock
-- Warlock
	710,	-- Banish
	6789,	-- Death Coil
	5782,	-- Fear
	5484,	-- Howl of Terror
	6358,	-- Seduction (Succubus)
	24259,	-- Spell Lock (Felhunter)
	30283,	-- Shadowfury
	30153,	-- Intercept (Felguard)
	18118,	-- Aftermath
	18223,	-- Curse of Exhaustion
-- Warrior
	20511,	-- Intimidating Shout
	676,	-- Disarm
	18498,	-- Silenced (Gag Order)
	7922,	-- Charge Stun
	12809,	-- Concussion Blow
	20253,	-- Intercept
	46968,	-- Shockwave
	58373,	-- Glyph of Hamstring
	23694,	-- Improved Hamstring
	1715,	-- Hamstring
	12323,	-- Piercing Howl
-- Racials
	20549,	-- War Stomp
}