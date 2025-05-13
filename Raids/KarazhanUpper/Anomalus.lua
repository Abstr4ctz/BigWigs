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

		trigger_manaboundStrike = "(.+) is afflicted by Manabound Strikes %((%d+)%)%.",
		trigger_manaboundFade = "Manabound Strikes fades from (.+)",

		trigger_arcaneDampening = "(.+) is afflicted by Arcane Dampening %(1%)%.",
		trigger_arcaneDampeningFade = "Arcane Dampening fades from (.+)",

		bar_manaboundExpire = "Manabound stacks expire",
	}
end)

-- timer and icon variables
local timer = {
	arcaneOverload = {
		7, 15, 13.5, 12.1, 10.9, 9.8, 8.8, 8, 7.2, 6.5, 5.8, 5.2, 4.5
	},
	minArcaneOverload = 4.5, -- minimum time between Arcane Overload casts
	manaboundDuration = 60,
	arcaneOverloadExplosion = 15,
	arcaneDampening = 45, -- duration of Arcane Dampening
}

local icon = {
	arcaneOverload = "INV_Misc_Bomb_04",
	arcanePrison = "Spell_Frost_Glacier",
	manaboundStrike = "Spell_Arcane_FocusedPower",
	manaboundExpire = "Spell_Holy_FlashHeal",
	arcaneDampening = "Spell_Nature_AbolishMagic", -- icon for Arcane Dampening
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
local dampenedPlayers = {}

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "AuraGoneEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "AuraGoneEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "AuraGoneEvent")
    self:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLY_DEATH", "OnFriendlyDeath")

	self:ThrottleSync(3, syncName.arcaneOverload)
	self:ThrottleSync(3, syncName.arcanePrison)
	self:ThrottleSync(3, syncName.manaboundStrike)
	self:ThrottleSync(3, syncName.manaboundStrikeFade)
	self:ThrottleSync(1, syncName.arcaneDampening)
	self:ThrottleSync(1, syncName.arcaneDampeningFade)

	self:UpdateManaboundStatusFrame()
end

function module:OnSetup()
	self.started = nil
    dampenedPlayers = {}
    manaboundStrikesPlayers = {}
end

function module:OnEngage()
	arcaneOverloadCount = 1
	manaboundStrikesPlayers = {}
    dampenedPlayers = {}

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
    dampenedPlayers = {}
end

function module:AfflictionEvent(msg)
	-- Arcane Overload
	if string.find(msg, L["trigger_arcaneOverloadYou"]) then
		self:Sync(syncName.arcaneOverload .. " " .. UnitName("player"))
	else
		local _, _, playerOverload = string.find(msg, L["trigger_arcaneOverloadOther"])
		if playerOverload then
			self:Sync(syncName.arcaneOverload .. " " .. playerOverload)
		end
	end

	-- Arcane Prison
	local _, _, playerPrison = string.find(msg, L["trigger_arcanePrison"])
	if playerPrison then
		self:Sync(syncName.arcanePrison .. " " .. playerPrison)
	end

	-- Manabound Strikes
	local _, _, playerManabound, countManabound = string.find(msg, L["trigger_manaboundStrike"])
	if playerManabound and countManabound then
		self:Sync(syncName.manaboundStrike .. " " .. playerManabound .. " " .. countManabound)
	end

	-- Arcane Dampening Application Check
	local _, _, playerDampening = string.find(msg, L["trigger_arcaneDampening"])
	if playerDampening then
        -- Handle potential 'You' case if trigger matches self directly
        if playerDampening == "You" then playerDampening = UnitName("player") end
		self:Sync(syncName.arcaneDampening .. " " .. playerDampening)
	end
end

function module:AuraGoneEvent(msg)
	local playerManaboundFade
    if msg == "CHAT_MSG_SPELL_AURA_GONE_SELF" then
        _, _, playerManaboundFade = string.find(msg, L["trigger_manaboundFade"])
        if playerManaboundFade then
             playerManaboundFade = UnitName("player")
             self:Sync(syncName.manaboundStrikeFade .. " " .. playerManaboundFade)
             self:RemoveBar(L["bar_manaboundExpire"])
        end
    else
        _, _, playerManaboundFade = string.find(msg, L["trigger_manaboundFade"])
        if playerManaboundFade then
             self:Sync(syncName.manaboundStrikeFade .. " " .. playerManaboundFade)
        end
    end

	-- Arcane Dampening Fade Check
	local playerDampeningFade
    if msg == "CHAT_MSG_SPELL_AURA_GONE_SELF" then
        _, _, playerDampeningFade = string.find(msg, L["trigger_arcaneDampeningFade"])
        if playerDampeningFade then
            playerDampeningFade = UnitName("player")
            self:Sync(syncName.arcaneDampeningFade .. " " .. playerDampeningFade)
        end
    else -- Check party/other
        _, _, playerDampeningFade = string.find(msg, L["trigger_arcaneDampeningFade"])
        if playerDampeningFade then
            self:Sync(syncName.arcaneDampeningFade .. " " .. playerDampeningFade)
        end
    end
