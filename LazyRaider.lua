--[[

	Addon various tools for lazy raiders.
	
	Currently done:
	* RaidRoll
	* AutoInvite
	* AutoRecruit
	* AutoDisband

]]

--[[

	Setup functions list:
	
	* addon:OnInitialize()
	* LazyRaider_OnLoad()
	* LazyRaider_OnEvent(self, event, ...)
	* LazyRaider_InitEvent()
	* LazyRaider_InitSlashCommands()
	* LazyRaider_Help(msg)
	* LazyRaider_SetWindow(msg)

]]

LazyRaider = LibStub("AceAddon-3.0"):NewAddon("LazyRaider")

local defaults = {
	profile = {
		minimap = {
			hide = false
		}
	}
}

function LazyRaider:OnInitialize()

	self.db = LibStub("AceDB-3.0"):New("LazyRaiderDB", defaults, "Default")
	LibStub("LibDBIcon-1.0"):Register("LazyRaider", LazyRaiderBroker, self.db.profile.minimap)
	LazyRaiderWindow_BoP_Check:SetChecked(LazyRaider_BoP)
		
end

function LazyRaider_OnLoad()

	LazyRaider_InitSlashCommands()
	LazyRaider_InitEvent()
	LazyRaider_InitDungeonMod()
	LazyRaider_InitChannelNumeric()
	LazyRaider_InitChannelAlphabetical()
	LazyRaider_AutoInvite = false
--	LazyRaider_BoP = true
	LazyRaider_AutoRecruit = false
	LazyRaider_Interval = 30
	LazyRaider_LastAnnounce = 0
	LazyRaider_NameCount = 0
	LazyRaider_RecruitType = "None"
	LazyRaider_PlayerClass = { }
	LazyRaider_PlayerRole = { }
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff78LazyRaider|r loaded! Help: |cff00eeff/lazyraider|r or |cff00eeff/lr|r")
	
end

function LazyRaider_OnEvent(self, event, ...)
	
	LazyRaider_EventHandler[event](self, ...)
	
end

function LazyRaider_InitEvent()
	
	LazyRaiderFrame:SetScript("OnEvent",LazyRaider_OnEvent)
	LazyRaiderFrame:SetScript("OnUpdate",LazyRaider_OnUpdate)

	LazyRaider_EventHandler = { }
	
	LazyRaider_EventHandler.CHAT_MSG_WHISPER = LazyRaider_OnWhisper
	LazyRaider_EventHandler.CHAT_MSG_SYSTEM = LazyRaider_OnSystemChat
	LazyRaider_EventHandler.RAID_ROSTER_UPDATE = LazyRaider_OnMembersChanged
	LazyRaider_EventHandler.PARTY_MEMBERS_CHANGED = LazyRaider_OnMembersChanged
	LazyRaider_EventHandler.CONFIRM_LOOT_ROLL = LazyRaider_ConfirmLootRoll
	LazyRaider_EventHandler.LOOT_BIND_CONFIRM = LazyRaider_LootBindConfirm
	
	for k, v in pairs(LazyRaider_EventHandler) do
		LazyRaiderFrame:RegisterEvent(k)
	end

end

function LazyRaider_InitSlashCommands()

	SLASH_LAZYRAIDERHELP1 = "/lazyraider"
	SLASH_LAZYRAIDERHELP2 = "/lr"
	
	SlashCmdList["LAZYRAIDERHELP"] = LazyRaider_Help

	SLASH_LAZYRAIDERWINDOW1 = "/lazywindow"
	SLASH_LAZYRAIDERWINDOW2 = "/lw"
	
	SlashCmdList["LAZYRAIDERWINDOW"] = LazyRaider_SetWindow	
	
	SLASH_RAIDROLL1 = "/raidroll"
	SLASH_RAIDROLL2 = "/rr"
	
	SlashCmdList["RAIDROLL"] = LazyRaider_RaidRoll
	
	SLASH_AUTOINVITE1 = "/autoinvite"
	SLASH_AUTOINVITE2 = "/inv"
	
	SlashCmdList["AUTOINVITE"] = LazyRaider_SetAutoInvite

	SLASH_AUTOINVITE1 = "/bindonpickup"
	SLASH_AUTOINVITE2 = "/bop"
	
	SlashCmdList["BINDONPICKUP"] = LazyRaider_SetBoP	
	
	SLASH_DISBAND1 = "/disband"
	SLASH_DISBAND2 = "/dis"
	
	SlashCmdList["DISBAND"] = LazyRaider_Disband	
	
	SLASH_RECRUIT1 = "/recruit"
	SLASH_RECRUIT2 = "/rec"
	
	SlashCmdList["RECRUIT"] = LazyRaider_Recruit
	
	SLASH_SHOWROLES1 = "/showroles"
	SLASH_SHOWROLES2 = "/sr"
	
	SlashCmdList["SHOWROLES"] = LazyRaider_SetShowRoles		
		
	SLASH_CHANGEROLE1 = "/changerole"
	SLASH_CHANGEROLE2 = "/cr"	
	
	SlashCmdList["CHANGEROLE"] = LazyRaider_ChangeRole			
	
end

function LazyRaider_Help(msg)

	DEFAULT_CHAT_FRAME:AddMessage("|cffffff78LazyRaider|r |cff00eeffcommands|r:")
	DEFAULT_CHAT_FRAME:AddMessage("----------------------------------------")
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff78Lazy Window|r: setup window")
	DEFAULT_CHAT_FRAME:AddMessage("|cff00eeff/lazywindow|r |cff00eeff/lw|r |cff00ee00on|r |cff00ee00off|r |cff00ee00reset|r")	
	DEFAULT_CHAT_FRAME:AddMessage("----------------------------------------")
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff78RandomRoll|r: random rolls an item")
	DEFAULT_CHAT_FRAME:AddMessage("|cff00eeff/randomroll|r |cff00eeff/rr|r |cff00ee00ItemLink|r")
	DEFAULT_CHAT_FRAME:AddMessage("----------------------------------------")
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff78AutoInvite|r: toggles the auto invite feature")	
	DEFAULT_CHAT_FRAME:AddMessage("|cff00eeff/autoinvite|r |cff00eeff/inv|r |cff00ee00on|r |cff00ee00off|r")	
	DEFAULT_CHAT_FRAME:AddMessage("----------------------------------------")
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff78BindOnPickup|r: toggles the BoP feature")	
	DEFAULT_CHAT_FRAME:AddMessage("|cff00eeff/bindonpickup|r |cff00eeff/bop|r |cff00ee00on|r |cff00ee00off|r")	
	DEFAULT_CHAT_FRAME:AddMessage("----------------------------------------")	
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff78Disband|r: disband your group")
	DEFAULT_CHAT_FRAME:AddMessage("|cff00eeff/disband|r |cff00eeff/dis|r optional:|cff00ee00message|r")	
	DEFAULT_CHAT_FRAME:AddMessage("----------------------------------------")
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff78Recruit|r: specified recruitment message")
	DEFAULT_CHAT_FRAME:AddMessage("|cff00eeff/recruit|r |cff00eeff/rec|r |cff00ee00mods|r |cff00ee00stop|r |cff00ee00help|r")	
	DEFAULT_CHAT_FRAME:AddMessage("----------------------------------------")	
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff78ShowRoles|r: show roles of your group")
	DEFAULT_CHAT_FRAME:AddMessage("|cff00eeff/showroles|r |cff00eeff/sr|r")
	DEFAULT_CHAT_FRAME:AddMessage("----------------------------------------")
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff78Change Role|r: set new role for group member")
	DEFAULT_CHAT_FRAME:AddMessage("|cff00eeff/changerole|r |cff00eeff/cr|r |cff00ee00name|r |cff00ee00role|r |cff00ee00help|r")
	DEFAULT_CHAT_FRAME:AddMessage("----------------------------------------")
	
