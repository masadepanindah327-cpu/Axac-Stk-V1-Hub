-- =========================================================================
-- AXAC CURSOR v1.2 — Smooth Touch Follower (Mobile & PC)
-- =========================================================================

return function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local LP = Players.LocalPlayer

    local T = {
        accent = Color3.fromRGB(178, 22, 30),
        ink    = Color3.fromRGB(232, 228, 220),
    }

    local old = LP:WaitForChild("PlayerGui"):FindFirstChild("AxacCursor")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "AxacCursor"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 9999
    gui.Parent = LP:WaitForChild("PlayerGui")

    -- Matikan cursor bawaan di PC (kalau di HP ga ngaruh)
    pcall(function() UIS.MouseIconEnabled = false end)

    -- ORB UTAMA
    local orb = Instance.new("Frame")
    orb.Size = UDim2.fromOffset(28, 28)
    orb.BackgroundColor3 = T.accent
    orb.BackgroundTransparency = 0.2
    orb.AnchorPoint = Vector2.new(0.5, 0.5)
    orb.BorderSizePixel = 0
    orb.ZIndex = 999
    orb.Parent = gui

    local orbCorner = Instance.new("UICorner")
    orbCorner.CornerRadius = UDim.new(1, 0)
    orbCorner.Parent = orb

    local orbStroke = Instance.new("UIStroke")
    orbStroke.Color = T.ink
    orbStroke.Thickness = 1.5
    orbStroke.Parent = orb

    -- CORE TENGAH
    local core = Instance.new("Frame")
    core.Size = UDim2.fromOffset(6, 6)
    core.BackgroundColor3 = T.ink
    core.AnchorPoint = Vector2.new(0.5, 0.5)
    core.Position = UDim2.fromScale(0.5, 0.5)
    core.BorderSizePixel = 0
    core.ZIndex = 1000
    core.Parent = orb
    
    local coreCorner = Instance.new("UICorner")
    coreCorner.CornerRadius = UDim.new(1, 0)
    coreCorner.Parent = core

    -- STATE TRACKING
    local targetPos = Vector2.new(0, 0)
    local currentPos = Vector2.new(0, 0)
    local isDragging = false
    local isHovering = false

    -- TRAIL
    local lastTrailTime = 0
    local function spawnTrail(pos)
        local dot = Instance.new("Frame")
        dot.Size = UDim2.fromOffset(12, 12)
        dot.BackgroundColor3 = T.accent
        dot.BackgroundTransparency = 0.4
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Position = UDim2.fromOffset(pos.X, pos.Y)
        dot.ZIndex = 998
        dot.Parent = gui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = dot

        TweenService:Create(dot, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(2, 2),
            BackgroundTransparency = 1
        }):Play()

        task.delay(0.4, function() dot:Destroy() end)
    end

    -- RIPPLE PAS KLIK
    local function spawnRipple(pos)
        local ring = Instance.new("Frame")
        ring.Size = UDim2.fromOffset(28, 28)
        ring.BackgroundTransparency = 1
        ring.AnchorPoint = Vector2.new(0.5, 0.5)
        ring.Position = UDim2.fromOffset(pos.X, pos.Y)
        ring.ZIndex = 998
        ring.Parent = gui

        local stroke = Instance.new("UIStroke")
        stroke.Color = T.accent
        stroke.Thickness = 2
        stroke.Parent = ring

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ring

        TweenService:Create(ring, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(80, 80),
            BackgroundTransparency = 1
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Transparency = 1,
            Thickness = 0.5
        }):Play()

        task.delay(0.45, function() ring:Destroy() end)
    end

    -- DETEKSI GESTUR (INPUT BEGAN / MOVED / ENDED)
    UIS.InputBegan:Connect(function(input, gp)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            targetPos = input.Position
            spawnRipple(targetPos)
            
            -- Animasi ngecil pas ditekan
            TweenService:Create(orb, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(20, 20),
                BackgroundTransparency = 0
            }):Play()
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            targetPos = input.Position
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
            -- Animasi balik normal pas dilepas
            TweenService:Create(orb, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(isHovering and 36 or 28, isHovering and 36 or 28),
                BackgroundTransparency = 0.2
            }):Play()
        end
    end)

    -- UPDATE POSISI TIAP FRAME (SMOOTH LERP)
    RunService.RenderStepped:Connect(function(dt)
        -- Lerp biar smooth, ga kaku
        currentPos = currentPos:Lerp(targetPos, math.min(1, dt * 25))
        orb.Position = UDim2.fromOffset(currentPos.X, currentPos.Y)

        -- Efek Trail
        if (currentPos - targetPos).Magnitude > 5 or isDragging then
            if tick() - lastTrailTime > 0.03 then
                lastTrailTime = tick()
                spawnTrail(currentPos)
            end
        end
    end)

    -- DETEKSI HOVER KE TOMBOL
    RunService.Heartbeat:Connect(function()
        local hovering = false
        for _, obj in ipairs(gui:GetGuiObjectsAtPosition(currentPos.X, currentPos.Y)) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                hovering = true
                break
            end
        end

        if hovering ~= isHovering then
            isHovering = hovering
            local targetSize = isHovering and 36 or 28
            local targetColor = isHovering and T.ink or T.accent
            
            TweenService:Create(orb, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(targetSize, targetSize),
                BackgroundColor3 = targetColor
            }):Play()
            TweenService:Create(core, TweenInfo.new(0.15), {
                BackgroundColor3 = isHovering and T.accent or T.ink
            }):Play()
        end
    end)
end
