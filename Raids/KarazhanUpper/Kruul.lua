local module, L = BigWigs:ModuleDeclaration("Kruul", "Karazhan")

-- module variables
module.revision = 30001
module.enabletrigger = module.translatedName
module.toggleoptions = {
    "bosskill",
    "callfromnether",
    "decursealert",
    "markofthelord",
    "markofthelordmark",
    "remorselessdebuff",
    "remorsestrikes",
    "tauntresistalert",
    "taunttracking",
    "proximity"
}

module.zonename = {
    AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
    AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
    "Outland",
    "???"
}

local _, playerClass = UnitClass("player")
local find = string.find
local gsub = string.gsub
local ipairs = ipairs
local pairs = pairs
local UnitName = UnitName

-- module defaults
module.defaultDB = {
    bosskill = true,
    callfromnether = false,
    decursealert = (playerClass == "MAGE" or playerClass == "DRUID"),
    markofthelord = true,
    markofthelordmark = true,
    remorselessdebuff = (playerClass == "WARRIOR" or playerClass == "DRUID" or playerClass == "PALADIN" or
        playerClass == "SHAMAN"),
    remorsestrikes = playerClass ~= "MAGE" and playerClass ~= "WARLOCK" and playerClass ~= "HUNTER",
    tauntresistalert = (playerClass == "WARRIOR" or playerClass == "DRUID" or playerClass == "PALADIN"),
    taunttracking = (playerClass ~= "MAGE" and playerClass ~= "WARLOCK" and playerClass ~= "HUNTER" and
        playerClass ~= "PRIEST"),
    proximity = playerClass ~= "WARRIOR" and playerClass ~= "ROGUE"
}

local syncName = {
    markofthelord = "KruulMarkOfTheLord" .. module.revision,
    markofthelordFade = "KruulMarkOfTheLordFade" .. module.revision,
    remorselessStrikes = "KruulRemorselessStrikes" .. module.revision,
    tauntApplied = "KruulTauntApplied" .. module.revision
}

