local module, L = BigWigs:ModuleDeclaration("Anomalus", "Karazhan")

-- module variables
module.revision = 30001
module.enabletrigger = module.translatedName
module.toggleoptions = { "arcaneoverload", "arcaneprison", "manaboundstrike", "manaboundframe", "markdampenedplayers", "bosskill" }
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
	AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
}

-- module defaults
module.defaultDB = {
	arcaneoverload = true,
	arcaneprison = true,
	manaboundstrike = true,
	manaboundframe = true,
	manaboundframeposx = 100,
	manaboundframeposy = 300,
	markdampenedplayers = false,
}

-- localization
L:RegisterTranslations("enUS", function()
	return {
		cmd = "Anomalus",

		arcaneoverload_cmd = "arcaneoverload",
		arcaneoverload_name = "Arcane Overload Alert",
		arcaneoverload_desc = "Warns when players get affected by Arcane Overload",

		arcaneprison_cmd = "arcaneprison",
		arcaneprison_name = "Arcane Prison Alert",
		arcaneprison_desc = "Warns when players get affected by Arcane Prison",

		manaboundstrike_cmd = "manaboundstrike",
		manaboundstrike_name = "Manabound Strike Alert",
		manaboundstrike_desc = "Warns when players get affected by Manabound Strike stacks",

		manaboundframe_cmd = "manaboundframe",
		manaboundframe_name = "Manabound Strikes Frame",
		manaboundframe_desc = "Shows a frame with player stacks and timers for Manabound Strikes",

		markdampenedplayers_cmd = "markdampenedplayers",
		markdampenedplayers_name = "Mark Dampened Players",
		markdampenedplayers_desc = "Mark players affected by Arcane Dampening if there are unused raid icons (requires assistant or leader)",

		trigger_arcaneOverloadYou = "You are afflicted by Arcane Overload",
		trigger_arcaneOverloadOther = "(.+) is afflicted by Arcane Overload",
		msg_arcaneOverloadYou = "BOMB ON YOU - DPS HARD THEN RUN AWAY!",
		msg_arcaneOverloadOther = "BOMB on %s!",
		bar_arcaneOverload = "Next Bomb",
		bar_arcaneOverloadExplosion = "BOMB ON YOU Explosion",

		trigger_arcanePrison = "(.+) is afflicted by Arcane Prison",
		msg_arcanePrison = "Arcane Prison on %s!",

		trigger_manaboundStrike = "(.+) is afflicted by Manabound Strikes %((%d+)%)",
		trigger_manaboundFade = "Manabound Strikes fades from (.+)",

		trigger_arcaneDampeningYou = "You are afflicted by Arcane Dampening",
		trigger_arcaneDampeningFadeYou = "Arcane Dampening fades from you",
		trigger_arcaneDampeningOther = "(.+) is afflicted by Arcane Dampening",
		trigger_arcaneDampeningFadeOther = "Arcane Dampening fades from (.+)",

		bar_manaboundExpire = "Manabound stacks expire",
	}
end)

-- timer and icon variables
local timer = {
	arcaneOverload = {
		7, 15, 13.5, 12.1, 10.9, 9.8, 8.8, 8, 7.2, 6.5, 5.8, 5.2, 4.5
	},
	minArcaneOverload = 4.5,
	manaboundDuration = 60,
	arcaneOverloadExplosion = 15,
	arcaneDampening = 45,
}

local icon = {
	arcaneOverload = "INV_Misc_Bomb_04",
	arcanePrison = "Spell_Frost_Glacier",
	manaboundStrike = "Spell_Arcane_FocusedPower",
	manaboundExpire = "Spell_Holy_FlashHeal",
	arcaneDampening = "Spell_Nature_AbolishMagic",
}

local syncName = {
	arcaneOverload = "AnomalusArcaneOverload" .. module.revision,
	arcanePrison = "AnomalusArcanePrison" .. module.revision,
	manaboundStrike = "AnomalusManaboundStrike" .. module.revision,
	manaboundStrikeFade = "AnomalusManaboundStrikeFade" .. module.revision,
	arcaneDampening = "AnomalusArcaneDampening" .. module.revision,
	arcaneDampeningFade = "AnomalusArcaneDampeningFade" .. module.revision,
}

