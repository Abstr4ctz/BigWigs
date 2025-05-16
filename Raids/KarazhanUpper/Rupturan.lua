local module, L = BigWigs:ModuleDeclaration("Rupturan the Broken", "Karazhan")

module.revision = 30001
module.enabletrigger = module.translatedName
module.toggleoptions = {
    "burningflesh",
    "livingstone",
    "dirtmound",
    "flamestrike",
    "bosskill"
}
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
	AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
	"Outland",
	"???"
}

local _, playerClass = UnitClass("player")
local dirtMoundTarget = nil -- Stores the name of the player targeted by Dirt Mound

module.defaultDB = {
	burningflesh = (playerClass == "PALADIN" or playerClass == "PRIEST"), -- Enabled by default for dispellers
    livingstone = true,
    dirtmound = true,
    flamestrike = true,
    bosskill = true,
}

L:RegisterTranslations("enUS", function()
	return {
		cmd = "Rupturan",

        -- Core Triggers & Messages
        engage_trigger = "All shall crumble...",
        victory_trigger = "Perished... To dust.",
        victory_message = "Rupturan Defeated!",
        trigger_phase2Yell = "Let the cracks of this world destroy you",

		-- Toggle Options: Bosskill
		bosskill_cmd = "bosskill",
		bosskill_name = "Boss Kills",
		bosskill_desc = "Show messages for boss kills.",
		
        -- Toggle Options & Strings: Burning Flesh
		burningflesh_cmd = "burningflesh",
		burningflesh_name = "Burning Flesh Alert & Dispel",
		burningflesh_desc = "Warns when players are afflicted by Burning Flesh. Clickable bar for Priests/Paladins.",
		trigger_burningFleshYou = "You are afflicted by Burning Flesh %(%d+%)%.",
		trigger_burningFleshOther = "(.+) is afflicted by Burning Flesh %(%d+%)%.",
		trigger_burningFleshFadeYou = "Burning Flesh fades from you%.",
		trigger_burningFleshFadeOther = "Burning Flesh fades from (.+)%.",
        msg_burningFleshOnYou = "Burning Flesh on YOU!",
        msg_burningFleshOnOther = "Burning Flesh on %s!",
        bar_dispelBurningFlesh = "Dispel BF: ",

        -- Toggle Options & Strings: Living Stone
		livingstone_cmd = "livingstone",
		livingstone_name = "Living Stone Stomp Alert",
		livingstone_desc = "Shows a timer for Living Stone's stomp after Crash Landing fades.",
        trigger_crashLandingFades = "Crash Landing fades from Living Stone",
        msg_livingStoneStompIncoming = "Living Stone STOMP soon!",
        bar_livingStoneStomp = "Living Stone STOMP",

        -- Toggle Options & Strings: Dirt Mound
		dirtmound_cmd = "dirtmound",
		dirtmound_name = "Dirt Mound Alerts",
		dirtmound_desc = "Warns for Dirt Mound Quake and when a Dirt Mound targets a player.",
        trigger_dirtMoundQuakeYou = "Dirt Mound's Quake .?.its (.+) for",
        trigger_dirtMoundSpawnEmote = "Rupturan commands the earth to crush (.+)!",
        msg_dirtMoundQuakeYou = "Dirt Mound Quake on YOU - MOVE!",
        msg_dirtMoundTargetYou = "Dirt Mound chasing YOU!",
        msg_dirtMoundTargetOtherNear = "Get away from diamond!",
        say_dirtMoundOnMe = "Dirt Mound on ME - Stay Away!",

        -- Toggle Options & Strings: Flamestrike
		flamestrike_cmd = "flamestrike",
		flamestrike_name = "Flamestrike Alert",
		flamestrike_desc = "Warns when Flamestrike (Ignite Rock) is casting.",
        msg_flamestrikeCasting = "Flamestrike incoming!",
        bar_flamestrikeCast = "Flamestrike Cast",
	}
end)

local timer = {
	burningFleshDuration = 15,
    livingStoneStomp = 5,
    flamestrikeCast = 3,
}

local icon = {
	burningFlesh = "Spell_Fire_Immolation",
    livingStoneStomp = "Ability_ThunderClap",
    dirtMoundQuake = "Spell_Nature_Earthquake",
    flamestrike = "Spell_Fire_SelfDestruct",
}

local color = {
    burningFlesh = "Orange",
    livingStoneStomp = "Red",
    flamestrike = "Red",
}

local syncName = {
	burningFleshApplied = "RupturanBurningFleshApplied" .. module.revision,
	burningFleshFaded = "RupturanBurningFleshFaded" .. module.revision,
    livingStoneStomp = "RupturanLivingStoneStomp" .. module.revision,
    dirtMoundSpawn = "RupturanDirtMoundSpawn" .. module.revision,
    flamestrike = "RupturanFlamestrike" .. module.revision,
    phase2 = "RupturanPhase2" .. module.revision,
}

--------------------------------------------------------------------------------
-- Module Lifecycle
--------------------------------------------------------------------------------

