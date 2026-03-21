local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trade = ReplicatedStorage.Trade
local TradeModule = require(ReplicatedStorage.Modules.TradeModule)
print(Trade.SendRequest)
Trade.SendRequest.OnClientInvoke = function(Player)
	print("done")
	Trade.AcceptRequest:FireServer()
	pcall(TradeModule.UpdateTradeRequestWindow,"ReceivingRequest", {
		Sender = {
			Name = Player.Name
		}
	})
	return true
end
print("HELLO")