local maxManaboundPlayers = 10
local arcaneOverloadCount = 0
local manaboundStrikesPlayers = {}

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
	self:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLY_DEATH", "OnFriendlyDeath")

	self:ThrottleSync(3, syncName.arcaneOverload)
	self:ThrottleSync(3, syncName.arcanePrison)
	self:ThrottleSync(3, syncName.manaboundStrike)
	self:ThrottleSync(3, syncName.manaboundStrikeFade)
	self:ThrottleSync(3, syncName.arcaneDampening)
	self:ThrottleSync(3, syncName.arcaneDampeningFade)

	self:UpdateManaboundStatusFrame()
end

function module:OnSetup()
	self.started = nil
end

function module:OnEngage()
	arcaneOverloadCount = 1
	manaboundStrikesPlayers = {}

	if self.db.profile.arcaneoverload then
		self:Bar(L["bar_arcaneOverload"], timer.arcaneOverload[arcaneOverloadCount], icon.arcaneOverload)
	end

	if self.db.profile.manaboundframe then
		self:ScheduleRepeatingEvent("UpdateManaboundStatusFrame", self.UpdateManaboundStatusFrame, 1, self)
	end
end

function module:OnDisengage()
	self:CancelScheduledEvent("UpdateManaboundStatusFrame")

	if self.manaboundStatusFrame then
		self.manaboundStatusFrame:Hide()
	end
end

function module:AfflictionEvent(msg)
	-- Arcane Overload
	if string.find(msg, L["trigger_arcaneOverloadYou"]) then
		self:Sync(syncName.arcaneOverload .. " " .. UnitName("player"))
	else
		local _, _, player = string.find(msg, L["trigger_arcaneOverloadOther"])
		if player then
			self:Sync(syncName.arcaneOverload .. " " .. player)
		end
	end

	-- Arcane Prison
	local _, _, player = string.find(msg, L["trigger_arcanePrison"])
	if player then
		self:Sync(syncName.arcanePrison .. " " .. player)
	end

	-- Manabound Strikes
	local _, _, player, count = string.find(msg, L["trigger_manaboundStrike"])
	if player and count then
		self:Sync(syncName.manaboundStrike .. " " .. player .. " " .. count)
	end

	-- Arcane Dampening
	if string.find(msg, L["trigger_arcaneDampeningYou"]) then
		self:Sync(syncName.arcaneDampening .. " " .. UnitName("player"))
	else
		local _, _, player = string.find(msg, L["trigger_arcaneDampeningOther"])
		if player then
			self:Sync(syncName.arcaneDampening .. " " .. player)
		end
	end
end

function module:CHAT_MSG_SPELL_AURA_GONE_SELF(msg)
	local _, _, playerManabound = string.find(msg, L["trigger_manaboundFade"])
	if playerManabound and playerManabound == UnitName("player") then
		self:Sync(syncName.manaboundStrikeFade .. " " .. UnitName("player"))
	end

	-- Arcane Dampening faded
	if string.find(msg, L["trigger_arcaneDampeningFadeYou"]) then
		self:Sync(syncName.arcaneDampeningFade .. " " .. UnitName("player"))
	end

	-- remove bar for manabound strikes if it was for self
	if playerManabound and playerManabound == UnitName("player") then
		self:RemoveBar(L["bar_manaboundExpire"])
	end
end

function module:CHAT_MSG_SPELL_AURA_GONE_PARTY(msg)
	local _, _, playerManabound = string.find(msg, L["trigger_manaboundFade"])
	if playerManabound then
		self:Sync(syncName.manaboundStrikeFade .. " " .. playerManabound)
	end

	-- Arcane Dampening faded
	local _, _, playerDampening = string.find(msg, L["trigger_arcaneDampeningFadeOther"])
	if playerDampening then
		self:Sync(syncName.arcaneDampeningFade .. " " .. playerDampening)
	end
end

function module:CHAT_MSG_SPELL_AURA_GONE_OTHER(msg)
	local _, _, playerManabound = string.find(msg, L["trigger_manaboundFade"])
	if playerManabound then
		self:Sync(syncName.manaboundStrikeFade .. " " .. playerManabound)
	end

	-- Arcane Dampening faded
	local _, _, playerDampening = string.find(msg, L["trigger_arcaneDampeningFadeOther"])
	if playerDampening then
		self:Sync(syncName.arcaneDampeningFade .. " " .. playerDampening)
	end
end

