-- SuperRingParts.lua
-- Integrated version of your script with a GUI field to replace the decal/asset id at runtime.
-- NOTE: This version adds a "Decal ID" text box + "Apply Decal" button that stores the chosen id in getgenv().CustomDecalId.
-- If you want the script to actually fetch the decal image bytes and spawn parts for non-transparent pixels
-- I can add an HTTP + PNG decode implementation, but I need to know whether you're running in a normal LocalScript
-- (no external HTTP) or in an executor environment that allows syn.request / http.request.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")

-- ===========
-- CONFIG
-- ===========
-- Default decal id (you can replace this in the GUI)
getgenv().CustomDecalId = getgenv().CustomDecalId or "123456789" -- put a default id here if you want

-- Settings for possible future pixel generation (not active until decoder implemented)
local pixelSampleResolution = 64 -- max dimension to sample from decal when decoding (placeholder)
local pixelPartSize = 0.5 -- studs per pixel (placeholder)

-- ===========
-- Utility: play sound
-- ===========
local function playSound(soundId)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. soundId
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

playSound("2865227271") -- initial sound

-- ===========
-- Existing Network / retain logic (kept mostly intact)
-- ===========
if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        Velocity = Vector3.new(14.46262424, 14.46262424, 14.46262424)
    }

    Network.RetainPart = function(Part)
        if typeof(Part) == "Instance" and Part:IsA("BasePart") and Part:IsDescendantOf(Workspace) then
            table.insert(Network.BaseParts, Part)
            Part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            Part.CanCollide = false
        end
    end

    local Folder = Instance.new("Folder", Workspace)
    Folder.Name = "SuperRingPartsFolder"
    local Part = Instance.new("Part", Folder)
    Part.Name = "AnchorPart"
    Part.Anchored = true
    Part.CanCollide = false
    Part.Transparency = 1
    local Attachment1 = Instance.new("Attachment", Part)

    local function EnablePartControl()
        LocalPlayer.ReplicationFocus = Workspace
        RunService.Heartbeat:Connect(function()
            pcall(function()
                sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
            end)
            for _, Part in pairs(Network.BaseParts) do
                if Part:IsDescendantOf(Workspace) then
                    Part.Velocity = Network.Velocity
                end
            end
        end)
    end

    EnablePartControl()
end

-- ===========
-- GUI (Main + toggle controls kept, plus decal id replacement UI)
-- ===========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SuperRingPartsGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 240)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -120)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 102, 51)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 14)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.Text = "Super Ring Parts v5"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.BackgroundColor3 = Color3.fromRGB(0,153,76)
Title.Font = Enum.Font.Fondamento
Title.TextSize = 22

-- Toggle
local ToggleButton = Instance.new("TextButton", MainFrame)
ToggleButton.Size = UDim2.new(0.5, 0, 0, 36)
ToggleButton.Position = UDim2.new(0.25, 0, 0.25, 0)
ToggleButton.Text = "Ring Parts Off"
ToggleButton.BackgroundColor3 = Color3.fromRGB(160,82,45)
ToggleButton.TextColor3 = Color3.fromRGB(255,255,255)
ToggleButton.Font = Enum.Font.Fondamento
ToggleButton.TextSize = 15
local ToggleCorner = Instance.new("UICorner", ToggleButton); ToggleCorner.CornerRadius = UDim.new(0,10)

-- Radius controls
local DecreaseRadius = Instance.new("TextButton", MainFrame)
DecreaseRadius.Size = UDim2.new(0.18,0,0,32)
DecreaseRadius.Position = UDim2.new(0.06,0,0.55,0)
DecreaseRadius.Text = "<"
DecreaseRadius.BackgroundColor3 = Color3.fromRGB(255,255,0)
DecreaseRadius.Font = Enum.Font.Fondamento
DecreaseRadius.TextSize = 18
local IncreaseRadius = Instance.new("TextButton", MainFrame)
IncreaseRadius.Size = UDim2.new(0.18,0,0,32)
IncreaseRadius.Position = UDim2.new(0.76,0,0.55,0)
IncreaseRadius.Text = ">"
IncreaseRadius.BackgroundColor3 = Color3.fromRGB(255,255,0)
IncreaseRadius.Font = Enum.Font.Fondamento
IncreaseRadius.TextSize = 18
local RadiusDisplay = Instance.new("TextLabel", MainFrame)
RadiusDisplay.Size = UDim2.new(0.52,0,0,32)
RadiusDisplay.Position = UDim2.new(0.24,0,0.55,0)
RadiusDisplay.Text = "Radius: 50"
RadiusDisplay.BackgroundColor3 = Color3.fromRGB(255,255,0)
RadiusDisplay.Font = Enum.Font.Fondamento
RadiusDisplay.TextSize = 15
local RadiusCorner = Instance.new("UICorner", RadiusDisplay); RadiusCorner.CornerRadius = UDim.new(0,10)

