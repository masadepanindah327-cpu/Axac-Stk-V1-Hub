-- =========================================================================
-- AXAC HUB — COMBINED ULTIMATE (LORENZO + ZEERO)
-- Fluent UI framework, Gold Accent branding, Watermark toggle.
-- Fixed: Added Floating Toggle to prevent losing UI.
-- =========================================================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- Kill Blur
pcall(function()
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("BlurEffect") then v.Enabled = false end
    end
end)
Lighting.ChildAdded:Connect(function(child)
    pcall(function() if child:IsA("BlurEffect") then task.wait(0.1) child.Enabled = false end end)
end)

-- ==========================================
-- AXAC THEME & UI (FLUENT)
-- ==========================================
local Window = Fluent:CreateWindow({
    Title = "Axac Hub",
    SubTitle = "Combined Ultimate | v3.1",
    TabWidth = 160,
    Size = UDim2.fromOffset(620, 480),
    Theme = "Dark",
    Acrylic = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "shield" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Effects = Window:AddTab({ Title = "Effects", Icon = "sun" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

-- ==========================================
-- AXAC FLOATING TOGGLE (FIX UI ILANG)
-- ==========================================
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "AxacToggleGui"
ToggleGui.ResetOnSpawn = false
ToggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ToggleGui.Parent = (gethui and gethui()) or CoreGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 45, 0, 45)
ToggleBtn.Position = UDim2.new(0, 15, 0.4, 0) -- Posisi di kiri layar
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
ToggleBtn.Text = "AX"
ToggleBtn.TextColor3 = Color3.fromRGB(250, 204, 21)
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.TextSize = 18
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Draggable = true
ToggleBtn.Parent = ToggleGui

local UICorner = Instance.new("UICorner", ToggleBtn)
UICorner.CornerRadius = UDim.new(0, 8)

local UIStroke = Instance.new("UIStroke", ToggleBtn)
UIStroke.Color = Color3.fromRGB(250, 204, 21)
UIStroke.Thickness = 2

local function ToggleWindow()
    if Window.Root then
        Window.Root.Visible = not Window.Root.Visible
    end
end

ToggleBtn.MouseButton1Click:Connect(ToggleWindow)

-- Deteksi kalau window Fluent ditutup pake X, tombol toggle tetep ada
task.spawn(function()
    repeat task.wait(0.1) until Window.Root
    Window.Root.Destroying:Connect(function()
        ToggleGui:Destroy()
    end)
    local closeBtn = Window.Root:FindFirstChild("CloseButton", true) or Window.Root:FindFirstChild("Close", true)
    if closeBtn then
        closeBtn.MouseButton1Click:Connect(function()
            -- Biarin window nutup, tapi jangan hancurin ToggleGui
            if Window.Root then Window.Root.Visible = false end
        end)
    end
end)

-- ==========================================
-- AXAC WATERMARK (CIRI KHAS)
-- ==========================================
local WM = Instance.new("ScreenGui")
WM.Name = "AxacWatermark"
WM.ResetOnSpawn = false
WM.IgnoreGuiInset = true
WM.Parent = (gethui and gethui()) or CoreGui

local WM_Frame = Instance.new("TextLabel")
WM_Frame.Size = UDim2.new(0, 100, 0, 24)
WM_Frame.Position = UDim2.new(0, 15, 0, 15)
WM_Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
WM_Frame.BackgroundTransparency = 0.2
WM_Frame.BorderSizePixel = 0
WM_Frame.Text = "AXAC"
WM_Frame.TextColor3 = Color3.fromRGB(250, 204, 21) -- Gold
WM_Frame.Font = Enum.Font.GothamBlack
WM_Frame.TextSize = 12
WM_Frame.Parent = WM

local WM_Corner = Instance.new("UICorner", WM_Frame)
WM_Corner.CornerRadius = UDim.new(0, 6)

local WM_Stroke = Instance.new("UIStroke", WM_Frame)
WM_Stroke.Color = Color3.fromRGB(250, 204, 21)
WM_Stroke.Thickness = 1.5

Tabs.Settings:AddToggle("WMToggle", {
    Title = "Show Watermark",
    Default = true,
    Callback = function(v) WM_Frame.Visible = v end
})

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================
local function checkIsKiller(p)
    if not p or not p.Character then return false end
    local charTools = p.Character:FindFirstChildWhichIsA("Tool")
    local backTools = p:FindFirstChild("Backpack") and p.Backpack:FindFirstChildWhichIsA("Tool")
    if charTools or backTools then return true end
    if p.Character:FindFirstChild("Knife") or p.Character:FindFirstChild("Killer") or p.Character:FindFirstChild("KillerScript") then return true end
    if p:FindFirstChild("Role") and tostring(p.Role.Value):lower():find("killer") then return true end
    return false
end

local function getHumanoid()
    if LocalPlayer.Character then return LocalPlayer.Character:FindFirstChildOfClass("Humanoid") end
    return nil
end

local function getRootPart()
    local char = LocalPlayer.Character
    local hum = getHumanoid()
    return hum and hum.RootPart
end

-- ==========================================
-- [TAB 1: MAIN / UTILITY]
-- ==========================================
_G.AutoRevive = false
_G.KillerAlert = false
_G.AntiTrap = false
_G.AntiAFK = false

Tabs.Main:AddToggle("AutoReviveToggle", {
    Title = "Auto Revive (Revive Downed)",
    Default = false,
    Callback = function(v)
        _G.AutoRevive = v
        task.spawn(function()
            while _G.AutoRevive do
                pcall(function()
                    local myRoot = getRootPart()
                    if myRoot then
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                                if not checkIsKiller(p) then
                                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                                    if hum and hum.Health > 0 and (p.Character:FindFirstChild("Downed") or hum.PlatformStand) then
                                        if (myRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude < 12 then
                                            local prompt = p.Character:FindFirstChildWhichIsA("ProximityPrompt", true)
                                            if prompt and fireproximityprompt then fireproximityprompt(prompt) end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.2)
            end
        end)
    end
})

Tabs.Main:AddToggle("KillerAlertToggle", {
    Title = "Killer Proximity Alert (<75m)",
    Default = false,
    Callback = function(v)
        _G.KillerAlert = v
        task.spawn(function()
            local lastAlert = 0
            while _G.KillerAlert do
                pcall(function()
                    local myRoot = getRootPart()
                    if myRoot then
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and checkIsKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                                local dist = math.floor((myRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude)
                                if dist <= 75 and (tick() - lastAlert > 4) then
                                    lastAlert = tick()
                                    Fluent:Notify({ Title = "⚠️ KILLER NEARBY", Content = p.Name .. " is " .. tostring(dist) .. "m away", Duration = 3 })
                                end
                            end
                        end
                    end
                end)
                task.wait(0.5)
            end
        end)
    end
})

Tabs.Main:AddToggle("AntiTrapToggle", {
    Title = "Anti Trap (Destroy HitBox)",
    Default = false,
    Callback = function(v)
        _G.AntiTrap = v
        if v then
            task.spawn(function()
                while _G.AntiTrap do
                    pcall(function()
                        for _, obj in ipairs(workspace:GetChildren()) do
                            if obj.Name == "Trap" then
                                local hb = obj:FindFirstChild("HitBox")
                                if hb then hb:Destroy() end
                            end
                        end
                    end)
                    task.wait(1)
                end
            end)
        end
    end
})

Tabs.Main:AddToggle("AntiAFKToggle", {
    Title = "Anti AFK (Auto Move)",
    Default = false,
    Callback = function(v)
        _G.AntiAFK = v
        task.spawn(function()
            while _G.AntiAFK do
                pcall(function()
                    if VirtualInputManager then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                        task.wait(0.1)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                    end
                end)
                task.wait(15)
            end
        end)
    end
})

-- ==========================================
-- [TAB 2: ESP]
-- ==========================================
local ESPFolder = workspace:FindFirstChild("AxacESPFolder") or Instance.new("Folder", workspace)
ESPFolder.Name = "AxacESPFolder"
_G.ESP_Active = false
_G.Tracers_Killer = false
_G.Tracers_Survivors = false
_G.ESP_ShowNames = false
_G.ESP_ShowDistance = false

Tabs.ESP:AddToggle("ESPToggle", {
    Title = "Player ESP (Highlight)",
    Default = false,
    Callback = function(v)
        _G.ESP_Active = v
        if not v then ESPFolder:ClearAllChildren() end
    end
})

Tabs.ESP:AddToggle("TracersKiller", {
    Title = "Tracer to Killer (Red)",
    Default = false,
    Callback = function(v)
        _G.Tracers_Killer = v
        if not v then
            for _, child in pairs(ESPFolder:GetChildren()) do
                if child.Name:find("Tracer_Killer_") then child:Destroy() end
            end
        end
    end
})

Tabs.ESP:AddToggle("TracersSurvivors", {
    Title = "Tracer to Survivors (Blue)",
    Default = false,
    Callback = function(v)
        _G.Tracers_Survivors = v
        if not v then
            for _, child in pairs(ESPFolder:GetChildren()) do
                if child.Name:find("Tracer_Survivor_") then child:Destroy() end
            end
        end
    end
})

Tabs.ESP:AddToggle("ESPNames", {
    Title = "Show Player Names",
    Default = false,
    Callback = function(v)
        _G.ESP_ShowNames = v
        if not v then
            for _, child in pairs(ESPFolder:GetChildren()) do
                if child.Name:find("Tag_") then child:Destroy() end
            end
        end
    end
})

Tabs.ESP:AddToggle("ESPDistance", {
    Title = "Show Distance",
    Default = false,
    Callback = function(v) _G.ESP_ShowDistance = v end
})

RunService.Heartbeat:Connect(function()
    if not _G.ESP_Active and not _G.Tracers_Killer and not _G.Tracers_Survivors and not _G.ESP_ShowNames and not _G.ESP_ShowDistance then
        if #ESPFolder:GetChildren() > 0 then ESPFolder:ClearAllChildren() end
        return
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local isKiller = checkIsKiller(p)
            local myRoot = getRootPart()
            local dist = myRoot and math.floor((myRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude) or 0

            if _G.ESP_Active then
                local hl = ESPFolder:FindFirstChild("Player_" .. p.Name)
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "Player_" .. p.Name
                    hl.Adornee = p.Character
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = ESPFolder
                end
                hl.FillColor = isKiller and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 120, 255)
                hl.FillTransparency = isKiller and 0.2 or 0.5
            end
            if myRoot then
                if _G.Tracers_Killer and isKiller then
                    local beam = ESPFolder:FindFirstChild("Tracer_Killer_" .. p.Name)
                    if not beam then
                        local a0 = Instance.new("Attachment", myRoot)
                        local a1 = Instance.new("Attachment", p.Character.HumanoidRootPart)
                        beam = Instance.new("Beam")
                        beam.Name = "Tracer_Killer_" .. p.Name
                        beam.Attachment0 = a0
                        beam.Attachment1 = a1
                        beam.Width0 = 0.12
                        beam.Width1 = 0.12
                        beam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
                        beam.FaceCamera = true
                        beam.Parent = ESPFolder
                    end
                end
                if _G.Tracers_Survivors and not isKiller then
                    local beam = ESPFolder:FindFirstChild("Tracer_Survivor_" .. p.Name)
                    if not beam then
                        local a0 = Instance.new("Attachment", myRoot)
                        local a1 = Instance.new("Attachment", p.Character.HumanoidRootPart)
                        beam = Instance.new("Beam")
                        beam.Name = "Tracer_Survivor_" .. p.Name
                        beam.Attachment0 = a0
                        beam.Attachment1 = a1
                        beam.Width0 = 0.08
                        beam.Width1 = 0.08
                        beam.Color = ColorSequence.new(Color3.fromRGB(0, 170, 255))
                        beam.FaceCamera = true
                        beam.Parent = ESPFolder
                    end
                end
            end
            if (_G.ESP_ShowNames or _G.ESP_ShowDistance) then
                local billboard = ESPFolder:FindFirstChild("Tag_" .. p.Name)
                if not billboard then
                    billboard = Instance.new("BillboardGui")
                    billboard.Name = "Tag_" .. p.Name
                    billboard.Adornee = p.Character:FindFirstChild("Head") or p.Character.HumanoidRootPart
                    billboard.Size = UDim2.new(0, 150, 0, 30)
                    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
                    billboard.AlwaysOnTop = true
                    local textLabel = Instance.new("TextLabel", billboard)
                    textLabel.Name = "Label"
                    textLabel.Size = UDim2.new(1, 0, 1, 0)
                    textLabel.BackgroundTransparency = 1
                    textLabel.Font = Enum.Font.GothamBold
                    textLabel.TextSize = 13
                    textLabel.TextStrokeTransparency = 0
                    textLabel.Parent = billboard
                    billboard.Parent = ESPFolder
                end
                local label = billboard:FindFirstChild("Label")
                if label then
                    local textStr = ""
                    if _G.ESP_ShowNames then textStr = p.Name end
                    if _G.ESP_ShowDistance then textStr = textStr .. " [" .. tostring(dist) .. "m]" end
                    label.Text = textStr
                    label.TextColor3 = isKiller and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(100, 200, 255)
                end
            end
        end
    end
end)

-- ==========================================
-- [TAB 3: TELEPORT]
-- ==========================================
Tabs.Teleport:AddButton({
    Title = "Teleport to Spawn / Lobby",
    Callback = function()
        local spawnLoc = workspace:FindFirstChild("SpawnLocation", true) or workspace:FindFirstChild("Lobby", true)
        local myRoot = getRootPart()
        if myRoot then
            if spawnLoc then myRoot.CFrame = spawnLoc.CFrame + Vector3.new(0, 5, 0)
            else myRoot.CFrame = CFrame.new(0, 10, 0) end
        end
    end
})

Tabs.Teleport:AddButton({
    Title = "Teleport to Exit Doors",
    Callback = function()
        local exits = {}
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "Exit" or obj.Name == "Gate" or obj.Name == "Escape" or obj.Name == "ExitDoor" then
                table.insert(exits, obj)
            end
        end
        local myRoot = getRootPart()
        if #exits > 0 and myRoot then
            local target = exits[math.random(1, #exits)]
            myRoot.CFrame = (target:IsA("Model") and target.PrimaryPart or target).CFrame
        else
            Fluent:Notify({ Title = "Teleport", Content = "Exit doors not open yet!", Duration = 3 })
        end
    end
})

-- ==========================================
-- [TAB 4: PLAYER]
-- ==========================================
_G.SpeedBoost = false
_G.CustomSpeed = 32
_G.InfJump = false
_G.Noclip = false
_G.SafeMode = false
_G.Fly = false
_G.FlySpeed = 50

local function updateSpeed()
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = _G.SpeedBoost and _G.CustomSpeed or 16 end
end

Tabs.Player:AddToggle("SpeedBoostToggle", {
    Title = "Speed Boost",
    Default = false,
    Callback = function(v) _G.SpeedBoost = v; updateSpeed() end
})

Tabs.Player:AddSlider("SpeedSlider", {
    Title = "Walk Speed Value",
    Min = 16, Max = 120, Default = 32, Rounding = 0,
    Callback = function(v) _G.CustomSpeed = v; if _G.SpeedBoost then updateSpeed() end end
})

Tabs.Player:AddToggle("InfJumpToggle", {
    Title = "Infinite Jump",
    Default = false,
    Callback = function(v) _G.InfJump = v end
})

Tabs.Player:AddToggle("NoclipToggle", {
    Title = "Noclip (Walk Through Walls)",
    Default = false,
    Callback = function(v) _G.Noclip = v end
})

Tabs.Player:AddToggle("SafeModeToggle", {
    Title = "Safe Mode (Auto TP from Killer)",
    Default = false,
    Callback = function(v)
        _G.SafeMode = v
        task.spawn(function()
            while _G.SafeMode do
                pcall(function()
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and checkIsKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            local myRoot = getRootPart()
                            if myRoot and (myRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude < 30 then
                                myRoot.CFrame = myRoot.CFrame + Vector3.new(math.random(-50, 50), 15, math.random(-50, 50))
                                task.wait(1)
                            end
                        end
                    end
                end)
                task.wait(0.3)
            end
        end)
    end
})

Tabs.Player:AddToggle("FlyToggle", {
    Title = "Fly",
    Default = false,
    Callback = function(v)
        _G.Fly = v
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if v then
            local bv = Instance.new("BodyVelocity", hrp)
            bv.Name = "AxacFly"
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.zero
            local bg = Instance.new("BodyGyro", hrp)
            bg.Name = "AxacFlyGyro"
            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bg.P = 10000
            bg.D = 500
            RunService.RenderStepped:Connect(function()
                if not _G.Fly then
                    if hrp:FindFirstChild("AxacFly") then hrp.AxacFly:Destroy() end
                    if hrp:FindFirstChild("AxacFlyGyro") then hrp.AxacFlyGyro:Destroy() end
                    return
                end
                local cam = workspace.CurrentCamera
                local dir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end
                if dir.Magnitude > 0 then bv.Velocity = dir.Unit * _G.FlySpeed
                else bv.Velocity = Vector3.zero end
                bg.CFrame = cam.CFrame
            end)
        else
            if hrp:FindFirstChild("AxacFly") then hrp.AxacFly:Destroy() end
            if hrp:FindFirstChild("AxacFlyGyro") then hrp.AxacFlyGyro:Destroy() end
        end
    end
})

Tabs.Player:AddSlider("FlySpeedSlider", {
    Title = "Fly Speed",
    Min = 10, Max = 300, Default = 50, Rounding = 0,
    Callback = function(v) _G.FlySpeed = v end
})

-- ==========================================
-- [TAB 5: EFFECTS]
-- ==========================================
local originalFogEnd = Lighting.FogEnd
local originalBrightness = Lighting.Brightness
local originalClockTime = Lighting.ClockTime
local originalAmbient = Lighting.Ambient

Tabs.Effects:AddToggle("FullBright", {
    Title = "Full Brightness",
    Default = false,
    Callback = function(v)
        Lighting.Brightness = v and 3 or originalBrightness
        Lighting.ClockTime = v and 12 or originalClockTime
    end
})

Tabs.Effects:AddToggle("AmbientGlow", {
    Title = "Ambient Light",
    Default = false,
    Callback = function(v)
        Lighting.Ambient = v and Color3.fromRGB(180, 180, 180) or originalAmbient
    end
})

Tabs.Effects:AddToggle("NoFog", {
    Title = "No Fog",
    Default = false,
    Callback = function(v)
        Lighting.FogEnd = v and 999999 or originalFogEnd
    end
})

Tabs.Effects:AddToggle("NoShadows", {
    Title = "Disable Shadows",
    Default = false,
    Callback = function(v) Lighting.GlobalShadows = not v end
})

Tabs.Effects:AddSlider("FOVSlider", {
    Title = "FOV (Field of View)",
    Min = 70, Max = 120, Default = 70, Rounding = 0,
    Callback = function(v) workspace.CurrentCamera.FieldOfView = v end
})

Tabs.Effects:AddSlider("MaxZoom", {
    Title = "Max Camera Distance",
    Min = 12, Max = 250, Default = 12, Rounding = 0,
    Callback = function(v) LocalPlayer.CameraMaxZoomDistance = v end
})

Tabs.Effects:AddToggle("XRayToggle", {
    Title = "X-Ray (Transparent Walls)",
    Default = false,
    Callback = function(v)
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj.Parent:FindFirstChildOfClass("Humanoid") then
                if v then
                    if not obj:FindFirstChild("OriginalTransparency") then
                        local tag = Instance.new("NumberValue")
                        tag.Name = "OriginalTransparency"
                        tag.Value = obj.Transparency
                        tag.Parent = obj
                    end
                    obj.Transparency = 0.5
                else
                    if obj:FindFirstChild("OriginalTransparency") then
                        obj.Transparency = obj.OriginalTransparency.Value
                        obj.OriginalTransparency:Destroy()
                    end
                end
            end
        end
    end
})

-- ==========================================
-- LISTENERS & LOOP
-- ==========================================
local function setupHumanoidSpeedCheck(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if _G.SpeedBoost and hum.WalkSpeed ~= _G.CustomSpeed then
                hum.WalkSpeed = _G.CustomSpeed
            end
        end)
    end
end
if LocalPlayer.Character then setupHumanoidSpeedCheck(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(setupHumanoidSpeedCheck)

RunService.Heartbeat:Connect(function(deltaTime)
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if _G.SpeedBoost and hum then
            hum.WalkSpeed = _G.CustomSpeed
            if hum.MoveDirection.Magnitude > 0 and root then
                local extraSpeed = (_G.CustomSpeed - 16) / 10
                if extraSpeed > 0 then
                    root.CFrame = root.CFrame + (hum.MoveDirection * (extraSpeed * deltaTime * 10))
                end
            end
        end
        
        if _G.Noclip then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if _G.InfJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Hotkey Toggle (Right Ctrl)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
        ToggleWindow()
    end
end)
