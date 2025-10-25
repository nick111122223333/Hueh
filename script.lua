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

-- Folder for parts
local Folder = Instance.new("Folder", Workspace)
Folder.Name = "SuperRingPartsFolder"

-- Default ring parts setup
if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        Velocity = Vector3.new(14.46262424, 14.46262424, 14.46262424)
    }
    Network.RetainPart = function(Part)
        if typeof(Part) == "Instance" and Part:IsA("BasePart") and Part:IsDescendantOf(workspace) then
            table.insert(Network.BaseParts, Part)
            Part.CustomPhysicalProperties = PhysicalProperties.new(0,0,0,0,0)
            Part.CanCollide = false
        end
    end
    local function EnablePartControl()
        LocalPlayer.ReplicationFocus = workspace
        RunService.Heartbeat:Connect(function()
            sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
            for _, Part in pairs(Network.BaseParts) do
                if Part:IsDescendantOf(workspace) then
                    Part.Velocity = Network.Velocity
                end
            end
        end)
    end
    EnablePartControl()
end

-- GUI Creation (simplified)
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "SuperRingPartsGUI"
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0,220,0,190)
MainFrame.Position = UDim2.new(0.5,-110,0.5,-95)
MainFrame.BackgroundColor3 = Color3.fromRGB(0,102,51)
local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0,20)

-- Toggle button for ring parts
local ToggleButton = Instance.new("TextButton", MainFrame)
ToggleButton.Size = UDim2.new(0.8,0,0,35)
ToggleButton.Position = UDim2.new(0.1,0,0.3,0)
ToggleButton.Text = "Ring Parts Off"
ToggleButton.BackgroundColor3 = Color3.fromRGB(160,82,45)
ToggleButton.TextColor3 = Color3.fromRGB(255,255,255)

-- Ring Parts Logic
local ringPartsEnabled = false
ToggleButton.MouseButton1Click:Connect(function()
    ringPartsEnabled = not ringPartsEnabled
    ToggleButton.Text = ringPartsEnabled and "Ring Parts On" or "Ring Parts Off"
    ToggleButton.BackgroundColor3 = ringPartsEnabled and Color3.fromRGB(50,205,50) or Color3.fromRGB(160,82,45)
end)

local radius = 50
local height = 100
local rotationSpeed = 0.5
local attractionStrength = 1000

-- Track parts
local parts = {}
local function RetainPart(Part)
    if Part:IsA("BasePart") and not Part.Anchored and Part:IsDescendantOf(workspace) then
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
        if not table.find(parts, part) then
            table.insert(parts, part)
        end
    end
end

local function removePart(part)
    local index = table.find(parts, part)
    if index then table.remove(parts,index) end
end

for _, part in pairs(workspace:GetDescendants()) do addPart(part) end
workspace.DescendantAdded:Connect(addPart)
workspace.DescendantRemoving:Connect(removePart)

RunService.Heartbeat:Connect(function()
    if not ringPartsEnabled then return end
    if humanoidRootPart then
        local center = humanoidRootPart.Position
        for _, part in pairs(parts) do
            if part.Parent and not part.Anchored then
                local pos = part.Position
                local distance = (Vector3.new(pos.X, center.Y, pos.Z)-center).Magnitude
                local angle = math.atan2(pos.Z-center.Z, pos.X-center.X)
                local newAngle = angle + math.rad(rotationSpeed)
                local targetPos = Vector3.new(
                    center.X + math.cos(newAngle)*math.min(radius,distance),
                    center.Y + (height*(math.abs(math.sin((pos.Y-center.Y)/height)))),
                    center.Z + math.sin(newAngle)*math.min(radius,distance)
                )
                local directionToTarget = (targetPos-part.Position).Unit
                part.Velocity = directionToTarget * attractionStrength
            end
        end
    end
end)

-- SHAPE FROM DECAL
local shapeEnabled = false
local behindOffset = Vector3.new(0,0,-5)
local partSize = 2
local referencePosition = humanoidRootPart.Position + behindOffset

-- Function to create shape from 2D pattern (1 = pixel exists, 0 = transparent)
local function createShape(pattern)
    Folder:ClearAllChildren()
    if not pattern then return end
    for y,row in ipairs(pattern) do
        for x,val in ipairs(row) do
            if val == 1 then
                local part = Instance.new("Part")
                part.Size = Vector3.new(partSize,partSize,partSize)
                part.Anchored = true
                part.CanCollide = false
                part.Color = Color3.fromRGB(255,0,0)
                part.Position = referencePosition + Vector3.new((x-#row/2)*partSize,(#pattern/2-y)*partSize,0)
                part.Parent = Folder
            end
        end
    end
end

-- Example pattern: simple heart
local heartPattern = {
    {0,1,0,1,0},
    {1,1,1,1,1},
    {1,1,1,1,1},
    {0,1,1,1,0},
    {0,0,1,0,0}
}

-- GUI toggle for shape
local ShapeButton = Instance.new("TextButton", MainFrame)
ShapeButton.Size = UDim2.new(0.8,0,0,35)
ShapeButton.Position = UDim2.new(0.1,0,0.7,0)
ShapeButton.Text = "Shape Off"
ShapeButton.BackgroundColor3 = Color3.fromRGB(160,82,45)
ShapeButton.TextColor3 = Color3.fromRGB(255,255,255)

ShapeButton.MouseButton1Click:Connect(function()
    shapeEnabled = not shapeEnabled
    ShapeButton.Text = shapeEnabled and "Shape On" or "Shape Off"
    if shapeEnabled then
        createShape(heartPattern)
    else
        Folder:ClearAllChildren()
    end
end)

-- Follow player
RunService.Heartbeat:Connect(function()
    if shapeEnabled then
        referencePosition = humanoidRootPart.Position + behindOffset
        for _, part in pairs(Folder:GetChildren()) do
            local offset = part.Position - referencePosition
            part.Position = referencePosition + offset
        end
    end
end)
