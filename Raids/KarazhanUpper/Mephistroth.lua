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
	if not self.started then return end
	if sender == self.translatedName and msg == L["victory_trigger"] then
		self:Victory()
	end
end

function module:HandleUnitCastEvent(casterGuid, targetGuid, eventType, spellIdCasted, castTimeMs)
    if not self.started then return end
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
    if not self.started then return end

    if string.find(msg, L["trigger_shacklesAppliedYou"]) then
        self:Sync(syncName.shacklesDebuffLanded .. " " .. UnitName("player"))
        return
    else
        local _, _, shacklesPlayer = string.find(msg, L["trigger_shacklesAppliedOther"])
        if shacklesPlayer then
            self:Sync(syncName.shacklesDebuffLanded .. " " .. shacklesPlayer)
            return
        end
    end

    if string.find(msg, L["trigger_doomAppliedYou"]) then
        self:Sync(syncName.doomApplied .. " " .. UnitName("player"))
        return
    else
        local _, _, doomPlayer = string.find(msg, L["trigger_doomAppliedOther"])
        if doomPlayer then
            self:Sync(syncName.doomApplied .. " " .. doomPlayer)
            return
        end
    end

    if string.find(msg, L["trigger_sleepAppliedYou"]) then
        self:Sync(syncName.sleepApplied .. " " .. UnitName("player"))
        return
    else
        local _, _, sleepPlayer = string.find(msg, L["trigger_sleepAppliedOther"])
        if sleepPlayer then
            self:Sync(syncName.sleepApplied .. " " .. sleepPlayer)
            return
        end
    end
end

function module:HandleAuraGoneEvent(msg)
    if not self.started then return end

    if string.find(msg, L["trigger_shacklesFadedYou"]) then
        self:Sync(syncName.shacklesDebuffRemoved .. " " .. UnitName("player"))
        return
    else
        local _, _, shacklesPlayer = string.find(msg, L["trigger_shacklesFadedOther"])
        if shacklesPlayer then
            self:Sync(syncName.shacklesDebuffRemoved .. " " .. shacklesPlayer)
            return
        end
    end

    local _, _, doomPlayer = string.find(msg, L["trigger_doomFaded"])
    if doomPlayer then
        if doomPlayer == "you" then doomPlayer = UnitName("player") end
        self:Sync(syncName.doomFaded .. " " .. doomPlayer)
        return
    end

    local _, _, sleepPlayer = string.find(msg, L["trigger_sleepFaded"])
    if sleepPlayer then
        if sleepPlayer == "you" then sleepPlayer = UnitName("player") end
        self:Sync(syncName.sleepFaded .. " " .. sleepPlayer)
        return
    end
end

function module:HandleFriendlyDeath(msg)
    if not self.started then return end
    local _, _, playerName = string.find(msg, "(.+) dies")
    if playerName then
        self:Sync(syncName.shacklesDebuffRemoved .. " " .. playerName)
        self:Sync(syncName.doomFaded .. " " .. playerName)
        self:Sync(syncName.sleepFaded .. " " .. playerName)
    end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if not self.started then return end

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
    elseif sync == syncName.doomApplied then
        if rest then
            self:TriggerDoomWarning(rest)
        end
    elseif sync == syncName.doomFaded then
        if rest then
            self:RemoveDoomDisplay(rest)
        end
    elseif sync == syncName.sleepApplied then
        if rest then
            self:TriggerSleepParalysisWarning(rest)
        end
    elseif sync == syncName.sleepFaded then
        if rest then
            self:RemoveSleepParalysisDisplay(rest)
        end
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
    if playerName == UnitName("player") then
        self:Message(L["msg_doomOnYou"], "Important", nil, "Alarm")
    else
        if self.db.profile.doomofoutlanddecurse and (playerClass == "MAGE" or playerClass == "DRUID") then
            self:Message(string.format(L["msg_doomOnOther"], playerName), "Attention")
        end
    end

    if self.db.profile.doomofoutlanddecurse and (playerClass == "MAGE" or playerClass == "DRUID") then
        local barText = L["bar_doomDecursePrefix"] .. playerName
        local spellToCast
        if playerClass == "MAGE" then spellToCast = "Remove Lesser Curse"
        elseif playerClass == "DRUID" then spellToCast = "Remove Curse" end
        if spellToCast then
            self:Bar(barText, timer.doomDuration, icon.doom, true, "Yellow")
            self:SetCandyBarOnClick("BigWigsBar " .. barText, function(c,m,afflicted) TargetByName(afflicted,true) CastSpellByName(spellToCast) end, playerName)
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
    if self.db.profile.sleepparalysismark then
        local markToUse = self:GetAvailableRaidMark()
        if markToUse then
            self:SetRaidTargetForPlayer(playerName, markToUse)
        end
    end

    if playerName == UnitName("player") then
        self:Message(L["msg_sleepOnYou"], "Important", nil, "Alarm")
    else
        if self.db.profile.sleepparalysisdispel and (playerClass == "PALADIN" or playerClass == "PRIEST") then
            self:Message(string.format(L["msg_sleepOnOther"], playerName), "Attention")
        end
    end

    if self.db.profile.sleepparalysisdispel and (playerClass == "PALADIN" or playerClass == "PRIEST") then
        local barText = L["bar_sleepDispelPrefix"] .. playerName
        local spellToCast
        if playerClass == "PALADIN" then spellToCast = "Cleanse"
        elseif playerClass == "PRIEST" then spellToCast = "Dispel Magic" end
        if spellToCast then
            self:Bar(barText, timer.sleepParalysisDuration, icon.sleepParalysis, true, "Cyan")
            self:SetCandyBarOnClick("BigWigsBar " .. barText, function(c,m,afflicted) TargetByName(afflicted,true) CastSpellByName(spellToCast) end, playerName)
        end
    end