end

function LazyRaider_SetWindow(msg)

	if (string.lower(msg) == "on") then
		LazyRaiderWindow:Show()
	elseif (string.lower(msg) == "off") then	
		LazyRaiderWindow:Hide()
	elseif 	(string.lower(msg) == "reset") then
		LazyRaiderWindow:ClearAllPoints()
		LazyRaiderWindow:SetPoint("CENTER", 0, 30)	
		DEFAULT_CHAT_FRAME:AddMessage("|cffffff78LazyRaiderWindow|r: default position")
	else
		if LazyRaiderWindow:IsShown() then
			LazyRaiderWindow:Hide()
		else
			LazyRaiderWindow:Show()
		end
	end	

end

--[[

	Main functions list:
	
	* LazyRaider_RaidRoll(msg)
	* LazyRaider_SetAutoInvite(msg)
	* LazyRaider_SetBoP(msg)
	* LazyRaider_Disband(msg)
	* LazyRaider_Recruit(msg)
	* LazyRaider_ShowRecruitSyntax()
	* LazyRaider_InitDungeonMod()
	* LazyRaider_FormingFive()
	* LazyRaider_FormingTen()
	* LazyRaider_FormingTventyfive()
	* LazyRaider_FormingCustom()
	* LazyRaider_InitChannelNumeric()
	* LazyRaider_InitChannelAlphabetical()
	* LazyRaider_SetShowRoles(msg)
	* LazyRaider_ChangeRole(msg)
	* LazyRaider_ShowChangeRoleSyntax()
	
]]

function LazyRaider_RaidRoll(msg)

	LazyRaider_ItemLink = string.match(strtrim(msg), "^\124c%x+\124Hitem[:%-%d]+\124h%[[^\124]+%]\124h\124r")
	LazyRaider_ItemLink = (LazyRaider_ItemLink == nil) and "" or (" " .. LazyRaider_ItemLink)
	LazyRaider_RollCount, LazyRaider_RollName, _ = LazyRaider_GetGroupMembers()
		
	if GetNumRaidMembers() > 0 then
		ChatType = "RAID"
	elseif GetNumPartyMembers() > 0 then
		ChatType = "PARTY"
	else
		ChatType = "SAY"
	end
	
	SendChatMessage("Raid Rolling" .. LazyRaider_ItemLink, ChatType, nil, nil)
	
	local namesPerLine = 5
	for line = 1, math.floor((LazyRaider_RollCount + namesPerLine - 1) / namesPerLine) do
		local message = ""
		local index = 1 + (line - 1) * namesPerLine
		for i = index, math.min(LazyRaider_RollCount, index + namesPerLine - 1) do
			message = message .. " " .. i .. "-" .. LazyRaider_RollName[i]
		end
			message = strtrim(message)
			SendChatMessage(message, ChatType, nil, nil)
		end
		
		RandomRoll(1, LazyRaider_RollCount)
	
end

function LazyRaider_SetAutoInvite(msg)

	if (string.lower(msg) == "on") then
		LazyRaider_AutoInvite = true
		LazyRaiderWindow_AutoInvite_Check:SetChecked(true)
		DEFAULT_CHAT_FRAME:AddMessage("AutoInvite enabled")
	elseif (string.lower(msg) == "off") then
		LazyRaider_AutoInvite = false
		LazyRaiderWindow_AutoInvite_Check:SetChecked(false)
		DEFAULT_CHAT_FRAME:AddMessage("AutoInvite disabled")
	else
		LazyRaider_AutoInvite = not LazyRaider_AutoInvite
		LazyRaiderWindow_AutoInvite_Check:SetChecked(LazyRaider_AutoInvite)
		DEFAULT_CHAT_FRAME:AddMessage(LazyRaider_AutoInvite and "AutoInvite enabled" or "AutoInvite disabled")
	end
	
end

function LazyRaider_SetBoP(msg)

	if (string.lower(msg) == "on") then
		LazyRaider_BoP = true
		LazyRaiderWindow_BoP_Check:SetChecked(true)
		DEFAULT_CHAT_FRAME:AddMessage("BindOnPickup enabled")
	elseif (string.lower(msg) == "off") then
		LazyRaider_BoP = false
		LazyRaiderWindow_BoP_Check:SetChecked(false)
		DEFAULT_CHAT_FRAME:AddMessage("BindOnPickup disabled")
	else
		LazyRaider_BoP = not LazyRaider_BoP
		LazyRaiderWindow_BoP_Check:SetChecked(LazyRaider_BoP)
		DEFAULT_CHAT_FRAME:AddMessage(LazyRaider_BoP and "BindOnPickup enabled" or "BindOnPickup disabled")
	end
	
end

function LazyRaider_Disband(msg)

	local nameCount, nameArray, _ = LazyRaider_GetGroupMembers()
	if (nameCount > 0) then
		SendChatMessage("[Disband] " .. msg, GetNumRaidMembers() > 0 and "RAID" or "PARTY", nil, nil)
		LazyRaiderWindow_DisbandBox:AddHistoryLine(LazyRaiderWindow_DisbandBox_Buffer ~= nil and LazyRaiderWindow_DisbandBox_Buffer or "")
		LazyRaiderWindow_DisbandBox:SetText(LazyRaiderWindow_DisbandBox_Buffer ~= nil and LazyRaiderWindow_DisbandBox_Buffer or "")	
		for i = 1, nameCount do
			if (nameArray[i] ~= UnitName("player")) then
				UninviteUnit(nameArray[i])
			end
		end
	end
