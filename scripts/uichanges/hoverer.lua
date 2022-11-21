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

local module = {}

local DEBUG_SHOW_PREFAB = GetModConfigData("DEBUG_SHOW_PREFAB", true)
local RichText = import("widgets/RichText")

AddLocalPlayerPostInit(function(_, context) 
	DEBUG_SHOW_PREFAB = context.config["DEBUG_SHOW_PREFAB"] 
end)

local HOVERER_TEXT_SIZE = 30
local TEXT_SIZE = 30
local GetMouseTargetItem = GetMouseTargetItem
local RequestEntityInformation = RequestEntityInformation
local TheSim = TheSim
local debug_getinfo = debug.getinfo
local math_clamp = math.clamp
local string_find = string.find
local string_sub = string.sub
local math_ceil = math.ceil
local TheInput_IsKeyDown = TheInput.IsKeyDown
local TheInputProxy_GetLocalizedControl = TheInputProxy.GetLocalizedControl
local TheInput_IsControlPressed = TheInput.IsControlPressed
local CONTROL_FORCE_INSPECT = CONTROL_FORCE_INSPECT
local CONTROL_FORCE_TRADE = CONTROL_FORCE_TRADE

local informationOnAltOnly
local canShowItemRange
local canShowExtendedInfoIndicator

