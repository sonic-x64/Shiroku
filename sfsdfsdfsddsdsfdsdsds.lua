local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Configuration / State
local lp = Players.LocalPlayer
local selfChams = {}
local enabled = false
local color = Color3.fromRGB(155, 125, 175)
local transparency = 0
local reflectance = 0
local material = 'ForceField'
local addEffect = 'none'
local particleColor = Color3.fromRGB(255, 255, 255)
local particleTransparency = 0
local charConnection

local cachedData = {
	parts = {},
	accessories = {},
	clothing = {},
	bodyColors = nil,
	faceDecal = nil,
}

local r15Parts = {
	'LeftFoot', 'LeftLowerLeg', 'LeftUpperLeg',
	'RightFoot', 'RightLowerLeg', 'RightUpperLeg',
	'LeftHand', 'LeftLowerArm', 'LeftUpperArm',
	'RightHand', 'RightLowerArm', 'RightUpperArm',
	'LowerTorso', 'UpperTorso', 'Head',
}

local partSet = {}
for _, name in ipairs(r15Parts) do
	partSet[name] = true
end

-- Helpers
local function isR15Part(name)
	return partSet[name] == true
end

local function cacheCharacter(char)
	if not char then return end

	cachedData.parts = {}
	cachedData.accessories = {}
	cachedData.clothing = {}
	cachedData.bodyColors = nil
	cachedData.faceDecal = nil

	for _, child in ipairs(char:GetChildren()) do
		if isR15Part(child.Name) and (child:IsA('MeshPart') or child:IsA('BasePart')) then
			cachedData.parts[child.Name] = {
				Material = child.Material,
				Color = child.Color,
				Transparency = child.Transparency,
				Reflectance = child.Reflectance,
				TextureID = child:IsA('MeshPart') and child.TextureID or nil,
			}
		elseif child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle")
			if handle and (handle:IsA("MeshPart") or handle:IsA("BasePart")) then
				cachedData.accessories[child] = {
					Material = handle.Material,
					Color = handle.Color,
					Transparency = handle.Transparency,
					Reflectance = handle.Reflectance,
					TextureID = handle:IsA('MeshPart') and handle.TextureID or nil,
				}
			end
		end
	end

	-- Cache clothing
	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA('Shirt') then
			cachedData.clothing.Shirt = desc.ShirtTemplate
		elseif desc:IsA('Pants') then
			cachedData.clothing.Pants = desc.PantsTemplate
		elseif desc:IsA('BodyColors') then
			cachedData.bodyColors = {
				HeadColor3 = desc.HeadColor3,
				LeftArmColor3 = desc.LeftArmColor3,
				LeftLegColor3 = desc.LeftLegColor3,
				RightArmColor3 = desc.RightArmColor3,
				RightLegColor3 = desc.RightLegColor3,
				TorsoColor3 = desc.TorsoColor3,
			}
		end
	end

	-- Cache face decal
	local head = char:FindFirstChild("Head")
	if head then
		local face = head:FindFirstChildOfClass("Decal")
		if face then
			cachedData.faceDecal = face.Texture
		end
	end
end

local function removeParticles(char)
	if not char then return end
	for _, part in ipairs(char:GetChildren()) do
		if isR15Part(part.Name) then
			local stars = part:FindFirstChild('stars')
			local specks = part:FindFirstChild('Specks')
			if stars then pcall(function() stars:Destroy() end) end
			if specks then pcall(function() specks:Destroy() end) end
		end
	end
end

