------------------------------------------------
-- Healium unitframes management
-- by SinaC (https://github.com/SinaC/)
------------------------------------------------
local H, C, L, oUF = unpack(select(2, ...))

local myclass = select(2, UnitClass("player"))


-- Aliases
local FlashFrame = H.FlashFrame
local PerformanceCounter = H.PerformanceCounter
local DumpSack = H.DumpSack

-- Raid unitframes header
local PlayerRaidHeader = nil
local PetRaidHeader = nil
local TankRaidHeader = nil
local NamelistRaidHeader = nil

-- Fields added to Header
--		hVisibilityAttribute: custom visibility attribute used when calling SpawnHeader for this header
-- Fields added to TukuiUnitframe
--		hDisabled: true if unitframe is dead/ghost/disconnected, false otherwise
--		hButtons: heal buttons (SecureActionButtonTemplate)
--		hDebuffs: debuff on unit (no template)
--		hBuffs: buffs on unit (only buff castable by heal buttons)
-- Fields added to hButton
--		hSpellBookID: spellID of spell linked to button
--		hMacroName: name of macro linked to button
--		hPrereqFailed: button is disabled because of prereq
--		hOOM: not enough mana to cast spell
--		hNotUsable: not usable (see http://www.wowwiki.com/API_IsUsableSpell)  -> NOT YET USED
--		hDispelHighlight: debuff dispellable by button
--		hOOR: unit of range
--		hInvalid: spell is not valid

-------------------------------------------------------
-- Constants
-------------------------------------------------------
local ActivatePrimarySpecSpellName = GetSpellInfo(63645)
local ActivateSecondarySpecSpellName = GetSpellInfo(63644)
local MaxButtonCount = 12
local MaxDebuffCount = 8
local MaxBuffCount = 6
local UpdateDelay = 0.2
local DispelSoundFile = "Sound\\Doodad\\BellTollHorde.wav"
local Visibility25 = "custom [@raid26,exists] hide;show"
local Visibility10 = "custom [@raid11,exists] hide;show"

-------------------------------------------------------
-- Helpers
-------------------------------------------------------
local function Message(...)
	print("oUF_Healium:", ...)
end

local function ERROR(...)
	print("|CFFFF0000oUF_Healium|r:",...)
end

local function WARNING(...)
	print("|CFF00FFFFoUF_Healium|r:",...)
end

local function DEBUG(lvl, ...)
	if C.general.debug and C.general.debug >= lvl then
		print("|CFF00FF00TH|r:",...)
	end
end

-- Get value or set to default if nil
local function Getter(value, default)
	return value == nil and default or value
end

-- Format big number
local function ShortValueNegative(v)
	if v <= 999 then return v end
	if v >= 1000000 then
		local value = string.format("%.1fm", v/1000000)
		return value
	elseif v >= 1000 then
		local value = string.format("%.1fk", v/1000)
		return value
	end
end

-- Get book spell id from spell name
local function GetSpellBookID(spellName)
	for i = 1, 300, 1 do
		local spellBookName = GetSpellBookItemName(i, SpellBookFrame.bookType)
		if not spellBookName then break end
		if spellName == spellBookName then
			local slotType = GetSpellBookItemInfo(i, SpellBookFrame.bookType)
			if slotType == "SPELL" then
				return i
			end
			return nil
		end
	end
	return nil
end

-- Is spell learned?
local function IsSpellLearned(spellID)
	local spellName = GetSpellInfo(spellID)
	if not spellName then return nil end
	local skillType, globalSpellID = GetSpellBookItemInfo(spellName)
	-- skill type: "SPELL", "PETACTION", "FUTURESPELL", "FLYOUT"
	if skillType == "SPELL" and globalSpellID == spellID then return skillType end
	return nil
end

local function AddToNamelist(list, name)
	if list ~= "" then
		local names = { strsplit(",", list) }
		for _, v in ipairs(names) do
			if v == name then return false end
		end
		list = list .. "," .. name
	else
		list = name
	end
	return true
end

local function RemoveFromNamelist(list, name)
	if list == "" then return false end
	local names = { strsplit(",", list) }
	local found = false
	list = ""
	for _, v in ipairs(names) do
		if v == name then
			found = true
		else
			list = (list or "") .. "," .. v
		end
	end
	return found
end

-------------------------------------------------------
-- Unitframes list management
-------------------------------------------------------
local Unitframes = {}
-- Save frame
local function SaveUnitframe(frame)
	tinsert(Unitframes, frame)
end

-- Get unitframe with pointing to this unit
local function GetUnitframesFromUnit(unit)
	PerformanceCounter:Increment("oUF_Healium", "GetUnitframesFromUnit")
	if not Unitframes then return nil end
	local frames = {}
	for _, frame in ipairs(Unitframes) do
		--if frame and frame.unit == unit then return frame end
		if frame and frame.unit == unit then
			tinsert(frames, frame)
		end
	end
	--return nil
	return frames
end

-- Loop among every valid (parent shown and unit not nil) unitframe in party/raid and call a function
local function ForEachUnitframe(fct, ...)
	PerformanceCounter:Increment("oUF_Healium", "ForEachUnitframe")
	if not Unitframes then return end
	for _, frame in ipairs(Unitframes) do
		--if frame and frame:IsShown() then -- IsShown is false if /reloadui
		if frame and frame.unit ~= nil and frame:GetParent():IsShown() then -- IsShown is false if /reloadui
			fct(frame, ...)
		end
	end
end

-- Loop among every members in party/raid and call a function even if not shown or unit is nil (only for DEBUG purpose)
local function ForEachMember(fct, ...)
	PerformanceCounter:Increment("oUF_Healium", "ForEachMember")
	if not Unitframes then return end
	for _, frame in ipairs(Unitframes) do
		if frame then
			fct(frame, ...)
		end
	end
end

-------------------------------------------------------
-- Raid header management
-------------------------------------------------------
local function ToggleHeader(header)
	if not header then return end
	--DEBUG(1000,"header:"..header:GetName().."  "..tostring(header:IsShown()))
	if header:IsShown() then
		UnregisterAttributeDriver(header, "state-visibility")
		header:Hide()
	else
		RegisterAttributeDriver(header, "state-visiblity", header.hVisibilityAttribute)
		header:Show()
	end
end

-------------------------------------------------------
-- Settings
-------------------------------------------------------
local SpecSettings = nil
-- Return settings for current spec
local function GetSpecSettings()
	--DEBUG(1000,"GetSettings")
	if not C[myclass] then return end
	local ptt = GetPrimaryTalentTree()
	if not ptt then return nil end
	SpecSettings = C[myclass][ptt]
	--DEBUG(1000,"SpecSettings:"..tostring(SpecSettings).."  "..(SpecSettings and tostring(SpecSettings.spells) or "nil"))
	return SpecSettings
end

-- Check spell settings
local function CheckSpellSettings()
	--DEBUG(1000,"CheckSpellSettings")
	-- Check settings
	if SpecSettings then
		for _, spellSetting in ipairs(SpecSettings.spells) do
			if spellSetting.spellID and not IsSpellLearned(spellSetting.spellID) then
				local name = GetSpellInfo(spellSetting.spellID)
				if name then
					ERROR(string.format(L.healium_CHECKSPELL_SPELLNOTLEARNED, name, spellSetting.spellID))
				else
					ERROR(string.format(L.healium_CHECKSPELL_SPELLNOTEXISTS, spellSetting.spellID))
				end
			elseif spellSetting.macroName and GetMacroIndexByName(spellSetting.macroName) == 0 then
				ERROR(string.format(L.healium_CHECKSPELL_MACRONOTFOUND, spellSetting.macroName))
			end
		end
	end
end

-- Create a list with spellID and spellName from a list of spellID (+ remove duplicates)
local function CreateDebuffFilterList(listName, list)
	local newList = {}
	local i = 1
	local index = 1
	while i <= #list do
		local spellName = GetSpellInfo(list[i])
		if spellName then
			-- Check for duplicate
			local j = 1
			local found = false
			while j < #newList do
				if newList[j].spellName == spellName then
					found = true
					break
				end
				j = j + 1
			end
			if not found then
				-- Create entry in new list
				newList[index] = { spellID = list[i], spellName = spellName }
				index = index + 1
			-- else
				-- -- Duplicate found
				-- WARNING(string.format(L.healium_SETTINGS_DUPLICATEBUFFDEBUFF, list[i], newList[j].spellID, spellName, listName))
			end
		else
			-- Unknown spell found
			WARNING(string.format(L.healium_SETTINGS_UNKNOWNBUFFDEBUFF, list[i], listName))
		end
		i = i + 1
	end
	return newList
end

local function InitializeSettings()
	-- TODO: for every class <> myclass, C[class] = nil

	-- Fill blacklist and whitelist with spellName instead of spellID
	if C.blacklist and C.unitframes.debuffFilter == "BLACKLIST" then
		C.blacklist = CreateDebuffFilterList("debuff blacklist", C.blacklist)
	else
		--DEBUG(1000,"Clearing debuffBlacklist")
		C.blacklist = nil
	end

	if C.whitelist and C.unitframes.debuffFilter == "WHITELIST" then
		C.whitelist = CreateDebuffFilterList("debuff whitelist", C.whitelist)
	else
		--DEBUG(1000,"Clearing debuffWhitelist")
		C.whitelist = nil
	end

	-- Add spellName to spell list
	if C[myclass] then
		for _, specSetting in pairs(C[myclass]) do
			for _, spellSetting in ipairs(specSetting.spells) do
				if spellSetting.spellID then
					local spellName = GetSpellInfo(spellSetting.spellID)
					spellSetting.spellName = spellName
				end
			end
		end
	end

	-- Set namelist to "" if not found
	if not C.namelist.list then C.namelist.list = "" end
end


-------------------------------------------------------
-- Tooltips
-------------------------------------------------------
-- Heal buttons tooltip
local function ButtonOnEnter(self)
	-- Heal tooltips are anchored to tukui tooltip
	local tooltipAnchor = (ElvUI and _G["TooltipHolder"]) or (Tukui and _G["TukuiTooltipAnchor"]) or self -- TODO: remove reference to Tukui/ElvUI
	GameTooltip_SetDefaultAnchor(GameTooltip, tooltipAnchor)
	--GameTooltip:SetOwner(tooltipAnchor, "ANCHOR_NONE")
	GameTooltip:ClearLines()
	if self.hInvalid then
		if self.hSpellBookID then
			local name = GetSpellInfo(self.hSpellBookID) -- in this case, hSpellBookID contains global spellID
			GameTooltip:AddLine(string.format(L.healium_TOOLTIP_UNKNOWNSPELL, name, self.hSpellBookID), 1, 1, 1)
		elseif self.hMacroName then
			GameTooltip:AddLine(string.format(L.healium_TOOLTIP_UNKNOWN_MACRO, self.hMacroName), 1, 1, 1)
		else
			GameTooltip:AddLine(L.healium_TOOLTIP_UNKNOWN, 1, 1, 1)
		end
	else
		if self.hSpellBookID then
			GameTooltip:SetSpellBookItem(self.hSpellBookID, SpellBookFrame.bookType)
		elseif self.hMacroName then
			GameTooltip:AddLine(string.format(L.healium_TOOLTIP_MACRO, self.hMacroName), 1, 1, 1)
		else
			GameTooltip:AddLine(L.healium_TOOLTIP_UNKNOWN, 1, 1, 1)
		end
		local unit = SecureButton_GetUnit(self)
		if not UnitExists(unit) then return end
		local unitName = UnitName(unit)
		if not unitName then unitName = "-" end
		GameTooltip:AddLine(string.format(L.healium_TOOLTIP_TARGET, unitName), 1, 1, 1)
	end
	GameTooltip:Show()
end

-- Debuff tooltip
local function DebuffOnEnter(self)
	--http://wow.go-hero.net/framexml/13164/TargetFrame.xml
	if self:GetCenter() > GetScreenWidth()/2 then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	GameTooltip:SetUnitDebuff(self.unit, self:GetID())
end

-- Buff tooltip
local function BuffOnEnter(self)
	--http://wow.go-hero.net/framexml/13164/TargetFrame.xml
	if self:GetCenter() > GetScreenWidth()/2 then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	GameTooltip:SetUnitBuff(self.unit, self:GetID())
end

-------------------------------------------------------
-- Healium buttons/buff/debuffs update
-------------------------------------------------------
-- Update healium button cooldown
local function UpdateButtonCooldown(frame, index, start, duration, enabled)
	PerformanceCounter:Increment("oUF_Healium", "UpdateButtonCooldown")
	if not frame.hButtons then return end
	--DEBUG(1000,"UpdateButtonCooldown")
	local button = frame.hButtons[index]
	CooldownFrame_SetTimer(button.cooldown, start, duration, enabled)
end

-- Update healium button OOM
local function UpdateButtonOOM(frame, index, OOM)
	PerformanceCounter:Increment("oUF_Healium", "UpdateButtonOOM")
	if not frame.hButtons then return end
	--DEBUG(1000,"UpdateButtonOOM")
	local button = frame.hButtons[index]
	--if not button then return end
	button.hOOM = OOM
end

-- Update healium button OOR
local function UpdateButtonOOR(frame, index, spellName)
	PerformanceCounter:Increment("oUF_Healium", "UpdateButtonOOR")
	if not frame.hButtons then return end
	DEBUG(1000,"UpdateButtonOOR")
	local button = frame.hButtons[index]
	local inRange = IsSpellInRange(spellName, frame.unit)
	if not inRange or inRange == 0 then
		button.hOOR = true
	else
		button.hOOR = false
	end
end

-- Update healium button color depending on frame and button status
-- frame disabled -> color in dark red except rez if dead or ghost
-- out of range -> color in deep red
-- disabled -> dark gray
-- not usable -> color in medium red
-- out of mana -> color in medium blue
-- dispel highlight -> color in debuff color
local function UpdateButtonsColor(frame)
	PerformanceCounter:Increment("oUF_Healium", "UpdateButtonsColor")
	if not SpecSettings then return end
	if not frame.hButtons then return end
	if not frame:IsShown() then return end
	local unit = frame.unit

	local isDeadOrGhost = UnitIsDead(unit) or UnitIsGhost(unit)
	local isConnected = UnitIsConnected(unit)
	for index, spellSetting in ipairs(SpecSettings.spells) do
		local button = frame.hButtons[index]
		if frame.hDisabled and (not isConnected or ((not spellSetting.rez or spellSetting.rez == false) and isDeadOrGhost)) then
			-- not (rez and unit is dead) -> color in red
			button.texture:SetVertexColor(1, 0.1, 0.1)
		elseif button.hOOR and not button.hInvalid then
			-- out of range -> color in red
			button.texture:SetVertexColor(1.0, 0.3, 0.3)
		elseif button.hPrereqFailed and not button.hInvalid then
			-- button disabled -> color in gray
			button.texture:SetVertexColor(0.2, 0.2, 0.2)
		elseif button.hNotUsable and not button.hInvalid then
			-- button not usable -> color in medium red
			button.texture:SetVertexColor(1.0, 0.5, 0.5)
		elseif button.hOOM and not button.hInvalid then
			-- no mana -> color in blue
			button.texture:SetVertexColor(0.5, 0.5, 1.0)
		elseif button.hDispelHighlight ~= "none" and not button.hInvalid then
			-- dispel highlight -> color with debuff color
			local debuffColor = DebuffTypeColor[button.hDispelHighlight] or DebuffTypeColor["none"]
			button:SetBackdropColor(debuffColor.r, debuffColor.g, debuffColor.b)
			-- --button:SetBackdropBorderColor(debuffColor.r, debuffColor.g, debuffColor.b)
			button.texture:SetVertexColor(debuffColor.r, debuffColor.g, debuffColor.b)
		else
			button.texture:SetVertexColor(1, 1, 1)
			button:SetBackdropColor(0.6, 0.6, 0.6)
			button:SetBackdropBorderColor(0.1, 0.1, 0.1)
		end
	end
end

-- Update healium frame buff/debuff and prereq
local LastDebuffSoundTime = GetTime()
local listBuffs = {} -- GC-friendly
local listDebuffs = {} -- GC-friendly
local function UpdateFrameBuffsDebuffsPrereqs(frame)
	PerformanceCounter:Increment("oUF_Healium", "UpdateFrameBuffsDebuffsPrereqs")

	--DEBUG(1000,"UpdateFrameBuffsDebuffsPrereqs: frame: "..frame:GetName().." unit: "..(unit or "nil"))

	local unit = frame.unit
	if not unit then return end

	-- reset button.hPrereqFailed and button.hDispelHighlight
	if frame.hButtons and not frame.hDisabled then
		--DEBUG(1000,"---- reset dispel, disabled")
		for index, button in ipairs(frame.hButtons) do
			button.hDispelHighlight = "none"
			button.hPrereqFailed = false
		end
	end

	-- buff: parse buff even if showBuff is set to false for prereq
	local buffCount = 0
	if not frame.hDisabled then
		local buffIndex = 1
		if SpecSettings then
			for i = 1, 40, 1 do
				-- get buff
				name, _, icon, count, _, duration, expirationTime, _, _, _, spellID = UnitAura(unit, i, "PLAYER|HELPFUL")
				if not name then
					buffCount = i-1
					break
				end
				listBuffs[i] = spellID -- display only buff castable by player but keep whole list of buff to check prereq
				-- is buff casted by player and in spell list?
				local found = false
				for index, spellSetting in ipairs(SpecSettings.spells) do
					if spellSetting.spellID and spellSetting.spellID == spellID then
						found = true
					elseif spellSetting.macroName then
						local macroID = GetMacroIndexByName(spellSetting.macroName)
						if macroID > 0 then
							local spellName = GetMacroSpell(macroID)
							if spellName == name then
								found = true
							end
						end
					end
				end
				if found and frame.hBuffs then
					-- buff casted by player and in spell list
					local buff = frame.hBuffs[buffIndex]
					-- id, unit  used by tooltip
					buff:SetID(i)
					buff.unit = unit
					-- texture
					buff.icon:SetTexture(icon)
					-- count
					if count > 1 then
						buff.count:SetText(count)
						buff.count:Show()
					else
						buff.count:Hide()
					end
					-- cooldown
					if duration and duration > 0 then
						--DEBUG(1000, "BUFF ON")
						local startTime = expirationTime - duration
						buff.cooldown:SetCooldown(startTime, duration)
					else
						--DEBUG(1000, "BUFF OFF")
						buff.cooldown:Hide()
					end
					-- show
					buff:Show()
					-- next buff
					buffIndex = buffIndex + 1
					-- too many buff?
					if buffIndex > MaxBuffCount then
						--WARNING(string.format(L.healium_BUFFDEBUFF_TOOMANYBUFF, frame:GetName(), unit))
						break
					end
				end
			end
		end
		if frame.hBuffs then
			for i = buffIndex, MaxBuffCount, 1 do
				-- hide remainder buff
				local buff = frame.hBuffs[i]
				buff:Hide()
			end
		end
	end

	-- debuff: parse debuff even if showDebuff is set to false for prereq
	local debuffCount = 0
	local debuffIndex = 1
	if SpecSettings or C.unitframes.showDebuff then
		for i = 1, 40, 1 do
			-- get debuff
			local name, _, icon, count, debuffType, duration, expirationTime, _, _, _, spellID = UnitDebuff(unit, i)
			if not name then
				debuffCount = i-1
				break
			end
			--debuffType = "Curse" -- DEBUG purpose :)
			listDebuffs[i] = {spellID, debuffType} -- display not filtered debuff but keep whole debuff list to check prereq
			local dispellable = false -- default: non-dispellable
			if debuffType then
				for _, spellSetting in ipairs(SpecSettings.spells) do
					if spellSetting.dispels then
						local canDispel = type(spellSetting.dispels[debuffType]) == "function" and spellSetting.dispels[debuffType]() or spellSetting.dispels[debuffType]
						if canDispel then
							dispellable = true
							break
						end
					end
				end
			end
			local filtered = false -- default: not filtered
			if not dispellable then
				-- non-dispellable are rejected or filtered using blacklist/whitelist
				if C.unitframes.debuffFilter == "DISPELLABLE" then
					filtered = true
				elseif C.unitframes.debuffFilter == "BLACKLIST" and C.blacklist then
					-- blacklisted ?
					filtered = false -- default: not filtered
					for _, entry in ipairs(C.blacklist) do
						if entry.spellName == name then
							filtered = true -- found in blacklist -> filtered
							break
						end
					end
				elseif C.unitframes.debuffFilter == "WHITELIST" and C.whitelist then
					-- whitelisted ?
					filtered = true -- default: filtered
					for _, entry in ipairs(C.whitelist) do
						if entry.spellName == name then
							filtered = false -- found in whitelist -> not filtered
							break
						end
					end
				end
			end
			if not filtered and frame.hDebuffs then
				-- debuff not filtered
				local debuff = frame.hDebuffs[debuffIndex]
				-- id, unit  used by tooltip
				debuff:SetID(i)
				debuff.unit = unit
				-- texture
				debuff.icon:SetTexture(icon)
				-- count
				if count > 1 then
					debuff.count:SetText(count)
					debuff.count:Show()
				else
					debuff.count:Hide()
				end
				-- cooldown
				if duration and duration > 0 then
					local startTime = expirationTime - duration
					debuff.cooldown:SetCooldown(startTime, duration)
					debuff.cooldown:Show()
				else
					debuff.cooldown:Hide()
				end
				-- debuff color
				local debuffColor = debuffType and DebuffTypeColor[debuffType] or DebuffTypeColor["none"]
				--DEBUG(1000,"debuffType: "..(debuffType or 'nil').."  debuffColor: "..(debuffColor and debuffColor.r or 'nil')..","..(debuffColor and debuffColor.g or 'nil')..","..(debuffColor and debuffColor.b or 'nil'))
				debuff:SetBackdropBorderColor(debuffColor.r, debuffColor.g, debuffColor.b)
				-- show
				debuff:Show()
				-- next debuff
				debuffIndex = debuffIndex + 1
				--- too many debuff?
				if debuffIndex > MaxDebuffCount then
					--WARNING(string.format(L.healium_BUFFDEBUFF_TOOMANYDEBUFF, frame:GetName(), unit))
					break
				end
			end
		end
	end
	if frame.hDebuffs then
		for i = debuffIndex, MaxDebuffCount, 1 do
			-- hide remainder debuff
			local debuff = frame.hDebuffs[i]
			debuff:Hide()
		end
	end

	--DEBUG(1000,"BUFF:"..buffCount.."  DEBUFF:"..debuffCount)

	-- color dispel button if dispellable debuff + prereqs management (is buff or debuff a prereq to enable/disable a spell)
	if SpecSettings and frame.hButtons and not frame.hDisabled then
		local isUnitInRange = UnitInRange(unit)
		local debuffDispellableFound = false
		local highlightDispel = Getter(C.unitframes.highlightDispel, true)
		local playSound = Getter(C.unitframes.playSoundOnDispel, true)
		local flashStyle = C.unitframes.flashStyle
		for index, spellSetting in ipairs(SpecSettings.spells) do
			local button = frame.hButtons[index]
			-- buff prereq: if not present, spell is inactive
			if spellSetting.buffs then
				--DEBUG(1000,"searching buff prereq for "..spellSetting.spellID)
				local prereqBuffFound = false
				for _, prereqBuffSpellID in ipairs(spellSetting.buffs) do
					--DEBUG(1000,"buff prereq for "..spellSetting.spellID.." "..prereqBuffSpellID)
					--for _, buff in pairs(listBuffs) do
					for i = 1, buffCount, 1 do
						local buff = listBuffs[i]
						--DEBUG(1000,"buff on unit "..buffSpellID)
						if buff == prereqBuffSpellID then
							--DEBUG(1000,"PREREQ: "..prereqBuffSpellID.." is a buff prereq for "..spellSetting.spellID.." "..button:GetName())
							prereqBuffFound = true
							break
						end
					end
					if prereqBuffFound then break end
				end
				if not prereqBuffFound then
					--DEBUG(1000,"PREREQ: BUFF for "..spellSetting.spellID.." NOT FOUND")
					button.hPrereqFailed = true
				end
			end
			-- debuff prereq: if present, spell is inactive
			if spellSetting.debuffs then
				--DEBUG(1000,"searching buff prereq for "..spellSetting.spellID)
				local prereqDebuffFound = false
				for _, prereqDebuffSpellID in ipairs(spellSetting.debuffs) do
					--DEBUG(1000,"buff prereq for "..spellSetting.spellID.." "..prereqDebuffSpellID)
					--for _, debuff in ipairs(listDebuffs) do
					for i = 1, debuffCount, 1 do
						local debuff = listDebuffs[i]
						local debuffSpellID = debuff[1] -- [1] = spellID
						--DEBUG(1000,"debuff on unit "..debuffSpellID)
						if debuffSpellID == prereqDebuffSpellID then
							--DEBUG(1000,"PREREQ: "..prereqDebuffSpellID.." is a debuff prereq for "..spellSetting.spellID.." "..button:GetName())
							prereqDebuffFound = true
							break
						end
					end
					if prereqDebuffFound then break end
				end
				if prereqDebuffFound then
					--DEBUG(1000,"PREREQ: DEBUFF for "..spellSetting.spellID.." FOUND")
					button.hPrereqFailed = true
				end
			end
			-- color dispel button if affected by a debuff curable by a player spell
			if spellSetting.dispels and (highlightDispel or playSound or flashStyle ~= "NONE") then
				--for _, debuff in ipairs(listDebuffs) do
				for i = 1, debuffCount, 1 do
					local debuff = listDebuffs[i]
					local debuffType = debuff[2] -- [2] = debuffType
					if debuffType then
						--DEBUG(1000,"type: "..type(spellSetting.dispels[debuffType]))
						local canDispel = type(spellSetting.dispels[debuffType]) == "function" and spellSetting.dispels[debuffType]() or spellSetting.dispels[debuffType]
						if canDispel then
							--print("DEBUFF dispellable")
							local debuffColor = DebuffTypeColor[debuffType] or DebuffTypeColor["none"]
							-- Highlight dispel button?
							if highlightDispel then
								button.hDispelHighlight = debuffType
							end
							-- Flash dispel?
							if isUnitInRange then
								if flashStyle == "FLASH" then
									FlashFrame:ShowFlashFrame(button, debuffColor, 320, 100, false)
								elseif flashStyle == "FADEOUT" then
									FlashFrame:Fadeout(button, 0.3)
								end
							end
							debuffDispellableFound = true
							break -- a debuff dispellable is enough
						end
					end
				end
			end
		end
		if debuffDispellableFound then
			-- Play sound?
			if playSound and isUnitInRange then
				local now = GetTime()
				--print("DEBUFF in range: "..now.."  "..h_listDebuffsoundTime)
				if now > LastDebuffSoundTime + 7 then -- no more than once every 7 seconds
					--print("DEBUFF in time")
					PlaySoundFile(DispelSoundFile)
					LastDebuffSoundTime = now
				end
			end
		end
	end

	-- Color buttons
	UpdateButtonsColor(frame)
end

-- For each spell, get cooldown then loop among Healium Unitframes and set cooldown
local lastCD = {} -- keep a list of CD between calls, if CD information are the same, no need to update buttons
local function UpdateCooldowns()
	PerformanceCounter:Increment("oUF_Healium", "UpdateCooldowns")
	--DEBUG(1000,"UpdateCooldowns")
	if not SpecSettings then return end
	for index, spellSetting in ipairs(SpecSettings.spells) do
		local start, duration, enabled
		if spellSetting.spellID then
			start, duration, enabled = GetSpellCooldown(spellSetting.spellID)
		elseif spellSetting.macroName then
			local name = GetMacroSpell(spellSetting.macroName)
			if name then
				start, duration, enabled = GetSpellCooldown(name)
			else
				enabled = false
			end
		end
		if start and start > 0 then
			local arrayEntry = lastCD[index]
			if not arrayEntry or arrayEntry.start ~= start or arrayEntry.duration ~= duration then
				--DEBUG(1000,"CD KEEP:"..index.."  "..start.."  "..duration.."  /  "..(arrayEntry and arrayEntry.start or 'nil').."  "..(arrayEntry and arrayEntry.duration or 'nil'))
				ForEachUnitframe(UpdateButtonCooldown, index, start, duration, enabled)
				lastCD[index] = { start = start, duration = duration }
			--else
				--DEBUG(1000,"CD SKIP:"..index.."  "..start.."  "..duration.."  /  "..(arrayEntry and arrayEntry.start or 'nil').."  "..(arrayEntry and arrayEntry.duration or 'nil'))
			end
		-- else
			-- DEBUG(1000,"CD: skipping:"..index)
		end
	end
end

-- Check OOM spells
local lastOOM = {} -- keep OOM status of previous step, if no change, no need to update butttons
local function UpdateOOMSpells()
	PerformanceCounter:Increment("oUF_Healium", "UpdateOOMSpells")
	if not C.unitframes.showOOM then return end
	--DEBUG(1000,"UpdateOOMSpells")
	if not SpecSettings then return end
	local change = false -- TODO: remove this flag by calling a new method ForEachUnitframe(UpdateButtonColor, index) -- update frame.hButtons[index] color
	for index, spellSetting in ipairs(SpecSettings.spells) do
		local spellName = spellSetting.spellName -- spellName is automatically set if spellID was found in settings
		if spellSetting.macroName then
			local macroID = GetMacroIndexByName(spellSetting.macroName)
			if macroID > 0 then
				spellName = GetMacroSpell(macroID)
			end
		end
		if spellName then
			--DEBUG(1000,"spellName:"..spellName)
			local _, OOM = IsUsableSpell(spellName)
			if lastOOM[index] ~= OOM then
				local change = true
				lastOOM[index] = OOM
				ForEachUnitframe(UpdateButtonOOM, index, OOM)
			-- else
				-- DEBUG(1000,"Skipping UpdateButtonOOM:"..index)
			end
		end
	end
	if change then
		ForEachUnitframe(UpdateButtonsColor)
	end
end

-- Check OOR spells
local function UpdateOORSpells()
	PerformanceCounter:Increment("oUF_Healium", "UpdateOORSpells")
	if not C.unitframes.showOOR then return end
	--DEBUG(1000,"UpdateOORSpells")
	if not SpecSettings then return end
	for index, spellSetting in ipairs(SpecSettings.spells) do
		local spellName = spellSetting.spellName -- spellName is automatically set if spellID was found in settings
		if spellSetting.macroName then
			local macroID = GetMacroIndexByName(spellSetting.macroName)
			if macroID > 0 then
				spellName = GetMacroSpell(macroID)
			end
		end
		if spellName then
			--DEBUG(1000,"spellName:"..spellName)
			ForEachUnitframe(UpdateButtonOOR, index, spellName)
		end
	end
	ForEachUnitframe(UpdateButtonsColor)
end

-- Change player's name's color if it has aggro or not
local function UpdateThreat(self, event, unit)
	PerformanceCounter:Increment("oUF_Healium", "UpdateThreat")
	if (self.unit ~= unit) or (unit == "target" or unit == "pet" or unit == "focus" or unit == "focustarget" or unit == "targettarget") then return end
	local threat = UnitThreatSituation(self.unit)
	--DEBUG(1000,"UpdateThreat:"..tostring(self.unit).." / "..tostring(unit).." --> "..tostring(threat))
	if threat and threat > 1 then
		--self.Name:SetTextColor(1,0.1,0.1)
		local r, g, b = GetThreatStatusColor(threat)
		--DEBUG(1000,"==>"..r..","..g..","..b)
		self.Name:SetTextColor(r, g, b)
	else
		self.Name:SetTextColor(1, 1, 1)
	end
end

-- PostUpdateHealth, called after health bar has been updated
local function PostUpdateHealth(health, unit, min, max)
	PerformanceCounter:Increment("oUF_Healium", "PostUpdateHeal")
	--DEBUG(1000,"PostUpdateHeal: "..(unit or "nil"))

	local frame = health:GetParent()
	--local unit = frame.unit

	--DEBUG(1000,"PostUpdateHeal: "..frame:GetName().."  "..(unit or 'nil'))
	if not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit) then
		if not UnitIsConnected(unit) then
			health.value:SetText("|cffD7BEA5"..L.unitframes_ouf_offline.."|r")
		elseif UnitIsDead(unit) then
			health.value:SetText("|cffD7BEA5"..L.unitframes_ouf_dead.."|r")
		elseif UnitIsGhost(unit) then
			health.value:SetText("|cffD7BEA5"..L.unitframes_ouf_ghost.."|r")
		end
		if not frame.hDisabled then
			--DEBUG(1000,"->DISABLE")
			frame.hDisabled = true
			-- hide buff
			if frame.hBuffs then
				--DEBUG(1000,"disable healium buffs")
				for _, buff in ipairs(frame.hBuffs) do
					buff:Hide()
				end
			end
			UpdateButtonsColor(frame)
		end
	elseif frame.hDisabled then
		--DEBUG(1000,"DISABLED")
		frame.hDisabled = false
		UpdateButtonsColor(frame)
	end
	--print("min:"..tostring(min).."  max:"..tostring(max))
	local showPercentage = Getter(C.unitframes.showPercentage, false)
	--if showPercentage and min ~= max and UnitIsConnected(unit) and not UnitIsDead(unit) and not UnitIsGhost(unit) then
	if UnitIsConnected(unit) and not UnitIsDead(unit) and not UnitIsGhost(unit) then
		if min == max then
			health.value:SetText("")
		else
			local r, g, b = 1, 1, 1
			if Tukui or ElvUI then
				r, g, b = oUF.ColorGradient(min/max, 0.69, 0.31, 0.31, 0.65, 0.63, 0.35, 0.33, 0.59, 0.33) -- Tukui has modified ColorGradient
			else
				r, g, b = oUF.ColorGradient(min, max, 0.69, 0.31, 0.31, 0.65, 0.63, 0.35, 0.33, 0.59, 0.33) -- Tukui has modified ColorGradient
			end
			if showPercentage then
				local perc = math.floor(min / max * 100)
				--health.value:SetText("|cff559655-"..h_ShortValueNegative(max-min).."|r")
				--health.value:SetFormattedText("|cff%02x%02x%02x-"..h_ShortValueNegative(max-min).."|r", r * 255, g * 255, b * 255)
				--health.value:SetFormattedText("|cffAF5050%d|r |cffD7BEA5-|r |cff%02x%02x%02x%d%%|r", min, r * 255, g * 255, b * 255, floor(min / max * 100))
				health.value:SetFormattedText("|cff%02x%02x%02x%d%%|r", r * 255, g * 255, b * 255, perc)
			else
				health.value:SetFormattedText("|cff%02x%02x%02x-"..ShortValueNegative(max-min).."|r", r * 255, g * 255, b * 255)
			end
		end
	end
