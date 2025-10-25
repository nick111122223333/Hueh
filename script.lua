-- Image Spawning Button
local SpawnImageButton = Instance.new("TextButton")
SpawnImageButton.Size = UDim2.new(0.8, 0, 0, 35)
SpawnImageButton.Position = UDim2.new(0.1, 0, 0.75, 0)
SpawnImageButton.Text = "Spawn Image"
SpawnImageButton.BackgroundColor3 = Color3.fromRGB(75, 0, 130) -- Dark purple
SpawnImageButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SpawnImageButton.Font = Enum.Font.Fondamento
SpawnImageButton.TextSize = 18
SpawnImageButton.Parent = MainFrame

local SpawnImageCorner = Instance.new("UICorner")
SpawnImageCorner.CornerRadius = UDim.new(0, 10)
SpawnImageCorner.Parent = SpawnImageButton

-- Image settings
local IMAGE_ID = "114128730301476" -- <--- CHANGE THIS to your decal/texture ID
local BLOCK_SIZE = 1
local OFFSET_BEHIND = 10

-- Function to spawn voxel image behind player
local function SpawnVoxelImage()
    local folder = Instance.new("Folder", Workspace)
    folder.Name = "VoxelImage"

    -- Get texture from asset ID
    local image = Instance.new("ImageLabel")
    image.Size = UDim2.new(1,0,1,0)
    image.Image = "rbxassetid://"..IMAGE_ID
    image.Visible = false
    image.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local TEXTURE_SIZE = 32 -- Number of blocks per row/column (can increase for higher resolution)

    for y = 1, TEXTURE_SIZE do
        for x = 1, TEXTURE_SIZE do
            -- Sample pixel (simulate random here; replace with real pixel data if desired)
            if math.random() > 0.5 then
                local part = Instance.new("Part")
                part.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
                part.Anchored = true
                part.CanCollide = false
                part.Color = Color3.fromHSV(x/TEXTURE_SIZE, 1, 1)
                part.Position = humanoidRootPart.Position + Vector3.new(
                    (x - TEXTURE_SIZE/2) * BLOCK_SIZE,
                    (TEXTURE_SIZE/2 - y) * BLOCK_SIZE,
                    -OFFSET_BEHIND
                )
                part.Parent = folder
            end
        end
    end

    image:Destroy() -- Clean up the ImageLabel
    playSound("2865227271")
end

-- Connect button to function
SpawnImageButton.MouseButton1Click:Connect(SpawnVoxelImage)