function module:OnEnable()
    -- Core Event Registration
	self:RegisterYellEngage(L["engage_trigger"])
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "MonsterYellHandler")
    self:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLY_DEATH", "HandleFriendlyDeath")

    -- Burning Flesh Event Registration
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "BurningFleshAfflictionHandler")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "BurningFleshAfflictionHandler")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "BurningFleshAfflictionHandler")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "BurningFleshFadeHandler")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "BurningFleshFadeHandler")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "BurningFleshFadeHandler")

    -- Other Ability Event Registration
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "CrashLandingFadeHandler")
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "DirtMoundQuakeHandler")
    self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE", "DirtMoundSpawnHandler")

    if SUPERWOW_VERSION or SetAutoloot then
		self:RegisterEvent("UNIT_CASTEVENT", "UnitCastEventHandler")
	end

	self:ThrottleSync(1, syncName.burningFleshApplied)
	self:ThrottleSync(2, syncName.burningFleshFaded)
    self:ThrottleSync(2, syncName.livingStoneStomp)
    self:ThrottleSync(2, syncName.dirtMoundSpawn)
    self:ThrottleSync(2, syncName.flamestrike)
    self:ThrottleSync(2, syncName.phase2)
end

function module:OnSetup()
	self.started = nil
    dirtMoundTarget = nil
end

function module:OnEngage()
	self.started = true
    dirtMoundTarget = nil
end

function module:OnDisengage()
	self.started = false
    if dirtMoundTarget then
        self:RestorePreviousRaidTargetForPlayer(dirtMoundTarget)
        dirtMoundTarget = nil
    end
end

--------------------------------------------------------------------------------
-- Core Event Parsers (Combat Log, Emotes, Yells)
--------------------------------------------------------------------------------

-- Handles boss yells for victory and phase transitions.
function module:MonsterYellHandler(msg, sender)
	if sender == self.translatedName then
        if msg == L["victory_trigger"] then
            self:Victory()
        elseif msg == L["trigger_phase2Yell"] then
            self:Sync(syncName.phase2)
        end
    end
end

-- Handles Burning Flesh affliction messages.
function module:BurningFleshAfflictionHandler(msg)
    if string.find(msg, L["trigger_burningFleshYou"]) then
        self:Sync(syncName.burningFleshApplied .. " " .. UnitName("player"))
    else
        local _, _, playerName = string.find(msg, L["trigger_burningFleshOther"])
        if playerName then
            self:Sync(syncName.burningFleshApplied .. " " .. playerName)
        end
    end
end

-- Handles Burning Flesh fade messages.
function module:BurningFleshFadeHandler(msg)
    if string.find(msg, L["trigger_burningFleshFadeYou"]) then
        self:Sync(syncName.burningFleshFaded .. " " .. UnitName("player"))
    elseif string.find(msg, L["trigger_burningFleshFadeOther"]) then
        local _, _, playerName = string.find(msg, L["trigger_burningFleshFadeOther"])
        if playerName then
            self:Sync(syncName.burningFleshFaded .. " " .. playerName)
        end
    end
end

-- Handles player deaths to clean up associated warnings.
function module:HandleFriendlyDeath(msg)
    local _, _, playerName = string.find(msg, "(.+) dies")
    if playerName then
        self:Sync(syncName.burningFleshFaded .. " " .. playerName)

        if dirtMoundTarget == playerName then
            self:RestorePreviousRaidTargetForPlayer(dirtMoundTarget)
            dirtMoundTarget = nil
        end
    end
end

-- Handles Crash Landing fade for Living Stone stomp.
function module:CrashLandingFadeHandler(msg)
    if string.find(msg, L["trigger_crashLandingFades"]) then
        if self.db.profile.livingstone then
		    self:Sync(syncName.livingStoneStomp)
        end
	end
end

-- Handles Dirt Mound Quake hitting the player.
function module:DirtMoundQuakeHandler(msg)
    if string.find(msg, L["trigger_dirtMoundQuakeYou"]) then
        if self.db.profile.dirtmound then
		    self:ShowDirtMoundQuakeWarning()
        end
	end
end

-- Handles Dirt Mound spawn emote.
function module:DirtMoundSpawnHandler(msg)
    local _,_,player = string.find(msg, L["trigger_dirtMoundSpawnEmote"])
    if player then
        if self.db.profile.dirtmound then
			self:Sync(syncName.dirtMoundSpawn .. " " .. player)
        end
	end
end

-- Handles UNIT_CASTEVENT for abilities like Flamestrike.
function module:UnitCastEventHandler(_, _, eventType, spellIdCasted, castTimeMs)
    if spellIdCasted == 51298 and eventType == "START" then
        if self.db.profile.flamestrike then
            local castDurationSec = timer.flamestrikeCast
            if castTimeMs and castTimeMs > 0 then
                castDurationSec = castTimeMs / 1000
            end
            self:Sync(syncName.flamestrike .. " " .. castDurationSec)
        end
	end
end

