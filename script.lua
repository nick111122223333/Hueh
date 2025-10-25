-- Ensure PlayerGui exists
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Check if GUI already exists (prevents duplicates)
local ScreenGui = PlayerGui:FindFirstChild("SuperRingPartsGUI")
if not ScreenGui then
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SuperRingPartsGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui
end

-- Main Frame
local MainFrame = ScreenGui:FindFirstChild("MainFrame")
if not MainFrame then
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 220, 0, 190)
    MainFrame.Position = UDim2.new(0.5, -110, 0.5, -95)
    MainFrame.BackgroundColor3 = Color3.fromRGB(204, 0, 0)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 20)
    UICorner.Parent = MainFrame
end

-- Add the Spawn Image Button
local SpawnImageButton = MainFrame:FindFirstChild("SpawnImageButton")
if not SpawnImageButton then
    SpawnImageButton = Instance.new("TextButton")
    SpawnImageButton.Name = "SpawnImageButton"
    SpawnImageButton.Size = UDim2.new(0.8, 0, 0, 35)
    SpawnImageButton.Position = UDim2.new(0.1, 0, 0.75, 0)
    SpawnImageButton.Text = "Spawn Image"
    SpawnImageButton.BackgroundColor3 = Color3.fromRGB(75, 0, 130)
    SpawnImageButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SpawnImageButton.Font = Enum.Font.Fondamento
    SpawnImageButton.TextSize = 18
    SpawnImageButton.Parent = MainFrame

    local SpawnImageCorner = Instance.new("UICorner")
    SpawnImageCorner.CornerRadius = UDim.new(0, 10)
    SpawnImageCorner.Parent = SpawnImageButton
end

-- Image spawning function
local IMAGE_ID = "114128730301476"
local BLOCK_SIZE = 2
local OFFSET_BEHIND = 15
local PIXEL_RES = 16

local function SpawnVoxelImage()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local folder = Instance.new("Folder", Workspace)
    folder.Name = "VoxelImage_"..LocalPlayer.Name

    local humanoidRootPart = LocalPlayer.Character.HumanoidRootPart
    local forward = humanoidRootPart.CFrame.LookVector
    local right = humanoidRootPart.CFrame.RightVector
    local up = Vector3.new(0,1,0)

    for y = 1, PIXEL_RES do
        for x = 1, PIXEL_RES do
            if math.random() > 0.5 then
                local part = Instance.new("Part")
                part.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
                part.Anchored = true
                part.CanCollide = false
                part.Color = Color3.fromHSV(x/PIXEL_RES, 1, 1)
                part.Position = humanoidRootPart.Position
                    - forward * OFFSET_BEHIND
                    + right * ((x - PIXEL_RES/2) * BLOCK_SIZE)
                    + up * ((PIXEL_RES/2 - y) * BLOCK_SIZE)
                part.Parent = folder

                if getgenv().Network then
                    Network.RetainPart(part)
                end
            end
        end
    end
end

SpawnImageButton.MouseButton1Click:Connect(SpawnVoxelImage)
