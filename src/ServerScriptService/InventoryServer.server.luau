-- Services
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')

-- Modules
local ServerModules = ServerScriptService:WaitForChild('Modules')
local ProfileService = require(ServerModules:WaitForChild('ProfileService'))
local WorldItems = require(ServerModules:WaitForChild('WorldItems'))
local Configs = require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('Configs'))

local BACKPACK_CAPACITY = 24

-- Remotes (criados em código, idempotente: reusa os que já existem no Studio).
local Remotes = ReplicatedStorage:FindFirstChild('Remotes')
if not Remotes then
	Remotes = Instance.new('Folder')
	Remotes.Name = 'Remotes'
	Remotes.Parent = ReplicatedStorage
end

local function ensureRemote(className, name)
	local existing = Remotes:FindFirstChild(name)
	if existing then return existing end
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = Remotes
	return remote
end

local GetInventory = ensureRemote('RemoteFunction', 'GetInventory')
local DropItem = ensureRemote('RemoteFunction', 'DropItem')
local ProfileLoaded = ensureRemote('RemoteEvent', 'ProfileLoaded')
local InventoryUpdated = ensureRemote('RemoteEvent', 'InventoryUpdated')

-- Profiles
local ProfileTemplate = {
	Inventory = {},
}

local ProfileStore = ProfileService.GetProfileStore('PlayerData', ProfileTemplate)
local Profiles = {}

-- Lógica de inventário (server-authoritative) --------------------------------

-- Valida o item, encontra um slot livre e replica a mudança ao dono.
-- Retorna true só se o item realmente entrou no inventário.
local function addItemToInventory(player, itemName)
	if not Configs[itemName] then
		return false -- item inexistente: rejeita input não confiável
	end

	local profile = Profiles[player]
	if not profile then return false end

	local inventory = profile.Data.Inventory
	for i = 1, BACKPACK_CAPACITY do
		local slot = tostring(i)
		if not inventory[slot] then
			inventory[slot] = itemName
			InventoryUpdated:FireClient(player, inventory)
			return true
		end
	end

	return false -- inventário cheio
end

-- Player lifecycle -----------------------------------------------------------

Players.PlayerAdded:Connect(function(player)
	local profile = ProfileStore:LoadProfileAsync('Player_' .. player.UserId)

	if profile then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick('Seu perfil foi carregado em outro servidor.')
		end)

		if player.Parent ~= Players then
			-- Player saiu antes do profile carregar.
			profile:Release()
			return
		end

		Profiles[player] = profile
		ProfileLoaded:FireClient(player)
	else
		player:Kick('Data Error')
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local profile = Profiles[player]
	if profile then
		profile:Release()
		Profiles[player] = nil
	end
end)

-- Remotes --------------------------------------------------------------------

GetInventory.OnServerInvoke = function(player)
	local profile = Profiles[player]
	if not profile then return {} end
	return profile.Data.Inventory
end

DropItem.OnServerInvoke = function(player, slotName)
	if type(slotName) ~= 'string' then return false end

	local profile = Profiles[player]
	if not profile then return false end

	local inventory = profile.Data.Inventory
	local itemName = inventory[slotName]
	if not itemName then return false end

	inventory[slotName] = nil
	InventoryUpdated:FireClient(player, inventory)

	local character = player.Character
	local root = character and character:FindFirstChild('HumanoidRootPart')
	if root then
		WorldItems.spawn(itemName, root.CFrame * CFrame.new(0, 0, -5))
	end

	return true
end

WorldItems.init(addItemToInventory)

local DEMO_SPAWNS = {
	{ item = 'BronzeAxe', cframe = CFrame.new(-6, 3, -10) },
	{ item = 'IronAxe', cframe = CFrame.new(0, 3, -10) },
	{ item = 'GoldenAxe', cframe = CFrame.new(6, 3, -10) },
}

for _, entry in ipairs(DEMO_SPAWNS) do
	WorldItems.spawn(entry.item, entry.cframe)
end