local function applyStars(char)
	if not char then return end
	for _, part in ipairs(char:GetChildren()) do
		if isR15Part(part.Name) and (part:IsA('MeshPart') or part:IsA('BasePart')) then
			local existing = part:FindFirstChild('stars')
			if existing then existing:Destroy() end

			pcall(function()
				local stars = Instance.new('ParticleEmitter')
				stars.Name = 'stars'
				stars.Lifetime = NumberRange.new(0.45, 0.9)
				stars.LockedToPart = true
				stars.LightEmission = 1
				stars.Drag = 5
				stars.Squash = NumberSequence.new(-0.1)
				stars.Speed = NumberRange.new(0.001, 0.001)
				stars.Brightness = 3
				stars.ZOffset = 1
				stars.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.508, 0.05, 0.05),
					NumberSequenceKeypoint.new(1, 0),
				})
				stars.Rate = 150
				stars.Texture = 'rbxassetid://1084996976'
				stars.EmissionDirection = Enum.NormalId.Bottom
				stars.Color = ColorSequence.new(particleColor)
				stars.Transparency = NumberSequence.new(particleTransparency)
				stars.Parent = part
			end)
		end
	end
end

local function applyParticles(char)
	if not char then return end
	for _, part in ipairs(char:GetChildren()) do
		if isR15Part(part.Name) and (part:IsA('MeshPart') or part:IsA('BasePart')) then
			local existing = part:FindFirstChild('Specks')
			if existing then existing:Destroy() end

			pcall(function()
				local specks = Instance.new('ParticleEmitter')
				specks.Name = 'Specks'
				specks.Lifetime = NumberRange.new(0.22, 0.22)
				specks.SpreadAngle = Vector2.new(90, 90)
				local t = particleTransparency
				specks.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, math.min(1, t + 0.8)),
					NumberSequenceKeypoint.new(0.25, math.max(0, t - 0.1)),
					NumberSequenceKeypoint.new(1, math.min(1, t + 0.8)),
				})
				specks.LightEmission = 1
				specks.Color = ColorSequence.new(particleColor)
				specks.Drag = 5
				specks.Squash = NumberSequence.new(0)
				specks.Speed = NumberRange.new(1, 1)
				specks.Brightness = 4.2
				specks.Size = NumberSequence.new(0.15)
				specks.Acceleration = Vector3.new(0, -15, 0)
				specks.RotSpeed = NumberRange.new(-45, 45)
				specks.Rate = 100
				specks.Texture = 'rbxassetid://7216849703'
				specks.Parent = part
			end)
		end
	end
end

local function applyChams(char, skipParticles)
	if not char then return end

local function applyPropsToPart(p)
    -- Handle the head separately
    if p.Name == "Head" then
        -- If Neon, force BrickColor and remove texture
        if material == "Neon" then
            p.Material = Enum.Material.Neon
            p.BrickColor = BrickColor.new(color) -- forces correct color
            p.Transparency = transparency
            p.Reflectance = reflectance
            if p:IsA("MeshPart") then
                p.TextureID = ""
            end
            -- Remove any decals on the head to prevent weird effects
            for _, decal in ipairs(p:GetChildren()) do
                if decal:IsA("Decal") then
                    decal.Parent = nil
                end
            end
        else
            -- Other materials behave normally
            p.Material = Enum.Material[material]
            p.Color = color
            p.Transparency = transparency
            p.Reflectance = reflectance
            if p:IsA("MeshPart") then
                p.TextureID = ""
            end
        end
    else
        -- All other parts
        p.Material = Enum.Material[material]
        p.Color = color
        if p:IsA('MeshPart') then p.TextureID = '' end
        p.Reflectance = reflectance
        p.Transparency = transparency
    end
end

	-- Remove clothing
	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA('Pants') or desc:IsA('Shirt') then
			pcall(function() desc:Destroy() end)
		end
	end

	for _, child in ipairs(char:GetChildren()) do
		if isR15Part(child.Name) and (child:IsA('MeshPart') or child:IsA('BasePart')) then
			pcall(function() applyPropsToPart(child) end)
			-- Remove face decal if head and Neon
			if child.Name == "Head" and material == "Neon" then
				for _, decal in ipairs(child:GetChildren()) do
					if decal:IsA("Decal") then
						decal.Parent = nil
					end
				end
			end
		elseif child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle")
			if handle and (handle:IsA("MeshPart") or handle:IsA("BasePart")) then
				pcall(function() applyPropsToPart(handle) end)
			end
		end
	end

	if not skipParticles then
		if addEffect == 'stars' then
			applyStars(char)
		elseif addEffect == 'particles' then
			applyParticles(char)
		else
			removeParticles(char)
		end
	end
