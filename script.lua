-- StarterGui Script

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HeartTornadoGui"
screenGui.Parent = playerGui

-- Button
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 150, 0, 50)
button.Position = UDim2.new(0.5, -75, 0.9, -25)
button.Text = "Activate Heart Tornado"
button.Parent = screenGui
button.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
button.TextColor3 = Color3.new(1,1,1)
button.Font = Enum.Font.SourceSansBold
button.TextScaled = true

-- Variables
local RunService = game:GetService("RunService")
local tornadoActive = false
local heartParts = {}
local numParts = 30
local scale = 0.3
local heightOffset = 2
local rotationSpeed = 2

-- Heart shape function
local function heartPosition(t)
    local x = 16 * math.sin(t)^3
    local y = 13*math.cos(t) - 5*math.cos(2*t) - 2*math.cos(3*t) - math.cos(4*t)
    return Vector3.new(x * scale, y * scale + heightOffset, -y * 0.1)
end

-- Spawn heart parts
local function createHeartParts()
    for i = 1, numParts do
        local part = Instance.new("Part")
        part.Size = Vector3.new(1,1,1) * scale
        part.Anchored = true
        part.CanCollide = false
        part.Material = Enum.Material.Neon
        part.BrickColor = BrickColor.random()
        part.Parent = workspace
        table.insert(heartParts, part)
    end
end

-- Remove heart parts
local function clearHeartParts()
    for _, part in ipairs(heartParts) do
        if part and part.Parent then
            part:Destroy()
        end
    end
    heartParts = {}
end

-- Animate heart tornado
local connection
local function startHeartTornado()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")

    createHeartParts()
    
    connection = RunService.RenderStepped:Connect(function(dt)
        local time = tick() * rotationSpeed
        for i, part in ipairs(heartParts) do
            local t = (i / numParts) * (2 * math.pi) + time
            local offset = heartPosition(t)
            part.Position = hrp.Position + offset
        end
    end)
end

local function stopHeartTornado()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    clearHeartParts()
end

-- Button click
button.MouseButton1Click:Connect(function()
    tornadoActive = not tornadoActive
    if tornadoActive then
        button.Text = "Deactivate Heart Tornado"
        startHeartTornado()
    else
        button.Text = "Activate Heart Tornado"
        stopHeartTornado()
    end
end)
