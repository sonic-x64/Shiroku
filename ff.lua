local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer
local selfChams = {}
local enabled = false

-- Settings
local color = Color3.fromRGB(155, 125, 175)
local transparency = 0
local reflectance = 0
local material = 'ForceField'
local effect = 'none'
local heatTime = 0

-- PERFORMANCE CACHE
local partCache = {} 
local originalSettings = {}
local heatConnection
local charConnection

local r15Names = {
	'LeftFoot', 'LeftLowerLeg', 'LeftUpperLeg', 'RightFoot', 'RightLowerLeg', 'RightUpperLeg',
	'LeftHand', 'LeftLowerArm', 'LeftUpperArm', 'RightHand', 'RightLowerArm', 'RightUpperArm',
	'LowerTorso', 'UpperTorso', 'Head'
}

-- Built-in heat map values
local heatMap = {
	LeftFoot = 0.7, LeftLowerLeg = 0.3, LeftUpperLeg = 0.5,
	RightFoot = 0.7, RightLowerLeg = 0.3, RightUpperLeg = 0.5,
	LeftHand = 0.7, LeftLowerArm = 0.3, LeftUpperArm = 0.5,
	RightHand = 0.7, RightLowerArm = 0.3, RightUpperArm = 0.5,
	LowerTorso = 0.3, UpperTorso = 0.5, Head = 0.5,
}

-- BUILD THE CACHE (Only runs once when you spawn)
local function buildCache(char)
	partCache = {}
	originalSettings = {}
	if not char then return end

	-- 1. Grab Body Parts
	for _, name in ipairs(r15Names) do
		local p = char:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			table.insert(partCache, {Instance = p, HeatKey = name})
			originalSettings[p] = {
				Material = p.Material, Color = p.Color,
				Transparency = p.Transparency, Reflectance = p.Reflectance,
				TextureID = p:IsA("MeshPart") and p.TextureID or nil
			}
		end
	end

	-- 2. Grab Accessories (Hair/Hats)
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Accessory") then
			local h = child:FindFirstChild("Handle")
			if h and h:IsA("BasePart") then
				-- We treat accessories as "Head" for the heat pulse pulse
				table.insert(partCache, {Instance = h, HeatKey = "Head"})
				originalSettings[h] = {
					Material = h.Material, Color = h.Color,
					Transparency = h.Transparency, Reflectance = h.Reflectance,
					TextureID = h:IsA("MeshPart") and h.TextureID or nil
				}
			end
		end
	end
    
    -- Destroy Clothing
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("Shirt") or desc:IsA("Pants") then desc:Destroy() end
    end
end

-- ULTRA FAST UPDATE (No searching, just direct property setting)
local function applyChams(heatPulse)
	local targetMat = Enum.Material[material]
	
	for _, cacheItem in ipairs(partCache) do
		local p = cacheItem.Instance
		p.Material = targetMat
		p.Color = color
		p.Reflectance = reflectance
		if p:IsA("MeshPart") then p.TextureID = "" end
		
		if effect == "heat" then
			local base = heatMap[cacheItem.HeatKey] or 0.5
			p.Transparency = base + (0.2 * (heatPulse or 0))
		else
			p.Transparency = transparency
		end
	end
end

-- THE LOOP (Throttled for FPS)
local function startHeatLoop()
	if heatConnection then heatConnection:Disconnect() end
	heatTime = 0
	heatConnection = RunService.Heartbeat:Connect(function(dt)
		if not enabled or effect ~= "heat" then 
            if heatConnection then heatConnection:Disconnect() end
            return 
        end
		heatTime = heatTime + dt
		local pulse = math.sin(heatTime * 3) * 0.5 + 0.5
		applyChams(pulse)
	end)
end

-- PUBLIC API
function selfChams:setEnabled(val)
	enabled = val
	local char = lp.Character
	if enabled then
		buildCache(char)
		if effect == "heat" then startHeatLoop() else applyChams() end
		
		charConnection = lp.CharacterAdded:Connect(function(nc)
			nc:WaitForChild("Humanoid")
			task.wait(1.2) -- Wait for hair to load
			buildCache(nc)
			if effect == "heat" then startHeatLoop() else applyChams() end
		end)
	else
		if heatConnection then heatConnection:Disconnect() end
		if charConnection then charConnection:Disconnect() end
		-- Restore
		for part, data in pairs(originalSettings) do
			if part and part.Parent then
				part.Material = data.Material
				part.Color = data.Color
				part.Transparency = data.Transparency
				part.Reflectance = data.Reflectance
				if part:IsA("MeshPart") then part.TextureID = data.TextureID end
			end
		end
	end
end

-- Simplified Setters
function selfChams:setColor(c) color = c if enabled then applyChams() end end
function selfChams:setMaterial(m) material = m if enabled then applyChams() end end
function selfChams:setTransparency(t) transparency = t if enabled then applyChams() end end
function selfChams:setEffect(e) 
    effect = e 
    if enabled then 
        if e == "heat" then startHeatLoop() else applyChams() end 
    end 
end

return selfChams