function module:OnFriendlyDeath(msg)
    local _, _, player = string.find(msg, "(.+) dies")
    if player then
        self:SetRaidTargetForPlayer(player, 0)

        if manaboundStrikesPlayers[player] then
            self:ManaboundStrikeFade(player)
        end
    end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.arcaneOverload and rest then
		self:ArcaneOverload(rest)
	elseif sync == syncName.arcanePrison and rest then
		self:ArcanePrison(rest)
	elseif string.find(sync, syncName.manaboundStrike) and rest then
		local _, _, player, count = string.find(rest, "([^%s]+) (%d+)")
		if player and count then
			self:ManaboundStrike(player, count)
		end
	elseif sync == syncName.manaboundStrikeFade and rest then
		self:ManaboundStrikeFade(rest)
	elseif sync == syncName.arcaneDampening and rest then
		self:ArcaneDampening(rest)
	elseif sync == syncName.arcaneDampeningFade and rest then
		self:ArcaneDampeningFade(rest)
	end
end

function module:ArcaneOverload(player)
	arcaneOverloadCount = arcaneOverloadCount + 1

	local nextTimer = timer.arcaneOverload[arcaneOverloadCount] or timer.minArcaneOverload

	if self.db.profile.arcaneoverload then
		if player == UnitName("player") then
			self:Message(L["msg_arcaneOverloadYou"], "Important", true, "Alarm")
			self:WarningSign(icon.arcaneOverload, 5, true, "BOMB ON YOU")
			self:Bar(L["bar_arcaneOverloadExplosion"], timer.arcaneOverloadExplosion, icon.arcaneOverload, true, "red")
		else
			self:Message(string.format(L["msg_arcaneOverloadOther"], player), "Important")
		end

		self:SetRaidTargetForPlayer(player, 8)

		self:RemoveBar(L["bar_arcaneOverload"])
		self:Bar(L["bar_arcaneOverload"], nextTimer, icon.arcaneOverload)
	end
end

function module:ArcanePrison(player)
	if self.db.profile.arcaneprison then
		self:Message(string.format(L["msg_arcanePrison"], player), "Attention")
	end
end

function module:ManaboundStrike(player, count)
	if tonumber(count) then
		manaboundStrikesPlayers[player] = {
			count = tonumber(count),
			expires = GetTime() + timer.manaboundDuration
		}
		if player == UnitName("player") and self.db.profile.manaboundstrike then
			self:RemoveBar(L["bar_manaboundExpire"])
			self:Bar(L["bar_manaboundExpire"], timer.manaboundDuration, icon.manaboundExpire)
		end
		self:UpdateManaboundStatusFrame()
	end
end

function module:ManaboundStrikeFade(player)
	if manaboundStrikesPlayers[player] then
		manaboundStrikesPlayers[player] = nil
		if player == UnitName("player") then
			self:RemoveBar(L["bar_manaboundExpire"])
		end
		self:UpdateManaboundStatusFrame()
	end
end

function module:ArcaneDampening(player)
	self:MarkDampenedPlayer(player)
	if player == UnitName("player") then
		self:Bar("Arcane Dampening - Can Soak", timer.arcaneDampening, icon.arcaneDampening)
	end
end

function module:ArcaneDampeningFade(player)
	self:RemoveDampenedPlayerMark(player)
	if player == UnitName("player") then
		self:RemoveBar("Arcane Dampening - Can Soak")
	end
end

function module:MarkDampenedPlayer(player)
	if self.db.profile.markdampenedplayers then
		local markToUse = self:GetAvailableRaidMark({ 8 })
		if markToUse then
			self:SetRaidTargetForPlayer(player, markToUse)
		end
	end
end

function module:RemoveDampenedPlayerMark(player)
	if self.db.profile.markdampenedplayers then
		self:SetRaidTargetForPlayer(player, 0)
	end
end

