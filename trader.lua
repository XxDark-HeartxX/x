local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trade = ReplicatedStorage.Trade

Trade.SendRequest.OnClientInvoke = function(Player)
	task.delay(0.2,function()
		Trade.AcceptRequest:FireServer()
	end)
	print("done")
end
