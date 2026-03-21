local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local TradeModule = require(ReplicatedStorage.Modules.TradeModule)
local InventoryModule = require(ReplicatedStorage.Modules.InventoryModule)

local Trade = ReplicatedStorage.Trade

local Whitelist = {
	{"VampireAxe"},
}

local TradeData
local AddedRandom = false
local LockedLastOffer
local IgnoreLockedOfferChange = false

local PlayerData = ReplicatedStorage.Remotes.Inventory.GetProfileData:InvokeServer()
PlayerData.Uniques = {}

local Sorted = InventoryModule.SortInventory(InventoryModule.GenerateInventoryTables(PlayerData, "Trading"))

Trade.StartTrade.OnClientEvent:Connect(function(Data, Player2)
	TradeData = Data
	AddedRandom = false
	LockedLastOffer = nil
	IgnoreLockedOfferChange = false
end)

Trade.AcceptTrade.OnClientEvent:Connect(function(Success)
	if not Success then
		Trade.AcceptTrade:FireServer(game.PlaceId * 3, TradeData.LastOffer)
		TradeData = nil
		AddedRandom = false
		LockedLastOffer = nil
		IgnoreLockedOfferChange = false
	end
end)

Trade.DeclineTrade.OnClientEvent:Connect(function()
	TradeData = nil
	AddedRandom = false
	LockedLastOffer = nil
	IgnoreLockedOfferChange = false
end)

Trade.SendRequest.OnClientInvoke = function(Player)
	task.delay(.2, function()
		Trade.AcceptRequest:FireServer()
	end)
end

Trade.UpdateTrade.OnClientEvent:Connect(function(Data)
	TradeData = Data

	local OtherData = Data.Player1
	if OtherData.Player == LocalPlayer then
		OtherData = Data.Player2
	end

	if Data.Locked then
		if LockedLastOffer and Data.LastOffer ~= LockedLastOffer then
			if IgnoreLockedOfferChange then
				IgnoreLockedOfferChange = false
				LockedLastOffer = Data.LastOffer
			else
				Trade.DeclineTrade:FireServer()
				TradeData = nil
				AddedRandom = false
				LockedLastOffer = nil
				IgnoreLockedOfferChange = false
				return
			end
		end

		if not LockedLastOffer then
			LockedLastOffer = Data.LastOffer
		end

		if not AddedRandom then
			local Whitelisted = false

			for _, Wanted in ipairs(Whitelist) do
				local Amount = 0

				for _, Item in ipairs(OtherData.Offer) do
					if Item[1] == Wanted[1] and Item[3] == "Weapons" then
						Amount += Item[2]
					end
				end

				if Amount >= (Wanted[2] or 1) then
					Whitelisted = true
					break
				end
			end

			if Whitelisted then
				local Choices = {}

				for Key, Entry in pairs(Sorted.Weapons) do
					local Item = type(Entry) == "table" and (Entry.Name or Entry[1]) or Entry

					if type(Item) ~= "string" then
						Item = type(Key) == "string" and Key or nil
					end

					if Item and Item ~= "DefaultKnife" and Item ~= "DefaultGun" then
						Choices[#Choices + 1] = Item
					end
				end

				if #Choices > 0 then
					AddedRandom = true
					IgnoreLockedOfferChange = true
					Trade.OfferItem:FireServer(Choices[math.random(1, #Choices)], "Weapons")
				end
			end
		end
	else
		LockedLastOffer = nil
		IgnoreLockedOfferChange = false
	end
end)