-- localization
L:RegisterTranslations(
    "enUS",
    function()
        return {
            -- General Command
            cmd = "Kruul",
            -- Engage/Death/Enrage Triggers & Messages
            trigger_engage = "Stepping before the High Lord of the Burning Legion",
            trigger_death_yell = "I shall see you again, mortals.",
            msg_kruulDown = "Highlord Kruul Defeated!",
            trigger_wrathOfTheHighlord = "Kruul gains Wrath of the Highlord",
            msg_wrathOfTheHighlord = "Kruul is ENRAGED - Good luck!",
            -- Bosskill Feature
            bosskill_cmd = "bosskill",
            bosskill_name = "Boss Defeated Alert",
            bosskill_desc = "Shows an alert when Kruul is defeated.",
            -- Call From Nether Feature
            callfromnether_cmd = "callfromnether",
            callfromnether_name = "Nether Infernal Alert & Timer",
            callfromnether_desc = "Timer/Alert for Nether Infernal (stops on Enrage).",
            bar_callfromnether = "Next Infernal",
            msg_callfromnether = "Nether Infernal Spawned!",
            -- Mark of the Highlord Feature (Includes Decurse)
            markofthelord_cmd = "markofthelord",
            markofthelord_name = "Mark of the Highlord Alert",
            markofthelord_desc = "Warns when players get afflicted by Mark of the Highlord.",
            trigger_markofthelordYou = "You are afflicted by Mark of the Highlord",
            trigger_markofthelordOther = "(.+) is afflicted by Mark of the Highlord",
            trigger_markofthelordFade = "Mark of the Highlord fades from you",
            trigger_markofthelordFadeOther = "Mark of the Highlord fades from (.+)",
            msg_markofthelordYou = "Mark of the Highlord on YOU - GET OUT!",
            msg_markofthelordOther = "Mark of the Highlord on %s!",
            bar_markofthelordExpires = "Mark on YOU! GET OUT!",
            bar_nextCurses = "Next Mark of the Highlord",
            -- Mark of the Highlord - Raid Mark Sub-feature
            markofthelordmark_cmd = "markofthelordmark",
            markofthelordmark_name = "Mark of the Highlord Raid Mark",
            markofthelordmark_desc = "Marks players with Mark of the Highlord and restores previous mark when it fades.",
            -- Mark of the Highlord - Decurse Alert Sub-feature
            decursealert_cmd = "decursealert",
            decursealert_name = "Decurse Reminder (Mage/Druid)",
            decursealert_desc = "Shows a message and clickable bar reminding you to decurse Mark of the Highlord.",
            bar_decurse_prefix = "CLICK ME > ",
            -- Remorseless Strikes & Debuff Feature
            remorsestrikes_cmd = "remorsestrikes",
            remorsestrikes_name = "Next Remorseless Strikes Alert",
            remorsestrikes_desc = "Shows a timer for Kruul's next Remorseless Strikes.",
            trigger_remorselessStrikes = "Kruul's Remorseless Strikes",
            bar_nextRemorselessStrikes = "Next Remorseless Strikes",
            remorselessdebuff_cmd = "remorselessdebuff",
            remorselessdebuff_name = "Remorseless Debuff Timer (Self)",
            remorselessdebuff_desc = "Personal timer, resets on Remorseless Strikes hits/misses on YOU. Warns on expiry.",
            bar_remorselessDebuff = "Time Since Last Strike",
            msg_tauntNow = "TAUNT NOW! (Remorseless Debuff Expired)",
            -- Taunt Tracking & Resist Alert Feature
            taunttracking_cmd = "taunttracking",
            taunttracking_name = "Taunt Timer Bar",
            taunttracking_desc = "Shows a timer bar when Kruul is taunted.",
            trigger_tauntGains = "^Kruul gains (.+)%.?$",
            trigger_tauntAfflicted = "^Kruul is afflicted by (.+)%.?$",
            bar_taunt_prefix = "Taunt: ",
            tauntresistalert_cmd = "tauntresistalert",
            tauntresistalert_name = "Taunt Resist Alert",
            tauntresistalert_desc = "Alerts when a taunt is resisted by Kruul.",
            trigger_tauntResistYou = "^Your (.+) was resisted by Kruul%.?$",
            trigger_tauntResistOther = "^([^%s']+)%'s (.+) was resisted by Kruul%.?$",
            msg_tauntResistYou = "YOUR Taunt Resisted!",
            msg_tauntResistOther = "%s's Taunt Resisted!",
            sound_tauntResist = "Info",
            warnSign_tauntResistedYou = "YOUR TAUNT RESISTED!",
            warnSign_tauntResistedOther_suffix = "'s TAUNT RESISTED!",
            -- Proximity Warning Feature
            proximity_cmd = "proximity",
            proximity_name = "Proximity Warning",
            proximity_desc = "Show Proximity Warning Frame",
            -- Sync Messages
            sync_markofthelord = syncName.markofthelord .. "(.+)",
            sync_markofthelordfade = syncName.markofthelordFade .. "(.+)"
        }
    end
)

module.proximityCheck = function(unit)
    return CheckInteractDistance(unit, 2)
end
module.proximitySilent = true

module:RegisterYellEngage(L.trigger_engage)

local timer = {
    markofthelordDuration = 20,
    nextCurses = 30,
    nextCursesEnraged = 15,
    firstRemorselessStrikes = 2,
    remorselessStrikes = 4,
    callfromnether = 25,
    remorselessDebuffDuration = 25,
    signTauntResistDuration = 2
}

local icon = {
    markofthelord = "Spell_Shadow_AntiShadow",
    nextCurses = "Spell_Shadow_AntiShadow",
    remorselessStrikes = "Spell_Shadow_RaiseDead",
    callfromnether = "Spell_Shadow_SummonInfernal",
    decurse = "Spell_Nature_RemoveCurse",
    remorselessDebuff = "Spell_Shadow_RaiseDead",
    tauntWarrior = "Spell_Nature_Reincarnation",
    growlDruid = "Ability_Physical_Taunt",
    challengingShout = "Ability_BullRush",
    mockingBlow = "Ability_Warrior_PunishingBlow",
    challengingRoar = "Ability_Druid_ChallengingRoar",
    slamShaman = "Spell_Nature_EarthQuake",
    reckoningPaladin = "Spell_Holy_Redemption"
}

local color = {
    red = "Red",
    orange = "Orange",
    purple = "Purple"
}

