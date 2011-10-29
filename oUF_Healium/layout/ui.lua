-- inspiration for unitframes  \FrameXML\CompactUnitFrame.lua
-- game fonts: http://www.wowwiki.com/API_FontInstance_SetFontObject
local H, C, L, oUF = unpack(select(2, ...))

local function MLAnchorUpdate(self)
	if self.Leader:IsShown() then
		self.MasterLooter:SetPoint("TOPLEFT", 14, 8)
	else
		self.MasterLooter:SetPoint("TOPLEFT", 2, 8)
	end
end

function H:CreateHealiumButton(parent, name, size, anchor)
	--print(">Healium:CreateHealiumButton")
	-- frame
	local button = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
	button:SetFrameLevel(1)
	button:SetHeight(size)
	button:SetWidth(size)
	button:SetFrameStrata("BACKGROUND")
	button:SetPoint(unpack(anchor))
	-- texture setup, texture icon is set in UpdateFrameButtons
	button.texture = button:CreateTexture(nil, "BORDER")
	button.texture:SetPoint("TOPLEFT", button ,"TOPLEFT", 0, 0)
	button.texture:SetPoint("BOTTOMRIGHT", button ,"BOTTOMRIGHT", 0, 0)
	button:SetPushedTexture("Interface/Buttons/UI-Quickslot-Depress")
	button:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
	-- cooldown overlay
	button.cooldown = CreateFrame("Cooldown", "$parentCD", button, "CooldownFrameTemplate")
	button.cooldown:SetAllPoints(button.texture)
	--print("<Healium:CreateHealiumButton")
	return button
end

function H:CreateHealiumDebuff(parent, name, size, anchor)
	--print(">Healium:CreateHealiumDebuff")
	-- frame
	local debuff = CreateFrame("Frame", name, parent) -- --debuff = CreateFrame("Frame", debuffName, parent, "TargetDebuffFrameTemplate")
	debuff:SetFrameLevel(1)
	debuff:SetHeight(size)
	debuff:SetWidth(size)
	debuff:SetFrameStrata("BACKGROUND")
	debuff:SetPoint(unpack(anchor))
	-- icon
	debuff.icon = debuff:CreateTexture(nil, "ARTWORK")
	debuff.icon:SetPoint("TOPLEFT", 2, -2)
	debuff.icon:SetPoint("BOTTOMRIGHT", -2, 2)
	-- cooldown
	debuff.cooldown = CreateFrame("Cooldown", "$parentCD", debuff, "CooldownFrameTemplate")
	debuff.cooldown:SetAllPoints(debuff.icon)
	debuff.cooldown:SetReverse()
	-- count
	debuff.count = debuff:CreateFontString("$parentCount", "OVERLAY")
	debuff.count:SetFontObject(NumberFontNormal)
	debuff.count:SetPoint("BOTTOMRIGHT", 1, -1)
	debuff.count:SetJustifyH("CENTER")
	--print("<Healium:CreateHealiumDebuff")
	return debuff
end

function H:CreateHealiumBuff(parent, name, size, anchor)
	--print(">Healium:CreateHealiumBuff")
	-- frame
	local buff = CreateFrame("Frame", name, parent) --buff = CreateFrame("Frame", buffName, frame, "TargetBuffFrameTemplate")
	buff:SetFrameLevel(1)
	buff:SetHeight(size)
	buff:SetWidth(size)
	buff:SetFrameStrata("BACKGROUND")
	buff:SetPoint(unpack(anchor))
	-- icon
	buff.icon = buff:CreateTexture(nil, "ARTWORK")
	buff.icon:SetPoint("TOPLEFT", 2, -2)
	buff.icon:SetPoint("BOTTOMRIGHT", -2, 2)
	-- cooldown
	buff.cooldown = CreateFrame("Cooldown", "$parentCD", buff, "CooldownFrameTemplate")
	buff.cooldown:SetAllPoints(buff.icon)
	buff.cooldown:SetReverse()
	-- count
	buff.count = buff:CreateFontString("$parentCount", "OVERLAY")
	buff.count:SetFontObject(NumberFontNormal)
	buff.count:SetPoint("BOTTOMRIGHT", 1, -1)
	buff.count:SetJustifyH("CENTER")
	--print("<Healium:CreateHealiumBuff")
	return buff
end