end


-- Death handling for dampened players
function module:OnFriendlyDeath(msg)
	local _, _, player = string.find(msg, "(.+) dies%.?$")
	if player then
		-- Remove raid marker if the player was tracked as dampened
		if dampenedPlayers[player] then
			self:RemoveDampenedPlayerMark(player)
		end
        -- Also remove from Manabound tracking if they die
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

	-- Calculate next timer (minimum 4.5 seconds)
	local nextTimer = timer.arcaneOverload[arcaneOverloadCount] or timer.minArcaneOverload

	if self.db.profile.arcaneoverload then
		if player == UnitName("player") then
			self:Message(L["msg_arcaneOverloadYou"], "Important", true, "Alarm")
			self:WarningSign(icon.arcaneOverload, 5, true, "BOMB ON YOU")
			-- Add personal explosion bar with red color
			self:Bar(L["bar_arcaneOverloadExplosion"], timer.arcaneOverloadExplosion, icon.arcaneOverload, true, "red")
		else
			self:Message(string.format(L["msg_arcaneOverloadOther"], player), "Important")
		end

		-- Logic to find and handle existing Skull mark
		if self.db.profile.markdampenedplayers then
			local playerWithSkull = nil
			-- Iterate through raid members to find who currently has Skull (8)
			for i = 1, GetNumRaidMembers() do -- Use GetNumRaidMembers for efficiency
				local unitid = "raid" .. i
				if UnitExists(unitid) then
					local currentMark = GetRaidTargetIndex(unitid)
					if currentMark == 8 then
						playerWithSkull = UnitName(unitid)
						break
					end
				end
			end

			-- If we found someone with Skull, check if they are dampened
			if playerWithSkull and dampenedPlayers[playerWithSkull] then
				self:RestorePreviousRaidTargetForPlayer(playerWithSkull)
			end
		end

		-- Now, set the Skull mark on the new bomb target
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
		-- Update or add player to tracking table
		manaboundStrikesPlayers[player] = {
			count = tonumber(count),
			expires = GetTime() + timer.manaboundDuration
		}

		-- Only show bar for the player's own debuff
		if player == UnitName("player") and self.db.profile.manaboundstrike then
			self:RemoveBar(L["bar_manaboundExpire"])
			self:Bar(L["bar_manaboundExpire"], timer.manaboundDuration, icon.manaboundExpire)
		end

		self:UpdateManaboundStatusFrame()
	end
end

function module:ManaboundStrikeFade(player)
	-- Remove player from tracking table
	if manaboundStrikesPlayers[player] then
		manaboundStrikesPlayers[player] = nil

		-- Only remove the player's own bar
		if player == UnitName("player") then
			self:RemoveBar(L["bar_manaboundExpire"])
		end

		self:UpdateManaboundStatusFrame()
	end
end

function module:ArcaneDampening(player)
	self:MarkDampenedPlayer(player)
end

function module:ArcaneDampeningFade(player)
	self:RemoveDampenedPlayerMark(player)
end

function module:MarkDampenedPlayer(player)
    -- Avoid re-marking if already tracked
	if dampenedPlayers[player] then return end

	if self.db.profile.markdampenedplayers then
		-- don't use skull mark (8) as that is reserved for the latest Arcane Overload
		local markToUse = self:GetAvailableRaidMark({ 8 })
		if markToUse then
			if self:SetRaidTargetForPlayer(player, markToUse) then
				dampenedPlayers[player] = markToUse
			end
		end
	end

	-- Add personal bar for the player who got Dampening
	if player == UnitName("player") then
		self:Bar("Arcane Dampening - Can Soak", timer.arcaneDampening, icon.arcaneDampening, true, "Blue")
	end
end

function module:RemoveDampenedPlayerMark(player)
	if not dampenedPlayers[player] then return end

	if self.db.profile.markdampenedplayers then
		self:RestorePreviousRaidTargetForPlayer(player)
	end
	dampenedPlayers[player] = nil

	if player == UnitName("player") then
		self:RemoveBar("Arcane Dampening - Can Soak")
	end
end

