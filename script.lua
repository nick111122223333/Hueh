-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Folder for controlling parts
local ShapeFolder = Instance.new("Folder", Workspace)
ShapeFolder.Name = "ShapePartsFolder"

-- Super Ring / Existing Part Handling
if not getgenv().Network then
    getgenv().Network = { BaseParts = {}, Velocity = Vector3.new(14.46262424,14.46262424,14.46262424) }

    Network.RetainPart = function(Part)
        if typeof(Part) == "Instance" and Part:IsA("BasePart") and Part:IsDescendantOf(Workspace) then
            table.insert(Network.BaseParts, Part)
            Part.CustomPhysicalProperties = PhysicalProperties.new(0,0,0,0,0)
            Part.CanCollide = false
        end
    end

    local function EnablePartControl()
        LocalPlayer.ReplicationFocus = Workspace
        RunService.Heartbeat:Connect(function()
            sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
            for _, Part in pairs(Network.BaseParts) do
                if Part:IsDescendantOf(Workspace) then
                    Part.Velocity = Network.Velocity
                end
            end
        end)
    end

    EnablePartControl()
end

-- Ring / Tornado Settings
local radius = 50
local height = 100
local rotationSpeed = 0.5
local attractionStrength = 1000
local ringPartsEnabled = false
local shapeEnabled = false
local partSpacing = 2
local behindOffset = Vector3.new(0,0,-5)

-- Collect existing unanchored parts
local function getAvailableParts()
    local available = {}
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(character) then
            table.insert(available, part)
        end
    end
    return available
end

-- Map parts to a 2D shape pattern (1 = solid pixel, 0 = transparent)
local function mapPartsToShape(pattern, centerPosition)
    local availableParts = getAvailableParts()
    if #availableParts == 0 then return end

    local index = 1
    local rows = #pattern
    local cols = #pattern[1]

    for y,row in ipairs(pattern) do
        for x,val in ipairs(row) do
            if val == 1 and index <= #availableParts then
                local part = availableParts[index]
                index += 1

                local offsetX = (x - cols/2) * partSpacing
                local offsetY = (rows/2 - y) * partSpacing
                local targetPos = centerPosition + Vector3.new(offsetX, offsetY, behindOffset.Z)

                part.Velocity = (targetPos - part.Position) * 10
                part.CanCollide = false
                part.Parent = ShapeFolder
            end
        end
    end
end

-- Example shape (heart)
local heartPattern = {
    {0,1,0,1,0},
    {1,1,1,1,1},
    {1,1,1,1,1},
    {0,1,1,1,0},
    {0,0,1,0,0}
}

-- Collect and manage all available parts for tornado ring
local parts = {}
local function RetainPart(Part)
    if Part:IsA("BasePart") and not Part.Anchored and Part:IsDescendantOf(Workspace) then
        if Part.Parent == LocalPlayer.Character or Part:IsDescendantOf(LocalPlayer.Character) then
            return false
        end
        Part.CustomPhysicalProperties = PhysicalProperties.new(0,0,0,0,0)
        Part.CanCollide = false
        return true
    end
    return false
end

local function addPart(part)
    if RetainPart(part) then
        if not table.find(parts, part) then table.insert(parts, part) end
    end
end

local function removePart(part)
    local index = table.find(parts, part)
    if index then table.remove(parts, index) end
end

for _, part in pairs(Workspace:GetDescendants()) do addPart(part) end
Workspace.DescendantAdded:Connect(addPart)
Workspace.DescendantRemoving:Connect(removePart)

-- Heart / Shape + Ring update loop
RunService.Heartbeat:Connect(function()
    local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    local tornadoCenter = humanoidRootPart.Position

    -- Tornado / Ring
    if ringPartsEnabled then
        for _, part in pairs(parts) do
            if part.Parent and not part.Anchored then
                local pos = part.Position
                local distance = (Vector3.new(pos.X,tornadoCenter.Y,pos.Z) - tornadoCenter).Magnitude
                local angle = math.atan2(pos.Z - tornadoCenter.Z, pos.X - tornadoCenter.X)
                local newAngle = angle + math.rad(rotationSpeed)
                local targetPos = Vector3.new(
                    tornadoCenter.X + math.cos(newAngle) * math.min(radius, distance),
                    tornadoCenter.Y + (height * (math.abs(math.sin((pos.Y - tornadoCenter.Y) / height)))),
                    tornadoCenter.Z + math.sin(newAngle) * math.min(radius, distance)
                )
                local directionToTarget = (targetPos - part.Position).unit
                part.Velocity = directionToTarget * attractionStrength
            end
        end
    end

    -- Shape behind player
    if shapeEnabled then
        mapPartsToShape(heartPattern, tornadoCenter + behindOffset)
    end
end)

-- GUI / Toggle Buttons (simplified for demonstration)
-- You can integrate these into your existing GUI
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "ShapeGUI"

local ToggleShapeButton = Instance.new("TextButton", ScreenGui)
ToggleShapeButton.Size = UDim2.new(0, 200, 0, 50)
ToggleShapeButton.Position = UDim2.new(0.5, -100, 0, 100)
ToggleShapeButton.Text = "Toggle Shape"
ToggleShapeButton.MouseButton1Click:Connect(function()
    shapeEnabled = not shapeEnabled
    ToggleShapeButton.Text = shapeEnabled and "Shape On" or "Shape Off"
end)

-- Optional: Integrate your existing toggle/radius buttons here
