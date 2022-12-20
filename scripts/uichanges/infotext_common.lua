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

local configs_to_load = {
	"DEBUG_SHOW_PREFAB", "hoverer_insight_font_size", "inventorybar_insight_font_size", 
	"followtext_insight_font_size", "alt_only_information", "hover_range_indicator", "extended_info_indicator"
}

local module = {
	configs = {},
	new_configs = ClientCoreEventer:CreateEvent("new_configs"),
}

module.Initialize = function()
	if module.initialized then
		--errorf("Cannot initialize %s more than once.", debug.getinfo(1, "S"):match("([%w_]+)%.lua$"))
		return module
	end

	for i,v in pairs(configs_to_load) do
		module.configs[v] = GetModConfigData(v, true)
	end

	OnContextUpdate:AddListener("infotext_common", function(context) 
		for i,v in pairs(configs_to_load) do
			module.configs[v] = context.config[v]
		end

		module.new_configs:Push(module.configs)
	end)


	module.initialized = true

	return module
end

--[[
setmetatable(module, {
	__index = module.configs
})
--]]

return module