-- Decal ID UI
local DecalLabel = Instance.new("TextLabel", MainFrame)
DecalLabel.Size = UDim2.new(0.9,0,0,20)
DecalLabel.Position = UDim2.new(0.05,0,0.75,0)
DecalLabel.Text = "Decal / Texture Asset ID:"
DecalLabel.BackgroundTransparency = 1
DecalLabel.TextColor3 = Color3.fromRGB(255,255,255)
DecalLabel.Font = Enum.Font.Fondamento
DecalLabel.TextSize = 14

local DecalTextBox = Instance.new("TextBox", MainFrame)
DecalTextBox.Size = UDim2.new(0.9,0,0,28)
DecalTextBox.Position = UDim2.new(0.05,0,0.79,0)
DecalTextBox.Text = tostring(getgenv().CustomDecalId)
DecalTextBox.ClearTextOnFocus = false
DecalTextBox.Font = Enum.Font.Fondamento
DecalTextBox.TextSize = 14

local ApplyDecalButton = Instance.new("TextButton", MainFrame)
ApplyDecalButton.Size = UDim2.new(0.9,0,0,28)
ApplyDecalButton.Position = UDim2.new(0.05,0,0.92,0)
ApplyDecalButton.Text = "Apply Decal ID"
ApplyDecalButton.BackgroundColor3 = Color3.fromRGB(50,205,50)
ApplyDecalButton.Font = Enum.Font.Fondamento
ApplyDecalButton.TextSize = 16
local ApplyDecalCorner = Instance.new("UICorner", ApplyDecalButton); ApplyDecalCorner.CornerRadius = UDim.new(0,8)

-- Minimizing & dragging kept minimal for readability
local MinimizeButton = Instance.new("TextButton", MainFrame)
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -38, 0, 6)
MinimizeButton.Text = "-"
MinimizeButton.BackgroundColor3 = Color3.fromRGB(0,255,0)
MinimizeButton.Font = Enum.Font.Fondamento
MinimizeButton.TextSize = 15
local MinimizeCorner = Instance.new("UICorner", MinimizeButton); MinimizeCorner.CornerRadius = UDim.new(0,15)

-- Basic dragging
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- ===========
-- Ring generation logic (kept from your script)
-- ===========
local radius = 50
local height = 100
local rotationSpeed = 0.5
local attractionStrength = 1000
local ringPartsEnabled = false

local function RetainPart(Part)
    if Part:IsA("BasePart") and not Part.Anchored and Part:IsDescendantOf(workspace) then
        if Part.Parent == LocalPlayer.Character or Part:IsDescendantOf(LocalPlayer.Character) then
            return false
        end
        Part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        Part.CanCollide = false
        return true
    end
    return false
end

local parts = {}
local function addPart(part)
    if RetainPart(part) then
        if not table.find(parts, part) then
            table.insert(parts, part)
        end
    end
end

local function removePart(part)
    local index = table.find(parts, part)
    if index then
        table.remove(parts, index)
    end
end

for _, part in pairs(workspace:GetDescendants()) do
    addPart(part)
end

workspace.DescendantAdded:Connect(addPart)
workspace.DescendantRemoving:Connect(removePart)

RunService.Heartbeat:Connect(function()
    if not ringPartsEnabled then return end
    local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local tornadoCenter = humanoidRootPart.Position
        for _, part in pairs(parts) do
            if part.Parent and not part.Anchored then
                local pos = part.Position
                local distance = (Vector3.new(pos.X, tornadoCenter.Y, pos.Z) - tornadoCenter).Magnitude
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
end)

-- ===========
-- Button functionality
-- ===========
ToggleButton.MouseButton1Click:Connect(function()
    ringPartsEnabled = not ringPartsEnabled
    ToggleButton.Text = ringPartsEnabled and "Ring Parts On" or "Ring Parts Off"
    ToggleButton.BackgroundColor3 = ringPartsEnabled and Color3.fromRGB(50,205,50) or Color3.fromRGB(160,82,45)
    playSound("12221967")
end)

