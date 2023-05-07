local icon = LibStub("LibDBIcon-1.0")

LazyRaiderBroker = LibStub("LibDataBroker-1.1"):NewDataObject("LazyRaiderI", {

	type = "data source",
	text = "LazyRaider",
	icon = "Interface\\AddOns\\LazyRaider\\Icon"
	
})

function LazyRaiderBroker.OnTooltipShow(tooltip)

	if LazyRaider_AutoRecruit == false then
		tooltip:AddLine("                         LazyRaider")
	elseif LazyRaider_AutoRecruit == true then
		tooltip:AddLine("              Broadcasting In Progress...")
		tooltip:AddLine(" ")
	end
	if  LazyRaider_AutoRecruit == true then
		tooltip:AddLine("|cff00ee00Mod|r |cffeda55f"..LazyRaider_RecruitType.."|r |cff00ee00to channel|r |cffeda55f"..LazyRaider_Channel.."|r |cff00ee00with|r |cffeda55f"..SecondsToTime(LazyRaider_Interval).."|r |cff00ee00interval|r")
		tooltip:AddLine("|cff00ee00New message in|r |cffeda55f"..SecondsToTime(LazyRaider_Interval - LazyRaider_LastAnnounce).."|r")
	end	
	tooltip:AddLine(" ")
	tooltip:AddLine("|cffeda55fLeftButton|r |cff00ee00click to open LazyRaider window|r")
	

end

function LazyRaiderBroker.OnClick(self, button)
	
	if button == "RightButton" then
		DEFAULT_CHAT_FRAME:AddMessage("Sorry! RightButton click do nothing at this moment")
	elseif button == "LeftButton" then
		if LazyRaiderWindow:IsShown() then
			LazyRaiderWindow:Hide()
		else
			LazyRaiderWindow:Show()
		end
	end
	
end