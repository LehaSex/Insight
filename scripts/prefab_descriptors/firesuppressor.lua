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

-- firesupressor.lua [Prefab]
local function OnFireSuppressorSpawned(inst)
	--[[
	local a = SpawnPrefab("insight_range_indicator")
	rawset(_G, "a", a)
	a:Attach(inst)
	a:SetRadius(4 / WALL_STUDS_PER_TILE)
	a:SetColour(Color.fromHex("#ff0000"))
	a:SetVisible(true)
	--]]
	
	-- tuning says default range is 15
	inst.snowball_range = SpawnPrefab("insight_range_indicator")
	inst.snowball_range:Attach(inst)
	inst.snowball_range:SetRadius(TUNING.FIRE_DETECTOR_RANGE / WALL_STUDS_PER_TILE)
	inst.snowball_range:SetColour(Color.fromHex(Insight.COLORS.WET))
	inst.snowball_range:SetVisible(false)

	inst:AddComponent("dst_deployhelper")
	inst.components.dst_deployhelper.onenablehelper = OnHelperStateChange
end

local function OnClientInit()
	if not IS_DS then return end
	AddPrefabPostInit("firesuppressor", OnFireSuppressorSpawned)
end

return {
	OnClientInit = OnClientInit
}