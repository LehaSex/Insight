--[[
Copyright (C) 2020, 2021 penguin0616

This file is part of Insight.

The source code of this program is shared under the RECEX
SHARED SOURCE LICENSE (version 1.0).
The source code is shared for referrence and academic purposes
with the hope that people can read and learn from it. This is not
Free and Open Source software, and code is not redistributable
without permission of the author. Read the RECEX SHARED
SOURCE LICENSE for details
The source codes does not come with any warranty including
the implied warranty of merchandise.
You should have received a copy of the RECEX SHARED SOURCE
LICENSE in the form of a LICENSE file in the root of the source
directory. If not, please refer to
<https://raw.githubusercontent.com/Recex/Licenses/master/SharedSourceLicense/LICENSE.txt>
]]

-- This file is responsible for dealing with controls.
--------------------------------------------------------------------------
--[[ Private Variables ]]
--------------------------------------------------------------------------
local _string, xpcall, package, tostring, print, os, unpack, require, getfenv, setmetatable, next, assert, tonumber, io, rawequal, collectgarbage, getmetatable, module, rawset, math, debug, pcall, table, newproxy, type, coroutine, _G, select, gcinfo, pairs, rawget, loadstring, ipairs, _VERSION, dofile, setfenv, load, error, loadfile = string, xpcall, package, tostring, print, os, unpack, require, getfenv, setmetatable, next, assert, tonumber, io, rawequal, collectgarbage, getmetatable, module, rawset, math, debug, pcall, table, newproxy, type, coroutine, _G, select, gcinfo, pairs, rawget, loadstring, ipairs, _VERSION, dofile, setfenv, load, error, loadfile
local TheInput, TheInputProxy, TheGameService, TheShard, TheNet, FontManager, PostProcessor, TheItems, EnvelopeManager, TheRawImgui, ShadowManager, TheSystemService, TheInventory, MapLayerManager, RoadManager, TheLeaderboards, TheSim = TheInput, TheInputProxy, TheGameService, TheShard, TheNet, FontManager, PostProcessor, TheItems, EnvelopeManager, TheRawImgui, ShadowManager, TheSystemService, TheInventory, MapLayerManager, RoadManager, TheLeaderboards, TheSim

local CONTROLS_REVERSE = {}

local control_cache = {}

local KNOWN_CONTROLS = {
	LEFT_ANALOG_CLICK = (IS_DST and CONTROL_MENU_MISC_3) or nil, -- 70 | nil
	RIGHT_ANALOG_CLICK = (IS_DST and CONTROL_MENU_MISC_4) or CONTROL_OPEN_DEBUG_MENU, -- 71 | 62
}
setmetatable(KNOWN_CONTROLS, {
	__index = function(self, index)
		errorf("Attempt to retrieve KNOWN_CONTROL '%s', which does not exist right now.", index)
	end
})

-- print(TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_OPEN_DEBUG_MENU))

--------------------------------------------------------------------------
--[[ Private Functions ]]
--------------------------------------------------------------------------
local function OnControlMapped(deviceId, controlId, inputId, hasChanged)
	print("CTRL CHANGE:", deviceId, controlId, inputId, hasChanged) -- does this ever actually happen?
end

local function OnControl() end

--------------------------------------------------------------------------
--[[ Exported Functions ]]
--------------------------------------------------------------------------
local function Prettify(control)
	return "[" .. (CONTROLS_REVERSE[control] or "<UNKNOWN>") .. " - " .. control .. "]"
end
--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------
require("constants")
for i,v in pairs(getfenv(0)) do
	if i:sub(1, #("CONTROL_")) == "CONTROL_" and type(v) == "number" then
		CONTROLS_REVERSE[v] = i
	end
end
--[[
-- Probably will need these, but whatever for now.
CONTROLS_REVERSE[1] = MOVE_UP
CONTROLS_REVERSE[2] = MOVE_DOWN
CONTROLS_REVERSE[3] = MOVE_LEFT
CONTROLS_REVERSE[4] = MOVE_RIGHT
--]]

--TheInput:OnControlMapped(OnControlMapped)
--TheInput:AddControlHandler(OnControl)

return {
	KNOWN_CONTROLS = KNOWN_CONTROLS,
	CONTROLS_REVERSE = CONTROLS_REVERSE,

	Prettify = Prettify
}