end

function LazyRaider_Recruit(msg)

	local startstop = string.lower(strsplit(" ", msg))
	local preset = LazyRaider_DungeonMod[string.upper(startstop)]
	local recchannel, interval, message = string.match(msg, "[^ ]+ (%w+) (%d+) (.+)")

	if preset ~= nil and recchannel ~= nil and interval ~= nil and message ~= nil then		
		if LazyRaider_SetGroupRoles() == false then
			return
		end
		local presetnumeric = LazyRaider_ChannelNumeric[string.upper(recchannel)]
		local presetalphabetical = LazyRaider_ChannelAlphabetical[string.upper(recchannel)]
		if presetnumeric ~= nil then
			LazyRaider_Channel = "CHANNEL"
			LazyRaider_ChannelId = recchannel
		elseif presetalphabetical ~= nil then
			LazyRaider_Channel = string.upper(recchannel)
			LazyRaider_ChannelId = nil
		else
			DEFAULT_CHAT_FRAME:AddMessage("Available chat IDs: 1, 2, 3, 4, 5, 6, 7, SAY, YELL, EMOTE, PARTY, RAID, GUILD, BATTLEGROUND")
			return
		end		
		LazyRaider_Interval = tonumber(interval)	
		if (LazyRaider_Interval < 30) then
			DEFAULT_CHAT_FRAME:AddMessage("Recruit interval should be atleast 30 seconds. Set to 30 seconds.")
			LazyRaider_Interval = 30
		end
		LazyRaider_DungeonName = message
		preset()
		LazyRaiderWindow_RecruitBox:AddHistoryLine(message)
		LazyRaiderWindow_RecruitBox:SetText(message)
		--UIDropDownMenu_SetSelectedName(LazyRaiderWindow_Recruit_ModMenu, string.upper(startstop))
		LazyRaiderWindow_Recruit_ModButton:SetText(string.upper(startstop))
		--UIDropDownMenu_SetSelectedName(LazyRaiderWindow_Recruit_ChannelMenu, string.upper(recchannel))
		LazyRaiderWindow_Recruit_ChannelButton:SetText(string.upper(recchannel))
		--UIDropDownMenu_SetSelectedName(LazyRaiderWindow_Recruit_IntervalMenu, interval)
		LazyRaiderWindow_Recruit_IntervalButton:SetText(interval)
		DEFAULT_CHAT_FRAME:AddMessage("Starting Recruit")					
	elseif startstop == "stop" then
		LazyRaider_AutoRecruit = false
		LazyRaider_RecruitType = "None"
		DEFAULT_CHAT_FRAME:AddMessage("Stopping Recruit")
	elseif startstop == "mods" then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffff78Available mods|r:")
		DEFAULT_CHAT_FRAME:AddMessage("----------------------------------------")
		for k, v in pairs(LazyRaider_DungeonMod) do
			DEFAULT_CHAT_FRAME:AddMessage(string.upper(k))
		end		
		DEFAULT_CHAT_FRAME:AddMessage("----------------------------------------")
	else
		LazyRaider_ShowRecruitSyntax()		
	end		

end

function LazyRaider_ShowRecruitSyntax()

	DEFAULT_CHAT_FRAME:AddMessage("|cffffff78Recruit|r")
	DEFAULT_CHAT_FRAME:AddMessage("----------------------------------------")
	DEFAULT_CHAT_FRAME:AddMessage("|cff00eeff/recruit|r |cff00ee00mods|r |cff00ee00stop|r |cff00ee00help|r")
	DEFAULT_CHAT_FRAME:AddMessage("|cff00eeff/rec|r |cff00ee00mod|r |cff00ee00channel|r |cff00ee00interval|r |cff00ee00message|r")	
	DEFAULT_CHAT_FRAME:AddMessage("-- Syntax example: |cff00eeff/recruit|r |cff00ee00custom 5 30 test|r")
	DEFAULT_CHAT_FRAME:AddMessage("-- Syntax example: |cff00eeff/recruit|r |cff00ee00d5 guild 45 test")
	DEFAULT_CHAT_FRAME:AddMessage("-- Syntax example: |cff00eeff/rec|r |cff00ee00mods|r")
	DEFAULT_CHAT_FRAME:AddMessage("----------------------------------------")
	
end

function LazyRaider_InitDungeonMod()

	LazyRaider_DungeonMod = { }
	LazyRaider_DungeonMod["D5"] = LazyRaider_FormingFive
	LazyRaider_DungeonMod["D10"] = LazyRaider_FormingTen
	LazyRaider_DungeonMod["D25"] = LazyRaider_FormingTventyfive
	LazyRaider_DungeonMod["CUSTOM"] = LazyRaider_FormingCustom

end

function LazyRaider_FormingFive()

	DEFAULT_CHAT_FRAME:AddMessage("Forming a Group(5) party")
	LazyRaider_RecruitType = "Group(d5)"
	LazyRaider_ClassCap = 5
	LazyRaider_RequiredTanks = 1
	LazyRaider_RequiredHealers = 1
	LazyRaider_RequiredDps = 5 - LazyRaider_RequiredTanks - LazyRaider_RequiredHealers
	LazyRaider_LastAnnounce = LazyRaider_Interval
	LazyRaider_AutoRecruit = true

end

function LazyRaider_FormingTen()

	DEFAULT_CHAT_FRAME:AddMessage("Forming a Group(10) raid")
	LazyRaider_RecruitType = "Group(d10)"
	LazyRaider_ClassCap = 5
	LazyRaider_RequiredTanks = 2
	LazyRaider_RequiredHealers = 2
	LazyRaider_RequiredDps = 10 - LazyRaider_RequiredTanks - LazyRaider_RequiredHealers
	LazyRaider_LastAnnounce = LazyRaider_Interval
	LazyRaider_AutoRecruit = true

end

function LazyRaider_FormingTventyfive()

	DEFAULT_CHAT_FRAME:AddMessage("Forming a Group(25) raid")
	LazyRaider_RecruitType = "Group(d25)"
	LazyRaider_ClassCap = 10
	LazyRaider_RequiredTanks = 3
	LazyRaider_RequiredHealers = 5
	LazyRaider_RequiredDps = 25 - LazyRaider_RequiredTanks - LazyRaider_RequiredHealers
	LazyRaider_LastAnnounce = LazyRaider_Interval
	LazyRaider_AutoRecruit = true