local tauntSpells = {
    ["Taunt"] = {duration = 3, iconKey = "tauntWarrior"},
    ["Growl"] = {duration = 3, iconKey = "growlDruid"},
    ["Challenging Shout"] = {duration = 6, iconKey = "challengingShout"},
    ["Mocking Blow"] = {duration = 6, iconKey = "mockingBlow"},
    ["Challenging Roar"] = {duration = 6, iconKey = "challengingRoar"},
    ["Earthshaker Slam"] = {duration = 3, iconKey = "slamShaman"},
    ["Hand of Reckoning"] = {duration = 3, iconKey = "reckoningPaladin"}
}

local function GetBaseSpellName(capturedString)
    if not capturedString then
        return nil
    end
    local baseName = capturedString
    baseName = gsub(baseName, "%.?$", "")
    baseName = gsub(baseName, "%s*%([^)]*%)$", "")
    baseName = gsub(baseName, "%s*$", "")
    baseName = gsub(baseName, "^%s*", "")
    return baseName
end

function module:OnEnable()
    self:RegisterEvent("CHAT_MSG_MONSTER_YELL")

    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "AfflictionEvent_MarkOfTheLord")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "AfflictionEvent_MarkOfTheLord")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "AuraGoneEvent_MarkOfTheLord")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "AuraGoneEvent_MarkOfTheLord")
    self:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLY_DEATH", "OnFriendlyDeath_MarkOfTheLord")

    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "RemorselessStrikeDamage_Self")
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", "RemorselessStrikeDamage_Party")
    self:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES", "RemorselessStrikeMiss_Self")

    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "BossBuffEvent")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_APPLIED_CREATURE", "BossBuffEvent")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE", "BossBuffEvent")
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "BossBuffEvent")
    
    self:RegisterEvent("CHAT_MSG_SPELL_PARTY_DAMAGE", "TauntResistEvent")
    self:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE", "TauntResistEvent")

    self:ThrottleSync(1, syncName.remorselessStrikes)
    self:ThrottleSync(0.5, syncName.tauntApplied)
end

function module:OnSetup()
    self.started = false
    self.enragePhase = false
    self.isInfernalTimerActive = false
    if self.db.profile.proximity then
        self:Proximity()
    end
end

function module:OnEngage()
    self.started = true
    self.enragePhase = false
    self.isInfernalTimerActive = false

    if self.db.profile.markofthelord then
        self:Bar(L["bar_nextCurses"], timer.nextCurses, icon.nextCurses)
    end
    if self.db.profile.remorsestrikes then
        self:Bar(L["bar_nextRemorselessStrikes"], timer.firstRemorselessStrikes, icon.remorselessStrikes)
    end
    if self.db.profile.callfromnether then
        self:Bar(L["bar_callfromnether"], timer.callfromnether, icon.callfromnether)
        self:ScheduleRepeatingEvent(
            "Kruul_RepeatingInfernalTimer",
            self.HandleInfernalSpawn,
            timer.callfromnether,
            self
        )
        self.isInfernalTimerActive = true
    end
    if self.db.profile.proximity then
        self:Proximity()
    end
end

function module:OnDisengage()
    self.started = false
    self:RemoveProximity()
    self:CancelScheduledEvent("KruulRemorselessDebuff_Expired_Event")
    self:RemoveBar(L["bar_remorselessDebuff"])
    self:CancelScheduledEvent("Kruul_RepeatingInfernalTimer")
    self:RemoveBar(L["bar_callfromnether"])
    self.isInfernalTimerActive = false
end

function module:Victory()
    if self.started then
        if self.db.profile.bosskill then
            self:Message(self.translatedName .. " has been defeated! (Fallback Msg)", "Bosskill", nil)
        end
        BigWigsBossRecords:EndBossfight(self)
        self.core:DisableModule(self:ToString())
    end
end

function module:CHAT_MSG_MONSTER_YELL(msg, sender)
    if not self.started then
        return
    end
    if sender == self.translatedName and msg == L["trigger_death_yell"] then
        self:Victory()
    end
end

function module:HandleInfernalSpawn()
    if not (self.db.profile.callfromnether and self.started) then
        if self.isInfernalTimerActive then
            self:CancelScheduledEvent("Kruul_RepeatingInfernalTimer")
            self:RemoveBar(L["bar_callfromnether"])
            self.isInfernalTimerActive = false
        end
        return
    end

    self:Message(L["msg_callfromnether"], "Attention", nil, "Alert")
    self:Bar(L["bar_callfromnether"], timer.callfromnether, icon.callfromnether)
