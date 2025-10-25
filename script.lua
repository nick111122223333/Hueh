-- Shape display script (uses ONLY existing, unanchored parts — no new parts created)
-- Controls:
--   1-4 = select shape (1 = Heart, 2 = Star, 3 = Smile, 4 = Triangle)
--   H   = toggle display on / off
--
-- Important: This version will NOT create new parts. It only collects existing BaseParts
-- in Workspace that are NOT Anchored and NOT descendants of the player's character or the ShapePartsFolder.
-- If there are fewer available parts than pixels in the selected shape, the script will use as many parts
-- as it has and skip remaining pixels (no new parts will be made).

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

-- Collect available parts: only existing parts that satisfy criteria
local function collectAvailableParts()
    local parts = {}
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            local isInCharacter = character and part:IsDescendantOf(character)
            local isInFolder = part:IsDescendantOf(ShapeFolder)
            if (not part.Anchored) and (not isInCharacter) and (not isInFolder) then
                -- mark as non-collidable for safer placement
                pcall(function() part.CanCollide = false end)
                table.insert(parts, part)
            end
        end
    end
    return parts
end

-- assignedParts are the parts currently used to render the shape (they are taken from availableParts)
local assignedParts = {}

local function releaseAssignedParts()
    for _, p in ipairs(assignedParts) do
        if p and p:IsA("BasePart") then
            -- Return part to Workspace root (keep it unanchored)
            p.Parent = Workspace
            p.Anchored = false
            -- Keep CanCollide false to avoid collisions
            p.CanCollide = false
        end
    end
    assignedParts = {}
end

-- Map a pattern to existing parts and position them relative to player.
-- IMPORTANT: This function will NOT create new parts. If there are not enough parts,
-- it will use as many as available and skip remaining pixels.
local function updateShape()
    if not shapeEnabled then
        releaseAssignedParts()
        return
    end

    local shapeEntry = Shapes[currentShapeName]
    if not shapeEntry then
        warn("Shape not found:", currentShapeName)
        return
    end

    -- Recollect available parts each update to reflect workspace changes
    local availableParts = collectAvailableParts()

    -- If previously assigned parts still exist and are valid, prefer to reuse them first.
    -- We'll build a working pool that excludes those parts (to avoid double-using).
    local pool = {}
    local assignedSet = {}
    for _, p in ipairs(assignedParts) do
        if p and p.Parent and p:IsA("BasePart") then
            assignedSet[p] = true
            table.insert(pool, p)
        end
    end
    -- Append other available parts not already assigned
    for _, p in ipairs(availableParts) do
        if not assignedSet[p] then
            table.insert(pool, p)
        end
    end

    local pattern = shapeEntry.pattern
    local rows = #pattern
    local cols = #pattern[1] or 0

    -- Count required pixels
    local required = 0
    for _, row in ipairs(pattern) do
        for _, v in ipairs(row) do
            if v == 1 then required = required + 1 end
        end
    end

    if #pool < 1 then
        warn("No available unanchored parts found in Workspace to form shape. Script will not create parts.")
        releaseAssignedParts()
        return
    end

    if #pool < required then
        -- Inform but still proceed using as many as possible
        warn(string.format("Not enough available parts: need %d but only found %d. Shape will be partial.", required, #pool))
    end

    -- Clear previous assigned parts' anchoring/parenting only for those not reused.
    -- We'll compute new assignedParts list as we map pixels.
    local newAssigned = {}
    local poolIndex = 1

    local center = (humanoidRootPart and humanoidRootPart.Position + behindOffset) or (Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame.Position + behindOffset) or Vector3.new(0,5,0)

    for y = 1, rows do
        local row = pattern[y]
        for x = 1, cols do
            if row[x] == 1 then
                if poolIndex > #pool then
                    -- out of parts, skip remaining pixels
                    -- continue
                else
                    local part = pool[poolIndex]
                    poolIndex = poolIndex + 1

                    if part and part:IsA("BasePart") then
                        -- Position calculation: center the pattern
                        local offsetX = (x - (cols + 1) / 2) * partSpacing
                        local offsetY = ((rows + 1) / 2 - y) * partSpacing
                        local targetPos = center + Vector3.new(offsetX, offsetY, 0)

                        -- Prepare part appearance & physics: anchor while showing
                        part.Anchored = true
                        part.CanCollide = false
                        pcall(function()
                            part.Size = Vector3.new(partSpacing, partSpacing, partSpacing) * 0.9
                            if part:IsA("BasePart") and shapeEntry.color then
                                part.Color = shapeEntry.color
                                part.Material = Enum.Material.Neon
                            end
                        end)

                        part.CFrame = CFrame.new(targetPos)
                        part.Parent = ShapeFolder

                        table.insert(newAssigned, part)
                    end
                end
            end
        end
    end

    -- Release any old assigned parts that weren't reused
    for _, old in ipairs(assignedParts) do
        local reused = false
        for _, v in ipairs(newAssigned) do
            if old == v then
                reused = true
                break
            end
        end
        if not reused then
            if old and old:IsA("BasePart") then
                old.Parent = Workspace
                old.Anchored = false
                old.CanCollide = false
            end
        end
    end

    assignedParts = newAssigned
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
        releaseAssignedParts()
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
        -- refresh character references if needed
        if not character or not character.Parent then
            character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        end
        updateShape()
    end
end)

-- Final note
print("Shape display loaded (use EXISTING unanchored parts only). Press H to toggle. Press 1=Heart, 2=Star, 3=Smile, 4=Triangle to choose shapes.")
