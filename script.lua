-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- GUI SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DynamicDecalShapesGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 180)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -90)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 102, 51)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.Text = "Decal Shapes v2"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.BackgroundColor3 = Color3.fromRGB(0, 153, 76)
Title.Font = Enum.Font.Fondamento
Title.TextSize = 22
Title.Parent = MainFrame

-- BUTTONS
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0.8, 0, 0, 35)
ToggleButton.Position = UDim2.new(0.1, 0, 0.3, 0)
ToggleButton.Text = "Off"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255,0,0)
ToggleButton.TextColor3 = Color3.fromRGB(255,255,255)
ToggleButton.Font = Enum.Font.Fondamento
ToggleButton.TextSize = 15
ToggleButton.Parent = MainFrame

local Shape1Button = Instance.new("TextButton")
Shape1Button.Size = UDim2.new(0.35, 0, 0, 30)
Shape1Button.Position = UDim2.new(0.05, 0, 0.6, 0)
Shape1Button.Text = "Heart"
Shape1Button.BackgroundColor3 = Color3.fromRGB(255,128,128)
Shape1Button.Parent = MainFrame

local Shape2Button = Instance.new("TextButton")
Shape2Button.Size = UDim2.new(0.35, 0, 0, 30)
Shape2Button.Position = UDim2.new(0.6, 0, 0.6, 0)
Shape2Button.Text = "Star"
Shape2Button.BackgroundColor3 = Color3.fromRGB(255,255,128)
Shape2Button.Parent = MainFrame

-- SETTINGS
local partSize = 0.5
local behindOffset = Vector3.new(0,0,5)
local shapeEnabled = false
local currentPattern = nil

-- PATTERN MODULE
local patterns = {
    Heart = {
        {0,1,0,1,0},
        {1,1,1,1,1},
        {1,1,1,1,1},
        {0,1,1,1,0},
        {0,0,1,0,0},
    },
    Star = {
        {0,0,1,0,0},
        {0,1,1,1,0},
        {1,1,1,1,1},
        {0,1,1,1,0},
        {0,0,1,0,0},
    }
}

-- FOLDER TO HOLD PARTS
local Folder = Instance.new("Folder")
Folder.Name = "DecalShapeParts"
Folder.Parent = Workspace

-- CREATE PARTS FUNCTION
local function createShape(pattern)
    Folder:ClearAllChildren()
    if not pattern then return end

    for y,row in ipairs(pattern) do
        for x,val in ipairs(row) do
            if val == 1 then
                local part = Instance.new("Part")
                part.Size = Vector3.new(partSize, partSize, partSize)
                part.Anchored = true
                part.CanCollide = false
                part.Color = Color3.fromRGB(255,0,0)
                part.Position = humanoidRootPart.Position + behindOffset + Vector3.new((x-3)*partSize,(3-y)*partSize,0)
                part.Parent = Folder
            end
        end
    end
end

-- BUTTON CONNECTIONS
ToggleButton.MouseButton1Click:Connect(function()
    shapeEnabled = not shapeEnabled
    ToggleButton.Text = shapeEnabled and "Shape On" or "Shape Off"
    ToggleButton.BackgroundColor3 = shapeEnabled and Color3.fromRGB(50,205,50) or Color3.fromRGB(255,0,0)
    if shapeEnabled then
        createShape(currentPattern)
    else
        Folder:ClearAllChildren()
    end
end)

Shape1Button.MouseButton1Click:Connect(function()
    currentPattern = patterns.Heart
    if shapeEnabled then createShape(currentPattern) end
end)

Shape2Button.MouseButton1Click:Connect(function()
    currentPattern = patterns.Star
    if shapeEnabled then createShape(currentPattern) end
end)

-- FOLLOW PLAYER
RunService.Heartbeat:Connect(function()
    if shapeEnabled and Folder then
        local offset = behindOffset
        for _, part in pairs(Folder:GetChildren()) do
            part.Position = humanoidRootPart.Position + offset + (part.Position - Folder.Position)
        end
        Folder.Position = humanoidRootPart.Position + offset
    end
end)
