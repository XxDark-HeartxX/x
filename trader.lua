local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trade = ReplicatedStorage.Trade

Trade.SendRequest.OnClientInvoke = function()
	Trade.AcceptRequest:FireServer()
	print("done")
end
print("HELLO")
