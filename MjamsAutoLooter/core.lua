------------------------------------------------------
--                                                  --
--          MAL - MjamsAutoLooter 1.0		   		--
--                                                  --
--          Author: Mjam - [H]Mirage Raceway        --
--                                                  --
------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------- Variables and Libs
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
MjamsAutoLooter = LibStub("AceAddon-3.0"):NewAddon("MjamsAutoLooter", "AceConsole-3.0", "AceEvent-3.0")

-- General
local mal_version = "1.0"
local mal_statusText = "MjamsAutoLooter v"..mal_version
local AceGUI = LibStub("AceGUI-3.0")


-- broker/minimap
local mal_ldb = LibStub("LibDataBroker-1.1")
local mal_Broker = nil
local mal_minimapicon = LibStub("LibDBIcon-1.0")
local mal_brokervalue = nil
local mal_brokerlabel = nil

-- Options
MjamsAutoLooter:RegisterChatCommand("MAL", "MALSlashProcessorFunc")
local mal_options = {
    name = "MjamsAutoLooter",
    handler = MjamsAutoLooter,
    type = 'group',
	childGroups = "tab",
    args = {
		tab1 = {
			type = "group",
            name = "General",
			width = "full",
			order = 1,
			args = {
				enableAutoloot = {
					type = 'toggle',
					name = 'Autoloot Enabled',
					desc = 'Toggle Autoloot Addon',
					get = function(info) return MALDB.enabled end,
					set = function(info, val) MALDB.enabled = val end,
					width = 2.5,
				},
				Lootplayer = {
					type = 'input',
					name = 'Loot Player',
					desc = 'Player to distribute loot to',
					get = function(info) return MALDB.Lootplayer end,
					set = function(info, val) MALDB.Lootplayer = val end,
					width = 2.5,
				},
				debugmode = {
					type = 'toggle',
					name = 'Debug Mode',
					desc = 'Toggle Debug Mode',
					get = function(info) return MALDB.debug end,
					set = function(info, val) MALDB.debug = val end,
					width = 2.5,
				},
			},
		},
    },
}

local debugItemDB = {
	"Tigerseye",
	"Subterranean Cape",
	"Crystalline Cuffs",
	"Cursed Felblade",
	"Robe of Evocation",
	"Cavedweller Bracers",
	"Chanting Blade",
	"Shadowgem"
}

local TBCDB = {
	"Mark of the Illidari",
	"Shadowsong Amethyst",
	"Seaspray Emerald",
	"Empyrean Sapphire",
	"Lionseye",
	"Pyrestone",
	"Crimson Spinel",
	"Heart of Darkness",
	"Sunmote",
}
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------- Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------------------------------------------
----------------------
function MjamsAutoLooter:OnInitialize()
	LibStub("AceConfig-3.0"):RegisterOptionsTable("MjamsAutoLooter", mal_options, nil)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MjamsAutoLooter"):SetParent(InterfaceOptionsFramePanelContainer)	
end

function MjamsAutoLooter:OnEnable()

	self:RegisterEvent("LOOT_OPENED")

	self:CreateDataBroker()
	
	if MALDB == nil then	MALDB = {}	end
	if MALDB.debug == nil then	MALDB.debug = false	end
	if MALDB.enabled == nil then	MALDB.enabled = true end
	if MALDB.Lootplayer == nil then MALDB.Lootplayer = UnitName("player") end
	if MALDB.autolootDB == nil then MALDB.autolootDB = {} end
	if MALDB.statDB == nil then MALDB.statDB = {} end
	if MALDB.brokertext == nil then MALDB.brokertext = "RecordHistory" end
	
end

------------------------------------------------------------------------------------------------------------
-- UI
------------------------------------------------------------------------------------------------------------
function MjamsAutoLooter:CreateDataBroker()
	mal_Broker = mal_ldb:NewDataObject("mal_Broker", {
		type = "data source",
		label = "MjamsAutoLooter",
		text = "MAL",
		-- text = function()
			-- if MALDB.enabled then
				-- return "|cff00FF00On|r"
			-- else
				-- return "|cffFF0000Off|r"
			-- end,
		icon = "Interface\\Icons\\Inv_misc_ammo_bullet_01",
		OnClick = function(self, button)
			if button=="LeftButton" then
				MALDB.enabled = not MALDB.enabled
			elseif button=="RightButton" then
				InterfaceOptionsFrame_Show()
				InterfaceOptionsFrame_OpenToCategory("MjamsAutoLooter")				
			end
		end,
		OnTooltipShow = function(tooltip)
			tooltip:AddLine("|cFFffffffMjamsAutoLooter v"..mal_version.."|r")
			tooltip:AddLine(" ")
			tooltip:AddLine(" ")
			if MALDB.enabled then
				tooltip:AddLine("|cffffd100Autoloot|r enabled", 0.2, 1, 0.2)
			else
				tooltip:AddLine("|cffffd100Autoloot|r disabled", 1, 0.2, 0.2)
			end
			tooltip:AddLine(" ")			
			tooltip:AddLine("|cffffd100Lootplayer:|r " .. MALDB.Lootplayer, 0.2, 0.2, 1)			
			tooltip:AddLine(" ")			
			tooltip:AddLine(" ")			
			tooltip:AddLine("|cffffd100Leftclick|r                 Toggle Addon", 0.9, 0.9, 0.9)
			tooltip:AddLine("|cffffd100Rightclick|r      Open Config Frame", 0.9, 0.9, 0.9)
				
		end,
	})
