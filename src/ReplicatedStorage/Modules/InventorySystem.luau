-- Services
local Players = game:GetService('Players')
local TweeService = game:GetService('TweenService')
local player = Players.LocalPlayer

local playerGUI = player:WaitForChild('PlayerGui')

-- Interface
local ScreenUI = playerGUI:WaitForChild('InventoryUI')
local BackGround = ScreenUI:WaitForChild('MainBg')
local MainShadow = ScreenUI:WaitForChild('MainShadow')
local OpenButton = ScreenUI:WaitForChild('Open')
local Holder = BackGround:WaitForChild('Holder')
local Slots = Holder:WaitForChild('Slots')


local Inventory = {}
Inventory.__index = Inventory

-- Configs
local Info = {
    2, -- time
    Enum.EasingStyle.Linear, --EasingStyle
    Enum.EasingDirection.Out -- EasingDirection
}

local tweenInfo = TweenInfo.new(table.unpack(Info))

-- Salvar Posições e Tamanhos para ficar mais fácil de utilizar o UDim2
local Values = {
    -- ShadowBG
    Shadow_StartingPos = UDim2.new(
        0.525, 0, 0.545, 0
    ),
    Shadow_StartingRotation = -3,
    Shadow_GoalPos = UDim2.new(
        0.7, 0, 0.5, 0
    ),
    Shadow_GoalRotation = 3,

    -- MainBG
    BG_StartingPos = UDim2.new(
        0.5, 0, 0.5, 0
    ),
    BG_StartingRotation = 0,
    BG_GoalPos = UDim2.new(
        0.3, 0, 0.5, 0
    ),
    BG_GoalRotation = -3,
}

-- Helpers
local function getSlot(slot, num)
    return slot:FindFirstChild(tostring(num))
end

function Inventory.new()
    local self = setmetatable({}, Inventory)

    return self
end

function Inventory.OpenUI()
    if not BackGround or not MainShadow then return end
    BackGround.Visible = not BackGround.Visible
    MainShadow.Visible = not MainShadow.Visible
end

return Inventory