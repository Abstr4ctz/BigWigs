local module, L = BigWigs:ModuleDeclaration("Sanv Tas'dal", "Karazhan")

-- module variables
module.revision = 30001
module.enabletrigger = module.translatedName
module.toggleoptions = {
    "phaseshifted",
    "overflowinghatred",
    "phasealerts",
    "autotarget_riftstalker_melee",
    "autotarget_riftwalker_caster",
    "autotarget_netherwalker_caster",
    "bosskill"
}
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
	AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
	"Outland",
	"???"
}

local _, playerClass = UnitClass("player")

-- module defaults
module.defaultDB = {
	phaseshifted = true,
	overflowinghatred = true,
    phasealerts = true,
    autotarget_riftstalker_melee = false,
    autotarget_riftwalker_caster = false,
    autotarget_netherwalker_caster = false,
}

-- localization
L:RegisterTranslations("enUS", function()
	return {
		cmd = "SanvTasdal",

		phaseshifted_cmd = "phaseshifted",
		phaseshifted_name = "Phase Shifted Alert",
		phaseshifted_desc = "Warns when players get affected by Phase Shifted",

		overflowinghatred_cmd = "overflowinghatred",
		overflowinghatred_name = "Overflowing Hatred Alert",
		overflowinghatred_desc = "Warns when Sanv Tas'dal begins casting Overflowing Hatred",

        phasealerts_cmd = "phasealerts",
        phasealerts_name = "Phase Two Alerts",
        phasealerts_desc = "Warns when Phase Two starts and ends.",

        autotarget_riftstalker_melee_cmd = "autotarget_riftstalker_melee",
        autotarget_riftstalker_melee_name = "Auto-Target Riftstalker (Melee)",
        autotarget_riftstalker_melee_desc = "Automatically targets Draenei Riftstalker during Phase Two.",

        autotarget_riftwalker_caster_cmd = "autotarget_riftwalker_caster",
        autotarget_riftwalker_caster_name = "Auto-Target Riftwalker",
        autotarget_riftwalker_caster_desc = "Automatically targets Draenei Riftwalker during Phase Two.",

        autotarget_netherwalker_caster_cmd = "autotarget_netherwalker_caster",
        autotarget_netherwalker_caster_name = "Auto-Target Netherwalker",
        autotarget_netherwalker_caster_desc = "Automatically targets Draenei Netherwalker during Phase Two.",

		trigger_phaseShiftedYou = "You are afflicted by Phase Shifted",
		trigger_phaseShiftedOther = "(.+) is afflicted by Phase Shifted",
		trigger_phaseShiftedFade = "Phase Shifted fades from you",
		trigger_phaseShiftedFadeOther = "Phase Shifted fades from (.+)",

		trigger_overflowingHatredCast = "Sanv Tas'dal begins to cast Overflowing Hatred",
		bar_overflowingHatredCast = "Overflowing Hatred",
		msg_overflowingHatred = "Overflowing Hatred casting - Hide!",
		warning_overflowingHatred = "HIDE NOW!",

		msg_phaseShiftedYou = "Phase Shift on YOU - KILL SHADES!",
		msg_phaseShiftedOther = "Phase Shift on %s!",
		bar_phaseShiftedExpires = "Phase Shift - KILL SHADES",

        trigger_phaseTwoYell = "Behold the great power of the Draenei!",
        msg_phaseTwoStart = "Phase Two - Adds spawning!",
        msg_phaseTwoEnd = "Phase Two Ended.",
        draenei_riftstalker_name = "Draenei Riftstalker",
        draenei_riftwalker_name = "Draenei Riftwalker",
        draenei_netherwalker_name = "Draenei Netherwalker",
	}
end)

-- timer and icon variables
local timer = {
	phaseShiftedDuration = 25,
	overflowingHatredCast = 4,
}

local icon = {
	phaseShifted = "Spell_Shadow_AbominationExplosion",
	overflowingHatred = "Spell_Fire_Incinerate",
}

local color = {
	red = "Red",
}

local syncName = {
	phaseShifted = "SanvTasdalPhaseShifted" .. module.revision,
	phaseShiftedFade = "SanvTasdalPhaseShiftedFade" .. module.revision,
	overflowingHatred = "SanvTasdalOverflowingHatred" .. module.revision,
    phaseTwoToggle = "SanvTasdalPhaseTwoToggle" .. module.revision,
}

local activeScanEvents = {}

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER")

	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "BeginsCastEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "BeginsCastEvent")

    self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "MonsterYellEvent")

	self:ThrottleSync(3, syncName.phaseShifted)
	self:ThrottleSync(3, syncName.phaseShiftedFade)
	self:ThrottleSync(3, syncName.overflowingHatred)
    self:ThrottleSync(3, syncName.phaseTwoToggle)
end

