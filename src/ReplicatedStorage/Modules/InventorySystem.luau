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

-- Painel de detalhes
local InfoBG = MainShadow:WaitForChild('InfoBG')
local Display = InfoBG:WaitForChild('Display')
local ViewportFrame = Display:WaitForChild('ViewportFrame')
local ItemName = InfoBG:WaitForChild('ItemName')
local ItemDescription = InfoBG:WaitForChild('ItemDescription')

-- Models
local Models = ReplicatedStorage:FindFirstChild('ItemModels') -- client n consegue acessar

-- Events 
local Remotes = ReplicatedStorage:WaitForChild('Remotes')
local UpdateViewportFrameModel = Remotes:FindFirstChild('UpdateViewportFrameModel')

-- Modules
local Modules = ReplicatedStorage:WaitForChild('Modules')
local Configs = require(Modules:FindFirstChild('Configs'))


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

local function updateViewport(modelName: string)
    for _, child in ipairs(ViewportFrame:GetChildren()) do
        if child:IsA('Model') then
            child:Destroy()
        end
    end

    local model = Models:FindFirstChild(modelName)
    if not model then
        warn('Modelo não encontrado:', modelName)
        return
    end

    local clone = model:Clone()
    clone.Parent = ViewportFrame

    local cf, size = clone:GetBoundingBox()
    clone:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0, 0, 0)) * CFrame.Angles(math.rad(180), math.rad(180), math.rad(75)))

    cf, size = clone:GetBoundingBox()

    local camera = Instance.new('Camera')
    camera.Parent = ViewportFrame
    ViewportFrame.CurrentCamera = camera

    -- Afasta mais a câmera e sobe um pouco
    local distance = math.max(size.X, size.Y, size.Z) * 0.90
    camera.CFrame = CFrame.new(
        cf.Position + Vector3.new(0, size.Y * 0.01 - 0.1, distance),
        cf.Position
    )
end

function Inventory.new()
    local self = setmetatable({}, Inventory)
    self.isDetailOpen = false
    return self
end

function Inventory:UpdateSlot(slotName, itemData)
    local slot = Slots:FindFirstChild(slotName)
    if not slot then return end

    local button = slot:FindFirstChild('Button')
    if not button then return end

    local icon = button:FindFirstChildWhichIsA('ImageLabel')
    if not icon then return end

    if itemData then
        icon.Image = itemData.Icon
        icon.Visible = true
    else
        icon.Image = ''
        icon.Visible = false
    end
end

function Inventory:LoadSlots(inventoryData)
    self.inventoryData = inventoryData or {}

    for i, slot in ipairs(Slots:GetChildren()) do
        if slot:IsA('Frame') then

            if inventoryData and inventoryData[slot.Name] then
                local itemName = inventoryData[slot.Name]
                self:UpdateSlot(slot.Name, Configs[itemName])
            end

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
    local itemName = self.inventoryData and self.inventoryData[slot.Name]
    if not itemName then
        warn('Slot Vazio', slot.Name)
        return
    end

    local data = Configs[itemName]
    if not data then
        warn('Sem item configurado para o slot: ', itemName)
        return
    end

    print('Slot clicked', slot.Name)
    
    ItemName.Text = data.Name
    ItemDescription.Text = data.Description
    updateViewport(data.Model)
    
    -- Toggle 
    if not BackGround or not MainShadow then return end
    
    if not self.isDetailOpen then
        -- Open
        self:AnimateDetails(true)
    elseif self.lastSlot == slot.Name then
        -- Close
        self:AnimateDetails(false)
    else
        print('Still')
    end

    self.lastSlot = slot.Name
end

function Inventory:AnimateDetails(open: boolean)
    self.isDetailOpen = open
    local target = open and 'Goal' or 'Starting'

    TweenService:Create(BackGround, tweenInfo, {
            Position = Values['BG_'.. target ..'Pos'],
            Rotation = Values['BG_'.. target ..'Rotation']
    }):Play()
        TweenService:Create(MainShadow, tweenInfo, {
            Position = Values['Shadow_'.. target ..'Pos'],
            Rotation = Values['Shadow_'.. target ..'Rotation']
    }):Play()
end

function Inventory.OpenUI()
    if not BackGround or not MainShadow then return end
    BackGround.Visible = not BackGround.Visible
    MainShadow.Visible = not MainShadow.Visible
end

return Inventory