end

function module:RemorselessStrikeDamage_Self(msg)
    if not self.started then
        return
    end
    if find(msg, L["trigger_remorselessStrikes"]) then
        self:Sync(syncName.remorselessStrikes)
        if self.db.profile.remorselessdebuff then
            self:ResetRemorselessDebuffTimer()
        end
    end
end

function module:RemorselessStrikeDamage_Party(msg)
    if not self.started then
        return
    end
    if find(msg, L["trigger_remorselessStrikes"]) then
        self:Sync(syncName.remorselessStrikes)
    end
end

function module:RemorselessStrikeMiss_Self(msg)
    if not self.started then
        return
    end
    if find(msg, L["trigger_remorselessStrikes"]) and self.db.profile.remorselessdebuff then
        self:ResetRemorselessDebuffTimer()
    end
end

function module:ResetRemorselessDebuffTimer()
    if not self.started or not self.db.profile.remorselessdebuff then
        return
    end
    self:CancelScheduledEvent("KruulRemorselessDebuff_Expired_Event")
    local scheduleHandle =
        self:ScheduleEvent(
        "KruulRemorselessDebuff_Expired_Event",
        self.HandleRemorselessDebuffExpired,
        timer.remorselessDebuffDuration,
        self
    )
    self:Bar(L["bar_remorselessDebuff"], timer.remorselessDebuffDuration, icon.remorselessDebuff)
end

function module:HandleRemorselessDebuffExpired()
    if not (self and self.db and self.db.profile) then
        return
    end
    if not self.started or not self.db.profile.remorselessdebuff then
        return
    end
    self:Message(L["msg_tauntNow"], "Urgent", nil, "Alarm")
end

function module:ProcessRemorselessStrikes()
    if not self.started or not self.db.profile.remorsestrikes then
        return
    end
    self:Bar(L["bar_nextRemorselessStrikes"], timer.remorselessStrikes, icon.remorselessStrikes)
end

function module:BossBuffEvent(msg)
    if not self.started then return end

    -- Check for Enrage
    if not self.enragePhase and find(msg, L["trigger_wrathOfTheHighlord"]) then
        self.enragePhase = true
        if self.db.profile.markofthelord then
            self:Message(L["msg_wrathOfTheHighlord"], "Important", nil, "Alarm")
        end
        -- Stop infernal timer on enrage
        if self.isInfernalTimerActive then
            self:CancelScheduledEvent("Kruul_RepeatingInfernalTimer")
            self:RemoveBar(L["bar_callfromnether"])
            self.isInfernalTimerActive = false
        end
    end

    -- Check for Taunt Affliction/Gain
    if self.db.profile.taunttracking then
        local capturedAfflictionSpell
        local _, _, gainSpell = find(msg, L["trigger_tauntGains"])
        if gainSpell and find(msg, "^Kruul gains") then
            capturedAfflictionSpell = gainSpell
        else
            local _, _, afflictedSpell = find(msg, L["trigger_tauntAfflicted"])
            if afflictedSpell and find(msg, "^Kruul is afflicted by") then
                capturedAfflictionSpell = afflictedSpell
            end
        end

        if capturedAfflictionSpell then
            local baseSpellName = GetBaseSpellName(capturedAfflictionSpell)
            if baseSpellName and tauntSpells[baseSpellName] then
                if UnitName("target") == self.translatedName then
                    local taunterName = UnitName("targettarget")
                    if taunterName then
                        self:Sync(syncName.tauntApplied .. " " .. baseSpellName .. " " .. taunterName)
                    end
                end
                return
            end
        end
    end
end

function module:ProcessTauntApplied(spellName, taunterName)
    if not self.started or not self.db.profile.taunttracking then
        return
    end

    local tauntData = tauntSpells[spellName]
    if tauntData then
        local duration = tauntData.duration
        local iconKey = tauntData.iconKey
        local actualIconPath = icon[iconKey] or icon.tauntWarrior
        local barText = L["bar_taunt_prefix"] .. taunterName .. " (" .. spellName .. ")"

        self:Bar(barText, duration, actualIconPath)
    end