function H:CreateHealiumUnitframe(self, unitframeWidth)
	--print(">Healium:CreateHealiumUnitframe")
	self.colors = H.oUF_colors
	self:RegisterForClicks("AnyUp")
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self.horizTopBorder = self:CreateTexture(nil, "BORDER")
	self.horizTopBorder:ClearAllPoints();
	self.horizTopBorder:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, -7);
	self.horizTopBorder:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, -7);
	self.horizTopBorder:SetTexture("Interface\\RaidFrame\\Raid-HSeparator");
	self.horizTopBorder:SetHeight(8);

	self.horizBottomBorder = self:CreateTexture(nil, "BORDER")
	self.horizBottomBorder:ClearAllPoints();
	self.horizBottomBorder:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, 1);
	self.horizBottomBorder:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, 1);
	self.horizBottomBorder:SetTexture("Interface\\RaidFrame\\Raid-HSeparator");
	self.horizBottomBorder:SetHeight(8);

	self.vertLeftBorder = self:CreateTexture(nil, "BORDER")
	self.vertLeftBorder:ClearAllPoints();
	self.vertLeftBorder:SetPoint("TOPRIGHT", self, "TOPLEFT", 7, 0);
	self.vertLeftBorder:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", 7, 0);
	self.vertLeftBorder:SetTexture("Interface\\RaidFrame\\Raid-VSeparator");
	self.vertLeftBorder:SetWidth(8);

	self.vertRightBorder = self:CreateTexture(nil, "BORDER")
	self.vertRightBorder:ClearAllPoints();
	self.vertRightBorder:SetPoint("TOPLEFT", self, "TOPRIGHT", -1, 0);
	self.vertRightBorder:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -1, 0);
	self.vertRightBorder:SetTexture("Interface\\RaidFrame\\Raid-VSeparator");
	self.vertRightBorder:SetWidth(8);

	self.menu = function(self)
		local unit = self.unit:gsub("(.)", string.upper, 1)
		if unit == "Targettarget" or unit == "focustarget" or unit == "pettarget" then return end

		if _G[unit.."FrameDropDown"] then
			ToggleDropDownMenu(1, nil, _G[unit.."FrameDropDown"], "cursor")
		elseif (self.unit:match("party")) then
			ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor")
		else
			FriendsDropDown.unit = self.unit
			FriendsDropDown.id = self.id
			FriendsDropDown.initialize = RaidFrameDropDown_Initialize
			ToggleDropDownMenu(1, nil, FriendsDropDown, "cursor")
		end
	end

	local health = CreateFrame('StatusBar', nil, self)
	--health:SetPoint("TOPLEFT")
	--health:SetPoint("TOPRIGHT")
	--health:SetHeight(27)
	health:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
	health:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -1)
	health:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -1, 4)
	--health:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill", "BORDER")
	self.Health = health

	health.bg = health:CreateTexture(nil, 'BORDER')
	health.bg:SetAllPoints(health)
	health.bg:SetTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Bg")
	health.bg:SetTexture(0.3, 0.3, 0.3)
	health.bg.multiplier = 0.3
	self.Health.bg = health.bg

	health.value = health:CreateFontString(nil, "OVERLAY")
	health.value:SetPoint("RIGHT", health, -3, 1)
	health.value:SetFontObject(GameFontNormalSmall)--NumberFontNormal
	-- local fontName, fontHeight, fontFlags = NumberFontNormal:GetFont()
	-- health.value:SetFont(fontName, 12, "THINOUTLINE")
	health.value:SetTextColor(1,1,1)
	health.value:SetShadowOffset(1, -1)
	self.Health.value = health.value

	health.colorDisconnected = true
	health.colorClass = true
	health.colorReaction = true

	local power = CreateFrame("StatusBar", nil, self)
	power:SetHeight(4)
	power:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 1, 4)
	power:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -1, 4)
	power:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Fill");
	self.Power = power

	power.frequentUpdates = true
	power.colorDisconnected = true

	power.bg = self.Power:CreateTexture(nil, "BORDER")
	power.bg:SetAllPoints(power)
	power.bg:SetTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Background")
	power.bg:SetAlpha(1)
	power.bg.multiplier = 0.4
	self.Power.bg = power.bg

	power.colorPower = true

	local name = health:CreateFontString(nil, "OVERLAY")
	name:SetPoint("LEFT", health, 3, 0)
	name:SetFontObject(GameFontNormal )
	name:SetShadowOffset(1, -1)
	self:Tag(name, "[oUF_Healium:namemedium]")
	self.Name = name

	local leader = health:CreateTexture(nil, "OVERLAY")
	leader:SetHeight(12)
	leader:SetWidth(12)
	leader:SetPoint("TOPLEFT", 0, 6)
	self.Leader = leader

	local LFDRole = health:CreateTexture(nil, "OVERLAY")
	LFDRole:SetHeight(12)
	LFDRole:SetWidth(12)
	LFDRole:SetPoint("TOPRIGHT", -2, -2)
	self.LFDRole = LFDRole

	local masterLooter = health:CreateTexture(nil, "OVERLAY")
	masterLooter:SetHeight(12)
	masterLooter:SetWidth(12)
	self.MasterLooter = masterLooter
	self:RegisterEvent("PARTY_LEADER_CHANGED", MLAnchorUpdate)
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", MLAnchorUpdate)

	if C["unitframes"].showsymbols == true then
		local RaidIcon = health:CreateTexture(nil, 'OVERLAY')
		RaidIcon:SetHeight(18)
		RaidIcon:SetWidth(18)
		RaidIcon:SetPoint('CENTER', self, 'CENTER')
		self.RaidIcon = RaidIcon
	end

	local ReadyCheck = self.Power:CreateTexture(nil, "OVERLAY")
	ReadyCheck:SetHeight(12)
	ReadyCheck:SetWidth(12)
	ReadyCheck:SetPoint('CENTER')
	self.ReadyCheck = ReadyCheck

	if C["unitframes"].showrange == true then
		local range = {insideAlpha = 1, outsideAlpha = C["unitframes"].raidalphaoor}
		self.Range = range
	end

	if C["unitframes"].showsmooth == true then
		health.Smooth = true
		power.Smooth = true
	end

	if C["unitframes"].healcomm then
		local mhpb = CreateFrame('StatusBar', nil, self.Health)
		mhpb:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
		mhpb:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
		mhpb:SetWidth(unitframeWidth)
		mhpb:SetStatusBarColor(0, 1, 0.5, 0.25)

		local ohpb = CreateFrame('StatusBar', nil, self.Health)
		ohpb:SetPoint('TOPLEFT', mhpb:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
		ohpb:SetPoint('BOTTOMLEFT', mhpb:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
		ohpb:SetWidth(unitframeWidth)
		ohpb:SetStatusBarColor(0, 1, 0, 0.25)

		self.HealPrediction = {
			myBar = mhpb,
			otherBar = ohpb,
			maxOverflow = 1,
		}
	end
	--print("<Healium:CreateHealiumUnitframe")
end