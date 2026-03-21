local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local InventoryModule = require(ReplicatedStorage.Modules.InventoryModule)
local Trade = ReplicatedStorage.Trade

local Whitelist = {
	{"VampireAxe"},
}

local TradeData
local Added = false
local Closing = false
local TheirSnapshot

local PlayerData = ReplicatedStorage.Remotes.Inventory.GetProfileData:InvokeServer()
PlayerData.Uniques = {}

local Sorted = InventoryModule.SortInventory(InventoryModule.GenerateInventoryTables(PlayerData, "Trading"))
local ValidWeapons = {}

for _, ItemName in Sorted.Sort.Weapons.Current do
	if ItemName ~= "DefaultKnife" and ItemName ~= "DefaultGun" then
		ValidWeapons[#ValidWeapons + 1] = ItemName
	end
end

Trade.StartTrade.OnClientEvent:Connect(function(Data)
	TradeData = Data
	Added = false
	Closing = false
	TheirSnapshot = nil
end)

Trade.AcceptTrade.OnClientEvent:Connect(function(Success)
	if not Success then
		Trade.AcceptTrade:FireServer(game.PlaceId * 3, TradeData.LastOffer)
	end

	TradeData = nil
	Added = false
	Closing = false
	TheirSnapshot = nil
end)

Trade.DeclineTrade.OnClientEvent:Connect(function()
	TradeData = nil
	Added = false
	Closing = false
	TheirSnapshot = nil
end)

Trade.SendRequest.OnClientInvoke = function(Player)
	task.delay(.2, function()
		Trade.AcceptRequest:FireServer()
	end)
end

Trade.UpdateTrade.OnClientEvent:Connect(function(Data)
	if Closing then
		return
	end

	TradeData = Data

	local TheirSide
	if Data.Player1.Player == LocalPlayer then
		TheirSide = Data.Player2
	elseif Data.Player2.Player == LocalPlayer then
		TheirSide = Data.Player1
	else
		return
	end

	local Totals = {}
	local Keys = {}

	for _, Offer in TheirSide.Offer do
		local Name = Offer[1]

		if Totals[Name] then
			Totals[Name] += Offer[2]
		else
			Totals[Name] = Offer[2]
			Keys[#Keys + 1] = Name
		end
	end

	local Whitelisted = false

	for _, Entry in Whitelist do
		if (Totals[Entry[1]] or 0) >= (Entry[2] or 1) then
			Whitelisted = true
			break
		end
	end

	if TheirSide.Accepted and not Whitelisted then
		Closing = true
		Trade.DeclineTrade:FireServer()
		return
	end

	if not Data.Locked then
		return
	end

	table.sort(Keys)

	local Parts = table.create(#Keys)

	for Index, Name in Keys do
		Parts[Index] = Name .. ":" .. Totals[Name]
	end

	local Signature = table.concat(Parts, "|")

	if Added then
		if Signature ~= TheirSnapshot then
			Closing = true
			Trade.DeclineTrade:FireServer()
		end

		return
	end

	if not Whitelisted or #ValidWeapons == 0 then
		return
	end

	Added = true
	TheirSnapshot = Signature
	Trade.OfferItem:FireServer(ValidWeapons[math.random(1, #ValidWeapons)], "Weapons")
end)