DecreaseRadius.MouseButton1Click:Connect(function()
    radius = math.max(0, radius - 5)
    RadiusDisplay.Text = "Radius: " .. radius
    playSound("12221967")
end)

IncreaseRadius.MouseButton1Click:Connect(function()
    radius = math.min(10000, radius + 5)
    RadiusDisplay.Text = "Radius: " .. radius
    playSound("12221967")
end)

MinimizeButton.MouseButton1Click:Connect(function()
    if MainFrame.Size.Y.Offset > 50 then
        MainFrame:TweenSize(UDim2.new(MainFrame.Size.X.Scale, MainFrame.Size.X.Offset, 0, 40), "Out", "Quad", 0.25, true)
        MinimizeButton.Text = "+"
    else
        MainFrame:TweenSize(UDim2.new(0, 320, 0, 240), "Out", "Quad", 0.25, true)
        MinimizeButton.Text = "-"
    end
    playSound("12221967")
end)

-- ===========
-- Decal ID apply handling
-- ===========
local function applyDecalId(newId)
    if not newId or newId == "" then
        StarterGui:SetCore("SendNotification", {
            Title = "Super Ring Parts",
            Text = "Please enter a valid asset id.",
            Duration = 3
        })
        playSound("12221967")
        return
    end
    getgenv().CustomDecalId = tostring(newId)
    DecalTextBox.Text = getgenv().CustomDecalId
    StarterGui:SetCore("SendNotification", {
        Title = "Super Ring Parts",
        Text = "Decal ID set to: " .. getgenv().CustomDecalId,
        Duration = 3
    })
    playSound("12221967")

    -- Placeholder: call generation function (not implemented here)
    -- When you confirm your environment, I will implement GenerateShapeFromDecal to fetch and decode the image,
    -- then spawn parts for non-transparent pixels using the Network.RetainPart/RetainPart logic.
    -- For now we only store the id and notify you.
end

ApplyDecalButton.MouseButton1Click:Connect(function()
    applyDecalId(DecalTextBox.Text)
end)

DecalTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        applyDecalId(DecalTextBox.Text)
    end
end)

-- ===========
-- Notifications & chat (kept)
-- ===========
-- Get player thumbnail for icon (kept original username usage)
local success, userId = pcall(function() return Players:GetUserIdFromNameAsync("Robloxlukasgames") end)
local thumbIcon = nil
if success and userId then
    local thumbType = Enum.ThumbnailType.HeadShot
    local thumbSize = Enum.ThumbnailSize.Size420x420
    local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
    thumbIcon = content
end

StarterGui:SetCore("SendNotification", {
    Title = "Super ring parts V5",
    Text = "enjoy",
    Icon = thumbIcon,
    Duration = 5
})
StarterGui:SetCore("SendNotification", {
    Title = "Credits",
    Text = "Original By Yumm Scriptblox",
    Icon = thumbIcon,
    Duration = 5
})
StarterGui:SetCore("SendNotification", {
    Title = "Credits",
    Text = "Edited By lukas",
    Icon = thumbIcon,
    Duration = 5
})

local function SendChatMessage(message)
    if TextChatService and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local textChannel = TextChatService.TextChannels.RBXGeneral
        if textChannel then
            textChannel:SendAsync(message)
        end
    else
        local success, _ = pcall(function()
            game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
        end)
    end
end
SendChatMessage("Super Ring Parts V5 By lukas")

-- ===========
-- Placeholder generator function
-- (This is a safe stub. If you want me to implement full fetch+PNG decode + spawn parts for non-transparent pixels,
-- tell me whether you run in a normal LocalScript (no HTTP) or an executor with HTTP (syn.request / http.request).
-- If you have HTTP access I will implement the fetching and a simple PNG alpha reader and then spawn parts.)
-- ===========
local function GenerateShapeFromDecal(assetId, resolution, partSize)
    -- assetId : string (asset id, numbers only)
    -- resolution: max dimension to sample (e.g., 32, 64)
    -- partSize: studs per pixel
    -- Return: boolean success
    -- Currently not implemented: this is where the fetch+decode+spawn code would live.
    warn("GenerateShapeFromDecal called with id:", assetId, "resolution:", resolution, "partSize:", partSize)
    -- If you confirm you have HTTP + want me to implement, I'll add the fetch + PNG decode + spawning logic.
    return false
end

-- Expose for other scripts if desired:
getgenv().SuperRingParts = getgenv().SuperRingParts or {}
getgenv().SuperRingParts.GenerateShapeFromDecal = GenerateShapeFromDecal

-- End of file
