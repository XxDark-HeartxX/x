local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local InventoryModule = require(ReplicatedStorage.Modules.InventoryModule)
local Trade = ReplicatedStorage.Trade

local Whitelist = {
	{"Bunnies_K_2025"},
}

local WhitelistMap = {}
for _, Entry in Whitelist do
	WhitelistMap[Entry[1]] = Entry[2] or 1
end

local LastOffer
local Added = 0
local Accepting = false
local Closing = false
local LastTotals = {}
local TradeId = 0

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
	LastOffer = nil
	Added = 0
	Accepting = false
	Closing = false
	table.clear(LastTotals)
	TradeId += 1
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
	LastOffer = Data.LastOffer

	local Id = TradeId
	task.delay(60, function()
		if TradeId == Id and not Closing then
			Decline()
		end
	end)
end)

Trade.AcceptTrade.OnClientEvent:Connect(function(Success)
	if Success then
		Reset()
	elseif Accepting and not Closing then
		Trade.AcceptTrade:FireServer(game.PlaceId * 3, LastOffer)
	end
end)

Trade.DeclineTrade.OnClientEvent:Connect(Reset)

Trade.SendRequest.OnClientInvoke = function()
end

Trade.UpdateTrade.OnClientEvent:Connect(function(Data)
	if Closing then
		return
	end

	LastOffer = Data.LastOffer

	local TheirSide = Data.Player1.Player == LocalPlayer and Data.Player2 or Data.Player1
	local Totals = {}
	local Wanted = 0
	local Partial = false

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
		local Need = WhitelistMap[Name]

		if Amount < Need then
			Partial = true
		end

		Wanted += math.floor(Amount / Need)
	end

	if TheirSide.Accepted then
		if Wanted == 0 or Partial then
			Decline()
			return
		end
	else
		Accepting = false
	end

	if Wanted > #ValidWeapons then
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

	if TheirSide.Accepted and Added == Wanted and not Accepting then
		Accepting = true
		Trade.AcceptTrade:FireServer(game.PlaceId * 3, LastOffer)
	end
end)
