-- Shape display script
-- Adds multiple pixel-art shapes (heart, star, smile, triangle) using reusable parts.
-- Controls:
--   1-4 = select shape (1 = Heart, 2 = Star, 3 = Smile, 4 = Triangle)
--   H   = toggle display on / off
--
-- Notes:
-- - Parts used for shapes will be Anchored while shown and CanCollide = false.
-- - If there are not enough available parts in the workspace, new parts will be created automatically.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer and (LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
local humanoidRootPart = character and character:WaitForChild("HumanoidRootPart")

-- Folder for shape parts
local ShapeFolder = Workspace:FindFirstChild("ShapePartsFolder")
if not ShapeFolder then
    ShapeFolder = Instance.new("Folder")
    ShapeFolder.Name = "ShapePartsFolder"
    ShapeFolder.Parent = Workspace
end

local partSpacing = 2
local behindOffset = Vector3.new(0, 0, -5)
local shapeEnabled = false
local currentShapeName = "Heart"

-- Pixel patterns for shapes (0 = empty, 1 = filled)
local Shapes = {
    Heart = {
        pattern = {
            {0,1,0,1,0},
            {1,1,1,1,1},
            {1,1,1,1,1},
            {0,1,1,1,0},
            {0,0,1,0,0}
        },
        color = Color3.fromRGB(255, 50, 100)
    },
    Star = {
        pattern = {
            {0,0,1,0,1,0,0},
            {0,0,1,0,1,0,0},
            {1,1,1,1,1,1,1},
            {0,0,1,0,1,0,0},
            {0,1,0,1,0,1,0},
            {0,0,1,0,1,0,0},
            {0,0,1,0,1,0,0}
        },
        color = Color3.fromRGB(255, 230, 70)
    },
    Smile = {
        pattern = {
            {0,0,1,1,1,0,0},
            {0,1,0,0,0,1,0},
            {1,0,0,0,0,0,1},
            {1,0,1,0,1,0,1},
            {1,0,0,0,0,0,1},
            {0,1,0,1,0,1,0},
            {0,0,1,1,1,0,0}
        },
        color = Color3.fromRGB(100, 200, 255)
    },
    Triangle = {
        -- small isosceles triangle (5x5)
        pattern = {
            {0,0,1,0,0},
            {0,1,1,1,0},
            {1,1,1,1,1},
            {0,0,0,0,0},
            {0,0,0,0,0}
        },
        color = Color3.fromRGB(120, 255, 140)
    }
}

-- Collect available (reusable) parts: prefer unanchored non-character parts
local availableParts = {}
for _, part in ipairs(Workspace:GetDescendants()) do
    if part:IsA("BasePart") and not part:IsDescendantOf(character) then
        -- We'll treat these parts as reusable. Ensure they don't collide.
        part.CanCollide = false
        table.insert(availableParts, part)
    end
end

-- Utility: create a new part to use
local function createPart()
    local p = Instance.new("Part")
    p.Size = Vector3.new(1.5, 1.5, 1.5)
    p.Anchored = false -- we'll anchor when showing shapes
    p.CanCollide = false
    p.Material = Enum.Material.Neon
    p.Name = "ShapePart"
    p.Parent = Workspace
    return p
end

-- Ensure we have at least n parts available (adds new parts if necessary)
local function ensureAvailableParts(n)
    while #availableParts < n do
        table.insert(availableParts, createPart())
    end
end

-- Keep track of which parts are currently assigned to shape so we can release them
local assignedParts = {}

-- Clear current shape: unassign parts and return them to Workspace (and un-anchor)
local function clearShape()
    for _, p in ipairs(assignedParts) do
        if p and p.Parent then
            p.Parent = Workspace
        end
        if p and p:IsA("BasePart") then
            p.Anchored = false
            p.CanCollide = false
        end
    end
    assignedParts = {}
end

-- Map a pattern to parts and position them relative to player
local function updateShape()
    -- If not enabled, clear and return parts
    if not shapeEnabled then
        clearShape()
        return
    end

    local shapeEntry = Shapes[currentShapeName]
    if not shapeEntry then
        warn("Shape not found:", currentShapeName)
        return
    end

    local pattern = shapeEntry.pattern
    local rows = #pattern
    local cols = #pattern[1] or 0

    -- Count required parts
    local required = 0
    for _, row in ipairs(pattern) do
        for _, v in ipairs(row) do
            if v == 1 then required = required + 1 end
        end
    end

    ensureAvailableParts(required)

    -- Release any previously assigned parts back to available pool (but keep them in the array)
    for _, p in ipairs(assignedParts) do
        -- do nothing special, they remain in availableParts; we'll re-use availableParts directly
    end
    assignedParts = {}

    -- Center calculations: use (cols+1)/2 so indexing 1..cols centers correctly
    local center = humanoidRootPart and (humanoidRootPart.Position + behindOffset) or (Workspace.CurrentCamera and (Workspace.CurrentCamera.CFrame.Position + behindOffset) or Vector3.new(0,5,0))
    local index = 1

    -- We'll iterate through pattern and assign parts from availableParts in order
    for y = 1, rows do
        local row = pattern[y]
        for x = 1, cols do
            local val = row[x]
            if val == 1 then
                local part = availableParts[index]
                if not part then
                    -- fallback: create a new part
                    part = createPart()
                    table.insert(availableParts, part)
                end

                -- Position calculation:
                local offsetX = (x - (cols + 1) / 2) * partSpacing
                local offsetY = ((rows + 1) / 2 - y) * partSpacing
                local targetPos = center + Vector3.new(offsetX, offsetY, 0)

                -- Prepare part appearance & physics
                part.Anchored = true   -- anchor so it stays in place
                part.CanCollide = false
                if part:IsA("BasePart") then
                    part.Size = Vector3.new(partSpacing, partSpacing, partSpacing) * 0.9
                    part.Color = shapeEntry.color or part.Color
                    part.Material = Enum.Material.Neon
                end

                part.CFrame = CFrame.new(targetPos)
                part.Parent = ShapeFolder

                table.insert(assignedParts, part)
                index = index + 1
            end
        end
    end
end

-- Shape selection helper
local function setShapeByName(name)
    if not Shapes[name] then
        warn("Unknown shape:", name)
        return
    end
    currentShapeName = name
    if shapeEnabled then
        updateShape()
    end
end

-- Toggle function
local function toggleShape()
    shapeEnabled = not shapeEnabled
    if not shapeEnabled then
        clearShape()
    else
        updateShape()
    end
    print("Shape display", shapeEnabled and "enabled" or "disabled", " — current shape:", currentShapeName)
end

-- Input handling: 1-4 select shapes, H toggles
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode
        if key == Enum.KeyCode.H then
            toggleShape()
        elseif key == Enum.KeyCode.One then
            setShapeByName("Heart")
        elseif key == Enum.KeyCode.Two then
            setShapeByName("Star")
        elseif key == Enum.KeyCode.Three then
            setShapeByName("Smile")
        elseif key == Enum.KeyCode.Four then
            setShapeByName("Triangle")
        end
    end
end)

-- Keep shape following player each frame when enabled
RunService.RenderStepped:Connect(function()
    if shapeEnabled then
        -- Small optimization: only update if player and root part exist
        if not humanoidRootPart or not humanoidRootPart.Parent then
            character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        end
        updateShape()
    end
end)

-- Optional: expose a simple API on the script for other scripts to use
local module = {}
module.Toggle = toggleShape
module.SetShape = setShapeByName
module.IsEnabled = function() return shapeEnabled end
module.GetCurrentShape = function() return currentShapeName end

-- Print usage
print("Shape display loaded. Press H to toggle. Press 1=Heart, 2=Star, 3=Smile, 4=Triangle to choose shapes.")

return module
