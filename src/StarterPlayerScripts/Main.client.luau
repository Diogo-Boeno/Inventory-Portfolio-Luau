-- Services
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local player = Players.LocalPlayer

local playerGUI = player:WaitForChild('PlayerGui')

-- Interface
local ScreenUI = playerGUI:WaitForChild('InventoryUI')

local OpenButton = ScreenUI:WaitForChild('Open')

-- Modules
local Modules = ReplicatedStorage:WaitForChild('Modules')
local InventorySystem = require(Modules:WaitForChild('InventorySystem'))

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild('Remotes')
local GetInventory = Remotes:WaitForChild('GetInventory')
local ProfileLoaded = Remotes:WaitForChild('ProfileLoaded')
local InventoryUpdated = Remotes:WaitForChild('InventoryUpdated')

-- load
local inventory = InventorySystem.new(ScreenUI)

ProfileLoaded.OnClientEvent:Connect(function()
	local inventoryData = GetInventory:InvokeServer()
	inventory:LoadSlots(inventoryData)
end)

InventoryUpdated.OnClientEvent:Connect(function(inventoryData)
	inventory:LoadSlots(inventoryData)
end)

-- Functions
if ScreenUI and not ScreenUI.Enabled then ScreenUI.Enabled = true end

OpenButton.Activated:Connect(function()
	inventory:ToggleInventoryUI()
end)

-- Drop: solta o item atualmente em detalhe (tecla Q).
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Q then
		inventory:DropSelected()
	end
end)
