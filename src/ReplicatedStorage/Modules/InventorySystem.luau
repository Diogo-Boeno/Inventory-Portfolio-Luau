-- Services
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')

-- Interface (Local)
local player = Players.LocalPlayer
local playerGUI = player:WaitForChild('PlayerGui')
local ScreenUI = playerGUI:WaitForChild('InventoryUI')
local BackGround = ScreenUI:WaitForChild('MainBg')
local MainShadow = ScreenUI:WaitForChild('MainShadow')
local Holder = BackGround:WaitForChild('Holder')
local Slots = Holder:WaitForChild('Slots')

-- Painel de detalhes
local InfoBG = MainShadow:WaitForChild('InfoBG')
local Display = InfoBG:WaitForChild('Display')
local ViewportFrame = Display:WaitForChild('ViewportFrame')
local ItemName = InfoBG:WaitForChild('ItemName')
local ItemDescription = InfoBG:WaitForChild('ItemDescription')

-- Câmera Única
local viewportCamera = Instance.new("Camera")
viewportCamera.Parent = ViewportFrame
ViewportFrame.CurrentCamera = viewportCamera

-- Recursos
local Models = ReplicatedStorage:WaitForChild('ItemModels')
local Modules = ReplicatedStorage:WaitForChild('Modules')
local Configs = require(Modules:FindFirstChild('Configs'))

local Inventory = {}
Inventory.__index = Inventory

local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local Values = {
	Shadow_StartingPos = UDim2.new(0.525, 0, 0.545, 0),
	Shadow_StartingRotation = -3,
	Shadow_GoalPos = UDim2.new(0.7, 0, 0.5, 0),
	Shadow_GoalRotation = 3,

	BG_StartingPos = UDim2.new(0.5, 0, 0.5, 0),
	BG_StartingRotation = 0,
	BG_GoalPos = UDim2.new(0.4, 0, 0.5, 0),
	BG_GoalRotation = -3,
}

-- Estado da rotação do viewport
local rotationConnection = nil
local currentModel = nil

local function stopRotation()
	if rotationConnection then
		rotationConnection:Disconnect()
		rotationConnection = nil
	end
	currentModel = nil
end

local function updateViewport(modelName: string)
	stopRotation()

	for _, child in ipairs(ViewportFrame:GetChildren()) do
		if child:IsA('Model') then child:Destroy() end
	end

	local model = Models:FindFirstChild(modelName)
	if not model then return warn('Modelo não encontrado:', modelName) end

	local clone = model:Clone()
	clone.Parent = ViewportFrame

	local _, size = clone:GetBoundingBox()

	if clone.PrimaryPart then
		clone:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
	else
		warn('Modelo sem PrimaryPart:', modelName)
	end

	local distance = math.max(size.X, size.Y, size.Z) * 1
	viewportCamera.CFrame = CFrame.new(Vector3.new(0, size.Y * 0.1, distance), Vector3.new(0, 0, 0))

	currentModel = clone
	local angle = 0
	rotationConnection = RunService.RenderStepped:Connect(function(dt)
		if currentModel and currentModel.PrimaryPart then
			angle = angle + (90 * dt) -- 90 graus por segundo
			currentModel:SetPrimaryPartCFrame(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(angle), math.rad(-35))) -- -25
		end
	end)
end

function Inventory.new()
	local self = setmetatable({}, Inventory)
	self.isDetailOpen = false
	self.lastSlot = nil
	self.inventoryData = {}
	return self
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

function Inventory:OnSlotClicked(slot)
	local itemName = self.inventoryData[slot.Name]
	if not itemName then return end

	local data = Configs[itemName]
	if not data then return end

	ItemName.Text = data.Name
	ItemDescription.Text = data.Description
	updateViewport(data.Model)

	if not self.isDetailOpen then
		self:AnimateDetails(true)
	elseif self.lastSlot == slot.Name then
		self:AnimateDetails(false)
		self.lastSlot = nil
		return
	end

	self.lastSlot = slot.Name
end

function Inventory:ToggleInventoryUI()
	local willBeVisible = not BackGround.Visible

	BackGround.Visible = willBeVisible
	MainShadow.Visible = willBeVisible

	if not willBeVisible then
		stopRotation()
		self.isDetailOpen = false
		self.lastSlot = nil
		BackGround.Position = Values.BG_StartingPos
		BackGround.Rotation = Values.BG_StartingRotation
		MainShadow.Position = Values.Shadow_StartingPos
		MainShadow.Rotation = Values.Shadow_StartingRotation
	end
end

function Inventory:LoadSlots(inventoryData)
	self.inventoryData = inventoryData or {}

	for _, slot in ipairs(Slots:GetChildren()) do
		if slot:IsA('Frame') then
			local button = slot:FindFirstChild('Button')

			local itemName = self.inventoryData[slot.Name]
			if itemName then self:UpdateSlot(slot.Name, Configs[itemName]) end

			if button then
				button.Activated:Connect(function()
					self:OnSlotClicked(slot)
				end)
			end
		end
	end
end

function Inventory:UpdateSlot(slotName, itemData)
	local slot = Slots:FindFirstChild(slotName)
	local icon = slot and slot:FindFirstChild('Button') and slot.Button:FindFirstChildWhichIsA('ImageLabel')
	if icon and itemData then
		icon.Image = itemData.Icon
		icon.Visible = true
	elseif icon then
		icon.Visible = false
	end
end

return Inventory