end

function module:TauntResistEvent(msg)
    if not self.started or not self.db.profile.tauntresistalert then
        return
    end
    if not find(msg, "resisted by Kruul") then
        return
    end

    local playerName, capturedSpellName, isSelfResist
    local _, _, yourSpell = find(msg, L["trigger_tauntResistYou"])
    if yourSpell then
        playerName = UnitName("player")
        capturedSpellName = yourSpell
        isSelfResist = true
    else
        local _, _, otherPlayer, otherSpell = find(msg, L["trigger_tauntResistOther"])
        if otherPlayer and otherSpell and otherPlayer ~= "Your" then
            playerName = otherPlayer
            capturedSpellName = otherSpell
            isSelfResist = false
        end
    end

    if playerName and capturedSpellName then
        local baseSpellName = GetBaseSpellName(capturedSpellName)
        if baseSpellName and tauntSpells[baseSpellName] then
            local message
            local warningSignText
            local tauntData = tauntSpells[baseSpellName]
            local actualIconPath = icon[tauntData.iconKey] or icon.tauntWarrior

            if isSelfResist then
                message = L["msg_tauntResistYou"]
                warningSignText = L["warnSign_tauntResistedYou"]
            else
                message = string.format(L["msg_tauntResistOther"], playerName)
                warningSignText = playerName .. L["warnSign_tauntResistedOther_suffix"]
            end

            self:Message(message, "Attention", nil, L["sound_tauntResist"])
            self:WarningSign(actualIconPath, timer.signTauntResistDuration, true, warningSignText)
        end
    end
end

function module:AfflictionEvent_MarkOfTheLord(msg)
    if not self.started then
        return
    end
    if find(msg, L["trigger_markofthelordYou"]) then
        self:Sync(syncName.markofthelord .. UnitName("player"))
    else
        local _, _, player = find(msg, L["trigger_markofthelordOther"])
        if player then
            self:Sync(syncName.markofthelord .. player)
        end
    end
end

function module:AuraGoneEvent_MarkOfTheLord(msg)
    if not self.started then
        return
    end
    if find(msg, L["trigger_markofthelordFade"]) then
        self:Sync(syncName.markofthelordFade .. UnitName("player"))
        self:RemoveBar(L["bar_markofthelordExpires"])
        if self.db.profile.decursealert and (playerClass == "MAGE" or playerClass == "DRUID") then
            self:RemoveBar(L["bar_decurse_prefix"] .. UnitName("player"))
        end
    else
        local _, _, player = find(msg, L["trigger_markofthelordFadeOther"])
        if player then
            self:Sync(syncName.markofthelordFade .. player)
            if self.db.profile.decursealert and (playerClass == "MAGE" or playerClass == "DRUID") then
                self:RemoveBar(L["bar_decurse_prefix"] .. player)
            end
        end
    end
end

function module:OnFriendlyDeath_MarkOfTheLord(msg)
    if not self.started then
        return
    end
    local _, _, player = find(msg, "(.+) dies")
    if player then
        self:Sync(syncName.markofthelordFade .. player)
        if self.db.profile.decursealert and (playerClass == "MAGE" or playerClass == "DRUID") then
            self:RemoveBar(L["bar_decurse_prefix"] .. player)
        end
    end
end

function module:MarkOfTheLord(player)
    if not self.started or not self.db.profile.markofthelord then
        return
    end
    if player == UnitName("player") then
        self:Sound("Beware")
        self:Message(L["msg_markofthelordYou"], "Important", nil, "Alarm")
        self:WarningSign(icon.markofthelord, 5, true, "GET OUT")
        self:Bar(L["bar_markofthelordExpires"], timer.markofthelordDuration, icon.markofthelord, true, color.red)
    else
        self:Message(string.format(L["msg_markofthelordOther"], player), "Important", nil, "Alert")
    end

    if self.db.profile.decursealert and (playerClass == "MAGE" or playerClass == "DRUID") then
        local barText = L["bar_decurse_prefix"] .. player
        local spellToCast
        if playerClass == "MAGE" then
            spellToCast = "Remove Lesser Curse"
        elseif playerClass == "DRUID" then
            spellToCast = "Remove Curse"
        end

        if spellToCast then
            self:Bar(barText, timer.markofthelordDuration, icon.decurse)
            self:SetCandyBarOnClick(
                "BigWigsBar " .. barText,
                function(clickedBarName, mouseButton, afflictedPlayerName)
                    TargetByName(afflictedPlayerName, true)
                    CastSpellByName(spellToCast)
                end,
                player
            )
        end
    end

    self:RemoveBar(L["bar_nextCurses"])
    -- Mark of the Highlord timing changes during enrage
    local nextCurseTimerValue = self.enragePhase and timer.nextCursesEnraged or timer.nextCurses
    self:Bar(L["bar_nextCurses"], nextCurseTimerValue, icon.nextCurses)

    if self.db.profile.markofthelordmark then
        self:SetCurseMark(player)
    end
