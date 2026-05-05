-- Services
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local player = Players.LocalPlayer

local playerGUI = player:WaitForChild('PlayerGui')

-- Interface
local ScreenUI = playerGUI:WaitForChild('InventoryUI')
local BackGround = ScreenUI:WaitForChild('MainBg')
local Holder = BackGround:WaitForChild('Holder')
local Slots = Holder:WaitForChild('Slots')

local OpenButton = ScreenUI:WaitForChild('Open')

-- Modules
local Modules = ReplicatedStorage:WaitForChild('Modules')
local InventorySystem = require(Modules:WaitForChild('InventorySystem'))

-- Load
local inventory = InventorySystem.new()

-- Functions
OpenButton.Activated:Connect(function()
    inventory:OpenUI()
end)