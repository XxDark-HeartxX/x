local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TradeModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TradeModule"))
local Trade = ReplicatedStorage:WaitForChild("Trade")

Trade.SendRequest.OnClientInvoke = function(Player)
	task.delay(0.2, function()
		Trade.AcceptRequest:FireServer()
	end)
end

Trade.StartTrade.OnClientEvent:Connect(function(a1, player2)
	print(a1)
	print(player2)
end)

local UpdateTrade
local LastOffer

UpdateTrade = hookfunction(TradeModule.UpdateTrade, function(plr)
	LastOffer = plr.LastOffer
	return UpdateTrade
end)

Trade.AcceptTrade.OnClientEvent:Connect(function(Success)
	if not Success then
		print(LastOffer)
		Trade.AcceptTrade:FireServer(game.PlaceId * 3, LastOffer)
	end
end)