--------------------------------------------------------------------------------
-- Sync Receiver
--------------------------------------------------------------------------------

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.burningFleshApplied and rest then
		self:ShowBurningFleshWarning(rest)
	elseif sync == syncName.burningFleshFaded and rest then
		self:RemoveBurningFleshWarning(rest)
    elseif sync == syncName.livingStoneStomp then
        self:ShowLivingStoneStompWarning()
    elseif sync == syncName.dirtMoundSpawn and rest then
        self:ShowDirtMoundSpawnWarning(rest)
    elseif sync == syncName.flamestrike and rest then
        local castTime = tonumber(rest) or timer.flamestrikeCast
        self:ShowFlamestrikeWarning(castTime)
    elseif sync == syncName.phase2 then
        self:HandlePhase2Transition()
	end
end

--------------------------------------------------------------------------------
-- Ability Warning Functions (Called by Sync Receiver or Direct Handlers)
--------------------------------------------------------------------------------

-- Shows warnings and bar for Burning Flesh.
function module:ShowBurningFleshWarning(playerName)
    if not self.db.profile.burningflesh then return end

    if playerName == UnitName("player") then
        self:Message(L["msg_burningFleshOnYou"], "Important", nil, "Alarm")
    else
        self:Message(string.format(L["msg_burningFleshOnOther"], playerName), "Attention")
    end
	
	local barText = L["bar_dispelBurningFlesh"] .. playerName
	local spellToCast
	if playerClass == "PALADIN" then spellToCast = "Cleanse"
	elseif playerClass == "PRIEST" then spellToCast = "Dispel Magic" end
	
	self:Bar(barText, timer.burningFleshDuration, icon.burningFlesh, true, color.burningFlesh)

    if spellToCast then
        self:SetCandyBarOnClick("BigWigsBar " .. barText, function(_, _, afflictedPlayerName)
            local previousTargetName = UnitName("target")
            TargetByName(afflictedPlayerName, true)
            CastSpellByName(spellToCast)
            if previousTargetName then TargetByName(previousTargetName) else ClearTarget() end
        end, playerName)
    end
end

-- Removes bar for Burning Flesh.
function module:RemoveBurningFleshWarning(playerName)
    self:RemoveBar(L["bar_dispelBurningFlesh"] .. playerName)
end

-- Shows warnings for Living Stone Stomp.
function module:ShowLivingStoneStompWarning()
	if not self.db.profile.livingstone then return end
	self:Message(L["msg_livingStoneStompIncoming"], "Attention", nil, "Alarm")
	self:Bar(L["bar_livingStoneStomp"], timer.livingStoneStomp, icon.livingStoneStomp, true, color.livingStoneStomp)
end

-- Shows warning for player being hit by Dirt Mound Quake.
function module:ShowDirtMoundQuakeWarning()
	self:Message(L["msg_dirtMoundQuakeYou"], "Important", nil, "Alarm")
    self:WarningSign(icon.dirtMoundQuake, 3, true, L["msg_dirtMoundQuakeYou"])
end

-- Shows warnings and manages raid target for Dirt Mound spawn.
function module:ShowDirtMoundSpawnWarning(playerName)
	if not self.db.profile.dirtmound or not playerName then return end

    if dirtMoundTarget then
        self:RestorePreviousRaidTargetForPlayer(dirtMoundTarget)
    end

	self:SetRaidTargetForPlayer(playerName, 3) -- Diamond icon
	dirtMoundTarget = playerName

	if playerName == UnitName("player") then
		self:Message(L["msg_dirtMoundTargetYou"], "Urgent", nil, "RunAway")
        self:WarningSign(icon.dirtMoundQuake, 5, true, L["msg_dirtMoundTargetYou"])
	    SendChatMessage(L["say_dirtMoundOnMe"], "SAY")
	else
		for i=1, GetNumRaidMembers() do -- Proximity check
			local unit = "raid"..i
			if UnitExists(unit) and UnitName(unit) == playerName and CheckInteractDistance(unit, 2) then
				self:Message(L.msg_dirtMoundTargetOtherNear, "Important")
				self:Sound("Alarm")
				break
			end
		end
	end
end

-- Shows warnings for Flamestrike.
function module:ShowFlamestrikeWarning(castTime)
	if not self.db.profile.flamestrike then return end

    self:Message(L["msg_flamestrikeCasting"], "Attention", nil, "Alarm")
	self:WarningSign(icon.flamestrike, castTime, true, L["bar_flamestrikeCast"])
	self:Bar(L["bar_flamestrikeCast"], castTime, icon.flamestrike, true, color.flamestrike)
end

-- Handles logic for Phase 2 transition.
function module:HandlePhase2Transition()
    if dirtMoundTarget then
        self:RestorePreviousRaidTargetForPlayer(dirtMoundTarget)
        dirtMoundTarget = nil
    end
end

--------------------------------------------------------------------------------
-- Victory
--------------------------------------------------------------------------------
function module:Victory()
	if self.db.profile.bosskill then
		self:Message(L["victory_message"], "Bosskill", nil, "Victory")
	end
	BigWigsBossRecords:EndBossfight(self)
	self.core:DisableModule(self:ToString())
end