end


function LazyRaider_FormingCustom()

	DEFAULT_CHAT_FRAME:AddMessage("Forming a Custom group")
	LazyRaider_RecruitType = "Custom"
	LazyRaider_LastAnnounce = LazyRaider_Interval
	LazyRaider_AutoRecruit = true

end

function LazyRaider_InitChannelNumeric()

	LazyRaider_ChannelNumeric = { }
	LazyRaider_ChannelNumeric["1"] = "1"
	LazyRaider_ChannelNumeric["2"] = "2"
	LazyRaider_ChannelNumeric["3"] = "3"
	LazyRaider_ChannelNumeric["4"] = "4"
	LazyRaider_ChannelNumeric["5"] = "5"
	LazyRaider_ChannelNumeric["6"] = "6"
	LazyRaider_ChannelNumeric["7"] = "7"
	
end

function LazyRaider_InitChannelAlphabetical()

	LazyRaider_ChannelAlphabetical = { }
	LazyRaider_ChannelAlphabetical["SAY"] = "SAY"
	LazyRaider_ChannelAlphabetical["YELL"] = "YELL"
	LazyRaider_ChannelAlphabetical["EMOTE"] = "EMOTE"
	LazyRaider_ChannelAlphabetical["PARTY"] = "PARTY"
	LazyRaider_ChannelAlphabetical["RAID"] = "RAID"
	LazyRaider_ChannelAlphabetical["GUILD"] = "GUILD"
	LazyRaider_ChannelAlphabetical["BATTLEGROUND"] = "BATTLEGROUND"

end

function LazyRaider_SetShowRoles(msg)
	
	if LazyRaider_SetGroupRoles() then
		LazyRaider_ShowRoles()
	end
	
end

function LazyRaider_ChangeRole(msg)

	local changename, changerole = string.match(msg:lower(), "(%w+) (%w+)")
	if (changename ~= nil and changerole ~= nil) then
		if LazyRaider_IsInGroup(UnitName(changename)) then
			LazyRaider_PlayerClass[UnitName(changename)] = UnitClass(changename)
			LazyRaiderWindow_ChangeRole_NameButton:SetText(changename:sub(1,1):upper()..changename:sub(2))
			--UIDropDownMenu_SetSelectedName(LazyRaiderWindow_ChangeRole_NameMenu, changename)
			LazyRaider_CRBuffer = changename
			local tank, dps, heal = LazyRaider_ParseRoles(msg:lower())
			local tankClasses = { ["Warrior"] = true, ["Death Knight"] = true, ["Paladin"] = true, ["Druid"] = true }
			local healerClasses = { ["Priest"] = true, ["Shaman"] = true, ["Paladin"] = true, ["Druid"] = true }
			if ((tank) and (tankClasses[LazyRaider_PlayerClass[UnitName(changename)]])) then
				LazyRaider_PlayerRole[UnitName(changename)] = { ["tank"] = tank, ["dps"] = dps, ["heal"] = heal }
				DEFAULT_CHAT_FRAME:AddMessage("|cffffff78"..UnitName(changename).."|r role was changed to TANK")
				LazyRaiderWindow_ChangeRole_RoleButton:SetText("Tank")
				--UIDropDownMenu_SetSelectedID(LazyRaiderWindow_ChangeRole_RoleMenu, 1)
			elseif (dps) then
				LazyRaider_PlayerRole[UnitName(changename)] = { ["tank"] = tank, ["dps"] = dps, ["heal"] = heal }
				DEFAULT_CHAT_FRAME:AddMessage("|cffffff78"..UnitName(changename).."|r role was changed to DPS")
				LazyRaiderWindow_ChangeRole_RoleButton:SetText("Dps")	
				--UIDropDownMenu_SetSelectedID(LazyRaiderWindow_ChangeRole_RoleMenu, 2)
			elseif ((heal)and (healerClasses[LazyRaider_PlayerClass[UnitName(changename)]])) then
				LazyRaider_PlayerRole[UnitName(changename)] = { ["tank"] = tank, ["dps"] = dps, ["heal"] = heal }
				DEFAULT_CHAT_FRAME:AddMessage("|cffffff78"..UnitName(changename).."|r role was changed to HEAL")
				LazyRaiderWindow_ChangeRole_RoleButton:SetText("Heal")
				--UIDropDownMenu_SetSelectedID(LazyRaiderWindow_ChangeRole_RoleMenu, 3)
			else
				DEFAULT_CHAT_FRAME:AddMessage("Incorrect role")
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("Name incorrect or member isn't part of your group")				
		end
	else	
		LazyRaider_ShowChangeRoleSyntax()
	end
	
end

function LazyRaider_ShowChangeRoleSyntax()

	DEFAULT_CHAT_FRAME:AddMessage("|cffffff78Change Role|r")
	DEFAULT_CHAT_FRAME:AddMessage("----------------------------------------")
	DEFAULT_CHAT_FRAME:AddMessage("|cff00eeff/changerole|r |cff00eeff/cr|r |cff00ee00name|r |cff00ee00role|r |cff00ee00help|r")
	DEFAULT_CHAT_FRAME:AddMessage("-- Syntax example: |cff00eeff/changerole|r |cff00ee00takado|r |cff00ee00dps|r")
	DEFAULT_CHAT_FRAME:AddMessage("-- Syntax example: |cff00eeff/cr|r |cff00ee00TaKAdO|r |cff00ee00dPS|r")		
	DEFAULT_CHAT_FRAME:AddMessage("----------------------------------------")

end

--[[

	Utility functions list:
	
	* LazyRaider_GetGroupMembers()
	* LazyRaider_GetRoles()
	* LazyRaider_ShowRoles()
	* LazyRaider_SetGroupRoles()
	* LazyRaider_ParseRoles(msg)
	* LazyRaider_IsInGroup(name)
	* LazyRaider_ConfirmLootRoll(self, ...)
	* LazyRaider_LootBindConfirm(self, ...)
	* LazyRaider_OnSystemChat(self, ...)
	* LazyRaider_OnWhisper(self, ...)
	* LazyRaider_OnUpdate(self, elapsed)
	* LazyRaider_OnMembersChanged(self, ...)
	* LazyRaider_NeedPlayer(class, tank, dps, heal)
	* LazyRaider_Trigraph(condition, iftrue, iffalse)
	
]]

