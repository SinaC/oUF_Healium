local H, C, L, oUF = unpack(select(2, ...))

print("H:"..tostring(H).."  C:"..tostring(C).."  L:"..tostring(L).."  oUF:"..tostring(oUF))

local DumpSack = H.DumpSack
local PerformanceCounter = H.PerformanceCounter
local FlashFrame = H.FlashFrame

print("DumpSack:"..tostring(DumpSack).."  PerformancerCounter:"..tostring(PerformancerCounter).."  FlashFrame:"..tostring(FlashFrame))

local function test1()
	print("TEST1")
	PerformanceCounter:Increment("oUF_Healium", "test1")
end

local function test2()
	print("TEST2")
	PerformanceCounter:Increment("oUF_Healium", "test2")
end

local function test3()
	print("TEST3")
	PerformanceCounter:Increment("oUF_Healium", "test3")
end

local debuff = CreateFrame("Frame", "debuffTest", UIParent)
debuff:CreatePanel("Default", 32, 32, "CENTER", UIParent, "CENTER", 0, 0)
-- icon
debuff.icon = debuff:CreateTexture(nil, "ARTWORK")
debuff.icon:Point("TOPLEFT", 2, -2)
debuff.icon:Point("BOTTOMRIGHT", -2, 2)
debuff.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
debuff.icon:SetTexture("Interface/Icons/INV_Misc_QuestionMark")
-- cooldown
debuff.cooldown = CreateFrame("Cooldown", "$parentCD", debuff, "CooldownFrameTemplate")
debuff.cooldown:SetAllPoints(debuff.icon)
debuff.cooldown:SetReverse()
-- count
debuff.count = debuff:CreateFontString("$parentCount", "OVERLAY")
debuff.count:SetFont(C["media"].uffont, 14, "OUTLINE")
debuff.count:Point("BOTTOMRIGHT", 1, -1)
debuff.count:SetJustifyH("CENTER")

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!! CooldownFrame_SetTimer  hook
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

local testFrame = CreateFrame("Frame")
testFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
testFrame:RegisterEvent("UNIT_AURA")
testFrame:RegisterEvent("UNIT_POWER")
testFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
	if event == "PLAYER_ENTERING_WORLD" then
		test1()
	elseif event == "UNIT_AURA" then
		test2()
	elseif event == "UNIT_POWER" then
		test3()
	end
end)

local LastPerformanceCounterReset = GetTime()
SLASH_OHM1 = "/ohm"
SlashCmdList["OHM"] = function(cmd)
	print("Let's go")
	-- debuff.cooldown:SetCooldown(GetTime(), 15)
	-- debuff.cooldown:Show()
	CooldownFrame_SetTimer(debuff.cooldown, GetTime(), 15, 1)
	

	debuff.count:SetText(9)
	debuff.count:Show()
	-- local time = GetTime()
	-- local counters = PerformanceCounter:Get("oUF_Healium")
	-- if not counters then
		-- DumpSack:Add("No performance counters")
		-- DumpSack:Flush("oUF_Healium")
	-- else
		-- local timespan = GetTime() - LastPerformanceCounterReset
		-- local header = "Performance counters. Elapsed=%.2fsec"
		-- local line = "%s=#%d L:%.4f  H:%.2f -> %.2f/sec"
		-- DumpSack:Add(header:format(timespan))
		-- for key, value in pairs(counters) do
			-- local count = value.count or 1
			-- local lowestSpan = value.lowestSpan or 0
			-- local highestSpan = value.highestSpan or 0
			-- DumpSack:Add(line:format(key, count, lowestSpan, highestSpan, count/timespan))
		-- end
		-- DumpSack:Flush("oUF_Healium")
	-- end
end