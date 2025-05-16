local module, L = BigWigs:ModuleDeclaration("Mephistroth", "Karazhan")

module.revision = 30001
module.enabletrigger = module.translatedName
module.toggleoptions = {
    "shacklescasting",
    "shacklesdebuffdisplay",
    "shardsofhellfury",
    "nathrezimterror",
    "doomofoutlanddecurse",
    "sleepparalysisdispel",
    "sleepparalysismark",
    "bosskill"
}
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
	AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
	"Outland",
	"???"
}

local _, playerClass = UnitClass("player")

module.defaultDB = {
	shacklescasting = true,
    shacklesdebuffdisplay = true,
    shardsofhellfury = true,
    nathrezimterror = true,
    doomofoutlanddecurse = (playerClass == "MAGE" or playerClass == "DRUID"),
    sleepparalysisdispel = (playerClass == "PALADIN" or playerClass == "PRIEST"),
    sleepparalysismark = true,
    bosskill = true,
}

L:RegisterTranslations("enUS", function()
	return {
		cmd = "Mephistroth",

		engage_trigger = "I foresaw your arrival, did you not think I watched your adventures within the tower of Karazhan?",
		victory_trigger = "This can not be! My purpose is brought to ruin...",
		victory_message = "Mephistroth Defeated!",

		bosskill_cmd = "bosskill",
		bosskill_name = "Boss Kills",
		bosskill_desc = "Show messages for boss kills.",

        shacklescasting_cmd = "shacklescasting",
        shacklescasting_name = "Shackles Cast Warning",
        shacklescasting_desc = "Warns all players when Mephistroth begins casting Shackles of the Legion.",

        shacklesdebuffdisplay_cmd = "shacklesdebuffdisplay",
        shacklesdebuffdisplay_name = "Shackles Debuff Display",
        shacklesdebuffdisplay_desc = "Shows alerts and timers when you are affected by Shackles of the Legion.",

        shardsofhellfury_cmd = "shardsofhellfury",
        shardsofhellfury_name = "Shards of Hellfury Cast Warning",
        shardsofhellfury_desc = "Warns when Mephistroth casts Shards of Hellfury.",

        nathrezimterror_cmd = "nathrezimterror",
        nathrezimterror_name = "Nathrezim Terror Cast Warning",
        nathrezimterror_desc = "Warns when Mephistroth casts Nathrezim Terror.",

        doomofoutlanddecurse_cmd = "doomofoutlanddecurse",
        doomofoutlanddecurse_name = "Doom of Outland Decurse (Mage/Druid)",
        doomofoutlanddecurse_desc = "Shows a clickable bar to decurse Doom of Outland.",

        sleepparalysisdispel_cmd = "sleepparalysisdispel",
        sleepparalysisdispel_name = "Sleep Paralysis Dispel (Paladin/Priest)",
        sleepparalysisdispel_desc = "Shows a clickable bar to dispel Sleep Paralysis.",

        sleepparalysismark_cmd = "sleepparalysismark",
        sleepparalysismark_name = "Mark Sleep Paralysis Target",
        sleepparalysismark_desc = "Marks players affected by Sleep Paralysis with a raid icon.",

        msg_shacklesCasting = "!!! STOP MOVING !!!",
        bar_shacklesCasting = "Casting Shackles!",
        alert_shacklesCastingSign = "STOP MOVING!",

        msg_shardsCasting = "Shards of Hellfury incoming!",
        bar_shardsCasting = "Casting Shards of Hellfury!",

        msg_terrorCasting = "Nathrezim Terror incoming!",
        bar_terrorCasting = "Casting Nathrezim Terror!",

        trigger_shacklesAppliedYou = "You are afflicted by Shackles of the Legion",
        trigger_shacklesAppliedOther = "(.+) is afflicted by Shackles of the Legion",
        trigger_shacklesFadedYou = "Shackles of the Legion fades from you",
        trigger_shacklesFadedOther = "Shackles of the Legion fades from (.+)%.",

        msg_shacklesOnYou = "You are SHACKLED! Don't move!",
        bar_shacklesDurationOnYou = "YOUR Shackles - Don't Move!",
        alert_shacklesDebuffSign = "SHACKLED - NO MOVE",

        trigger_doomAppliedYou = "You are afflicted by Doom of Outland %(%d+%)%.",
        trigger_doomAppliedOther = "(.+) is afflicted by Doom of Outland %(%d+%)%.",
        trigger_doomFaded = "Doom of Outland fades from (.+)%.",

        msg_doomOnYou = "Doom of Outland on YOU!",
        msg_doomOnOther = "Doom of Outland on %s!",
        bar_doomDecursePrefix = "Decurse Doom: ",

        trigger_sleepAppliedYou = "You are afflicted by Sleep Paralysis %(%d+%)%.",
        trigger_sleepAppliedOther = "(.+) is afflicted by Sleep Paralysis %(%d+%)%.",
        trigger_sleepFaded = "Sleep Paralysis fades from (.+)%.",

        msg_sleepOnYou = "Sleep Paralysis on YOU!",
        msg_sleepOnOther = "Sleep Paralysis on %s!",
        bar_sleepDispelPrefix = "Dispel Sleep: ",
	}
end)

