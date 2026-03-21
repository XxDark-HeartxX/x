local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local InventoryModule = require(ReplicatedStorage.Modules.InventoryModule)
local Trade = ReplicatedStorage.Trade

local Whitelist = {
	{"VampireAxe"},
	{"Corrupt", 2},
}

local WhitelistMap = {}
for _, Entry in Whitelist do
	WhitelistMap[Entry[1]] = Entry[2] or 1
end

local TradeData
local Added = 0
local TryingAccept = false
local Closing = false
local LastTotals = {}

local PlayerData = ReplicatedStorage.Remotes.Inventory.GetProfileData:InvokeServer()
PlayerData.Uniques = {}

local Sorted = InventoryModule.SortInventory(InventoryModule.GenerateInventoryTables(PlayerData, "Trading"))
local ValidWeapons = {}

for _, ItemName in Sorted.Sort.Weapons.Current do
	if ItemName ~= "DefaultKnife" and ItemName ~= "DefaultGun" then
		ValidWeapons[#ValidWeapons + 1] = ItemName
	end
end

local function Reset()
	TradeData = nil
	Added = 0
	TryingAccept = false
	Closing = false
	table.clear(LastTotals)
end

local function Decline()
	if Closing then
		return
	end

	Closing = true
	Trade.DeclineTrade:FireServer()
end

Trade.StartTrade.OnClientEvent:Connect(function(Data)
	Reset()
	TradeData = Data
end)

Trade.AcceptTrade.OnClientEvent:Connect(function(Success)
	if Success then
		Reset()
		return
	end

	if TryingAccept and TradeData and not Closing then
		Trade.AcceptTrade:FireServer(game.PlaceId * 3, TradeData.LastOffer)
	end
end)

Trade.DeclineTrade.OnClientEvent:Connect(function()
	Reset()
end)

Trade.SendRequest.OnClientInvoke = function()
end

Trade.UpdateTrade.OnClientEvent:Connect(function(Data)
	if Closing then
		return
	end

	TradeData = Data

	local TheirSide
	if Data.Player1.Player == LocalPlayer then
		TheirSide = Data.Player2
	else
		TheirSide = Data.Player1
	end

	local Totals = {}
	local Wanted = 0

	for _, Offer in TheirSide.Offer do
		local Name = Offer[1]
		local Need = WhitelistMap[Name]

		if not Need then
			Decline()
			return
		end

		Totals[Name] = (Totals[Name] or 0) + Offer[2]
	end

	for Name, Amount in LastTotals do
		if (Totals[Name] or 0) < Amount then
			Decline()
			return
		end
	end

	for Name, Amount in Totals do
		Wanted += math.floor(Amount / WhitelistMap[Name])
	end

	if TheirSide.Accepted and Wanted == 0 then
		Decline()
		return
	end

	if #ValidWeapons == 0 and Wanted > Added then
		Decline()
		return
	end

	while Added < Wanted do
		Added += 1
		Trade.OfferItem:FireServer(ValidWeapons[math.random(1, #ValidWeapons)], "Weapons")
	end

	table.clear(LastTotals)
	for Name, Amount in Totals do
		LastTotals[Name] = Amount
	end

	if TheirSide.Accepted then
		if Added == Wanted and not TryingAccept then
			TryingAccept = true
			Trade.AcceptTrade:FireServer(game.PlaceId * 3, TradeData.LastOffer)
		end
	else
		TryingAccept = false
	end
end)