end

-- Update healium frame debuff position, debuff must be anchored to last shown button
local function UpdateFrameDebuffsPosition(frame)
	PerformanceCounter:Increment("oUF_Healium", "UpdateFrameDebuffsPosition")
	if not frame.hDebuffs or not frame.hButtons then return end
	--DEBUG(1000,"UpdateFrameDebuffsPosition")
	--DEBUG(1000,"Update debuff position for "..frame:GetName())
	local anchor = frame
	if SpecSettings then -- if no heal buttons, anchor to unitframe
		anchor = frame.hButtons[#SpecSettings.spells]
	end
	--DEBUG(1000,"Update debuff position for "..frame:GetName().." anchoring on "..anchor:GetName())
	--local anchor = frame.hButtons[#SpecSettings.spells]
	local firstDebuff = frame.hDebuffs[1]
	--DEBUG(1000,"anchor: "..anchor:GetName().."  firstDebuff: "..firstDebuff:GetName())
	local debuffSpacing = SpecSettings and SpecSettings.debuffSpacing or 2
	firstDebuff:ClearAllPoints()
	firstDebuff:SetPoint("TOPLEFT", anchor, "TOPRIGHT", debuffSpacing, 0)
end

-- Update healium frame buttons, set texture, extra attributes and show/hide.
local function UpdateFrameButtons(frame)
	PerformanceCounter:Increment("oUF_Healium", "UpdateFrameButtons")
	if InCombatLockdown() then
		--DEBUG(1000,"UpdateFrameButtons: Cannot update buttons while in combat")
		return
	end
	--DEBUG(1000,"Update frame buttons for "..frame:GetName())
	if not frame.hButtons then return end
	for i, button in ipairs(frame.hButtons) do
		--DEBUG(1000,"UpdateFrameButtons:"..tostring(SpecSettings))--.."  "..(SpecSettings and SpecSettings.spells and tostring(#SpecSettings.spells) or "nil").."  "..i)
		if SpecSettings and i <= #SpecSettings.spells then
			local spellSetting = SpecSettings.spells[i]
			local icon, name, type
			if spellSetting.spellID then
				if IsSpellLearned(spellSetting.spellID) then
					type = "spell"
					name, _, icon = GetSpellInfo(spellSetting.spellID)
					button.hSpellBookID = GetSpellBookID(name)
					button.hMacroName = nil
				end
			elseif spellSetting.macroName then
				if GetMacroIndexByName(spellSetting.macroName) > 0 then
					type = "macro"
					icon = select(2,GetMacroInfo(spellSetting.macroName))
					name = spellSetting.macroName
					button.hSpellBookID = nil
					button.hMacroName = name
				end
			end
			if type and name and icon then
				--DEBUG(1000,"show button "..i.." "..frame:GetName().."  "..name)
				button.texture:SetTexture(icon)
				button:SetAttribute("type", type)
				button:SetAttribute(type, name)
				button.hInvalid = false
			else
				--DEBUG(1000,"invalid button "..i.." "..frame:GetName())
				button.hInvalid = true
				button.hSpellBookID = spellSetting.spellID
				button.hMacroName = spellSetting.macroName
				button.texture:SetTexture("Interface/Icons/INV_Misc_QuestionMark")
				button:SetAttribute("type","target") -- action is target if spell is not valid
			end
			button:Show()
		else
			--DEBUG(1000,"hide button "..i.." "..frame:GetName())
			button.hInvalid = true
			button.hSpellBookID = nil
			button.hMacroName = nil
			button.texture:SetTexture("")
			button:Hide()
		end
	end
end

-------------------------------------------------------
-- Unitframe and healium buttons/buff/debuffs creation
-------------------------------------------------------

local DelayedButtonsCreation = {}
-- Create heal buttons for a frame
local function CreateHealiumButtons(frame)
	if not frame then return end
	if frame.hButtons then return end

	--DEBUG(1000,"CreateHealiumButtons")
	if InCombatLockdown() then
		--DEBUG(1000,"CreateHealiumButtons: delayed creation of frame "..frame:GetName())
		tinsert(DelayedButtonsCreation, frame)
		return
	end

	frame.hButtons = {}
	local spellSize = frame:GetHeight()
	local spellSpacing = 2
	for i = 1, MaxButtonCount, 1 do
		-- name
		local buttonName = frame:GetName().."_HealiumButton_"..i
		local anchor
		if i == 1 then
			anchor = {"TOPLEFT", frame, "TOPRIGHT", spellSpacing, 0}
		else
			anchor = {"TOPLEFT", frame.hButtons[i-1], "TOPRIGHT", spellSpacing, 0}
		end
		local button = H:CreateHealiumButton(frame, buttonName, spellSize, anchor)
		assert(button.cooldown, "Missing cooldown on HealiumButton:"..buttonName)
		assert(button.texture, "Missing texture on HealiumButton:"..buttonName)
		-- click event/action, attributes 'type' and 'spell' are set in UpdateFrameButtons
		button:RegisterForClicks("AnyUp")
		button:SetAttribute("useparent-unit","true")
		button:SetAttribute("*unit2", "target")
		-- tooltip
		if C.unitframes.showButtonTooltip then
			button:SetScript("OnEnter", ButtonOnEnter)
			button:SetScript("OnLeave", function(frame)
				GameTooltip:Hide()
			end)
		end
		-- custom
		button.hPrereqFailed = false
		button.hOOM = false
		button.hDispelHighlight = "none"
		button.hOOR = false
		button.hInvalid = true
		button.hNotUsable = false
		-- hide
		button:Hide()
		-- save button
		tinsert(frame.hButtons, button)
	end
end

-- Create debuffs for a frame
local function CreateHealiumDebuffs(frame)
	if not frame then return end
	if frame.hDebuffs then return end

	--DEBUG(1000,"CreateHealiumDebuffs:"..frame:GetName())
	frame.hDebuffs = {}
	local debuffSize = frame:GetHeight()
	local debuffSpacing = 2
	for i = 1, MaxDebuffCount, 1 do
		--DEBUG(1000,"Create debuff "..i)
		-- name
		local debuffName = frame:GetName().."_HealiumDebuff_"..i
		local anchor
		if i == 1 then
			anchor = {"TOPLEFT", frame, "TOPRIGHT", debuffSpacing, 0}
		else
			anchor = {"TOPLEFT", frame.hDebuffs[i-1], "TOPRIGHT", debuffSpacing, 0}
		end
		local debuff = H:CreateHealiumDebuff(frame, debuffName, debuffSize, anchor)
		assert(debuff.icon, "Missing icon on HealiumDebuff:"..debuffName)
		assert(debuff.cooldown, "Missing cooldown on HealiumDebuff:"..debuffName)
		assert(debuff.count, "Missing count on HealiumDebuff:"..debuffName)
		-- tooltip
		if C.unitframes.showBuffDebuffTooltip then
			debuff:SetScript("OnEnter", DebuffOnEnter)
			debuff:SetScript("OnLeave", function(frame)
				GameTooltip:Hide()
			end)
		end
		-- hide
		debuff:Hide()
		-- save debuff
		tinsert(frame.hDebuffs, debuff)
	end
end

-- Create buff for a frame
local function CreateHealiumBuffs(frame)
	if not frame then return end
	if frame.hBuffs then return end

	--DEBUG(1000,"CreateHealiumBuffs:"..frame:GetName())
	frame.hBuffs = {}
	local buffSize = frame:GetHeight()
	local buffSpacing = 2
	for i = 1, MaxBuffCount, 1 do
		local buffName = frame:GetName().."_HealiumBuff_"..i
		local anchor
		 if i == 1 then
			anchor = {"TOPRIGHT", frame, "TOPLEFT", -buffSpacing, 0}
		else
			anchor = {"TOPRIGHT", frame.hBuffs[i-1], "TOPLEFT", -buffSpacing, 0}
		end
		local buff = H:CreateHealiumBuff(frame, buffName, buffSize, anchor)
		assert(buff.icon, "Missing icon on HealiumBuff:"..buffName)
		assert(buff.cooldown, "Missing cooldown on HealiumBuff:"..buffName)
		assert(buff.count, "Missing count on HealiumBuff:"..buffName)
		-- tooltip
		if C.unitframes.showBuffDebuffTooltip then
			buff:SetScript("OnEnter", BuffOnEnter)
			buff:SetScript("OnLeave", function(frame)
				GameTooltip:Hide()
			end)
		end
		-- hide
		buff:Hide()
		-- save buff
		tinsert(frame.hBuffs, buff)
	end
end

-- Create delayed frames
local function CreateDelayedButtons()
	if InCombatLockdown() then return false end
	--DEBUG(1000,"CreateDelayedButtons:"..tostring(DelayedButtonsCreation).."  "..(#DelayedButtonsCreation))
	if not DelayedButtonsCreation or #DelayedButtonsCreation == 0 then return false end

	for _, frame in ipairs(DelayedButtonsCreation) do
		--DEBUG(1000,"Delayed frame creation for "..frame:GetName())
		if not frame.hButtons then
			CreateHealiumButtons(frame)
		--else
			--DEBUG(1000,"Frame already created for "..frame:GetName())
		end
	end
	DelayedButtonsCreation = {}
	return true
end

local function Shared(self, unit)
	--DEBUG(1000,"Shared: "..(unit or "nil").."  "..self:GetName())

	local unitframeWidth = C.unitframes.width or 120
	H:CreateHealiumUnitframe(self, unitframeWidth)

	if self.Health then
		self.Health.PostUpdate = PostUpdateHealth
		self.Health.frequentUpdates = true
	end

	if C.unitframes.aggro == true then
		tinsert(self.__elements, UpdateThreat)
		self:RegisterEvent('PLAYER_TARGET_CHANGED', UpdateThreat)
		self:RegisterEvent('UNIT_THREAT_LIST_UPDATE', UpdateThreat)
		self:RegisterEvent('UNIT_THREAT_SITUATION_UPDATE', UpdateThreat)
	end

	-- Healium frames
	-- ==============
	-- heal buttons
	CreateHealiumButtons(self)

	-- healium debuffs
	if C.unitframes.showDebuff then
		CreateHealiumDebuffs(self)
	end

	-- healium buffs
	if C.unitframes.showBuff then
		CreateHealiumBuffs(self)
	end

	-- update healium buttons visibility, icon and attributes
	UpdateFrameButtons(self)

	-- update debuff position
	UpdateFrameDebuffsPosition(self)

	-- update buff/debuff/special spells
	--UpdateFrameBuffsDebuffsPrereqs(self) -- unit not yet set, unit passed as argument is "raid" instead of player or party1 or ...

	-- custom
	self.hDisabled = false

	-- save frame in healium frame list
	SaveUnitframe(self)

	--DEBUG(1000,"Unitframes created")
	return self
end

-------------------------------------------------------
-- Slash command handler
-------------------------------------------------------
local LastPerformanceCounterReset = GetTime()
local function SlashHandlerShowHelp()
	Message(string.format(L.healium_CONSOLE_HELP_GENERAL, SLASH_THLM1, SLASH_THLM2))
	Message(SLASH_THLM1..L.healium_CONSOLE_HELP_DEBUG)
	Message(SLASH_THLM1..L.healium_CONSOLE_HELP_DUMPGENERAL)
	Message(SLASH_THLM1..L.healium_CONSOLE_HELP_DUMPUNIT)
	Message(SLASH_THLM1..L.healium_CONSOLE_HELP_DUMPPERF)
	Message(SLASH_THLM1..L.healium_CONSOLE_HELP_DUMPSHOW)
	Message(SLASH_THLM1..L.healium_CONSOLE_HELP_RESETPERF)
	Message(SLASH_THLM1..L.healium_CONSOLE_HELP_REFRESH)
	Message(SLASH_THLM1..L.healium_CONSOLE_HELP_TOGGLE)
	Message(SLASH_THLM1..L.healium_CONSOLE_HELP_NAMELISTADD)
	Message(SLASH_THLM1..L.healium_CONSOLE_HELP_NAMELISTREMOVE)
	Message(SLASH_THLM1..L.healium_CONSOLE_HELP_NAMELISTCLEAR)
end

local function SlashHandlerDump(args)
	local function DumpFrame(frame)
		if not frame then return end
		DumpSack:Add("Frame "..tostring(frame:GetName()).." S="..tostring(frame:IsShown()).." U="..tostring(frame.unit).." D="..tostring(frame.hDisabled).." PS="..tostring(frame:GetParent():IsShown()))
		if frame.hButtons then
			DumpSack:Add("Buttons")
			for i, button in ipairs(frame.hButtons) do
				if button:IsShown() then
					DumpSack:Add("  "..i.." SID="..tostring(button.hSpellBookID).." MN="..tostring(button.hMacroName).." D="..tostring(button.hPrereqFailed).." NM="..tostring(button.hOOM).." DH="..tostring(button.hDispelHighlight).." OOR="..tostring(button.hOOR).." NU="..tostring(button.hNotUsable).." I="..tostring(button.hInvalid))
				end
			end
		else
			DumpSack:Add("Healium buttons not created")
		end
		if frame.hDebuffs then
			DumpSack:Add("Debuffs")
			for i, debuff in ipairs(frame.hDebuffs) do
				if debuff:IsShown() then
					DumpSack:Add("  "..i.." ID="..tostring(debuff:GetID()).." U="..tostring(debuff.unit))
				end
			end
		else
			DumpSack:Add("Healium debuffs not created")
		end
		if frame.hBuffs then
			DumpSack:Add("Buffs")
			for i, buff in ipairs(frame.hBuffs) do
				if buff:IsShown() then
					DumpSack:Add("  "..i.." ID="..tostring(buff:GetID()).." U="..tostring(buff.unit))
				end
			end
		else
			DumpSack:Add("Healium buffs not created")
		end
	end
	if not args then
		ForEachMember(DumpFrame)
		DumpSack:Flush("oUF_Healium")
	elseif args == "perf" then
		local time = GetTime()
		local counters = PerformanceCounter:Get("oUF_Healium")
		if not counters then
			DumpSack:Add("No performance counters")
			DumpSack:Flush("oUF_Healium")
		else
			local timespan = GetTime() - LastPerformanceCounterReset
			local header = "Performance counters. Elapsed=%.2fsec"
			local line = "%s=#%d L:%.4f  H:%.2f -> %.2f/sec"
			table.sort(counters, function(a, b)
				print("comparing "..a.count.."  and "..b.count) -- TODO: DEBUG this
				return a.count < b.count
			end)
			DumpSack:Add(header:format(timespan))
			for key, value in pairs(counters) do
				local count = value.count or 1
				local lowestSpan = value.lowestSpan or 0
				local highestSpan = value.highestSpan or 0
				DumpSack:Add(line:format(key, count, lowestSpan, highestSpan, count/timespan))
			end
			DumpSack:Flush("oUF_Healium")
		end
	elseif args == "show" then
		DumpSack:Show()
	else
		local frames = GetUnitframesFromUnit(args)
		if frames then
			for _, frame in ipairs(frames) do
			--if frame then
				DumpFrame(frame)
				DumpSack:Flush("oUF_Healium")
			end
		else
			Message(string.format(L.healium_CONSOLE_DUMP_UNITNOTFOUND,args))
		end
	end
end

local function SlashHandlerReset(args)
	if args == "perf" then
		PerformanceCounter:Reset("oUF_Healium")
		LastPerformanceCounterReset = GetTime()
		Message(L.healium_CONSOLE_RESET_PERF)
	end
end

local function SlashHandlerRefresh(args)
	if InCombatLockdown() then
		Message(L.healium_NOTINCOMBAT)
	else
		GetSpecSettings()
		CheckSpellSettings()
		CreateDelayedButtons()
		ForEachUnitframe(UpdateFrameButtons)
		ForEachUnitframe(UpdateFrameDebuffsPosition)
		ForEachUnitframe(UpdateFrameBuffsDebuffsPrereqs)
		UpdateCooldowns()
		if C.unitframes.showOOM then
			UpdateOOMSpells()
		end
		if C.unitframes.showOOR then
			UpdateOORSpells()
		end
		Message(L.healium_CONSOLE_REFRESH_OK)
	end
end

local function SlashHandlerToggle(args)
	if InCombatLockdown() then
		Message(L.healium_NOTINCOMBAT)
		return
	end
	if args == "raid" then
		ToggleHeader(PlayerRaidHeader)
	elseif args == "tank" then
		ToggleHeader(TankRaidHeader)
	elseif args == "pet" then
		ToggleHeader(PetRaidHeader)
	elseif args == "namelist" then
		ToggleHeader(NamelistRaidHeader)
	else
		Message(L.healium_CONSOLE_TOGGLE_INVALID)
	end
end

local function SlashHandlerNamelist(cmd)
	local function NamelistAdd(args)
		local name = args
		if not name then
			local realm
			name, realm = UnitName("target")
			if realm ~= nil then
				if realm:len() > 0 then
					name = name.."-".. realm
				end
			end
		end
		if name then
			local fAdded = AddToNamelist(C.namelist.list, name)
			if not fAdded then
				Message(L.healium_CONSOLE_NAMELIST_ADDALREADY)
			else
				Message(L.healium_CONSOLE_NAMELIST_ADDED:format(name))
				if NamelistRaidHeader then
					NamelistRaidHeader:SetAttribute("namelist", C.namelist.list)
				end
			end
		else
			Message(L.healium_CONSOLE_NAMELIST_ADDREMOVEINVALID)
		end
	end

	local function NamelistRemove(args)
		local name = args
		if not name then
			local _, playerRealm = UnitName("player")
			local targetName, targetRealm = UnitName("target")
			if targetName and (targetRealm == nil or playerRealm == targetRealm)  then
				name = targetName
			end
		end
		if name then
			local fRemoved = RemoveFromNamelist(C.namelist.list, name)
			if not fRemoved then
				Message(L.healium_CONSOLE_NAMELIST_REMOVENOTFOUND)
			else
				Message(L.healium_CONSOLE_NAMELIST_REMOVED:format(name))
				if NamelistRaidHeader then
					NamelistRaidHeader:SetAttribute("namelist", C.namelist.list)
				end
			end
		else
			Message(L.healium_CONSOLE_NAMELIST_ADDREMOVEINVALID)
		end
	end

	local function NamelistClear()
		C.namelist.list = ""
		if NamelistRaidHeader then
			NamelistRaidHeader:SetAttribute("namelist", list)
		end
	end

	local switch = cmd:match("([^ ]+)")
	local args = cmd:match("[^ ]+ (.+)")

	if switch == "add" then
		NamelistAdd(args)
	elseif switch == "remove" or switch == "rem" then
		NamelistRemove(args)
	elseif switch == "clear" then
		NamelistClear()
	else
		Message(L.healium_CONSOLE_NAMELIST_INVALIDOPTION)
	end
end


SLASH_THLM1 = "/th"
SLASH_THLM2 = "/thlm"
SlashCmdList["THLM"] = function(cmd)
	local switch = cmd:match("([^ ]+)")
	local args = cmd:match("[^ ]+ (.+)")
	-- debug: switch Debug
	if switch == "debug" then
		Debug = not Debug
		Message(Debug == false and L.healium_CONSOLE_DEBUG_DISABLED or L.healium_CONSOLE_DEBUG_ENABLED)
	-- DumpSack: dump frame/button/buff/debuff informations
	elseif switch == "dump" then
		SlashHandlerDump(args)
	elseif switch == "reset" then
		SlashHandlerReset(args)
	elseif switch == "refresh" then
		SlashHandlerRefresh(args)
	elseif switch == "toggle" then
		SlashHandlerToggle(args)
	elseif switch == "namelist" then
		SlashHandlerNamelist(args)
	else
		SlashHandlerShowHelp()
	end
end

-------------------------------------------------------
-- Handle healium specific events
-------------------------------------------------------

local fSettingsChecked = false -- stupid workaround  (when /reloadui PLAYER_ALIVE is not called)
local healiumEventHandler = CreateFrame("Frame")
healiumEventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")
healiumEventHandler:RegisterEvent("ADDON_LOADED")
healiumEventHandler:RegisterEvent("RAID_ROSTER_UPDATE")
healiumEventHandler:RegisterEvent("PARTY_MEMBERS_CHANGED")
healiumEventHandler:RegisterEvent("PLAYER_REGEN_ENABLED")
healiumEventHandler:RegisterEvent("PLAYER_TALENT_UPDATE")
healiumEventHandler:RegisterEvent("SPELL_UPDATE_COOLDOWN")
healiumEventHandler:RegisterEvent("UNIT_AURA")
healiumEventHandler:RegisterEvent("UNIT_POWER")
healiumEventHandler:RegisterEvent("UNIT_MAXPOWER")
--healiumEventHandler:RegisterEvent("SPELL_UPDATE_USABLE")
healiumEventHandler:RegisterEvent("PLAYER_LOGIN")
healiumEventHandler:RegisterEvent("UNIT_SPELLCAST_SENT")
healiumEventHandler:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
healiumEventHandler:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
--healiumEventHandler:RegisterEvent("SPELLS_CHANGED")
healiumEventHandler:RegisterEvent("PLAYER_ALIVE")
healiumEventHandler:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
	--DEBUG(1000,"Event: "..event)
	PerformanceCounter:Increment("oUF_Healium", event)

	if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
		--DEBUG(1000,"ADDON_LOADED:"..tostring(GetPrimaryTalentTree()).."  "..tostring(IsSpellLearned(974)).."  "..tostring(IsLoggedIn()))
		local version = GetAddOnMetadata(ADDON_NAME, "version")
		if version then
			Message(string.format(L.healium_GREETING_VERSION, tostring(version)))
		else
			Message(L.healium_GREETING_VERSIONUNKNOWN)
		end
		Message(L.healium_GREETING_OPTIONS)
		GetSpecSettings()
	elseif event == "PLAYER_LOGIN" then
		--DEBUG(1000,"PLAYER_LOGIN:"..tostring(GetPrimaryTalentTree()).."  "..tostring(IsSpellLearned(974)).."  "..tostring(IsLoggedIn()))
		GetSpecSettings()
		if SpecSettings then
			fSettingsChecked = true
			CheckSpellSettings()
		end
	elseif event == "PLAYER_ALIVE" then
		--DEBUG(1000,"PLAYER_ALIVE:"..tostring(GetPrimaryTalentTree()).."  "..tostring(IsSpellLearned(974)).."  "..tostring(IsLoggedIn()))
		GetSpecSettings()
		if SpecSettings and not fSettingsChecked then
			CheckSpellSettings()
		end
		ForEachUnitframe(UpdateFrameButtons)
		ForEachUnitframe(UpdateFrameDebuffsPosition)
		ForEachUnitframe(UpdateFrameBuffsDebuffsPrereqs)
	elseif event == "PLAYER_ENTERING_WORLD" then
		--DEBUG(1000,"PLAYER_ENTERING_WORLD:"..tostring(GetPrimaryTalentTree()).."  "..tostring(IsSpellLearned(974)).." "..tostring(self.hRespecing).."  "..tostring(IsLoggedIn()))
		ForEachUnitframe(UpdateFrameButtons)
		ForEachUnitframe(UpdateFrameDebuffsPosition)
		ForEachUnitframe(UpdateFrameBuffsDebuffsPrereqs)
	elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
		ForEachUnitframe(UpdateFrameButtons)
		ForEachUnitframe(UpdateFrameDebuffsPosition)
		ForEachUnitframe(UpdateFrameBuffsDebuffsPrereqs)
	elseif event == "PLAYER_REGEN_ENABLED" then
		--DEBUG(1000,"PLAYER_REGEN_ENABLED")
		local created = CreateDelayedButtons()
		if created then
			ForEachUnitframe(UpdateFrameButtons)
			ForEachUnitframe(UpdateFrameDebuffsPosition)
			ForEachUnitframe(UpdateFrameBuffsDebuffsPrereqs)
		end
	elseif event == "UNIT_SPELLCAST_SENT" and (arg2 == ActivatePrimarySpecSpellName or arg2 == ActivateSecondarySpecSpellName) then
		--DEBUG(1000,"UNIT_SPELLCAST_SENT:"..tostring(GetPrimaryTalentTree()).."  "..tostring(IsSpellLearned(974)).." "..tostring(self.hRespecing))
		self.hRespecing = 1 -- respec started
	elseif (event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_SUCCEEDED") and arg1 == "player" and (arg2 == ActivatePrimarySpecSpellName or arg2 == ActivateSecondarySpecSpellName) then
		--DEBUG(1000,"UNIT_SPELLCAST_INTERRUPTED:"..tostring(GetPrimaryTalentTree()).."  "..tostring(IsSpellLearned(974)).." "..tostring(self.hRespecing))
		self.hRespecing = nil --> respec stopped
	elseif event == "PLAYER_TALENT_UPDATE" then
		--DEBUG(1000,"PLAYER_TALENT_UPDATE:"..tostring(GetPrimaryTalentTree()).."  "..tostring(IsSpellLearned(974)).." "..tostring(self.hRespecing))
		if self.hRespecing == 2 then -- respec finished
			GetSpecSettings()
			CheckSpellSettings()
			ForEachUnitframe(UpdateFrameButtons)
			ForEachUnitframe(UpdateFrameDebuffsPosition)
			ForEachUnitframe(UpdateFrameBuffsDebuffsPrereqs)
			self.hRespecing = nil -- no respec running
		elseif self.hRespecing == 1 then -- respec not yet finished
			self.hRespecing = 2 -- respec finished
		else -- respec = nil, not respecing (called while connecting)
			GetSpecSettings()
			ForEachUnitframe(UpdateFrameButtons)
			ForEachUnitframe(UpdateFrameDebuffsPosition)
			ForEachUnitframe(UpdateFrameBuffsDebuffsPrereqs)
		end
	-- --elseif event == "SPELLS_CHANGED" and not self.hRespecing then
	-- elseif event == "SPELLS_CHANGED" then
		-- DEBUG(1000,"SPELLS_CHANGED:"..tostring(GetPrimaryTalentTree()).."  "..IsSpellLearned(974).." "..tostring(self.hRespecing))
		-- -- ForEachUnitframe(UpdateFrameButtons)
		-- -- ForEachUnitframe(UpdateFrameDebuffsPosition)
	-- end
	elseif event == "SPELL_UPDATE_COOLDOWN" then -- TODO: use SPELL_UPDATE_USABLE instead ?
		--DEBUG(1000,"SPELL_UPDATE_COOLDOWN:"..tostring(arg1).."  "..tostring(arg2).."  "..tostring(arg2))
		UpdateCooldowns()
	elseif event == "UNIT_AURA" then
		local frames = GetUnitframesFromUnit(arg1) -- Get frames from unit
		if frames then
			for _, frame in ipairs(frames) do
				if frame:IsShown() then UpdateFrameBuffsDebuffsPrereqs(frame) end -- Update buff/debuff only for unit
			end
		end
		--if frame and frame:IsShown() then UpdateFrameBuffsDebuffsPrereqs(frame) end -- Update buff/debuff only for unit
	elseif (event == "UNIT_POWER" or event == "UNIT_MAXPOWER") and arg1 == "player" then-- or event == "SPELL_UPDATE_USABLE" then
		if C.unitframes.showOOM then
			UpdateOOMSpells()
		end
	end
end)

if C.unitframes.showOOR then
	healiumEventHandler.hTimeSinceLastUpdate = GetTime()
	healiumEventHandler:SetScript("OnUpdate", function (self, elapsed)
		self.hTimeSinceLastUpdate = self.hTimeSinceLastUpdate + elapsed
		if self.hTimeSinceLastUpdate > UpdateDelay then
			if C.unitframes.showOOR then
				UpdateOORSpells()
			end
			self.hTimeSinceLastUpdate = 0
		end
	end)
end

-------------------------------------------------------
-- Main
-------------------------------------------------------

-- Remove unused section, get spellName from spellID, update buff/debuff lists, set default value
InitializeSettings()

-- Register style
oUF:RegisterStyle("oUF_HealiumR01R25", Shared)

-- Set unitframe creation handler
oUF:Factory(function(self)
	oUF:SetActiveStyle("oUF_HealiumR01R25")

	local unitframeWidth = C.unitframes.width or 120
	local unitframeHeight = C.unitframes.height or 28

	-- Players
	PlayerRaidHeader = self:SpawnHeader("oUF_HealiumRaid0125", nil, Visibility25,
		'oUF-initialConfigFunction', [[
			local header = self:GetParent()
			self:SetWidth(header:GetAttribute('initial-width'))
			self:SetHeight(header:GetAttribute('initial-height'))
		]],
		'initial-width', unitframeWidth,
		'initial-height', unitframeHeight,
		"showSolo", C.general.showsolo,
		"showParty", true,
		"showPlayer", C.general.showplayerinparty,
		"showRaid", true,
		"groupFilter", "1,2,3,4,5,6,7,8",
		"groupingOrder", "1,2,3,4,5,6,7,8",
		"groupBy", "GROUP",
		"yOffset", -4)
	PlayerRaidHeader:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 150, -300)
	PlayerRaidHeader.hVisibilityAttribute = Visibility25

	-- Pets, no pets in a group with 10 or more players
	if C.pets and C.pets.enable then
		PetRaidHeader = self:SpawnHeader("oUF_HealiumRaidPet0125", "SecureGroupPetHeaderTemplate", Visibility10,
			'oUF-initialConfigFunction', [[
				local header = self:GetParent()
				self:SetWidth(header:GetAttribute('initial-width'))
				self:SetHeight(header:GetAttribute('initial-height'))
			]],
			'initial-width', unitframeWidth,
			'initial-height', unitframeHeight,
			"showSolo", C.general.showsolo,
			"showParty", true,
			--"showPlayer", C.general.showplayerinparty,
			"showRaid", true,
			--"xoffset", H.Scale(3),
			"yOffset", -4,
			--"point", "LEFT",
			"groupFilter", "1,2,3,4,5,6,7,8",
			"groupingOrder", "1,2,3,4,5,6,7,8",
			"groupBy", "GROUP",
			--"maxColumns", 8,
			--"unitsPerColumn", 5,
			--"columnSpacing", H.Scale(3),
			--"columnAnchorPoint", "TOP",
			"filterOnPet", true,
			"sortMethod", "NAME"
		)
		PetRaidHeader:SetPoint("TOPLEFT", PlayerRaidHeader, "BOTTOMLEFT", 0, -50)
		PetRaidHeader.hVisibilityAttribute = Visibility10
	end

	if C.tanks and C.tanks.enable then
		-- Tank frame (attributes: [["groupFilter", "MAINTANK,TANK"]],  [["groupBy", "ROLE"]],    showParty, showRaid but not showSolo)
		TankRaidHeader = self:SpawnHeader("oUF_HealiumRaidTank0125", nil, Visibilityl25,
			'oUF-initialConfigFunction', [[
				local header = self:GetParent()
				self:SetWidth(header:GetAttribute('initial-width'))
				self:SetHeight(header:GetAttribute('initial-height'))
			]],
			'initial-width', unitframeWidth,
			'initial-height', unitframeHeight,
			"showSolo", false,
			"showParty", true,
			"showRaid", true,
			"showPlayer", C.general.showplayerinparty,
			"yOffset", -4,
			--"groupingOrder", "1,2,3,4,5,6,7,8",
			"groupFilter", "MAINTANK,TANK",
			--"groupBy", "ROLE",
			"sortMethod", "NAME"
		)
		TankRaidHeader:SetPoint("BOTTOMLEFT", PlayerRaidHeader, "TOPLEFT", 0, 50)
		TankRaidHeader.hVisibilityAttribute = Visibility25
	end

	if C.namelist and C.namelist.enable then
		-- Namelist frame
		NamelistRaidHeader = self:SpawnHeader("oUF_HealiumRaidNamelist0125", nil, Visibility25,
			'oUF-initialConfigFunction', [[
				local header = self:GetParent()
				self:SetWidth(header:GetAttribute('initial-width'))
				self:SetHeight(header:GetAttribute('initial-height'))
			]],
			'initial-width', unitframeWidth,
			'initial-height',unitframeHeight,
			"showSolo", C.general.showsolo,
			"showParty", true,
			"showRaid", true,
			"showPlayer", C.general.showplayerinparty,
			"yOffset", -4,
			"sortMethod", "NAME",
			"unitsPerColumn", 20,
			"nameList", C.namelist.list
		)
		NamelistRaidHeader:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -400, -300)
		NamelistRaidHeader.hVisibilityAttribute = Visibility25
	end
end)

-------------------------------------------------------
-- Kill blizzard frames
-------------------------------------------------------
local KillFrame = CreateFrame("Frame")
KillFrame:RegisterEvent("PLAYER_LOGIN")
KillFrame:SetScript("OnEvent", function(self, event, addon)
	local dummy = function() return end
	local function Kill(object)
		if object.UnregisterAllEvents then
			object:UnregisterAllEvents()
		end
		object.Show = dummy
		object:Hide()
	end
	InterfaceOptionsFrameCategoriesButton10:SetScale(0.00001)
	InterfaceOptionsFrameCategoriesButton10:SetAlpha(0)
	InterfaceOptionsFrameCategoriesButton11:SetScale(0.00001)
	InterfaceOptionsFrameCategoriesButton11:SetAlpha(0)
	Kill(CompactRaidFrameManager)
	Kill(CompactRaidFrameContainer)
	CompactUnitFrame_UpateVisible = dummy
	CompactUnitFrame_UpdateAll = dummy
end)