local timer = {
    shacklesDefaultCastFallback = 2.5,
    shacklesDebuffDuration = 6,
    shardsDefaultCastFallback = 3.0,
    terrorDefaultCastFallback = 2.5,
    doomDuration = 7,
    sleepParalysisDuration = 15,
}

local icon = {
    shackles = "INV_Belt_18",
    shards = "Spell_Fire_SoulBurn",
    terror = "Spell_Shadow_DeathCoil",
    doom = "Spell_Shadow_NightOfTheDead",
    sleepParalysis = "Spell_Shadow_AntiShadow",
}

local spellId = {
    ShacklesOfTheLegionCast = 51916,
    ShardsOfHellfury = 51942,
    NathrezimTerror = 51907,
}

local syncName = {
    shacklesCastDetected = "MephShacklesCastV" .. module.revision,
    shacklesDebuffLanded = "MephShacklesDebuffLandedV" .. module.revision,
    shacklesDebuffRemoved = "MephShacklesDebuffRemovedV" .. module.revision,
    shardsCastDetected = "MephShardsCastV" .. module.revision,
    terrorCastDetected = "MephTerrorCastV" .. module.revision,
    doomApplied = "MephDoomAppliedV" .. module.revision,
    doomFaded = "MephDoomFadedV" .. module.revision,
    sleepApplied = "MephSleepAppliedV" .. module.revision,
    sleepFaded = "MephSleepFadedV" .. module.revision,
}

--------------------------------------------------------------------------------
-- Initialisation
--------------------------------------------------------------------------------

function module:OnEnable()
	self:RegisterYellEngage(L["engage_trigger"])
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")

    if SUPERWOW_STRING or SetAutoloot then
        self:RegisterEvent("UNIT_CASTEVENT", "HandleUnitCastEvent")
    end

    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "HandleAfflictionEvent")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "HandleAfflictionEvent")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "HandleAfflictionEvent")

    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "HandleAuraGoneEvent")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "HandleAuraGoneEvent")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "HandleAuraGoneEvent")

    self:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLY_DEATH", "HandleFriendlyDeath")

	self:ThrottleSync(0.5, syncName.shacklesCastDetected)
    self:ThrottleSync(0.5, syncName.shacklesDebuffLanded)
    self:ThrottleSync(0.5, syncName.shacklesDebuffRemoved)
    self:ThrottleSync(0.5, syncName.shardsCastDetected)
    self:ThrottleSync(0.5, syncName.terrorCastDetected)
    self:ThrottleSync(0.5, syncName.doomApplied)
    self:ThrottleSync(0.5, syncName.doomFaded)
    self:ThrottleSync(0.5, syncName.sleepApplied)
    self:ThrottleSync(0.5, syncName.sleepFaded)
end

function module:OnSetup()
	self.started = nil
end

function module:OnEngage()
	self.started = true
end

function module:OnDisengage()
	self.started = false
end

--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

function module:CHAT_MSG_MONSTER_YELL(msg, sender)
	if self.started and sender == self.translatedName and msg == L["victory_trigger"] then
		self:Victory()
	end
end