function LazyRaider_GetGroupMembers()

	local memberCount = 0
	local nameArray = { }
	local classCount = { ["Warrior"] = 0, ["Paladin"] = 0, ["Druid"] = 0, ["Death Knight"] = 0, ["Priest"] = 0, ["Hunter"] = 0, ["Warlock"] = 0, ["Rogue"] = 0, ["Mage"] = 0, ["Shaman"] = 0 }

	if (GetNumRaidMembers() > 0) then
		for i = 1, 40 do
			local name, _, _, _, class = GetRaidRosterInfo(i)
			if (name ~= nil) then
				memberCount = memberCount + 1
				nameArray[memberCount] = name
				classCount[class] = classCount[class] + 1
			end
		end	
	elseif (GetNumPartyMembers() > 0) then	
		memberCount = 1
		nameArray[1] = UnitName("player")	
		classCount[UnitClass("player")] = 1	
		for i = 1, GetNumPartyMembers() do
			memberCount = memberCount + 1
			nameArray[memberCount] = UnitName("party" .. i)
			classCount[UnitClass("party" .. i)] = classCount[UnitClass("party" .. i)] + 1
		end
	else
		memberCount = 1
		nameArray[1] = UnitName("player")
		classCount[UnitClass("player")] = 1
	end

	return memberCount, nameArray, classCount

end

function LazyRaider_GetRoles()
	
	local nameCount, nameArray, _  = LazyRaider_GetGroupMembers()
	local numTanks, numDps, numHealers = 0, 0, 0
	local tanks, healers, dpsers = { }, { }, { }
	
	local tankClasses = { ["Warrior"] = true, ["Paladin"] = true, ["Druid"] = true }
	local healerClasses = { ["Priest"] = true, ["Shaman"] = true, ["Paladin"] = true, ["Druid"] = true }
	
	 for i = 1, nameCount do
		local name = nameArray[i]
		if LazyRaider_PlayerClass[UnitName(name)] == "Fake" then
			LazyRaider_PlayerClass[UnitName(name)] = UnitClass(name)
		end

		if (LazyRaider_PlayerRole[name].tank and tankClasses[LazyRaider_PlayerClass[name]]) then
			numTanks = numTanks + 1
			tanks[numTanks] = name
		elseif (LazyRaider_PlayerRole[name].heal and healerClasses[LazyRaider_PlayerClass[name]]) then
			numHealers = numHealers + 1
			healers[numHealers] = name 			
		else
			numDps = numDps + 1
			dpsers[numDps] = name
		end
	end	
	return tanks, healers, dpsers, numTanks, numHealers, numDps
end

function LazyRaider_ShowRoles()

	if GetNumRaidMembers() > 0 then
		ChatType = "RAID"
	elseif GetNumPartyMembers() > 0 then
		ChatType = "PARTY"
	else
		ChatType = "SAY"
	end
	
	local nameCount, nameArray, _ = LazyRaider_GetGroupMembers()
	local numTanks, numDps, numHealers = 0, 0, 0
	local tanks, healers, dpsers = { }, { }, { }
	
	local tankClasses = { ["Warrior"] = true, ["Death Knight"] = true, ["Paladin"] = true, ["Druid"] = true }
	local healerClasses = { ["Priest"] = true, ["Shaman"] = true, ["Paladin"] = true, ["Druid"] = true }
	
	for i = 1, nameCount do
		local name = nameArray[i]
		if (LazyRaider_PlayerRole[name].tank and tankClasses[LazyRaider_PlayerClass[name]]) then
			numTanks = numTanks + 1
			tanks[numTanks] = name
		elseif (LazyRaider_PlayerRole[name].heal and healerClasses[LazyRaider_PlayerClass[name]]) then
			numHealers = numHealers + 1
			healers[numHealers] = name
		else
			numDps = numDps + 1
			dpsers[numDps] = name
		end
	end
	
	local namesPerLine = 5
	for line = 1, math.floor((numTanks + namesPerLine - 1) / namesPerLine) do
		local message = "Tanks: "
		local index = 1 + (line - 1) * namesPerLine
		local first = true
		for i = index, math.min(numTanks, index + namesPerLine - 1) do
			if (not first) then
				message = message .. ", "
			end
			message = message .. tanks[i]
			first = false
		end
		message = strtrim(message)
		
		SendChatMessage(message, ChatType, nil, nil)
	end
	
	for line = 1, math.floor((numHealers + namesPerLine - 1) / namesPerLine) do
		local message = "Healers: "
		local index = 1 + (line - 1) * namesPerLine
		local first = true
		for i = index, math.min(numHealers, index + namesPerLine - 1) do
			if (not first) then
				message = message .. ", "
			end
			message = message .. healers[i]
			first = false
		end
		message = strtrim(message)
		
		SendChatMessage(message, ChatType, nil, nil)
	end
			
	for line = 1, math.floor((numDps + namesPerLine - 1) / namesPerLine) do
		local message = "DPS: "
		local index = 1 + (line - 1) * namesPerLine
		local first = true
		for i = index, math.min(numDps, index + namesPerLine - 1) do
			if (not first) then
				message = message .. ", "
			end
			message = message .. dpsers[i]
			first = false
		end
		message = strtrim(message)
		
		SendChatMessage(message, ChatType, nil, nil)
	end
end

function LazyRaider_SetGroupRoles()
		
	local nameCount, nameArray, _ = LazyRaider_GetGroupMembers()
	for i = 1, nameCount do
		if LazyRaider_PlayerRole[nameArray[i]] == nil and nameArray[i] ~= UnitName("player") then 
			LazyRaider_PlayerClass[UnitName(nameArray[i])] = UnitClass(nameArray[i])
			LazyRaider_PlayerRole[nameArray[i]] = { ["tank"] = tank, ["dps"] = dps, ["heal"] = heal }
			DEFAULT_CHAT_FRAME:AddMessage("|cffffff78"..nameArray[i].."|r got role DPS")	
		elseif LazyRaider_PlayerRole[nameArray[i]] == nil and nameArray[i] == UnitName("player") then
			local playerspec = ""
			local playerpoints = 0
			for i = 1, 3 do
				local specname, _, spentpoints, _ = GetTalentTabInfo(i)
				if spentpoints > playerpoints then
					playerpoints = spentpoints
					playerspec = specname
				end
			end			
			local tank, dps, heal = LazyRaider_ParseRoles(playerspec:lower())
			if (tank or heal or dps) then
				LazyRaider_PlayerClass[UnitName("player")] = UnitClass("player")
				LazyRaider_PlayerRole[UnitName("player")] = { ["tank"] = tank, ["dps"] = dps, ["heal"] = heal }
				DEFAULT_CHAT_FRAME:AddMessage("|cffffff78"..nameArray[i].."|r got role from talents tree")
			else
				DEFAULT_CHAT_FRAME:AddMessage("You have to spend a talents points to get your role")
				return false
			end
		end		
	end
	return true
	
