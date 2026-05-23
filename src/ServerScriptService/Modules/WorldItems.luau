local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local Configs = require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('Configs'))
local ItemModels = ReplicatedStorage:WaitForChild('ItemModels')

local WorldItems = {}

local worldFolder = nil
local pickupCallback = nil -- function(player, itemName) -> boolean

local function ensureFolder()
	local folder = Workspace:FindFirstChild('WorldItems')
	if not folder then
		folder = Instance.new('Folder')
		folder.Name = 'WorldItems'
		folder.Parent = Workspace
	end
	return folder
end

function WorldItems.init(onPickup)
	pickupCallback = onPickup
	worldFolder = ensureFolder()
end

function WorldItems.spawn(itemName, cframe)
	local config = Configs[itemName]
	if not config then
		warn('WorldItems.spawn: item desconhecido ->', itemName)
		return nil
	end

	local source = ItemModels:FindFirstChild(config.Model)
	if not source or not source:IsA('Model') then
		warn('WorldItems.spawn: modelo não encontrado ->', config.Model)
		return nil
	end

	local model = source:Clone()
	model:SetAttribute('ItemName', itemName)

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA('BasePart') then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end

	model.Parent = worldFolder
	model:PivotTo(cframe)

	local host = model.PrimaryPart or model:FindFirstChildWhichIsA('BasePart')
	if not host then
		warn('WorldItems.spawn: modelo sem BasePart ->', config.Model)
		model:Destroy()
		return nil
	end

	local prompt = Instance.new('ProximityPrompt')
	prompt.ActionText = 'Pegar'
	prompt.ObjectText = config.Name
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = host

	prompt.Triggered:Connect(function(player)
		-- Debounce imediato: evita que dois triggers no mesmo objeto dupliquem o item
		prompt.Enabled = false

		local pickedName = model:GetAttribute('ItemName')
		local consumed = pickupCallback ~= nil and pickupCallback(player, pickedName) == true

		if consumed then
			model:Destroy()
		else
			-- Inventário cheio (ou falha): devolve o prompt para tentar de novo
			prompt.Enabled = true
		end
	end)

	return model
end

return WorldItems