function module:UpdateManaboundStatusFrame()
	if not self.db.profile.manaboundframe then
		if self.manaboundStatusFrame then
			self.manaboundStatusFrame:Hide()
		end
		return
	end

	-- Create frame if needed
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

		-- Allow dragging
		self.manaboundStatusFrame:SetMovable(true)
		self.manaboundStatusFrame:EnableMouse(true)
		self.manaboundStatusFrame:RegisterForDrag("LeftButton")
		self.manaboundStatusFrame:SetScript("OnDragStart", function()
			this:StartMoving()
		end)
		self.manaboundStatusFrame:SetScript("OnDragStop", function()
			this:StopMovingOrSizing()
			local scale = this:GetEffectiveScale()
			this.module.db.profile.manaboundframeposx = this:GetLeft() * scale
			this.module.db.profile.manaboundframeposy = this:GetTop() * scale
		end)

		-- Header - Column labels
		self.manaboundStatusFrame.header = self.manaboundStatusFrame:CreateFontString(nil, "ARTWORK")
		self.manaboundStatusFrame.header:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
		self.manaboundStatusFrame.header:SetPoint("TOPLEFT", self.manaboundStatusFrame, "TOPLEFT", 10, -10)
		self.manaboundStatusFrame.header:SetText("Timer | Player name | Stack count")

		-- Create player lines (will be populated dynamically)
		self.manaboundStatusFrame.lines = {}
		for i = 1, maxManaboundPlayers do
			-- Support up to maxManaboundPlayers players
			local line = {}

			-- Timer column
			line.timer = self.manaboundStatusFrame:CreateFontString(nil, "ARTWORK")
			line.timer:SetFont("Fonts\\FRIZQT__.TTF", 9)
			line.timer:SetPoint("TOPLEFT", self.manaboundStatusFrame, "TOPLEFT", 10, -10 - (i * 15))
			line.timer:SetWidth(40)
			line.timer:SetJustifyH("LEFT")

			-- Player name column
			line.player = self.manaboundStatusFrame:CreateFontString(nil, "ARTWORK")
			line.player:SetFont("Fonts\\FRIZQT__.TTF", 9)
			line.player:SetPoint("LEFT", line.timer, "RIGHT", 10, 0)
			line.player:SetWidth(80)
			line.player:SetJustifyH("LEFT")

			-- Stack count column
			line.stacks = self.manaboundStatusFrame:CreateFontString(nil, "ARTWORK")
			line.stacks:SetFont("Fonts\\FRIZQT__.TTF", 9)
			line.stacks:SetPoint("LEFT", line.player, "RIGHT", 10, 0)
			line.stacks:SetWidth(30)
			line.stacks:SetJustifyH("CENTER")

			self.manaboundStatusFrame.lines[i] = line
		end
	end

	self.manaboundStatusFrame:Show()

	-- Update player data in the frame
	local lineIndex = 1
	local now = GetTime()

	-- Sort players by expiration time (soonest first) or alphabetically if times are equal
	local sortedPlayers = {}
	for player, data in pairs(manaboundStrikesPlayers) do
		table.insert(sortedPlayers, { name = player, expires = data.expires, count = data.count })
	end
	table.sort(sortedPlayers, function(a, b)
		if a.expires == b.expires then
			return a.name < b.name -- Alphabetical if same expiration
		end
		return a.expires < b.expires -- Sort by expiration time
	end)


	for _, playerData in ipairs(sortedPlayers) do
		if lineIndex <= maxManaboundPlayers then
			-- Max maxManaboundPlayers players shown
			local line = self.manaboundStatusFrame.lines[lineIndex]
            local data = manaboundStrikesPlayers[playerData.name] -- Get current data

            if data then -- Check if player still exists in main table (could have faded)
                local timeLeft = math.max(0, data.expires - now)

                -- Set the columns in the new format
                line.timer:SetText(string.format("%.0f", timeLeft))
                line.player:SetText(playerData.name)
                line.stacks:SetText(data.count)

                -- Color based on stack count
                if data.count >= 8 then
                    line.stacks:SetTextColor(1, 0, 0) -- Red for high stacks
                elseif data.count >= 5 then
                    line.stacks:SetTextColor(1, 0.5, 0) -- Orange for medium stacks
                else
                    line.stacks:SetTextColor(1, 1, 1) -- White for low stacks
                end

                -- Color timer based on time remaining
                if timeLeft < 5 then
                    line.timer:SetTextColor(0, 1, 0) -- Green for about to expire
                else
                    line.timer:SetTextColor(1, 1, 1) -- White for normal
                end

                lineIndex = lineIndex + 1
            end
		end
	end


	-- Hide unused lines
	for i = lineIndex, maxManaboundPlayers do
		local line = self.manaboundStatusFrame.lines[i]
		if line then
			line.timer:SetText("")
			line.player:SetText("")
			line.stacks:SetText("")
		end
	end

	-- Adjust frame height based on number of visible entries
	local numEntries = 0
	for _ in pairs(manaboundStrikesPlayers) do
		numEntries = numEntries + 1
	end

	local newHeight = math.max(40, 25 + (numEntries * 17))
	self.manaboundStatusFrame:SetHeight(newHeight)