end

function LazyRaider_ParseRoles(msg)
	return string.find(msg, "tank") ~= nil or string.find(msg, "prot") ~= nil or string.find(msg, "tang") ~= nil or string.find(msg, "feral combat") ~= nil or string.find(msg, "protection") ~= nil,
		string.find(msg, "dps") ~= nil or string.find(msg, "mage") ~= nil or string.find(msg, "arcane") ~= nil or string.find(msg, "fire") ~= nil or string.find(msg, "frost") ~= nil or string.find(msg, "rogue") ~= nil or string.find(msg, "assasin") ~= nil or string.find(msg, "combat") ~= nil or string.find(msg, "sub") ~= nil or string.find(msg, "warlock") ~= nil or string.find(msg, "lock") ~= nil or string.find(msg, "affli") ~= nil or string.find(msg, "demo") ~= nil or string.find(msg, "destro") ~= nil or string.find(msg, "ret") ~= nil or string.find(msg, "retro") ~= nil or string.find(msg, "retri") ~= nil or string.find(msg, "boomkin") ~= nil or string.find(msg, "bala") ~= nil or string.find(msg, "owl") ~= nil or string.find(msg, "fury") ~= nil or string.find(msg, "fwar") ~= nil or string.find(msg, "arms") ~= nil or string.find(msg, "awar") ~= nil or string.find(msg, "enha") ~= nil or string.find(msg, "enhancement") ~= nil or string.find(msg, "elem") ~= nil or string.find(msg, "ele") ~= nil or string.find(msg, "elemental") ~= nil or string.find(msg, "shadow") ~= nil or string.find(msg, "sp") ~= nil or string.find(msg, "spriest") ~= nil or string.find(msg, "hunter") ~= nil or string.find(msg, "hunt") ~= nil or string.find(msg, "bm") ~= nil or string.find(msg, "mm") ~= nil or string.find(msg, "surv") ~= nil or string.find(msg, "unholy") ~= nil or string.find(msg, "enh") ~= nil or string.find(msg, "moonkin") ~= nil or string.find(msg, "boomy") ~= nil or string.find(msg, "balance") ~= nil or string.find(msg, "survival") ~= nil or string.find(msg, "beast mastery") ~= nil or string.find(msg, "marksmanship") ~= nil or string.find(msg, "retribution") ~= nil or string.find(msg, "assassination") ~= nil or string.find(msg, "subtlety") ~= nil or string.find(msg, "affliction") ~= nil or string.find(msg, "demonology") ~= nil or string.find(msg, "destruction") ~= nil, 		
		string.find(msg, "heal") ~= nil or string.find(msg, "rdudu") ~= nil or string.find(msg, "holy") ~= nil or string.find(msg, "hpal") ~= nil or string.find(msg, "resto") ~= nil or string.find(msg, "coh") ~= nil or string.find(msg, "disc") ~= nil or string.find(msg, "tree") ~= nil or string.find(msg, "rsham") ~= nil or string.find(msg, "rdru") ~= nil or string.find(msg, "restoration") ~= nil or string.find(msg, "discipline") ~= nil
end

function LazyRaider_IsInGroup(name)
	
	local nameArray = { }
	
	if (GetNumRaidMembers() > 0) then
		for i = 1, 40 do
			local name = GetRaidRosterInfo(i);
			if (name ~= nil) then
				nameArray[name] = true
			end
		end
	elseif (GetNumPartyMembers() > 0) then
		nameArray[UnitName("player")] = true
		for i = 1, GetNumPartyMembers() do
			nameArray[UnitName("party" .. i)] = true
		end
	else
		nameArray[UnitName("player")] = true
	end
	
	return nameArray[name] ~= nil
	
end

function LazyRaider_ConfirmLootRoll(self, ...)

	if LazyRaider_BoP == true then
		local slotid, rolltype = ...
		ConfirmLootRoll(slotid, rolltype)
		StaticPopup_Hide("CONFIRM_LOOT_ROLL")
	end
	
end

function LazyRaider_LootBindConfirm(self, ...)

	if LazyRaider_BoP == true then
		local slot = ...
		LazyRaiderFrame:UnregisterEvent("LOOT_BIND_CONFIRM")
		LootSlot(slot)
		ConfirmLootSlot(slot)
		StaticPopup_Hide("LOOT_BIND")
		LazyRaiderFrame:RegisterEvent("LOOT_BIND_CONFIRM")
	end
	
end

function LazyRaider_OnSystemChat(self, ...)

	local arg1 = ...

	if (LazyRaider_RollCount ~= nil and string.match(arg1, "%w+[ ?].*%d %(%d%-%d%)") ~= nil) then
		local name, roll, low, high = string.match(arg1, "(%w+)[ ?].*(%d) %((%d)-(%d)%)")
		
		if (name == UnitName("player") and tonumber(low) <= tonumber(roll) and tonumber(roll) <= tonumber(high) and tonumber(low) == 1 and tonumber(high) == LazyRaider_RollCount) then
			local winner = LazyRaider_RollName[tonumber(roll)]
			SendChatMessage(winner .. " won" .. LazyRaider_ItemLink .. "!", ChatType, nil, nil)
			LazyRaider_RollCount = 0
		end
	end
	
end

function LazyRaider_OnWhisper(self, ...)

	local message, sender = ...
	local class = "Fake"
	LazyRaider_PlayerClass[sender] = class
	local lowerMsg = string.lower(message)
	
	if sender ~= UnitName("player") and not LazyRaider_IsInGroup(sender) then
		if (LazyRaider_AutoRecruit and LazyRaider_RecruitType ~= "Custom") then
		
			local tank, dps, heal = LazyRaider_ParseRoles(lowerMsg)
			if (tank or dps or heal) then
								
				LazyRaider_PlayerRole[sender] = { ["tank"] = tank, ["dps"] = dps, ["heal"] = heal }
				
				if (LazyRaider_NeedPlayer(class, tank, dps, heal)) then
					InviteUnit(sender)
				else
					SendChatMessage("Sorry, we don't need your role right now.", "WHISPER", nil, sender)
				end

			else
				SendChatMessage("Please, whisper me with the role(s) you wish to join as. Roles: tank, dps, heal.", "WHISPER", nil, sender)
			end
		
		elseif (LazyRaider_AutoInvite and (string.find(lowerMsg, "inv") ~= nil)) then
			InviteUnit(sender)
		end
		
	end
	
