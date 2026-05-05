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

-- Load
local inventory = InventorySystem.new()
inventory:LoadSlots()

-- Functions
OpenButton.Activated:Connect(function()
    inventory:OpenUI()
end)