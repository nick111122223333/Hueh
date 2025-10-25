-- Heart tornado using existing parts

local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local tornadoActive = false
local connection

-- Configuration
local partsFolder = workspace:WaitForChild("HeartParts") -- folder containing parts to use
local scale = 1        -- adjust size of the heart
local heightOffset = 2 -- vertical offset behind player
local rotationSpeed = 2

-- Heart shape function
local function heartPosition(t)
    local x = 16 * math.sin(t)^3
    local y = 13*math.cos(t) - 5*math.cos(2*t) - 2*math.cos(3*t) - math.cos(4*t)
    return Vector3.new(x * scale, y * scale + heightOffset, -y * 0.1)
end

-- Animate parts in heart shape
local function startHeartTornado()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local parts = partsFolder:GetChildren()
    local numParts = #parts

    connection = RunService.RenderStepped:Connect(function(dt)
        local time = tick() * rotationSpeed
        for i, part in ipairs(parts) do
            local t = (i / numParts) * (2 * math.pi) + time
            local offset = heartPosition(t)
            part.CFrame = CFrame.new(hrp.Position + offset)
        end
    end)
end

local function stopHeartTornado()
    if connection then
        connection:Disconnect()
        connection = nil
    end
end

-- GUI toggle
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "HeartTornadoGui"

local button = Instance.new("TextButton")
button.Size = UDim2.new(0,150,0,50)
button.Position = UDim2.new(0.5,-75,0.9,-25)
button.Text = "Activate Heart Tornado"
button.Parent = screenGui
button.BackgroundColor3 = Color3.fromRGB(255,100,100)
button.TextColor3 = Color3.new(1,1,1)
button.Font = Enum.Font.SourceSansBold
button.TextScaled = true

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