end

function LazyRaider_OnUpdate(self, elapsed)
	
	LazyRaider_LastAnnounce = LazyRaider_LastAnnounce + elapsed
		
	if (LazyRaider_AutoRecruit and LazyRaider_LastAnnounce >= LazyRaider_Interval) then
		
		if (LazyRaider_RecruitType == "Group(d5)") then
			local memberCount, _, _ = LazyRaider_GetGroupMembers()
			local _, _, _, numTanks, numHealers, numDps = LazyRaider_GetRoles()		
			LazyRaider_Message = LazyRaider_DungeonName .. "."
			if (numTanks < LazyRaider_RequiredTanks) then
				LazyRaider_Message = LazyRaider_Message .. " " .. (LazyRaider_RequiredTanks - numTanks) .. LazyRaider_Trigraph((LazyRaider_RequiredTanks - numTanks) > 1, " Tanks", " Tank")
			end
			if (numHealers < LazyRaider_RequiredHealers) then
				LazyRaider_Message = LazyRaider_Message .. " " .. (LazyRaider_RequiredHealers - numHealers) .. LazyRaider_Trigraph((LazyRaider_RequiredHealers - numHealers) > 1, " Healers", " Healer")
			end
			if (numDps < LazyRaider_RequiredDps) then
				LazyRaider_Message = LazyRaider_Message .. " " .. (LazyRaider_RequiredDps - numDps) .. " DPS"
			end	
			LazyRaider_Message = "LF"..(5-memberCount).."M "..LazyRaider_Message..". Send whisper with your role!"
			SendChatMessage("" .. LazyRaider_Message, LazyRaider_Channel, nil, LazyRaider_ChannelId)
			LazyRaider_LastAnnounce = 0
		elseif (LazyRaider_RecruitType == "Group(d10)") then
			local memberCount, _, _ = LazyRaider_GetGroupMembers()
			local _, _, _, numTanks, numHealers, numDps = LazyRaider_GetRoles()		
			LazyRaider_Message = LazyRaider_DungeonName .. "."
			if (numTanks < LazyRaider_RequiredTanks) then
				LazyRaider_Message = LazyRaider_Message .. " " .. (LazyRaider_RequiredTanks - numTanks) .. LazyRaider_Trigraph((LazyRaider_RequiredTanks - numTanks) > 1, " Tanks", " Tank")
			end
			if (numHealers < LazyRaider_RequiredHealers) then
				LazyRaider_Message = LazyRaider_Message .. " " .. (LazyRaider_RequiredHealers - numHealers) .. LazyRaider_Trigraph((LazyRaider_RequiredHealers - numHealers) > 1, " Healers", " Healer")
			end
			if (numDps < LazyRaider_RequiredDps) then
				LazyRaider_Message = LazyRaider_Message .. " " .. (LazyRaider_RequiredDps - numDps) .. " DPS"
			end	
			LazyRaider_Message = "LF"..(10-memberCount).."M "..LazyRaider_Message..". Send whisper with your role!"
			SendChatMessage("" .. LazyRaider_Message, LazyRaider_Channel, nil, LazyRaider_ChannelId)
			LazyRaider_LastAnnounce = 0
		elseif (LazyRaider_RecruitType == "Group(d25)") then
			local memberCount, _, _ = LazyRaider_GetGroupMembers()
			local _, _, _, numTanks, numHealers, numDps = LazyRaider_GetRoles()		
			LazyRaider_Message = LazyRaider_DungeonName .. "."
			if (numTanks < LazyRaider_RequiredTanks) then
				LazyRaider_Message = LazyRaider_Message .. " " .. (LazyRaider_RequiredTanks - numTanks) .. LazyRaider_Trigraph((LazyRaider_RequiredTanks - numTanks) > 1, " Tanks", " Tank")
			end
			if (numHealers < LazyRaider_RequiredHealers) then
				LazyRaider_Message = LazyRaider_Message .. " " .. (LazyRaider_RequiredHealers - numHealers) .. LazyRaider_Trigraph((LazyRaider_RequiredHealers - numHealers) > 1, " Healers", " Healer")
			end
			if (numDps < LazyRaider_RequiredDps) then
				LazyRaider_Message = LazyRaider_Message .. " " .. (LazyRaider_RequiredDps - numDps) .. " DPS"
			end	
			LazyRaider_Message = "LF"..(25-memberCount).."M "..LazyRaider_Message..". Send whisper with your role!"
			SendChatMessage("" .. LazyRaider_Message, LazyRaider_Channel, nil, LazyRaider_ChannelId)
			LazyRaider_LastAnnounce = 0			
		elseif (LazyRaider_RecruitType == "Custom") then
			SendChatMessage(LazyRaider_DungeonName, LazyRaider_Channel, nil, LazyRaider_ChannelId)
			LazyRaider_LastAnnounce = 0	
		end
	end
	
end

function LazyRaider_OnMembersChanged(self, ...)
	
	if (string.find(LazyRaider_RecruitType, "d5") ~= nil) then
		local memberCount, _, _ = LazyRaider_GetGroupMembers()
		if (memberCount == 5 and LazyRaider_AutoRecruit) then
			
			LazyRaider_AutoRecruit = false
			LazyRaider_RequiredAchievement = nil
			
			LazyRaider_ShowRoles()
			
		end
	elseif (string.find(LazyRaider_RecruitType, "d10") ~= nil) then
		local memberCount, _, _ = LazyRaider_GetGroupMembers()
		if (memberCount >= 2 and GetNumRaidMembers() == 0) then
			ConvertToRaid()
			SetRaidDifficulty(1)
		end
		if (memberCount == 10 and LazyRaider_AutoRecruit) then
			
			LazyRaider_AutoRecruit = false
			LazyRaider_RequiredAchievement = nil
			
			LazyRaider_ShowRoles()
			
		end
	elseif (string.find(LazyRaider_RecruitType, "d25") ~= nil) then
		local memberCount, _, _ = LazyRaider_GetGroupMembers()
		if (memberCount >= 2 and GetNumRaidMembers() == 0) then
			ConvertToRaid()
			SetRaidDifficulty(2)
		end
		if (memberCount == 25 and LazyRaider_AutoRecruit) then
			
			LazyRaider_AutoRecruit = false
			LazyRaider_RecruitType = "None"
			
			LazyRaider_ShowRoles()
			
		end
	end

end