function module:UpdateManaboundStatusFrame()
	if not self.db.profile.manaboundframe then
		if self.manaboundStatusFrame then
			self.manaboundStatusFrame:Hide()
		end
		return
	end

	if not self.manaboundStatusFrame then
		self.manaboundStatusFrame = CreateFrame("Frame", "AnomalusManaboundFrame", UIParent)
		self.manaboundStatusFrame.module = self
		self.manaboundStatusFrame:SetWidth(200)
		self.manaboundStatusFrame:SetHeight(120)
		self.manaboundStatusFrame:ClearAllPoints()
		local s = self.manaboundStatusFrame:GetEffectiveScale()
		self.manaboundStatusFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
				(self.db.profile.manaboundframeposx or 100) / s,
				(self.db.profile.manaboundframeposy or 300) / s)
		self.manaboundStatusFrame:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 8, right = 8, top = 8, bottom = 8 }
		})
		self.manaboundStatusFrame:SetBackdropColor(0, 0, 0, 1)

		self.manaboundStatusFrame:SetMovable(true)
		self.manaboundStatusFrame:EnableMouse(true)
		self.manaboundStatusFrame:RegisterForDrag("LeftButton")
		self.manaboundStatusFrame:SetScript("OnDragStart", function() this:StartMoving() end)
		self.manaboundStatusFrame:SetScript("OnDragStop", function()
			this:StopMovingOrSizing()
			local scale = this:GetEffectiveScale()
			this.module.db.profile.manaboundframeposx = this:GetLeft() * scale
			this.module.db.profile.manaboundframeposy = this:GetTop() * scale
		end)

		self.manaboundStatusFrame.header = self.manaboundStatusFrame:CreateFontString(nil, "ARTWORK")
		self.manaboundStatusFrame.header:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
		self.manaboundStatusFrame.header:SetPoint("TOPLEFT", self.manaboundStatusFrame, "TOPLEFT", 10, -10)
		self.manaboundStatusFrame.header:SetText("Timer | Player name | Stack count")

		self.manaboundStatusFrame.lines = {}
		for i = 1, maxManaboundPlayers do
			local line = {}
			line.timer = self.manaboundStatusFrame:CreateFontString(nil, "ARTWORK")
			line.timer:SetFont("Fonts\\FRIZQT__.TTF", 9)
			line.timer:SetPoint("TOPLEFT", self.manaboundStatusFrame, "TOPLEFT", 10, -10 - (i * 15))
			line.timer:SetWidth(40)
			line.timer:SetJustifyH("LEFT")

			line.player = self.manaboundStatusFrame:CreateFontString(nil, "ARTWORK")
			line.player:SetFont("Fonts\\FRIZQT__.TTF", 9)
			line.player:SetPoint("LEFT", line.timer, "RIGHT", 10, 0)
			line.player:SetWidth(80)
			line.player:SetJustifyH("LEFT")

			line.stacks = self.manaboundStatusFrame:CreateFontString(nil, "ARTWORK")
			line.stacks:SetFont("Fonts\\FRIZQT__.TTF", 9)
			line.stacks:SetPoint("LEFT", line.player, "RIGHT", 10, 0)
			line.stacks:SetWidth(30)
			line.stacks:SetJustifyH("CENTER")
			self.manaboundStatusFrame.lines[i] = line
		end
	end

	self.manaboundStatusFrame:Show()
	local lineIndex = 1
	local now = GetTime()

	for player, data in pairs(manaboundStrikesPlayers) do
		if lineIndex <= maxManaboundPlayers then
			local line = self.manaboundStatusFrame.lines[lineIndex]
			local timeLeft = math.max(0, data.expires - now)
			line.timer:SetText(string.format("%.0f", timeLeft))
			line.player:SetText(player)
			line.stacks:SetText(data.count)

			if data.count >= 8 then line.stacks:SetTextColor(1, 0, 0)
			elseif data.count >= 5 then line.stacks:SetTextColor(1, 0.5, 0)
			else line.stacks:SetTextColor(1, 1, 1) end

			if timeLeft < 5 then line.timer:SetTextColor(0, 1, 0)
			else line.timer:SetTextColor(1, 1, 1) end
			lineIndex = lineIndex + 1
		end
	end

	for i = lineIndex, maxManaboundPlayers do
		local line = self.manaboundStatusFrame.lines[i]
		if line then
			line.timer:SetText("")
			line.player:SetText("")
			line.stacks:SetText("")
		end
	end

	local numEntries = 0
	for _ in pairs(manaboundStrikesPlayers) do numEntries = numEntries + 1 end
	local newHeight = math.max(40, 25 + (numEntries * 17))
	self.manaboundStatusFrame:SetHeight(newHeight)
end