end

function module:MarkOfTheLordFade(player)
    if not self.started then
        return
    end
    if self.db.profile.markofthelordmark then
        self:RestoreMark(player)
    end
    if self.db.profile.decursealert and (playerClass == "MAGE" or playerClass == "DRUID") then
        self:RemoveBar(L["bar_decurse_prefix"] .. player)
    end
end

function module:SetCurseMark(player)
    local markToUse = self:GetAvailableRaidMark()
    if markToUse then
        self:SetRaidTargetForPlayer(player, markToUse)
    end
end

function module:RestoreMark(player)
    self:RestorePreviousRaidTargetForPlayer(player)
end

function module:BigWigs_RecvSync(sync, rest, nick)
    if not self.started then return end

    if sync == syncName.remorselessStrikes then
        self:ProcessRemorselessStrikes()
        return
    end

    if sync == syncName.tauntApplied then
        local tauntSpell, taunter
        local safeRest = rest or "" 

        for knownSpell, _ in pairs(tauntSpells) do
            local pattern = "^%s*" .. knownSpell .. "%s+(.+)$"
            local _, _, capturedTaunter = find(safeRest, pattern)
            if capturedTaunter then
                tauntSpell = knownSpell
                taunter = capturedTaunter
                break 
            end
        end

        if tauntSpell and taunter then
            self:ProcessTauntApplied(tauntSpell, taunter)
            return
        end
    end

    local _, _, markedPlayer = find(sync, L["sync_markofthelord"])
    if markedPlayer then
        self:MarkOfTheLord(markedPlayer)
        return
    end

    local _, _, unmarkedPlayer = find(sync, L["sync_markofthelordfade"])
    if unmarkedPlayer then
        self:MarkOfTheLordFade(unmarkedPlayer)
        return
    end
end