end

function module:RemoveSleepParalysisDisplay(playerName)
    if self.db.profile.sleepparalysismark then
        self:RestorePreviousRaidTargetForPlayer(playerName)
    end

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
    local mephistrothGuid = "Creature-0-0-0-0-12345-Mephistroth"

    DEFAULT_CHAT_FRAME:AddMessage("Mephistroth Test (All Abilities) started", "System")

    local currentTime = 2

    -- Cast Sequence
    self:ScheduleEvent("Test_Cast_Shackles", function()
        DEFAULT_CHAT_FRAME:AddMessage("TEST: Sim UNIT_CASTEVENT for Shackles.", "System")
        module:HandleUnitCastEvent(mephistrothGuid, nil, "START", spellId.ShacklesOfTheLegionCast, 2500)
    end, currentTime); currentTime = currentTime + 3

    self:ScheduleEvent("Test_Cast_Shards", function()
        DEFAULT_CHAT_FRAME:AddMessage("TEST: Sim UNIT_CASTEVENT for Shards.", "System")
        module:HandleUnitCastEvent(mephistrothGuid, nil, "START", spellId.ShardsOfHellfury, 3000)
    end, currentTime); currentTime = currentTime + 4

    self:ScheduleEvent("Test_Cast_Terror", function()
        DEFAULT_CHAT_FRAME:AddMessage("TEST: Sim UNIT_CASTEVENT for Terror.", "System")
        module:HandleUnitCastEvent(mephistrothGuid, nil, "START", spellId.NathrezimTerror, 2500)
    end, currentTime); currentTime = currentTime + 3

    -- Shackles Debuff Cycle on Self
    self:ScheduleEvent("Test_Shackles_Self_Debuff", function()
        DEFAULT_CHAT_FRAME:AddMessage("TEST: Sim Shackles on YOU.", "System")
        module:HandleAfflictionEvent(L["trigger_shacklesAppliedYou"]) -- This trigger is a fixed string for "self"
    end, currentTime);
    self:ScheduleEvent("Test_Shackles_Self_Fade", function()
        DEFAULT_CHAT_FRAME:AddMessage("TEST: Sim Shackles FADE for YOU.", "System")
        module:HandleAuraGoneEvent(L["trigger_shacklesFadedYou"]) -- This trigger is also a fixed string for "self"
    end, currentTime + timer.shacklesDebuffDuration + 0.5); currentTime = currentTime + timer.shacklesDebuffDuration + 2


    -- Doom of Outland Cycle
    local afflictedByDoom = otherPlayer1
    self:ScheduleEvent("Test_Doom_Other_Applied", function()
        DEFAULT_CHAT_FRAME:AddMessage("TEST: Sim Doom on " .. afflictedByDoom .. ".", "System")
        -- L["trigger_doomAppliedOther"] = "(.+) is afflicted by Doom of Outland %(%d+%)%."
        -- We need to construct a string that matches this pattern.
        local log_msg = string.format("%s is afflicted by Doom of Outland (1).", afflictedByDoom)
        module:HandleAfflictionEvent(log_msg)
    end, currentTime)

    self:ScheduleEvent("Test_Doom_Other_ClickBar_Info", function()
        if self.db.profile.doomofoutlanddecurse and (playerClass == "MAGE" or playerClass == "DRUID") then
            DEFAULT_CHAT_FRAME:AddMessage("TEST INFO: If Mage/Druid, try clicking 'Decurse Doom: "..afflictedByDoom.."' bar.", "System")
        end
    end, currentTime + 1)

    self:ScheduleEvent("Test_Doom_Other_Faded", function()
        DEFAULT_CHAT_FRAME:AddMessage("TEST: Sim Doom FADE for " .. afflictedByDoom .. ".", "System")
        -- L["trigger_doomFaded"] = "Doom of Outland fades from (.+)%."
        local log_msg = string.format("Doom of Outland fades from %s.", afflictedByDoom)
        module:HandleAuraGoneEvent(log_msg)
    end, currentTime + timer.doomDuration + 0.5); currentTime = currentTime + timer.doomDuration + 2


    -- Sleep Paralysis with Marking on otherPlayer3
    self:ScheduleEvent("Test_Sleep_Other_Applied_Mark", function()
        DEFAULT_CHAT_FRAME:AddMessage("TEST: Sim Sleep Paralysis on " .. otherPlayer3 .. " (should get raid mark).", "System")
        -- L["trigger_sleepAppliedOther"] = "(.+) is afflicted by Sleep Paralysis %(%d+%)%."
        local log_msg = string.format("%s is afflicted by Sleep Paralysis (1).", otherPlayer3)
        module:HandleAfflictionEvent(log_msg)
    end, currentTime)

    self:ScheduleEvent("Test_Sleep_Other_ClickBar_Info", function()
         if self.db.profile.sleepparalysisdispel and (playerClass == "PALADIN" or playerClass == "PRIEST") then
            DEFAULT_CHAT_FRAME:AddMessage("TEST INFO: If Paladin/Priest, try clicking 'Dispel Sleep: "..otherPlayer3.."' bar.", "System")
        end
    end, currentTime + 1)

    self:ScheduleEvent("Test_Sleep_Other_Faded_Mark", function()
        DEFAULT_CHAT_FRAME:AddMessage("TEST: Sim Sleep Paralysis FADE for " .. otherPlayer3 .. " (mark should be removed).", "System")
        -- L["trigger_sleepFaded"] = "Sleep Paralysis fades from (.+)%."
        local log_msg = string.format("Sleep Paralysis fades from %s.", otherPlayer3)
        module:HandleAuraGoneEvent(log_msg)
    end, currentTime + timer.sleepParalysisDuration + 0.5); currentTime = currentTime + timer.sleepParalysisDuration + 2


    -- Player Death Test
    self:ScheduleEvent("Test_PlayerDeath_All_Debuffs", function()
        DEFAULT_CHAT_FRAME:AddMessage("TEST: Sim Doom on " .. otherPlayer2 .. ".", "System")
        local doom_log_msg = string.format("%s is afflicted by Doom of Outland (1).", otherPlayer2)
        module:HandleAfflictionEvent(doom_log_msg)

        DEFAULT_CHAT_FRAME:AddMessage("TEST: Sim Sleep on " .. otherPlayer2 .. ".", "System")
        local sleep_log_msg = string.format("%s is afflicted by Sleep Paralysis (1).", otherPlayer2)
        module:HandleAfflictionEvent(sleep_log_msg)
    end, currentTime)

    self:ScheduleEvent("Test_PlayerDeath_Actual", function()
        DEFAULT_CHAT_FRAME:AddMessage("TEST: Sim " .. otherPlayer2 .. " DIES (Doom/Sleep bars & marks should be removed).", "System")
        module:HandleFriendlyDeath(otherPlayer2 .. " dies.")
    end, currentTime + (timer.doomDuration / 2) ); currentTime = currentTime + (timer.doomDuration / 2) + 2


	self:ScheduleEvent("Test_Victory", function()
		DEFAULT_CHAT_FRAME:AddMessage("TEST: Simulating Victory Yell.", "System")
		self:CHAT_MSG_MONSTER_YELL(L["victory_trigger"], self.translatedName)
	end, currentTime)
	self:ScheduleEvent("Test_End", function()
		DEFAULT_CHAT_FRAME:AddMessage("Mephistroth Test Complete. Check BigWigs and chat.", "System")
	end, currentTime + 2)
	return true
end