function module:Test()
	self:OnSetup() -- Call OnSetup to reset state before OnEngage
	self:OnEngage()

	local playerName = UnitName("player")
	local raid1Name = UnitName("raid1") or "TestRaid1" -- Fallback if not in a raid

	-- Log strings we'll use for testing, taken from your example
	-- We'll substitute playerName and raid1Name into these templates
	local manaboundAfflictedPlayerTmpl = "%s is afflicted by Manabound Strikes (1)."
	local manaboundAfflictedRaid1Tmpl = "%s is afflicted by Manabound Strikes (2)." -- Different stack for variety
	local manaboundFadePlayerTmpl = "Manabound Strikes fades from %s."
	local manaboundFadeRaid1Tmpl = "Manabound Strikes fades from %s."

	local arcaneOverloadAfflictedPlayerTmpl = "%s is afflicted by Arcane Overload (1)."
	local arcaneOverloadAfflictedRaid1Tmpl = "%s is afflicted by Arcane Overload (1)."
	local arcaneOverloadFadePlayerTmpl = "Arcane Overload fades from %s."
	local arcaneOverloadFadeRaid1Tmpl = "Arcane Overload fades from %s."

	local arcaneDampeningAfflictedPlayerTmpl = "%s is afflicted by Arcane Dampening (1)."
	local arcaneDampeningAfflictedRaid1Tmpl = "%s is afflicted by Arcane Dampening (1)."
	local arcaneDampeningFadePlayerTmpl = "Arcane Dampening fades from %s."
	local arcaneDampeningFadeRaid1Tmpl = "Arcane Dampening fades from %s."

	-- Arcane Prison doesn't have a "You are afflicted..." version in logs typically,
	-- it's usually "Target is afflicted by Arcane Prison" or a resist message.
	-- For testing direct affliction, we'll assume the "other" format.
	local arcanePrisonAfflictedPlayerTmpl = "%s is afflicted by Arcane Prison (1)." -- Using (1) as per logs, though actual prison may not show stacks.
	local arcanePrisonAfflictedRaid1Tmpl = "%s is afflicted by Arcane Prison (1)."


	local events = {
		-- == Manabound Strikes ==
		{ time = 2, func = function()
			print("Test: Player gets Manabound Strikes (1)")
			-- Need to determine if "You" or "PlayerName" is in the string for AfflictionEvent
			local msg = string.format(manaboundAfflictedPlayerTmpl, playerName)
			if msg == string.format(manaboundAfflictedPlayerTmpl, "You") then -- Simulate the "You are afflicted..." case
				module:AfflictionEvent("You are afflicted by Manabound Strikes (1).")
			else
				module:AfflictionEvent(msg)
			end
		end },
		{ time = 4, func = function()
			print("Test: " .. raid1Name .. " gets Manabound Strikes (2)")
			module:AfflictionEvent(string.format(manaboundAfflictedRaid1Tmpl, raid1Name))
		end },
		{ time = 6, func = function() -- Simulate player's Manabound fading
			print("Test: Manabound Strikes fades from Player")
			module:CHAT_MSG_SPELL_AURA_GONE_SELF(string.format(manaboundFadePlayerTmpl, "you")) -- Log says "you" for self fade
		end },
		{ time = 8, func = function() -- Simulate raid1's Manabound fading
			print("Test: Manabound Strikes fades from " .. raid1Name)
			module:CHAT_MSG_SPELL_AURA_GONE_OTHER(string.format(manaboundFadeRaid1Tmpl, raid1Name))
		end },

		-- == Arcane Overload ==
		{ time = 10, func = function()
			print("Test: Player gets Arcane Overload (1)")
			local msg = string.format(arcaneOverloadAfflictedPlayerTmpl, playerName)
			if msg == string.format(arcaneOverloadAfflictedPlayerTmpl, "You") then
				module:AfflictionEvent("You are afflicted by Arcane Overload (1).")
			else
				module:AfflictionEvent(msg)
			end
		end },
		{ time = 12, func = function()
			print("Test: " .. raid1Name .. " gets Arcane Overload (1)")
			module:AfflictionEvent(string.format(arcaneOverloadAfflictedRaid1Tmpl, raid1Name))
		end },
		-- Arcane Overload Fades (these come before Dampening normally)
		{ time = 14, func = function()
			print("Test: Arcane Overload fades from Player")
			module:CHAT_MSG_SPELL_AURA_GONE_SELF(string.format(arcaneOverloadFadePlayerTmpl, "you"))
		end },
		{ time = 16, func = function()
			print("Test: Arcane Overload fades from " .. raid1Name)
			module:CHAT_MSG_SPELL_AURA_GONE_OTHER(string.format(arcaneOverloadFadeRaid1Tmpl, raid1Name))
		end },

		-- == Arcane Dampening (typically after Overload fades) ==
		{ time = 14.1, func = function() -- Slightly after player overload fade
			print("Test: Player gets Arcane Dampening (1)")
			local msg = string.format(arcaneDampeningAfflictedPlayerTmpl, playerName)
			if msg == string.format(arcaneDampeningAfflictedPlayerTmpl, "You") then
				module:AfflictionEvent("You are afflicted by Arcane Dampening (1).")
			else
				module:AfflictionEvent(msg)
			end
		end },
		{ time = 16.1, func = function() -- Slightly after raid1 overload fade
			print("Test: " .. raid1Name .. " gets Arcane Dampening (1)")
			module:AfflictionEvent(string.format(arcaneDampeningAfflictedRaid1Tmpl, raid1Name))
		end },
		{ time = 18, func = function()
			print("Test: Arcane Dampening fades from Player")
			module:CHAT_MSG_SPELL_AURA_GONE_SELF(string.format(arcaneDampeningFadePlayerTmpl, "you"))
		end },
		{ time = 20, func = function()
			print("Test: Arcane Dampening fades from " .. raid1Name .. " (Simulating AURA_GONE_OTHER and Sync Reception)")
			-- Step 1: Simulate the game event that triggers the sync
			module:CHAT_MSG_SPELL_AURA_GONE_OTHER(string.format(arcaneDampeningFadeRaid1Tmpl, raid1Name))

			-- Step 2: Simulate BigWigs receiving the sync message that CHAT_MSG_SPELL_AURA_GONE_OTHER would have sent.
			-- This is where the mark removal logic actually happens.
			-- The 'rest' part of the sync would be the player's name.
			module:BigWigs_RecvSync(syncName.arcaneDampeningFade, raid1Name, "BigWigsTest") -- "BigWigsTest" can be any mock sender name
			print(" > Mark for " .. raid1Name .. " (Dampening) should now be removed.")
		end },
		{ time = 22, func = function()
			print("Test: Player gets Arcane Prison (1)")
			module:AfflictionEvent(string.format(arcanePrisonAfflictedPlayerTmpl, playerName))
		end },
		{ time = 24, func = function()
			print("Test: " .. raid1Name .. " gets Arcane Prison (1)")
			module:AfflictionEvent(string.format(arcanePrisonAfflictedRaid1Tmpl, raid1Name))
		end },
		-- Prison fade: "Arcane Prison fades from Depresia."
		{ time = 26, func = function()
			print("Test: Arcane Prison fades from Player")
			module:CHAT_MSG_SPELL_AURA_GONE_SELF(string.format("Arcane Prison fades from %s.", "you")) -- Assuming self fade is "you"
		end },
		{ time = 28, func = function()
			print("Test: Arcane Prison fades from " .. raid1Name)
			module:CHAT_MSG_SPELL_AURA_GONE_OTHER(string.format("Arcane Prison fades from %s.", raid1Name))
		end },

		-- Test player death with active effects
		{ time = 30, func = function()
			print("Test: " .. raid1Name .. " gets Arcane Dampening (1) again before dying")
			module:AfflictionEvent(string.format(arcaneDampeningAfflictedRaid1Tmpl, raid1Name))
		end },
		{ time = 30.1, func = function()
			print("Test: " .. raid1Name .. " gets Manabound Strikes (1) again before dying")
			module:AfflictionEvent(string.format(manaboundAfflictedPlayerTmpl, raid1Name)) -- Using player template for simplicity
		end },
		{ time = 32, func = function()
			print("Test: " .. raid1Name .. " dies")
			module:OnFriendlyDeath(raid1Name .. " dies.")
		end },


		{ time = 35, func = function()
			print("Test: Disengage")
			module:OnDisengage()
			print("Anomalus Test Complete. Check BigWigs messages/bars and chat for alerts.")
		end },
	}

	for i, event in ipairs(events) do
		self:ScheduleEvent("AnomalusComprehensiveTest" .. i, event.func, event.time)
	end

	self:Message("Anomalus Comprehensive Test started (using log strings)", "Positive")
	return true
end

-- Test command:
-- /run local m=BigWigs:GetModule("Anomalus"); BigWigs:SetupModule("Anomalus");m:Test();