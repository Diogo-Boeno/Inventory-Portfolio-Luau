local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')

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


local function need(parent: Instance, childName: string): Instance
	local child = parent:WaitForChild(childName, 5)
	assert(
		child,
		string.format(
			"InventorySystem: '%s' não encontrado em '%s'. A raiz precisa ter MainBg/Holder/Slots e MainShadow/InfoBG.",
			childName,
			parent.Name
		)
	)
	return child
end

function Inventory.new(root: Instance)
	local self = setmetatable({}, Inventory)

	self.root = root
	self.BackGround = need(root, 'MainBg')
	self.MainShadow = need(root, 'MainShadow')
	self.Slots = need(need(self.BackGround, 'Holder'), 'Slots')

	self.InfoBG = need(self.MainShadow, 'InfoBG')
	self.Display = need(self.InfoBG, 'Display')
	self.ViewportFrame = need(self.Display, 'ViewportFrame')
	self.ItemName = need(self.InfoBG, 'ItemName')
	self.ItemDescription = need(self.InfoBG, 'ItemDescription')

	self.viewportCamera = Instance.new('Camera')
	self.viewportCamera.Parent = self.ViewportFrame
	self.ViewportFrame.CurrentCamera = self.viewportCamera

	self.isDetailOpen = false
	self.lastSlot = nil
	self.inventoryData = {}
	self.connected = false
	self.rotationConnection = nil
	self.currentModel = nil

	return self
end

function Inventory:_stopRotation()
	if self.rotationConnection then
		self.rotationConnection:Disconnect()
		self.rotationConnection = nil
	end
	self.currentModel = nil
end

function Inventory:_updateViewport(modelName: string)
	self:_stopRotation()

	for _, child in ipairs(self.ViewportFrame:GetChildren()) do
		if child:IsA('Model') then child:Destroy() end
	end

	local model = Models:FindFirstChild(modelName)
	if not model then return warn('Modelo não encontrado:', modelName) end

	local clone = model:Clone()
	clone.Parent = self.ViewportFrame

	local _, size = clone:GetBoundingBox()

	if clone.PrimaryPart then
		clone:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
	else
		warn('Modelo sem PrimaryPart:', modelName)
	end

	local distance = math.max(size.X, size.Y, size.Z) * 1
	self.viewportCamera.CFrame = CFrame.new(Vector3.new(0, size.Y * 0.1, distance), Vector3.new(0, 0, 0))

	self.currentModel = clone
	local angle = 0
	self.rotationConnection = RunService.RenderStepped:Connect(function(dt)
		if self.currentModel and self.currentModel.PrimaryPart then
			angle = angle + (90 * dt) -- 90 graus por segundo
			self.currentModel:SetPrimaryPartCFrame(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(angle), math.rad(-35)))
		end
	end)
end

function Inventory:AnimateDetails(open: boolean)
	self.isDetailOpen = open
	local target = open and 'Goal' or 'Starting'

	TweenService:Create(self.BackGround, tweenInfo, {
		Position = Values['BG_'.. target ..'Pos'],
		Rotation = Values['BG_'.. target ..'Rotation']
	}):Play()

	TweenService:Create(self.MainShadow, tweenInfo, {
		Position = Values['Shadow_'.. target ..'Pos'],
		Rotation = Values['Shadow_'.. target ..'Rotation']
	}):Play()
end

function Inventory:OnSlotClicked(slot)
	local itemName = self.inventoryData[slot.Name]
	if not itemName then return end

	local data = Configs[itemName]
	if not data then return end

	self.ItemName.Text = data.Name
	self.ItemDescription.Text = data.Description
	self:_updateViewport(data.Model)

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
	local willBeVisible = not self.BackGround.Visible

	self.BackGround.Visible = willBeVisible
	self.MainShadow.Visible = willBeVisible

	if not willBeVisible then
		self:_stopRotation()
		self.isDetailOpen = false
		self.lastSlot = nil
		self.BackGround.Position = Values.BG_StartingPos
		self.BackGround.Rotation = Values.BG_StartingRotation
		self.MainShadow.Position = Values.Shadow_StartingPos
		self.MainShadow.Rotation = Values.Shadow_StartingRotation
	end
end

function Inventory:LoadSlots(inventoryData)
	self.inventoryData = inventoryData or {}

	for _, slot in ipairs(self.Slots:GetChildren()) do
		if slot:IsA('Frame') then
			-- Re-renderiza todos os slots: limpa os vazios e preenche os ocupados.
			local itemName = self.inventoryData[slot.Name]
			self:UpdateSlot(slot.Name, itemName and Configs[itemName] or nil)

			-- Conecta os botões uma única vez (LoadSlots roda a cada InventoryUpdated).
			if not self.connected then
				local button = slot:FindFirstChild('Button')
				if button then
					button.Activated:Connect(function()
						self:OnSlotClicked(slot)
					end)
				end
			end
		end
	end

	self.connected = true

	-- Se o item em detalhe foi removido, fecha o painel.
	if self.isDetailOpen and self.lastSlot and not self.inventoryData[self.lastSlot] then
		self:AnimateDetails(false)
		self.lastSlot = nil
	end
end

function Inventory:DropSelected()
	if not self.isDetailOpen or not self.lastSlot then return end

	-- Resolve o remote na hora da chamada: no edit mode do UI Labs
	local remotes = ReplicatedStorage:FindFirstChild('Remotes')
	local dropRemote = remotes and remotes:FindFirstChild('DropItem')
	if not dropRemote then return end

	local slotName = self.lastSlot
	local ok = dropRemote:InvokeServer(slotName)
	if ok then
		-- A grid se atualiza sozinha via InventoryUpdated; só fecha o painel
		self:AnimateDetails(false)
		self.lastSlot = nil
	end
end

function Inventory:UpdateSlot(slotName, itemData)
	local slot = self.Slots:FindFirstChild(slotName)
	local icon = slot and slot:FindFirstChild('Button') and slot.Button:FindFirstChildWhichIsA('ImageLabel')
	if icon and itemData then
		icon.Image = itemData.Icon
		icon.Visible = true
	elseif icon then
		icon.Visible = false
	end
end

function Inventory:Destroy()
	self:_stopRotation()
end

return Inventory