end

local function restoreCharacter(char)
	if not char then return end
	removeParticles(char)

	for _, part in ipairs(char:GetChildren()) do
		if isR15Part(part.Name) and cachedData.parts[part.Name] then
			local data = cachedData.parts[part.Name]
			pcall(function()
				part.Material = data.Material
				part.Color = data.Color
				part.Transparency = data.Transparency
				part.Reflectance = data.Reflectance
				if part:IsA('MeshPart') and data.TextureID then
					part.TextureID = data.TextureID
				end
			end)
		end
	end

	for acc, data in pairs(cachedData.accessories) do
		if acc and acc.Parent == char then
			local handle = acc:FindFirstChild("Handle")
			if handle then
				pcall(function()
					handle.Material = data.Material
					handle.Color = data.Color
					handle.Transparency = data.Transparency
					handle.Reflectance = data.Reflectance
					if handle:IsA('MeshPart') and data.TextureID then
						handle.TextureID = data.TextureID
					end
				end)
			end
		end
	end

	if cachedData.clothing.Shirt then
		pcall(function()
			local shirt = Instance.new('Shirt')
			shirt.ShirtTemplate = cachedData.clothing.Shirt
			shirt.Parent = char
		end)
	end
	if cachedData.clothing.Pants then
		pcall(function()
			local pants = Instance.new('Pants')
			pants.PantsTemplate = cachedData.clothing.Pants
			pants.Parent = char
		end)
	end

	-- Restore face decal
	local head = char:FindFirstChild("Head")
	if head and cachedData.faceDecal then
		local face = head:FindFirstChildOfClass("Decal")
		if not face then
			local newFace = Instance.new("Decal")
			newFace.Name = "face"
			newFace.Texture = cachedData.faceDecal
			newFace.Face = Enum.NormalId.Front
			newFace.Parent = head
		end
	end
end

-- Public Interface
function selfChams:setEnabled(val)
	enabled = val
	local char = lp.Character

	if enabled then
		cacheCharacter(char)
		applyChams(char)

		if charConnection then
			charConnection:Disconnect()
		end

		charConnection = lp.CharacterAdded:Connect(function(newChar)
			newChar:WaitForChild('Humanoid')
			task.wait(1.1)
			if enabled then
				cacheCharacter(newChar)
				applyChams(newChar)
				task.wait(0.5)
				applyChams(newChar)
			end
		end)
	else
		if charConnection then
			charConnection:Disconnect()
			charConnection = nil
		end
		restoreCharacter(char)
	end
end

function selfChams:setColor(c)
	color = c
	if enabled then applyChams(lp.Character) end
end

function selfChams:setTransparency(t)
	transparency = t
	if enabled then applyChams(lp.Character) end
end

function selfChams:setReflectance(r)
	reflectance = r
	if enabled then applyChams(lp.Character) end
end

function selfChams:setMaterial(m)
	material = m
	if enabled then applyChams(lp.Character) end
end

function selfChams:setAddEffect(e)
	addEffect = e
	if enabled then
		removeParticles(lp.Character)
		if e == 'stars' then
			applyStars(lp.Character)
		elseif e == 'particles' then
			applyParticles(lp.Character)
		end
	end
end

function selfChams:setParticleColor(c)
	particleColor = c
	if enabled then selfChams:setAddEffect(addEffect) end
end

function selfChams:setParticleTransparency(t)
	particleTransparency = t
	if enabled then selfChams:setAddEffect(addEffect) end
end

return selfChams