function module:HandleUnitCastEvent(casterGuid, targetGuid, eventType, spellIdCasted, castTimeMs)
    if eventType == "START" or eventType == "CHANNEL" then
        local castDurationSec
        if spellIdCasted == spellId.ShacklesOfTheLegionCast then
            if not self.db.profile.shacklescasting then return end
            castDurationSec = timer.shacklesDefaultCastFallback
            if castTimeMs and castTimeMs > 0 then castDurationSec = castTimeMs / 1000 end
            self:Sync(syncName.shacklesCastDetected .. " " .. castDurationSec)
        elseif spellIdCasted == spellId.ShardsOfHellfury then
            if not self.db.profile.shardsofhellfury then return end
            castDurationSec = timer.shardsDefaultCastFallback
            if castTimeMs and castTimeMs > 0 then castDurationSec = castTimeMs / 1000 end
            self:Sync(syncName.shardsCastDetected .. " " .. castDurationSec)
        elseif spellIdCasted == spellId.NathrezimTerror then
            if not self.db.profile.nathrezimterror then return end
            castDurationSec = timer.terrorDefaultCastFallback
            if castTimeMs and castTimeMs > 0 then castDurationSec = castTimeMs / 1000 end
            self:Sync(syncName.terrorCastDetected .. " " .. castDurationSec)
        end
    end
end

function module:HandleAfflictionEvent(msg)
    if string.find(msg, L["trigger_shacklesAppliedYou"]) then
        self:Sync(syncName.shacklesDebuffLanded .. " " .. UnitName("player"))
    elseif string.find(msg, L["trigger_shacklesAppliedOther"]) then
        local _, _, shacklesPlayer = string.find(msg, L["trigger_shacklesAppliedOther"])
        if shacklesPlayer then self:Sync(syncName.shacklesDebuffLanded .. " " .. shacklesPlayer) end
    elseif string.find(msg, L["trigger_doomAppliedYou"]) then
        self:Sync(syncName.doomApplied .. " " .. UnitName("player"))
    elseif string.find(msg, L["trigger_doomAppliedOther"]) then
        local _, _, doomPlayer = string.find(msg, L["trigger_doomAppliedOther"])
        if doomPlayer then self:Sync(syncName.doomApplied .. " " .. doomPlayer) end
    elseif string.find(msg, L["trigger_sleepAppliedYou"]) then
        self:Sync(syncName.sleepApplied .. " " .. UnitName("player"))
    elseif string.find(msg, L["trigger_sleepAppliedOther"]) then
        local _, _, sleepPlayer = string.find(msg, L["trigger_sleepAppliedOther"])
        if sleepPlayer then self:Sync(syncName.sleepApplied .. " " .. sleepPlayer) end
    end
end

function module:HandleAuraGoneEvent(msg)
    if string.find(msg, L["trigger_shacklesFadedYou"]) then
        self:Sync(syncName.shacklesDebuffRemoved .. " " .. UnitName("player"))
    elseif string.find(msg, L["trigger_shacklesFadedOther"]) then
        local _, _, shacklesPlayer = string.find(msg, L["trigger_shacklesFadedOther"])
        if shacklesPlayer then self:Sync(syncName.shacklesDebuffRemoved .. " " .. shacklesPlayer) end
    elseif string.find(msg, L["trigger_doomFaded"]) then
        local _, _, doomPlayer = string.find(msg, L["trigger_doomFaded"])
        if doomPlayer then
            if doomPlayer == "you" then doomPlayer = UnitName("player") end
            self:Sync(syncName.doomFaded .. " " .. doomPlayer)
        end
    elseif string.find(msg, L["trigger_sleepFaded"]) then
        local _, _, sleepPlayer = string.find(msg, L["trigger_sleepFaded"])
        if sleepPlayer then
            if sleepPlayer == "you" then sleepPlayer = UnitName("player") end
            self:Sync(syncName.sleepFaded .. " " .. sleepPlayer)
        end
    end
end

function module:HandleFriendlyDeath(msg)
    local _, _, playerName = string.find(msg, "(.+) dies")
    if playerName then
        self:Sync(syncName.shacklesDebuffRemoved .. " " .. playerName)
        self:Sync(syncName.doomFaded .. " " .. playerName)
        self:Sync(syncName.sleepFaded .. " " .. playerName)
    end
end