function module:Test()
	self:OnSetup()
	self:Engage()
    local testTarget = self.translatedName
    local player = UnitName("player")
    local tankA = UnitName("raid1") or "TankA"
    local tankB = UnitName("raid2") or "TankB"
    local cursedPlayer = UnitName("raid4") or "CursedGuy"
    local magePlayer = UnitName("raid5") or "MageDecurser"

	print("------------------------------------------")
	print("BigWigs Kruul Taunt Logic Test Started")
	print("------------------------------------------")
    print("Note: This test simulates COMBAT LOG messages and BigWigs SYNC messages.")
    print("      Ensure 'Taunt Timer Bar' & 'Taunt Resist Alert' options are ON for Kruul in /bw.")
    print("      For sync sending test, target an NPC named 'Kruul' when prompted.")
	print("------------------------------------------")

	local events = {
        { time = 0.1, func = function() print("[Test] Initial bars for Kruul should be present.") end },
        { time = 2, func = function()
            print("[Test] Simulating Remorseless Strikes on player.")
            module:RemorselessStrikeDamage_Self("Kruul's Remorseless Strikes hits You for 2000 Physical damage.")
        end },
        { time = 5, func = function()
            print("[Test] Simulating Mark of the Highlord on CursedGuy.")
            module:AfflictionEvent_MarkOfTheLord(cursedPlayer .. " is afflicted by Mark of the Highlord.")
        end },

        -- Taunt Logic - Scenario 1: TankA Taunts (Player targets Kruul)
        { time = 10, func = function()
            print("\n[Taunt Test 1] Scenario: Player targets "..testTarget..", TankA Taunts (basic).")
            DEFAULT_CHAT_FRAME:AddMessage(" >>>> Test Setup: Please TARGET '"..testTarget.."' now (if not already). <<<<")
        end },
        { time = 10.1, func = function()
            local msg = testTarget .. " is afflicted by Taunt."
            print(" > Simulating Combat Log: " .. msg)
            module:BossBuffEvent(msg) 
            local expectedRest = "Taunt " .. tankA
            print(" > Simulating Sync Receive: Sync='" .. syncName.tauntApplied .. "', Rest='" .. expectedRest .. "'")
            module:BigWigs_RecvSync(syncName.tauntApplied, expectedRest, "BigWigs")
            print(" > Expected: Bar 'Taunt: TankA (Taunt)' for 3s")
        end },

        -- Taunt Logic - Scenario 2: TankB uses Challenging Shout (Player NOT targeting Kruul)
        { time = 14, func = function()
            print("\n[Taunt Test 2] Scenario: Player NOT targeting "..testTarget..", TankB uses Challenging Shout (with rank).")
            DEFAULT_CHAT_FRAME:AddMessage(" >>>> Test Setup: Please UNTARGET '"..testTarget.."' or target something else. <<<<")
        end },
        { time = 14.1, func = function()
            local msg = testTarget .. " gains Challenging Shout (1)."
            print(" > Simulating Combat Log: " .. msg)
            module:BossBuffEvent(msg) 
            local expectedRest = "Challenging Shout " .. tankB
            print(" > Simulating Sync Receive: Sync='" .. syncName.tauntApplied .. "', Rest='" .. expectedRest .. "'")
            module:BigWigs_RecvSync(syncName.tauntApplied, expectedRest, "BigWigs")
            print(" > Expected: Bar 'Taunt: TankB (Challenging Shout)' for 6s")
        end },
        
        -- Enrage
        { time = 18, func = function()
             print("\n[Test] Simulating Enrage.")
             module:BossBuffEvent("Kruul gains Wrath of the Highlord.")
             print(" > Expected: Enrage message, Infernal bar stops. Next curse bar on MotH should be 15s.")
        end },
        { time = 19, func = function()
            print("[Test] Simulating Mark of the Highlord during Enrage.")
            module:AfflictionEvent_MarkOfTheLord("You are afflicted by Mark of the Highlord.")
            print(" > Expected: Next Curses bar for MotH should be 15s due to enrage.")
        end },

        -- Taunt Logic DURING Enrage - Scenario 3: TankA uses Hand of Reckoning
        { time = 22, func = function()
            print("\n[Taunt Test 3 - ENRAGED] Scenario: Player targets "..testTarget..", TankA uses Hand of Reckoning.")
            DEFAULT_CHAT_FRAME:AddMessage(" >>>> Test Setup: Please TARGET '"..testTarget.."' now. <<<<")
        end },
        { time = 22.1, func = function()
            local msg = testTarget .. " gains Hand of Reckoning (1)."
            print(" > Simulating Combat Log (ENRAGED): " .. msg)
            module:BossBuffEvent(msg)
            local expectedRest = "Hand of Reckoning " .. tankA
            print(" > Simulating Sync Receive (ENRAGED): Sync='" .. syncName.tauntApplied .. "', Rest='" .. expectedRest .. "'")
            module:BigWigs_RecvSync(syncName.tauntApplied, expectedRest, "BigWigs")
            print(" > Expected (ENRAGED): Bar 'Taunt: TankA (Hand of Reckoning)' for 3s")
        end },

        -- Taunt Resist DURING Enrage
        { time = 26, func = function()
            print("\n[Test - ENRAGED] Simulating YOUR Taunt being resisted by Kruul.")
            module:TauntResistEvent("Your Taunt was resisted by Kruul.")
            print(" > Expected (ENRAGED): Resist message & warning sign")
        end },
        
        -- Disengage
        { time = 30, func = function()
            print("\nTest: Disengage.")
            module:Disengage()
            print("------------------------------------------")
            print("BigWigs Kruul Taunt Logic Test Finished")
            print("------------------------------------------")
        end },
	}

	for i, event in ipairs(events) do
		self:ScheduleEvent("KruulMasterTestEvent" .. i, event.func, event.time)
	end

	self:Message("Kruul Master Test started", "Positive")
	return true
end

-- Test command:
-- /run local m=BigWigs:GetModule("Kruul"); BigWigs:SetupModule("Kruul");m:Test();