function module:OnSetup()
	self.started = nil
    self.inPhaseTwo = false
    self:StopAllAutoTargetScans()
end

function module:OnEngage()
    self.inPhaseTwo = false
    self:StopAllAutoTargetScans()
end

function module:OnDisengage()
    self.inPhaseTwo = false
    self:StopAllAutoTargetScans()
end

function module:MonsterYellEvent(msg, sender)
    if sender == self.translatedName and msg == L["trigger_phaseTwoYell"] then
        self:Sync(syncName.phaseTwoToggle)
    end
end

function module:AfflictionEvent(msg)
	-- Phase Shifted
	if string.find(msg, L["trigger_phaseShiftedYou"]) then
		self:Sync(syncName.phaseShifted .. " " .. UnitName("player"))
	else
		local _, _, player = string.find(msg, L["trigger_phaseShiftedOther"])
		if player then
			self:Sync(syncName.phaseShifted .. " " .. player)
		end
	end
end

function module:BeginsCastEvent(msg)
	if string.find(msg, L["trigger_overflowingHatredCast"]) then
		self:Sync(syncName.overflowingHatred)
	end
end

function module:CHAT_MSG_SPELL_AURA_GONE_SELF(msg)
	if string.find(msg, L["trigger_phaseShiftedFade"]) then
		self:Sync(syncName.phaseShiftedFade .. " " .. UnitName("player"))
		self:RemoveBar(L["bar_phaseShiftedExpires"])
	end
end

function module:CHAT_MSG_SPELL_AURA_GONE_OTHER(msg)
	local _, _, player = string.find(msg, L["trigger_phaseShiftedFadeOther"])
	if player then
		self:Sync(syncName.phaseShiftedFade .. " " .. player)
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.phaseShifted and rest then
		self:PhaseShifted(rest)
	elseif sync == syncName.phaseShiftedFade and rest then
		self:PhaseShiftedFade(rest)
	elseif sync == syncName.overflowingHatred then
		self:OverflowingHatred()
    elseif sync == syncName.phaseTwoToggle then
        self:TogglePhaseTwo()
	end
end

function module:PhaseShifted(player)
	if self.db.profile.phaseshifted then
		if player == UnitName("player") then
			self:Message(L["msg_phaseShiftedYou"], "Important", true, "Alarm")
			self:WarningSign(icon.phaseShifted, 5, true, "KILL SHADES")
			self:Bar(L["bar_phaseShiftedExpires"], timer.phaseShiftedDuration, icon.phaseShifted, true, "yellow")
		else
			self:Message(string.format(L["msg_phaseShiftedOther"], player), "Important")
		end
	end
end

function module:PhaseShiftedFade(player)
	-- No specific action on fade other than bar removal for self (handled in AURA_GONE_SELF)
end

function module:OverflowingHatred()
	if self.db.profile.overflowinghatred then
		self:Message(L["msg_overflowingHatred"], "Important", nil, "Alarm")
		self:Bar(L["bar_overflowingHatredCast"], timer.overflowingHatredCast, icon.overflowingHatred, true, color.red)
		self:WarningSign(icon.overflowingHatred, timer.overflowingHatredCast, true, L["warning_overflowingHatred"])
	end
end

function module:TogglePhaseTwo()
    self.inPhaseTwo = not self.inPhaseTwo

    if self.inPhaseTwo then
        if self.db.profile.phasealerts then
            self:Message(L["msg_phaseTwoStart"], "Attention", nil, "Info")
        end
        self:ManageAutoTargeting()
    else
        if self.db.profile.phasealerts then
            self:Message(L["msg_phaseTwoEnd"], "Positive", nil, "Info")
        end
        self:StopAllAutoTargetScans()
    end
end

function module:ManageAutoTargeting()
    self:StopAllAutoTargetScans()

    if not self.inPhaseTwo then return end

    -- Riftstalker
    if self.db.profile.autotarget_riftstalker_melee then
        if activeScanEvents.riftstalker then
            self:CancelScheduledEvent(activeScanEvents.riftstalker)
        end
        activeScanEvents.riftstalker = self:ScheduleRepeatingEvent("ScanAndTargetRiftstalkerEvent", function() self:ScanAndTargetMob("draenei_riftstalker_name") end, 0.75, self)
    end

    -- Riftwalker
    if self.db.profile.autotarget_riftwalker_caster then
        if activeScanEvents.riftwalker then
            self:CancelScheduledEvent(activeScanEvents.riftwalker)
        end
        activeScanEvents.riftwalker = self:ScheduleRepeatingEvent("ScanAndTargetRiftwalkerEvent", function() self:ScanAndTargetMob("draenei_riftwalker_name") end, 0.75, self)
    end

    -- Netherwalker
    if self.db.profile.autotarget_netherwalker_caster then
        if activeScanEvents.netherwalker then
            self:CancelScheduledEvent(activeScanEvents.netherwalker)
        end
        activeScanEvents.netherwalker = self:ScheduleRepeatingEvent("ScanAndTargetNetherwalkerEvent", function() self:ScanAndTargetMob("draenei_netherwalker_name") end, 0.75, self)
    end
