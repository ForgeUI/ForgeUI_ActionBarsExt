----------------------------------------------------------------------------------------------
-- Client Lua Script for ForgeUI addon
--
-- name: 		ForgeUI_BarsExt.lua
-- author:		Winty Badass@Jabbit
-- about:		Action bars extension addon
-----------------------------------------------------------------------------------------------

require "Window"

local F = _G["ForgeLibs"]["ForgeUI"] -- ForgeUI API
local G = _G["ForgeLibs"]["ForgeGUI"] -- ForgeGUI

local Util = F:API_GetModule("util")

local ActionBars -- ForgeUI_ActionBars addon

-----------------------------------------------------------------------------------------------
-- ForgeUI Addon Definition
-----------------------------------------------------------------------------------------------
local ForgeUI_ActionBarsExt = {
	_NAME = "ForgeUI_ActionBarsExt",
	_API_VERSION = 3,
	_VERSION = "1.0",
	DISPLAY_NAME = "Action bars ext",

	tSettings = {
		profile = {
			tFrames = {
			}
		},
		global = {
			tKeys = {
			}
		}
	}
}

local constDefaultBar = {
	strKey = "ForgeUI_UtilBarOne",
	strName = "Utility bar 1",
	strSnapTo = "bottom",
	tMove = { 0, -55 },
	nButtons = 1,
	tButtons = {  },
	nButtonSize = 50,
	nRows = 1,
	nColumns = 1,
	nMinId = 0,
	nButtonPaddingVer = 3,
	nButtonPaddingHor = 3,
	bDrawHotkey = true,
	bDrawShortcutBottom = false,
	bShow = true,
	bHideOOC = false,
}

local strProfile = ""

function ForgeUI_ActionBarsExt:ForgeAPI_Init()
	self.wndMenuItem = F:API_AddMenuItem(self, self.DISPLAY_NAME, "General")
	self.tSubMenuItems = {}

	ActionBars = Apollo.GetAddon("ForgeUI_ActionBars")
end

function ForgeUI_ActionBarsExt:ForgeAPI_LoadSettings()
	for strKey in pairs(self._DB.global.tKeys) do
		local bExists = false
		for _, tBar in pairs(self._DB.profile.tFrames) do
			if strKey == tBar.strKey then
				bExists = true
				break
			end
		end

		if not bExists then
			local tBar = ActionBars:API_GetTBar(strKey)
			if tBar then
				ActionBars:API_GetTBars()[strKey] = nil
				tBar:Destroy()
				F:API_DestroyMover(self, strKey)
				F:API_RemoveMenuItem(self.tSubMenuItems[strKey])
			end
		end
	end

	for _, v in pairs(self._DB.profile.tFrames) do
		local tBar = ActionBars:API_GetTBar(v.strKey)
		if not tBar then
			self:GenerateBar(v)
			self.tSubMenuItems[v.strKey] = F:API_AddMenuToMenuItem(self, self.wndMenuItem, v.strName, v.strKey)
		end
		self:SetupBar(v)
	end
end

function ForgeUI_ActionBarsExt:SetupBar(tBar)
	ActionBars:SetupBar(tBar, false, true)
	ActionBars:SetupButtons(tBar)
	ActionBars:EditButtons(tBar)
	ActionBars:PositionButtons(tBar)
end

