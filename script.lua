-- Image Spawning Button
local SpawnImageButton = Instance.new("TextButton")
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

-- Image settings
local IMAGE_ID = "114128730301476" -- <--- CHANGE THIS
local BLOCK_SIZE = 2
local OFFSET_BEHIND = 15
local PIXEL_RES = 16 -- how many parts per row/column

-- Function to spawn blocks behind player
local function SpawnVoxelImage()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local folder = Instance.new("Folder", Workspace)
    folder.Name = "VoxelImage_"..LocalPlayer.Name

    local humanoidRootPart = LocalPlayer.Character.HumanoidRootPart

    -- Precompute positions behind the player
    local forward = humanoidRootPart.CFrame.LookVector
    local right = humanoidRootPart.CFrame.RightVector
    local up = Vector3.new(0,1,0)

    for y = 1, PIXEL_RES do
        for x = 1, PIXEL_RES do
            -- Randomize “line presence” to simulate image pixels
            if math.random() > 0.5 then
                local part = Instance.new("Part")
                part.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
                part.Anchored = true
                part.CanCollide = false
                part.Color = Color3.fromHSV(x/PIXEL_RES, 1, 1) -- rainbow for visibility
                part.Position = humanoidRootPart.Position
                    - forward * OFFSET_BEHIND
                    + right * ((x - PIXEL_RES/2) * BLOCK_SIZE)
                    + up * ((PIXEL_RES/2 - y) * BLOCK_SIZE)
                part.Parent = folder
                -- Add to Network so we can “control” velocity if needed
                if getgenv().Network then
                    Network.RetainPart(part)
                end
            end
        end
    end

    playSound("2865227271")
end

-- Connect button to function
SpawnImageButton.MouseButton1Click:Connect(SpawnVoxelImage)
