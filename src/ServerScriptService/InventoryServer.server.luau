-- Services
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')

-- Modules
local Modules = ReplicatedStorage:WaitForChild('Modules')
local ServerModules = ServerScriptService:WaitForChild('Modules')
local ProfileService = require(ServerModules:WaitForChild('ProfileService'))

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild('Remotes')
local GetInventory = Remotes:WaitForChild('GetInventory')
local PickUpItem = Remotes:WaitForChild('PickUpItem')
local DropItem = Remotes:WaitForChild('DropItem')

local ProfileTemplate = {
    Inventory = {}
}

local ProfileStore = ProfileService.GetProfileStore('PlayerData', ProfileTemplate)
local Profiles = {}

-- Loader
Players.PlayerAdded:Connect(function(player)
    local profile = ProfileStore:LoadProfileAsync('Player_' .. player.UserId)

    if profile then
        profile:AddUserId(player.UserId)
        profile:Reconcile()
        Profiles[player] = profile

        --Itens de test
        -- if next(profile.Data.Inventory) == nil then
        --     profile.Data.Inventory['1'] = 'BronzeAxe'
        --     profile.Data.Inventory['2'] = 'IronAxe'
        --     profile.Data.Inventory['3'] = 'GoldenAxe'
        -- end

        local ProfileLoaded = Remotes:WaitForChild('ProfileLoaded')
        ProfileLoaded:FireClient(player)
    else
        player:Kick('Data Error')
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if Profiles[player] then
        Profiles[player]:Release()
        Profiles[player] = nil
    end
end)

GetInventory.OnServerInvoke = function(player)
    local profile = Profiles[player]
    if not profile then return {} end
    return profile.Data.Inventory
end

PickUpItem.OnServerInvoke = function(player, itemName)
    local profile = Profiles[player]
    if not profile then return end

    local inventory = profile.Data.Inventory

    for i = 1, 24 do -- for i = 1, backpack_capacity do
        local slot = tostring(i)
        if not inventory[slot] then
            inventory[slot] = itemName
            return true, slot
        end
    end

    return false, 'Full Inventory'
end

DropItem.OnServerInvoke = function(player, slotName)
    local profile = Profiles[player]
    if not profile then return false end

    local inventory = profile.Data.Inventory
    if not inventory[slotName] then return false end

    inventory[slotName] = nil
    return true
end