end

function module:ScanAndTargetMob(mobNameKey)
    local targetMobName = L[mobNameKey]
    if not targetMobName then
        -- self:Debug("ScanAndTargetMob: Invalid mobNameKey: " .. tostring(mobNameKey)) -- Optional debug
        return
    end

    local currentTargetName = UnitName("target")
    local shouldAttemptTarget = false

    if not UnitExists("target") then
        shouldAttemptTarget = true
    elseif UnitIsDeadOrGhost("target") then
        shouldAttemptTarget = true
    elseif currentTargetName ~= targetMobName then
        shouldAttemptTarget = true
    end

    if shouldAttemptTarget then
        TargetByName(targetMobName, true)
    end
end

function module:StopAllAutoTargetScans()
    for mobType, eventHandle in pairs(activeScanEvents) do
        if eventHandle then
            self:CancelScheduledEvent(eventHandle)
        end
        activeScanEvents[mobType] = nil
    end
end

-- Boss Encounter Test
function module:Test()
	self:OnSetup()
	self:Engage()

	local originalPlayer = UnitName("player")
	local testPlayerName1 = UnitName("raid1") or "TestPlayer1"
	local testPlayerName2 = UnitName("raid2") or "TestPlayer2"

	local events = {
        -- Phase Shifted events
		{ time = 2, func = function()
			self:AfflictionEvent(testPlayerName1 .. " is afflicted by Phase Shifted")
            print("Test: " .. testPlayerName1 .. " is afflicted by Phase Shifted")
		end },
        { time = 7, func = function()
			self:CHAT_MSG_SPELL_AURA_GONE_OTHER("Phase Shifted fades from " .. testPlayerName1)
            print("Test: Phase Shifted fades from " .. testPlayerName1)
		end },
        { time = 9, func = function()
			self:BeginsCastEvent("Sanv Tas'dal begins to cast Overflowing Hatred")
            print("Test: Sanv Tas'dal begins to cast Overflowing Hatred")
		end },
        { time = 12, func = function()
			self:AfflictionEvent("You are afflicted by Phase Shifted")
            print("Test: You are afflicted by Phase Shifted")
		end },

        -- Phase Two Start
        { time = 15, func = function()
            print("Test: Simulating Phase Two Start Yell")
            self:MonsterYellEvent(L["trigger_phaseTwoYell"], self.translatedName)
            -- To test auto-target for Riftstalker during this, ensure the option is enabled
            -- and the current playerClass is WARRIOR or ROGUE.
            -- Then, untarget or target something else and wait ~0.75s.
            -- You'd need to manually check if TargetByName was attempted.
        end },

        { time = 20, func = function()
            print("Test: Simulating another Overflowing Hatred during P2")
			self:BeginsCastEvent("Sanv Tas'dal begins to cast Overflowing Hatred")
		end },
        { time = 22, func = function()
			self:AfflictionEvent(testPlayerName2 .. " is afflicted by Phase Shifted")
            print("Test: " .. testPlayerName2 .. " is afflicted by Phase Shifted")
		end },
        { time = 25, func = function()
			self:CHAT_MSG_SPELL_AURA_GONE_SELF("Phase Shifted fades from you")
            print("Test: Phase Shifted fades from you")
		end },

        -- Phase Two End
        { time = 30, func = function()
            print("Test: Simulating Phase Two End Yell")
            self:MonsterYellEvent(L["trigger_phaseTwoYell"], self.translatedName)
            -- Auto-target scans should stop here.
        end },

        { time = 32, func = function()
			self:AfflictionEvent(testPlayerName1 .. " is afflicted by Phase Shifted") -- After P2
            print("Test: " .. testPlayerName1 .. " is afflicted by Phase Shifted (after P2)")
		end },
		{ time = 35, func = function()
			self:CHAT_MSG_COMBAT_FRIENDLY_DEATH(testPlayerName2 .. " dies")
            print("Test: " .. testPlayerName2 .. " dies")
		end },
		{ time = 40, func = function()
			print("Test: Disengage")
			self:Disengage()
		end },
	}

	for i, event in ipairs(events) do
		self:ScheduleEvent("SanvTasdalBossTest" .. i, event.func, event.time)
	end

	self:Message("Sanv Tasdal Boss Test started", "Positive")
	return true
end

-- Test command:
-- /run local m=BigWigs:GetModule("Sanv Tas'dal"); BigWigs:SetupModule("Sanv Tas'dal");m:Test();