function ForgeUI_ActionBarsExt:ForgeAPI_PopulateOptions()
	local wndGeneral = self.tOptionHolders["General"]

	-- new bar
	G:API_EditBox(self, wndGeneral, "", nil, nil, {
		strHint = "New bar (enter to confirm)",
		tWidths = { 195, 0 },
		tMove = { 0, 0 },
		fnCallbackReturn = self.NewBar,
	})

	-- remove bar
	local wndRemoveBarCombo = G:API_AddComboBox(self, wndGeneral, "Remove bar", nil, nil, { tMove = {200, 0}, tWidths = { 150, 200 }, 
		fnCallback = (function(module, value, key)
			self._DB.profile.tFrames[value] = nil
			self:RefreshConfig()
		end)
	})
	for k, v in pairs(self._DB.profile.tFrames) do
		G:API_AddOptionToComboBox(self, wndRemoveBarCombo, v.strName, k)
	end

	for k, v in pairs(self._DB.profile.tFrames) do
		local wnd = self.tOptionHolders[v.strKey]

		if v.bShow ~= nil then
			G:API_AddCheckBox(self, wnd, "Show", v, "bShow", { tMove = {0, 0},
				fnCallback = function(...) ActionBars:SetupBar(v) end })
		end

		if v.bShowMouseover ~= nil then
			G:API_AddCheckBox(self, wnd, "Show on mouseover", v, "bShowMouseover", { tMove = {200, 0},
				fnCallback = function(...) ActionBars:SetupBar(v) end })
		end

		if v.bHideOOC ~= nil then
			G:API_AddCheckBox(self, wnd, "Hide out of combat", v, "bHideOOC", { tMove = {400, 0},
				fnCallback = function(...) ActionBars:SetupBar(v) end })
		end

		if v.bDrawHotkey ~= nil then
			G:API_AddCheckBox(self, wnd, "Show hotkey", v, "bDrawHotkey", { tMove = {0, 30},
				fnCallback = function(...) ActionBars:EditButtons(v) end })
		end

		if v.bDrawShortcutBottom ~= nil then
			G:API_AddCheckBox(self, wnd, "Use bottom-styled hotkey", v, "bDrawShortcutBottom", { tMove = {10, 60},
				fnCallback = function(...) ActionBars:EditButtons(v) end })
		end

		if v.nButtons ~= nil then
			G:API_AddNumberBox(self, wnd, "Number of buttons ", v, "nButtons", {
  				tMove = {200, 30},
				fnCallback = function(...) ActionBars:SetupButtons(v); ActionBars:EditButtons(v); ActionBars:PositionButtons(v, true) end
			})
		end

		if v.nButtonSize ~= nil then
			G:API_AddNumberBox(self, wnd, "Button size ", v, "nButtonSize", { tMove = {400, 30},
				fnCallback = function(...) ActionBars:PositionButtons(v, true) end })
		end

		if v.nRows ~= nil then
			G:API_AddNumberBox(self, wnd, "Rows ", v, "nRows", { tMove = {200, 90},
				fnCallback = function(...) ActionBars:PositionButtons(v, true) end })
		end

		if v.nColumns ~= nil then
			G:API_AddNumberBox(self, wnd, "Columns ", v, "nColumns", { tMove = {200, 120},
				fnCallback = function(...) ActionBars:PositionButtons(v, true) end })
		end

		if v.nButtonPaddingHor ~= nil then
			G:API_AddNumberBox(self, wnd, "Horizontal padding ", v, "nButtonPaddingHor", { tMove = {400, 90},
				fnCallback = function(...) ActionBars:PositionButtons(v, true) end })
		end

		if v.nButtonPaddingVer ~= nil then
			G:API_AddNumberBox(self, wnd, "Vertical padding ", v, "nButtonPaddingVer", { tMove = {400, 120},
				fnCallback = function(...) ActionBars:PositionButtons(v, true) end })
		end

		if v.tButtons ~= nil then
			local wndAddSpecialCombo = G:API_AddComboBox(self, wnd, "Add utility bar button", nil, nil, { tMove = {0, 210}, tWidths = { 100, 300 }, 
				fnCallback = (function(module, value, key)
					table.insert(v.tButtons, value)
					self:RefreshConfig()
				end)
			})
			G:API_AddOptionToComboBox(self, wndAddSpecialCombo, "Stance", { 2, "GCBar" })
			G:API_AddOptionToComboBox(self, wndAddSpecialCombo, "Mount", { 26, "GCBar" })
			G:API_AddOptionToComboBox(self, wndAddSpecialCombo, "Recall", { 18, "GCBar" })
			G:API_AddOptionToComboBox(self, wndAddSpecialCombo, "Gadget", { 0, "GCBar" })
			G:API_AddOptionToComboBox(self, wndAddSpecialCombo, "Potion", { 27, "GCBar" })
			G:API_AddOptionToComboBox(self, wndAddSpecialCombo, "Path", { 2, "LASBar" })

			local wndAddActionCombo = G:API_AddComboBox(self, wnd, "Add action bar button", nil, nil, { tMove = {0, 180}, tWidths = { 100, 300 }, 
				fnCallback = (function(module, value, key)
					table.insert(v.tButtons, value)
					self:RefreshConfig()
				end)
			})
			G:API_AddOptionToComboBox(self, wndAddActionCombo, "Action 1", { 0, "LASBar" })
			G:API_AddOptionToComboBox(self, wndAddActionCombo, "Action 2", { 1, "LASBar" })
			G:API_AddOptionToComboBox(self, wndAddActionCombo, "Action 3", { 2, "LASBar" })
			G:API_AddOptionToComboBox(self, wndAddActionCombo, "Action 4", { 3, "LASBar" })
			G:API_AddOptionToComboBox(self, wndAddActionCombo, "Action 5", { 4, "LASBar" })
			G:API_AddOptionToComboBox(self, wndAddActionCombo, "Action 6", { 5, "LASBar" })
			G:API_AddOptionToComboBox(self, wndAddActionCombo, "Action 7", { 6, "LASBar" })
			G:API_AddOptionToComboBox(self, wndAddActionCombo, "Action 8", { 7, "LASBar" })

			local wndRemoveCombo = G:API_AddComboBox(self, wnd, "Remove button at index", nil, nil, { tMove = {350, 180}, tWidths = { 100, 300 }, 
				fnCallback = (function(module, value, key)
					table.remove(v.tButtons, value)
					self:RefreshConfig()
				end)
			})
			for k in pairs(v.tButtons) do
				G:API_AddOptionToComboBox(self, wndRemoveCombo, tostring(k), k)
			end
		end
	end
end

function ForgeUI_ActionBarsExt:GenerateBar(tBar)
	local wndNewBar = ActionBars:API_GetTBar(tBar.strKey)
	if not wndNewBar then
		wndNewBar = Apollo.LoadForm(ActionBars.xmlDoc, "ForgeUI_Bar", F:API_GetStratum("HudHigh"), ActionBars)
		wndNewBar:SetData(tBar)
		wndNewBar:AddEventHandler("MouseEnter", "OnMouseEnter", ActionBars)
		wndNewBar:AddEventHandler("MouseExit", "OnMouseExit", ActionBars)

		ActionBars:API_GetTBars()[tBar.strKey] = wndNewBar
	end

	return wndNewBar
end

function ForgeUI_ActionBarsExt:NewBar(strName)
	local tNewBar = Util:CopyTable(nil, constDefaultBar)

	tNewBar.strKey = "ForgeUI_CustomBar_" .. Util:MakeString(8)
	tNewBar.strName = strName

	self._DB.profile.tFrames[#self._DB.profile.tFrames + 1] = Util:CopyTable(nil, tNewBar)
	self._DB.global.tKeys[tNewBar.strKey] = true

	self:RefreshConfig()
end

F:API_NewAddon(ForgeUI_ActionBarsExt, { arDependencies = { "ForgeUI_ActionBars" } })