function module:BigWigs_RecvSync(sync, rest, nick)
    if sync == syncName.shacklesCastDetected then
        if self.db.profile.shacklescasting and rest then
            local castDuration = tonumber(rest) or timer.shacklesDefaultCastFallback
            self:TriggerShacklesCastWarning(castDuration)
        end
    elseif sync == syncName.shacklesDebuffLanded then
        if self.db.profile.shacklesdebuffdisplay and rest and rest == UnitName("player") then
            self:TriggerMyShacklesDebuffWarning()
        end
    elseif sync == syncName.shacklesDebuffRemoved then
        if self.db.profile.shacklesdebuffdisplay and rest and rest == UnitName("player") then
            self:RemoveMyShacklesDebuffDisplay()
        end
    elseif sync == syncName.shardsCastDetected then
        if self.db.profile.shardsofhellfury and rest then
            local castDuration = tonumber(rest) or timer.shardsDefaultCastFallback
            self:TriggerShardsCastWarning(castDuration)
        end
    elseif sync == syncName.terrorCastDetected then
        if self.db.profile.nathrezimterror and rest then
            local castDuration = tonumber(rest) or timer.terrorDefaultCastFallback
            self:TriggerTerrorCastWarning(castDuration)
        end
    elseif sync == syncName.doomApplied and rest then
        self:TriggerDoomWarning(rest)
    elseif sync == syncName.doomFaded and rest then
        self:RemoveDoomDisplay(rest)
    elseif sync == syncName.sleepApplied and rest then
        self:TriggerSleepParalysisWarning(rest)
    elseif sync == syncName.sleepFaded and rest then
        self:RemoveSleepParalysisDisplay(rest)
    end
end

--------------------------------------------------------------------------------
-- Ability Specific Functions
--------------------------------------------------------------------------------

function module:TriggerShacklesCastWarning(castDuration)
    self:Message(L["msg_shacklesCasting"], "Important")
    self:Bar(L["bar_shacklesCasting"], castDuration, icon.shackles, true, "Red")
    self:WarningSign(icon.shackles, castDuration, true, L["alert_shacklesCastingSign"])
    self:Sound("Beware")
end

function module:TriggerMyShacklesDebuffWarning()
    self:Bar(L["bar_shacklesDurationOnYou"], timer.shacklesDebuffDuration, icon.shackles)
    self:Message(L["msg_shacklesOnYou"], "Urgent", true, "Alarm")
    self:WarningSign(icon.shackles, timer.shacklesDebuffDuration, true, L["alert_shacklesDebuffSign"])
end

function module:RemoveMyShacklesDebuffDisplay()
    self:RemoveBar(L["bar_shacklesDurationOnYou"])
end

function module:TriggerShardsCastWarning(castDuration)
    self:Message(L["msg_shardsCasting"], "Attention")
    self:Bar(L["bar_shardsCasting"], castDuration, icon.shards, true, "Orange")
end

function module:TriggerTerrorCastWarning(castDuration)
    self:Message(L["msg_terrorCasting"], "Attention")
    self:Bar(L["bar_terrorCasting"], castDuration, icon.terror, true, "Purple")
end

function module:TriggerDoomWarning(playerName)
    local isSelf = (playerName == UnitName("player"))

    if isSelf then
        if self.db.profile.doomofoutlanddecurse then
            self:Message(L["msg_doomOnYou"], "Important", nil, "Alarm")
        end
    else
        if self.db.profile.doomofoutlanddecurse then
            self:Message(string.format(L["msg_doomOnOther"], playerName), "Attention")
        end
    end

    if self.db.profile.doomofoutlanddecurse then
        local barText = L["bar_doomDecursePrefix"] .. playerName
        local spellToCast
        if playerClass == "MAGE" then spellToCast = "Remove Lesser Curse"
        elseif playerClass == "DRUID" then spellToCast = "Remove Curse" end
        
        if spellToCast then
            self:Bar(barText, timer.doomDuration, icon.doom, true, "Yellow")
            self:SetCandyBarOnClick("BigWigsBar " .. barText, function(_, _, afflictedName)
                local previousTargetName = UnitName("target")
                TargetByName(afflictedName, true)
                CastSpellByName(spellToCast)
                if previousTargetName then TargetByName(previousTargetName) else ClearTarget() end
            end, playerName)
        end
    end
end

function module:RemoveDoomDisplay(playerName)
    if self.db.profile.doomofoutlanddecurse and (playerClass == "MAGE" or playerClass == "DRUID") then
        local barText = L["bar_doomDecursePrefix"] .. playerName
        self:RemoveBar(barText)
    end