local function OnHovererPostInit(hoverer)
	local oldSetString = hoverer.text.SetString
	local oldOnUpdate = hoverer.OnUpdate
	local oldHide = hoverer.text.Hide
	local oldHide2 = hoverer.secondarytext.Hide

	--local altOnlyIsVerbose
	hoverer.insightText = hoverer:AddChild(RichText(UIFONT, TEXT_SIZE))

	-- so, there's an issue where once you examine something, YOFFSETUP and YOFFSETDOWN are changed to compensate for that secondary text, but are never changed back
	-- so whereas normally hover text is unable to follow below a certain height because of math.min, the new YOFFSETUP means it is free to roam wherever vertically
	-- nothing like having to fix klei bugs myself because you literally can't report don't starve bugs

	-- this gets spam called
	function hoverer.text.Hide(self)
		if self.shown then 
			--GetMouseTargetItem() -- i could probably do this better, eh?
			if canShowItemRange and currentlySelectedItem ~= nil then
				OnCurrentlySelectedItemChanged(currentlySelectedItem, nil)
				currentlySelectedItem = nil
			end
			oldHide(self)
		end
	end

	function hoverer.secondarytext.Hide(self)
		if IS_DS then
			util.replaceupvalue(debug_getinfo(2).func, "YOFFSETUP", 40)
			util.replaceupvalue(debug_getinfo(2).func, "YOFFSETDOWN", 30)
		end

		if self.shown then
			oldHide2(self)
		end
	end
	-- TheInput:GetScreenPosition()

	if IS_DST then
		local YOFFSETUP = -80
		local YOFFSETDOWN = -50
		
		local XOFFSET = 10
		function hoverer:UpdatePosition(x, y)
			local scale = self:GetScale()
			local scr_w, scr_h = TheSim:GetScreenSize()
			local w = 0
			local h = 0

			local binx = 0

			local still_primary_text = false
			if self.text ~= nil and self.str ~= nil then
				local w0, h0 = self.text:GetRegionSize()
				--local str = 
				--local num_trailing_newlines = select(2, :gsub("\n", "\n"))
				--print("Text RegionSize:", h0)
				--h0 = h0 - num_trailing_newlines * self.text:GetSize()
				still_primary_text = true

				w = math.max(w, w0)
				h = math.max(h, h0)
				binx = binx + h0
			end

			
			if self.secondarytext ~= nil and self.secondarystr ~= nil then
				local w1, h1 = self.secondarytext:GetRegionSize()
				print("SecondaryText RegionSize:", h1)
				if h1 > h then
					still_primary_text = false
				end

				w = math.max(w, w1)
				h = math.max(h, h1)
				binx = binx + h1
			end

			
			local iw, ih = 0, 0
			local old_h = h
			if self.insightText ~= nil and self.insightText:GetString() then
				iw, ih = self.insightText:GetRegionSize()
				print("InsightText RegionSize:", ih)
				--print("InsightRegionSize:", ih)

				if still_primary_text then
					-- Remove Insight's size from the height
					h = h - ih
					print("Text RegionSize CHANGED:", h)
				end

				w = math.max(w, iw)
				h = math.max(h, ih)
				binx = binx + ih
			end


			

			w = w * scale.x * .5
			h = h * scale.y * .5

			-- (self.insightText.line_count * self.insightText.font_size) --
			--local r = select(2, self.text:GetString():gsub("\n", "\n")) + 1
			--  + self.insightText.font_size * .75

			local x_min = w + XOFFSET
			local x_max = scr_w - w - XOFFSET

			--local c = select(2, RichText.TrimNewlines(self.text:GetString()):gsub("\n", "\n"))

			-- I just kept making educated guessing and and maxing with this alt_y_min worked.
			-- Originally, there was a padding of 30*.75 here for some reason.
			--local alt_y_min = (ih/2 + (old_h+30)/2) * scale.y * .5
			-- Seems like the default y_min never gets used, but I don't care about that for now.

			local alt_y_min = (ih)-- * scale.y * .5
			
			local left_min = h + (YOFFSETDOWN * scale.y)

			local y_min = math.max(left_min, alt_y_min)
			local y_max = scr_h - h - YOFFSETUP * scale.y

			--print(left_min, "|", alt_y_min)

			--  + (5 + self.insightText.font_size * 2.75)

			self:SetPosition(
				math_clamp(x, x_min, x_max),
				math_clamp(y, y_min, y_max),
				0
			)
		end
	end
	
	function hoverer.OnUpdate(self, ...)
		if not self.text.shown then
			self.insightText:SetString(nil) -- this ends up causing some delay for text positioning?
		end

		oldOnUpdate(self, ...)
	end

	hoverer.text.SetString = function(self, text)
		if not localPlayer then
			return oldSetString(self, text)
		end

		if informationOnAltOnly == nil then
			informationOnAltOnly = GetModConfigData("alt_only_information", true)
		end

		if canShowItemRange == nil then
			canShowItemRange = GetModConfigData("hover_range_indicator", true)
		end

		if canShowExtendedInfoIndicator == nil then
			canShowExtendedInfoIndicator = GetModConfigData("extended_info_indicator", true)
		end

		--[[
		if altOnlyIsVerbose == nil then
			altOnlyIsVerbose = GetModConfigData("alt_only_is_verbose", true)
		end
		--]]

		--YOFFSETUP = util.getupvalue(debug.getinfo(2).func, "YOFFSETUP")
		--YOFFSETDOWN = util.getupvalue(debug.getinfo(2).func, "YOFFDOWN")
		--mprint('t1:', text) -- main action or whatnot, including alt
		-- additional hours going through hell and back
		-- i have such an irritating headache.
		--
		-- information
		local item = GetMouseTargetItem()
		local entityInformation = RequestEntityInformation(item, localPlayer, { FROM_INSPECTION = true, IGNORE_WORLDLY = true })
		local itemDescription = nil

		if item and DEBUG_SHOW_PREFAB then
			local pos = string_find(text, "\n")
			local prefab = " [" .. item.prefab .. "]"
			if pos then
				text = string_sub(text, 1, pos - 1) .. prefab .. string_sub(text, pos)
			else
				text = text .. prefab
			end
		end
		
		if entityInformation then
			-- control pressed doesn't have the game focus issues (alt+tab keeps the key down) and handles the changed keybinds in control menu. 
			if TheInput_IsControlPressed(TheInput, CONTROL_FORCE_INSPECT) then
				local altOnlyIsVerbose = TheInput_IsControlPressed(TheInput, CONTROL_FORCE_TRADE)
				if informationOnAltOnly == true and altOnlyIsVerbose == false then
					itemDescription = entityInformation.information

					if entityInformation.information ~= entityInformation.alt_information then
						local pos = string_find(text, "\n")
						if pos then
							text = string_sub(text, 1, pos - 1) .. (canShowExtendedInfoIndicator and "*" or "") .. string_sub(text, pos)
						else
							text = text .. "*"
						end
					end
					
				else
					itemDescription = entityInformation.alt_information
				end
			elseif informationOnAltOnly then
				itemDescription = nil
			else
				itemDescription = entityInformation.information
				if entityInformation.information ~= entityInformation.alt_information then
					local pos = string_find(text, "\n")
					if pos then
						text = string_sub(text, 1, pos - 1) .. (canShowExtendedInfoIndicator and "*" or "") .. string_sub(text, pos)
					else
						text = text .. (canShowExtendedInfoIndicator and "*" or "")
					end
				end
			end

			--[[
				if altOnlyIsVerbose == true then
					print'yeep'
					itemDescription = entityInformation.alt_information
				else
					itemDescription = entityInformation.information
				end
			]]

			--itemInfo = (TheInput:IsKeyDown(KEY_LALT) and itemInfo.alt_information) or itemInfo.information or nil
		end

		if canShowItemRange then
			if item == nil or entityInformation == nil then
				if currentlySelectedItem ~= nil then
					OnCurrentlySelectedItemChanged(currentlySelectedItem, nil)
					currentlySelectedItem = nil
				end
			elseif item and entityInformation and entityInformation.GUID then -- GUID presence means it is initialized
				if currentlySelectedItem ~= item then
					OnCurrentlySelectedItemChanged(currentlySelectedItem, item, entityInformation)
					currentlySelectedItem = item
				end
			end
		end

		if item and DEBUG_ENABLED then
			--itemInfo = string.format("Active: %s\n", tostring(entityManager:IsEntityActive(item))) .. (itemInfo or "")
		end

		hoverer.insightText:SetString(itemDescription) -- Trimming newlines handled here
		
		-- size info
		local hovertext_lines = select(2, text:gsub("\n", "\n"))
		local description_lines = hoverer.insightText.line_count or 0
		local total_lines = hovertext_lines + description_lines - 1

		local textPadding

		if IS_DST then
			textPadding = string.rep("\n ", total_lines)
			hoverer.insightText:SetPosition(0, hoverer.insightText.font_size / 4)
		else
			textPadding = string.rep("\n ", total_lines)
			hoverer.insightText:SetPosition(0, hoverer.insightText.font_size / 4)

			-- This probably will need revision
			--[[
			textPadding = string.rep("\n ", hoverer.insightText.line_count)
			hovertext_lines = hovertext_lines - 1
			if hovertext_lines < 0 then
				--r = 0 -- i commented this and that made the stars align
			end

			hoverer.insightText:SetPosition(0, -7.5 + (-15 * hovertext_lines) + dataHeight / 2) -- dataHeight used to be the height of the insight text
			--]]
		end

		-- Forces a position update.
		--self.str = text .. textPadding
		
		return oldSetString(self, text .. textPadding)
	end

	hoverer.secondarytext.SetString = function(self, text)
		-- stuff like boats, where the action is far below
		-- or any ground entity really
		-- explains why the text overlap from boats happened

		-- a good test case is holding an axe and hovering a beefalo

		-- default y is -30

		--[[
			hovering a beefalo holding an axe, insight text states:
			health
			damage
			hunger
			hunger decay
			tendency
			naughtiness
			mood
			brushed

			-- 8 lines, and on default offset of -30, this text is positioned betweenish lines 5 and 6.
			
		]]

		local offset = ((hoverer.insightText.line_count or 0) / 2) * hoverer.insightText.font_size
		offset = offset + hoverer.insightText.font_size / 4

		-- there's a 1 line gap in vanilla (both) between the primarytext and secondarytext
		if hoverer.insightText.raw_text == nil then
			self:SetPosition(0, -30) -- Default position
		else
			self:SetPosition(0, -offset)
		end

		return oldSetString(self, text)
	end
end


module.Initialize = function()
	if module.initialized then
		errorf("Cannot initialize %s more than once.", debug.getinfo(1, "S"):match("([%w_]+)%.lua$"))
		return
	end

	module.initialized = true
	AddClassPostConstruct("widgets/hoverer", OnHovererPostInit)
end

return module