end

function MjamsAutoLooter:MALSlashProcessorFunc()
	InterfaceOptionsFrame_Show()
	InterfaceOptionsFrame_OpenToCategory("MjamsAutoLooter")
end

------------------------------------------------------------------------------------------------------------
-- Log Events
------------------------------------------------------------------------------------------------------------
function MjamsAutoLooter:LOOT_OPENED()
	if MjamsAutoLooter:GetMasterlootStatus() and MALDB.enabled then
		MjamsAutoLooter:CheckLoot()
	end
end


------------------------------------------------------------------------------------------------------------
-- Loot Handling
------------------------------------------------------------------------------------------------------------


function MjamsAutoLooter:DistributeLoot(playerName, lootIndex)	
	for i = 1, GetNumGroupMembers() do
		if (GetMasterLootCandidate(lootIndex, i) == playerName) then
			GiveMasterLoot(lootIndex, i);
		end
	end
end

function MjamsAutoLooter:CheckLoot()
	
	for i = 1, GetNumLootItems() do
		_, lootName, _, _, rarity = GetLootSlotInfo(i);
		lootLink = GetLootSlotLink(i)
		if GetLootThreshold() <= rarity then
		
			local db = {}
			if MALDB.debug then
				db = debugItemDB
			else
				db = TBCDB
			end
			
			if MjamsAutoLooter:ArrayContains(db ,lootName) then
			
				MjamsAutoLooter:DistributeLoot(MALDB.Lootplayer, i)
				MjamsAutoLooter:AnnounceLoot(lootName, lootLink)
				
			else
				if MALDB.debug then
					print("Nope: " .. lootLink)
				end
			end
		end
	end
end

function MjamsAutoLooter:GetMasterlootStatus()
	lootmethod, masterlooterPartyID, _ = GetLootMethod()
	if lootmethod == "master" and masterlooterPartyID == 0 and UnitInRaid("player") ~= nil then
		--self:Print("Masterloot")
		return true
	else
		--self:Print("No Masterloot - " .. lootmethod .. " - " .. masterlooterPartyID .. " - " .. UnitInRaid("player"))
		return false
	end
end

function MjamsAutoLooter:AnnounceLoot(lootName, lootLink)

	local poopchance = math.random(5)
	local msg = ""
	
	if poopchance == 1 then
		local poo = math.random(20)
		if poo == 1 then
			msg = lootLink .. " looted... Shut up, i saw that one!"
		elseif poo == 2 then
			msg = "What? No? We did not get ANY " .. lootLink .. " today..."
		elseif poo == 3 then
			msg = "What a shit item: " .. lootLink
		elseif poo == 4 then
			msg = "HA TOLD YOU " .. lootLink .. " GONNA DROP TODAY"
		elseif poo == 5 then
			msg = "Another " .. lootLink .. " for the Auction Hou... i mean Guild Bank..."
		elseif poo == 6 then
			msg = "Dude, i was still drinking, i didnt have the time to loot " .. lootLink .. " yet"
		elseif poo == 7 then
			msg = "The one item we never gonna give to Fx: " .. lootLink
		elseif poo == 8 then
			msg = "Can't distribute " .. lootLink .. " to Wobble since he is dead as always"
		elseif poo == 9 then
			msg = "Gonna simp on a specific shadowpriest later and gift her " .. lootLink .. ", but i she will probably still parse gray."
		elseif poo == 10 then
			msg = "Who need warglaives when you can have this: " .. lootLink
		elseif poo == 11 then
			msg = lootLink .. " has a 5% chance to drop. since we killed a lot of trash, our chance must been up to over 100%!!!11"
		elseif poo == 12 then
			msg = "Wish we could get " .. lootLink .. " from the monthly Consortium bag"
		elseif poo == 13 then
			msg = '"Damn, im out of arrows again" - Mewey'
		elseif poo == 14 then
			msg = "Fuck, i cant walk my dog, i hit my knee with a " .. lootLink
		elseif poo == 15 then
			msg = lootLink .. " looks like a scale of a salmonsnake"
		elseif poo == 16 then
			msg = ">>> SICK LOOOOT - " .. lootLink .. " - SICK LOOOOT <<<"
		elseif poo == 17 then
			msg = "WHAT? A " .. lootLink .. "??? I'd sell my tree waifu for that.."
		elseif poo == 18 then
			msg = "Nice, a pristine " .. lootLink .. " for my furry costume"
		elseif poo == 19 then
			msg = "Where is the top of the stairs?"
		elseif poo == 20 then
			msg = "Follow me on twitch.tv/lanc3qt or i will sell " .. lootLink .. " on the auctionhouse!"
		end
	else
		msg = "MjamsAutoLooter: " .. lootLink
	end
	SendChatMessage(msg, "RAID")
end


------------------------------------------------------------------------------------------------------------
-- Helper Functions
------------------------------------------------------------------------------------------------------------


function MjamsAutoLooter:ArrayContains(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end