end

function module:TriggerSleepParalysisWarning(playerName)
    local isSelf = (playerName == UnitName("player"))

    -- Raid Marking
    if self.db.profile.sleepparalysismark then
        local markToUse = self:GetAvailableRaidMark()
        if markToUse then
            self:SetRaidTargetForPlayer(playerName, markToUse)
        end
    end

    -- Messages
    if isSelf then
        if self.db.profile.sleepparalysisdispel then
            self:Message(L["msg_sleepOnYou"], "Important", nil, "Alarm")
        end
    else
        if self.db.profile.sleepparalysisdispel then
            self:Message(string.format(L["msg_sleepOnOther"], playerName), "Attention")
        end
    end

    -- Clickable Bar for Dispel
    if self.db.profile.sleepparalysisdispel then
        local barText = L["bar_sleepDispelPrefix"] .. playerName
        local spellToCast
        if playerClass == "PALADIN" then spellToCast = "Cleanse"
        elseif playerClass == "PRIEST" then spellToCast = "Dispel Magic" end
        
        if spellToCast then
            self:Bar(barText, timer.sleepParalysisDuration, icon.sleepParalysis, true, "Cyan")
            self:SetCandyBarOnClick("BigWigsBar " .. barText, function(_, _, afflictedName)
                local previousTargetName = UnitName("target")
                TargetByName(afflictedName, true)
                CastSpellByName(spellToCast)
                if previousTargetName then TargetByName(previousTargetName) else ClearTarget() end
            end, playerName)
        end
    end
end

function module:RemoveSleepParalysisDisplay(playerName)
    -- Raid Mark Removal
    if self.db.profile.sleepparalysismark then
        self:RestorePreviousRaidTargetForPlayer(playerName)
    end

    -- Bar Removal
    if self.db.profile.sleepparalysisdispel and (playerClass == "PALADIN" or playerClass == "PRIEST") then
        local barText = L["bar_sleepDispelPrefix"] .. playerName
        self:RemoveBar(barText)
    end
end

--------------------------------------------------------------------------------
-- Victory Function
--------------------------------------------------------------------------------
function module:Victory()
    if self.started then
        if self.db.profile.bosskill then
            self:Message(L["victory_message"], "Bosskill", nil, "Victory")
        end
        BigWigsBossRecords:EndBossfight(self)
        self.core:DisableModule(self:ToString())
    end
end

