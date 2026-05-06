-- Services
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local player = Players.LocalPlayer

local playerGUI = player:WaitForChild('PlayerGui')

-- Interface
local ScreenUI = playerGUI:WaitForChild('InventoryUI')

local OpenButton = ScreenUI:WaitForChild('Open')

-- Modules
local Modules = ReplicatedStorage:WaitForChild('Modules')
local InventorySystem = require(Modules:WaitForChild('InventorySystem'))

-- Remotes
local Remotes = ReplicatedStorage:FindFirstChild('Remotes')
local GetInventory = Remotes:FindFirstChild('GetInventory')
local ProfileLoaded = Remotes:WaitForChild('ProfileLoaded')

-- load
local inventory = InventorySystem.new()

ProfileLoaded.OnClientEvent:Connect(function()
    local inventoryData = GetInventory:InvokeServer()
    inventory:LoadSlots(inventoryData)
end)

-- Functions
OpenButton.Activated:Connect(function()
    inventory:OpenUI()
end)