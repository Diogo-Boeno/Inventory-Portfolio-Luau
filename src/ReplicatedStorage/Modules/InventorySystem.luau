-- Services
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local player = Players.LocalPlayer

local playerGUI = player:WaitForChild('PlayerGui')

-- Interface
local ScreenUI = playerGUI:WaitForChild('InventoryUI')
local BackGround = ScreenUI:WaitForChild('MainBg')
local MainShadow = ScreenUI:WaitForChild('MainShadow')
local OpenButton = ScreenUI:WaitForChild('Open')
local Holder = BackGround:WaitForChild('Holder')
local Slots = Holder:WaitForChild('Slots')
local InfoBG = MainShadow:WaitForChild('InfoBG')
local Display = InfoBG:WaitForChild('Display')
local ViewportFrame = Display:WaitForChild('ViewportFrame')

local Models = game:GetService('ServerStorage'):FindFirstChild('Items')


local Inventory = {}
Inventory.__index = Inventory

-- Configs
local Info = {
    0.5, -- time
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
        0.4, 0, 0.5, 0
    ),
    BG_GoalRotation = -3,
}

local function updateViewport(modelName)
    for _, child in ipairs(ViewportFrame:GetChildren()) do
        child:Destroy()
    end

    local model = Models:FindFirstChild(modelName)
    if not model then
        warn('Modelo não encontrado:', modelName)
        return
    end

    local clone = model:Clone()
    clone.Parent = ViewportFrame

    local camera = Instance.new('Camera')
    camera.Parent = ViewportFrame
    ViewportFrame.CurrentCamera = camera

    local cf, size = clone:GetBoundingBox()
    camera.CFrame = CFrame.new(
        cf.Position + Vector3.new(0, size.Y * 0.5, size.Z * 2),
        cf.Position
    )
end

function Inventory.new()
    local self = setmetatable({}, Inventory)
    self.isDetailOpen = false
    return self
end

function Inventory:LoadSlots()
    for i, slot in ipairs(Slots:GetChildren()) do
        if slot:IsA('Frame') then
            local button = slot:FindFirstChild('Button')
            if button then
                button.Activated:Connect(function()
                    self:OnSlotClicked(slot)
                end)
            end
        end
    end
end

function Inventory:OnSlotClicked(slot)
    print('Slot clicked', slot.Name)

    if not BackGround or not MainShadow then return end

    if not self.isDetailOpen then
        -- Abrindo
        self.isDetailOpen = true

        TweenService:Create(BackGround, tweenInfo, {
            Position = Values.BG_GoalPos,
            Rotation = Values.BG_GoalRotation
        }):Play()
        TweenService:Create(MainShadow, tweenInfo, {
            Position = Values.Shadow_GoalPos,
            Rotation = Values.Shadow_GoalRotation
        }):Play()
    else
        -- Fechando
        self.isDetailOpen = false
        TweenService:Create(BackGround, tweenInfo, {
            Position = Values.BG_StartingPos,
            Rotation = Values.BG_StartingRotation
        }):Play()
        TweenService:Create(MainShadow, tweenInfo, {
            Position = Values.Shadow_StartingPos,
            Rotation = Values.Shadow_StartingRotation
        }):Play()
    end
end

function Inventory.OpenUI()
    if not BackGround or not MainShadow then return end
    BackGround.Visible = not BackGround.Visible
    MainShadow.Visible = not MainShadow.Visible
end

return Inventory