--------------------------------------------------------------------------------
-- Test Function
--------------------------------------------------------------------------------
function module:Test()
	self:OnSetup()
    self:Engage()

    local player = UnitName("player")
    local otherPlayer1 = UnitName("raid1") or "TestRaid1"
    local otherPlayer2 = UnitName("raid2") or "TestRaid2"
    local otherPlayer3 = UnitName("raid3") or "TestRaid3WithMark"
    local mephistrothGuid = "Creature-0-0-0-0-12345-Mephistroth" -- Example GUID

    DEFAULT_CHAT_FRAME:AddMessage("Mephistroth Test (Improved Version) started", "System")

    local currentTime = 0 -- Start time at 0 for easier relative scheduling
    local originalPlayerClass = playerClass -- Save original class
    local originalDoomDecurseProfile = self.db.profile.doomofoutlanddecurse
    local originalSleepDispelProfile = self.db.profile.sleepparalysisdispel

    -- Helper for test scheduling
    local function ScheduleTestEvent(delay, description, eventFunc)
        currentTime = currentTime + delay
        DEFAULT_CHAT_FRAME:AddMessage(string.format("TEST (%.1fs): %s", currentTime, description), "System")
        self:ScheduleEvent("MephTestEvent_" .. currentTime, eventFunc, currentTime)
    end

    ScheduleTestEvent(2, "Sim UNIT_CASTEVENT for Shackles.", function()
        module:HandleUnitCastEvent(mephistrothGuid, nil, "START", spellId.ShacklesOfTheLegionCast, 2500)
    end)
    ScheduleTestEvent(3, "Sim UNIT_CASTEVENT for Shards.", function()
        module:HandleUnitCastEvent(mephistrothGuid, nil, "START", spellId.ShardsOfHellfury, 3000)
    end)
    ScheduleTestEvent(4, "Sim UNIT_CASTEVENT for Terror.", function()
        module:HandleUnitCastEvent(mephistrothGuid, nil, "START", spellId.NathrezimTerror, 2500)
    end)

    ScheduleTestEvent(3, "Sim Shackles on YOU.", function()
        module:HandleAfflictionEvent(L["trigger_shacklesAppliedYou"])
    end)
    ScheduleTestEvent(timer.shacklesDebuffDuration + 0.5, "Sim Shackles FADE for YOU.", function()
        module:HandleAuraGoneEvent(L["trigger_shacklesFadedYou"])
    end)

    local afflictedByDoom = otherPlayer1
    ScheduleTestEvent(2, "Sim Doom on " .. afflictedByDoom .. ".", function()
        playerClass = "MAGE" -- Simulate being a Mage for this part
        self.db.profile.doomofoutlanddecurse = true -- Ensure option is on
        module:HandleAfflictionEvent(string.format("%s is afflicted by Doom of Outland (1).", afflictedByDoom))
        if self.db.profile.doomofoutlanddecurse then
            DEFAULT_CHAT_FRAME:AddMessage("TEST INFO: If Mage/Druid, try clicking 'Decurse Doom: "..afflictedByDoom.."' bar.", "System")
        end
    end)
    ScheduleTestEvent(timer.doomDuration + 0.5, "Sim Doom FADE for " .. afflictedByDoom .. ".", function()
        module:HandleAuraGoneEvent(string.format("Doom of Outland fades from %s.", afflictedByDoom))
        playerClass = originalPlayerClass -- Restore class
        self.db.profile.doomofoutlanddecurse = originalDoomDecurseProfile -- Restore profile
    end)

    ScheduleTestEvent(2, "Sim Sleep Paralysis on " .. otherPlayer3 .. " (should get raid mark).", function()
        playerClass = "PRIEST" -- Simulate being a Priest
        self.db.profile.sleepparalysisdispel = true -- Ensure option is on
        self.db.profile.sleepparalysismark = true
        module:HandleAfflictionEvent(string.format("%s is afflicted by Sleep Paralysis (1).", otherPlayer3))
         if self.db.profile.sleepparalysisdispel then
            DEFAULT_CHAT_FRAME:AddMessage("TEST INFO: If Paladin/Priest, try clicking 'Dispel Sleep: "..otherPlayer3.."' bar.", "System")
        end
    end)
    ScheduleTestEvent(timer.sleepParalysisDuration + 0.5, "Sim Sleep Paralysis FADE for " .. otherPlayer3 .. " (mark should be removed).", function()
        module:HandleAuraGoneEvent(string.format("Sleep Paralysis fades from %s.", otherPlayer3))
        playerClass = originalPlayerClass
        self.db.profile.sleepparalysisdispel = originalSleepDispelProfile
    end)

    ScheduleTestEvent(2, "Sim Doom & Sleep on " .. otherPlayer2 .. " before death.", function()
        self.db.profile.doomofoutlanddecurse = true
        self.db.profile.sleepparalysisdispel = true
        self.db.profile.sleepparalysismark = true
        module:HandleAfflictionEvent(string.format("%s is afflicted by Doom of Outland (1).", otherPlayer2))
        module:HandleAfflictionEvent(string.format("%s is afflicted by Sleep Paralysis (1).", otherPlayer2))
    end)
    ScheduleTestEvent(timer.doomDuration / 2, "Sim " .. otherPlayer2 .. " DIES (Doom/Sleep bars & marks should be removed).", function()
        module:HandleFriendlyDeath(otherPlayer2 .. " dies.")
        self.db.profile.doomofoutlanddecurse = originalDoomDecurseProfile
        self.db.profile.sleepparalysisdispel = originalSleepDispelProfile
    end)

	ScheduleTestEvent(2, "Simulating Victory Yell.", function()
		module:CHAT_MSG_MONSTER_YELL(L["victory_trigger"], self.translatedName)
	end)
	ScheduleTestEvent(2, "Mephistroth Test Complete. Check BigWigs and chat.", function()
        -- Restore original class just in case any test part failed to do so
        playerClass = originalPlayerClass
        self.db.profile.doomofoutlanddecurse = originalDoomDecurseProfile
        self.db.profile.sleepparalysisdispel = originalSleepDispelProfile
    end)
	return true
end