end


function module:Test()
    -- Ensure the module is set up before running tests
	self:OnSetup()
	self:OnEnable() -- Ensure events are registered
	self:Engage()

    -- Helper to get player names, defaulting if not in raid
    local function getPlayerName(raidUnit) return UnitName(raidUnit) or raidUnit end

	local p1 = getPlayerName("raid1")
	local p2 = getPlayerName("raid2")
	local p3 = getPlayerName("raid3")
	local p4 = getPlayerName("raid4")
	local p5 = getPlayerName("raid5")
	local selfPlayer = UnitName("player") or "Player" -- Use actual player name

	-- Define log messages using helper function for names
    -- *** Define Dampening log messages using the corrected patterns ***
	local dampeningApplyLog = "%s is afflicted by Arcane Dampening (1)."
	local dampeningFadeLog = "Arcane Dampening fades from %s."

	local events = {
		-- Manabound Strikes events (Keep these for context)
		{ time = 3, func = function() print("Test: "..p1.." gets Manabound Strikes (1)"); module:AfflictionEvent(p1 .. " is afflicted by Manabound Strikes (1)") end },
		{ time = 8, func = function() print("Test: "..p2.." gets Manabound Strikes (1)"); module:AfflictionEvent(p2 .. " is afflicted by Manabound Strikes (1)") end },

		-- Arcane Overload (Keep for Skull interaction test)
		{ time = 5, func = function() print("Test: "..p1.." gets Arcane Overload (Skull)"); module:AfflictionEvent(p1 .. " is afflicted by Arcane Overload") end },

		-- *** Arcane Dampening Test Cases ***
		{ time = 10, func = function()
            print("Test: "..p3.." gets Arcane Dampening (Should get marked)")
            module:AfflictionEvent(string.format(dampeningApplyLog, p3))
            -- Verification: Check raid target icons after ~1 sec sync delay
        end },
		{ time = 12, func = function()
            print("Test: "..p4.." gets Arcane Dampening (Should get marked)")
            module:AfflictionEvent(string.format(dampeningApplyLog, p4))
        end },
        { time = 14, func = function()
            print("Test: You get Arcane Dampening (Should get marked and bar)")
            module:AfflictionEvent(string.format(dampeningApplyLog, "You")) -- Use "You" for self affliction trigger
        end },
		{ time = 18, func = function()
            print("Test: Arcane Dampening Fades from "..p3.." (Mark should be removed)")
            module:AuraGoneEvent(string.format(dampeningFadeLog, p3))
        end },
		{ time = 20, func = function()
            print("Test: "..p5.." gets Arcane Overload (Skull) - P4 should keep their Dampening mark")
            module:AfflictionEvent(p5 .. " is afflicted by Arcane Overload")
        end },
        { time = 22, func = function()
            print("Test: Arcane Dampening Fades from You (Mark and bar should be removed)")
            -- Simulate the AURA_GONE_SELF event *containing* the correct log line text
            module:AuraGoneEvent(string.format(dampeningFadeLog, selfPlayer))
        end },
		{ time = 25, func = function()
            print("Test: "..p4.." dies while dampened (Mark should be removed)")
            module:OnFriendlyDeath(p4 .. " dies.")
        end },
        { time = 27, func = function()
            print("Test: "..p5.." (bomb target) gets dampened (should get NON-SKULL mark)")
            module:AfflictionEvent(string.format(dampeningApplyLog, p5))
        end },
        { time = 29, func = function()
            print("Test: "..p2.." gets bomb (Skull) - "..p5.." should retain their non-skull mark.")
            module:AfflictionEvent(p2 .. " is afflicted by Arcane Overload")
        end },
        { time = 31, func = function()
             print("Test: Dampening fades from "..p5);
             module:AuraGoneEvent(string.format(dampeningFadeLog, p5))
        end },

		-- Manabound Fade (Keep for context)
		{ time = 40, func = function() print("Test: Manabound Fades from "..p1); module:AuraGoneEvent("Manabound Strikes fades from " .. p1) end },

		-- Disengage
		{ time = 45, func = function() print("Test: Disengage"); module:Disengage() end },
	}

	-- Schedule each event at its absolute time
	for i, event in ipairs(events) do
		self:ScheduleEvent("AnomalusTest" .. i, event.func, event.time)
	end

	self:Message("Anomalus test started (with Dampening focus)", "Positive")
	return true
end


-- Test command:
-- /run local m=BigWigs:GetModule("Anomalus"); if m then BigWigs:SetupModule("Anomalus"); m:Test() else print("Anomalus module not found") end