function LazyRaider_NeedPlayer(class, tank, dps, heal)

	local nameCount, nameArray, _  = LazyRaider_GetGroupMembers()
	
	local numTanks, numDps, numHealers = 0, 0, 0
	local possibleTanks, possibleHealers = 4 * LazyRaider_ClassCap, 4 * LazyRaider_ClassCap
	
	local tankClasses = { ["Warrior"] = true, ["Paladin"] = true, ["Druid"] = true, ["Fake"] = true }
	local healerClasses = { ["Priest"] = true, ["Shaman"] = true, ["Paladin"] = true, ["Druid"] = true, ["Fake"] = true }
	
	if (nameCount >= 1) then
		
		for i = 1, nameCount do
			if (tankClasses[LazyRaider_PlayerClass[nameArray[i]]]) then
				possibleTanks = possibleTanks - 1
			end
			if (healerClasses[LazyRaider_PlayerClass[nameArray[i]]]) then
				possibleHealers = possibleHealers - 1
			end
			
			if (numTanks < LazyRaider_RequiredTanks and LazyRaider_PlayerRole[nameArray[i]].tank) then
				numTanks = numTanks + 1
			elseif (numHealers < LazyRaider_RequiredHealers and LazyRaider_PlayerRole[nameArray[i]].heal) then
				numHealers = numHealers + 1
			elseif (numDps < LazyRaider_RequiredDps and LazyRaider_PlayerRole[nameArray[i]].dps) then
				numDps = numDps + 1
			end
		end
		
		if (numTanks < LazyRaider_RequiredTanks and tank and tankClasses[class] and LazyRaider_Trigraph(healerClasses[class], possibleHealers - 1 + numHealers >= LazyRaider_RequiredHealers, true)) then
			return true
		end
		if (numDps < LazyRaider_RequiredDps and dps and LazyRaider_Trigraph(healerClasses[class], possibleHealers - 1 + numHealers >= LazyRaider_RequiredHealers, true) and LazyRaider_Trigraph(tankClasses[class], possibleTanks - 1 + numTanks >= LazyRaider_RequiredTanks, true)) then
			return true
		end
		if (numHealers < LazyRaider_RequiredHealers and heal and healerClasses[class] and LazyRaider_Trigraph(tankClasses[class], possibleTanks - 1 + numTanks >= LazyRaider_RequiredTanks, true)) then
			return true
		end

	end
	
	return false

end

function LazyRaider_Trigraph(condition, iftrue, iffalse)
	if (condition) then
		return iftrue
	else
		return iffalse
	end
end

--[[

	LazyRaiderWindow Buttons 

]]

function LazyRaider_ChangeRole_Name()
	
	local nameCount, nameArray, _ = LazyRaider_GetGroupMembers()
	for i = 1, nameCount do
		local info = UIDropDownMenu_CreateInfo()
		info.text = nameArray[i]
		info.arg1 = nameArray[i]
		info.func = LazyRaider_ChangeRole_NameSelect
		UIDropDownMenu_AddButton(info)
	end
	
end

function LazyRaider_ChangeRole_NameSelect(self, arg1, arg2, checked)

	if (not checked) then	
		--UIDropDownMenu_SetSelectedValue(LazyRaiderWindow_ChangeRole_NameMenu, self.value)
		LazyRaider_CRBuffer = self
		LazyRaiderWindow_ChangeRole_NameButton:SetText(self)
	end
	
end

function LazyRaider_ChangeRole_Role()
	
	local roles = { [1] = "Tank", [2] = "Dps", [3] = "Heal", }
	for k,v in ipairs(roles) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = v
		info.arg1 = v
		info.func = LazyRaider_ChangeRole_RoleSelect
		UIDropDownMenu_AddButton(info)
	end
	
end

function LazyRaider_ChangeRole_RoleSelect(self, arg1, arg2, checked)

		if LazyRaider_CRBuffer then		
			--UIDropDownMenu_SetSelectedValue(LazyRaiderWindow_ChangeRole_RoleMenu, self.value)
			LazyRaider_ChangeRole(LazyRaider_CRBuffer.." "..self)
		else 
			DEFAULT_CHAT_FRAME:AddMessage("You should choose name")
		end
	
end

function LazyRaiderWindow_Recruit_Mod()
	
	for k, v in pairs(LazyRaider_DungeonMod) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = k
		info.arg1 = k			
		info.func = LazyRaiderWindow_Recruit_ModSelect
		UIDropDownMenu_AddButton(info)
	end
	
end

function LazyRaiderWindow_Recruit_ModSelect(self, arg1, arg2, checked)

	if (not checked) then
		--UIDropDownMenu_SetSelectedValue(LazyRaiderWindow_Recruit_ModMenu, self.value)
		LazyRaiderWindow_Recruit_ModBuffer = self
		LazyRaiderWindow_Recruit_ModButton:SetText(self)
	end
	
end

function LazyRaiderWindow_Recruit_Channel()
	
	for k,v in pairs(LazyRaider_ChannelNumeric) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = v
		info.arg1 = v		
		info.func = LazyRaiderWindow_Recruit_ChannelSelect
		UIDropDownMenu_AddButton(info)
	end
	
	for k,v in pairs(LazyRaider_ChannelAlphabetical) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = v
		info.arg1 = v		
		info.func = LazyRaiderWindow_Recruit_ChannelSelect
		UIDropDownMenu_AddButton(info)
	end	
	
end

function LazyRaiderWindow_Recruit_ChannelSelect(self, arg1, arg2, checked)

	if (not checked) then
		--UIDropDownMenu_SetSelectedValue(LazyRaiderWindow_Recruit_ChannelMenu, self.value)
		LazyRaiderWindow_Recruit_ChannelBuffer = self
		LazyRaiderWindow_Recruit_ChannelButton:SetText(self)
	end
	
end

function LazyRaiderWindow_Recruit_Interval()
	
	local intervals = { [1] = "30", [2] = "45", [3] = "60", [4] = "90", [5] = "120", [6] = "180", [7] = "240", [8] = "300", [9] = "450", [10] = "600"}
	for k,v in ipairs(intervals) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = v
		info.arg1 = v			
		info.func = LazyRaiderWindow_Recruit_IntervalSelect
		UIDropDownMenu_AddButton(info)
	end
	
end

function LazyRaiderWindow_Recruit_IntervalSelect(self, arg1, arg2, checked)

	if (not checked) then
		--UIDropDownMenu_SetSelectedValue(LazyRaiderWindow_Recruit_IntervalMenu, self.value)
		LazyRaiderWindow_Recruit_IntervalBuffer = self
		LazyRaiderWindow_Recruit_IntervalButton:SetText(self)
	end
	
end