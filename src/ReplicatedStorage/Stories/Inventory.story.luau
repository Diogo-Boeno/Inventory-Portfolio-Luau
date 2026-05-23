local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventorySystem = require(ReplicatedStorage.Modules.InventorySystem)

local story = function(target)
	local template = script.Parent.InventoryUI
	local clone = template:Clone()

	for _, child in clone:GetChildren() do
		child.Parent = target
	end
	clone:Destroy()

	local inventory = InventorySystem.new(target)

	inventory:LoadSlots({
		["1"] = "BronzeAxe",
		["2"] = "IronAxe",
		["3"] = "GoldenAxe",
	})

    local mainBg = target:FindFirstChild("MainBg")
	local mainShadow = target:FindFirstChild("MainShadow")
	if mainBg then mainBg.Visible = true end
	if mainShadow then mainShadow.Visible = true end

    local openButton = target:FindFirstChild("Open")
	if openButton then
		openButton.Activated:Connect(function()
			inventory:ToggleInventoryUI()
		end)
	end

	return function()
		inventory:Destroy()
		for _, child in target:GetChildren() do
			child:Destroy()
		end
	end
end

return story
