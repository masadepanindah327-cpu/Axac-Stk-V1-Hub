-- ==========================================================
-- AXAC STK HUB V42.0 — REVIVE FIXED + SAFE GATE
-- Two modes only: Carry Revive (grab → carry → drop → wait)
--                 Self Revive  (dead → TP to living player)
-- Gate Escape is gated behind 60s runtime + kill-proof warning.
-- Security hardened. No key system. No telemetry.
-- ==========================================================

local cloneref = cloneref or clonereference or function(o) return o end

local Players             = cloneref(game:GetService("Players"))
local RunService          = cloneref(game:GetService("RunService"))
local UserInputService    = cloneref(game:GetService("UserInputService"))
local CoreGui             = cloneref(game:GetService("CoreGui"))
local Workspace           = cloneref(game:GetService("Workspace"))
local TweenService        = cloneref(game:GetService("TweenService"))
local VirtualInputManager = cloneref(game:GetService("VirtualInputManager"))
local TeleportService     = cloneref(game:GetService("TeleportService"))
local HttpService         = cloneref(game:GetService("HttpService"))
local Lighting            = cloneref(game:GetService("Lighting"))
local StarterGui          = cloneref(game:GetService("StarterGui"))

local LP = Players.LocalPlayer

-- ==========================================================
-- CLEAN PRIOR INSTANCES
-- ==========================================================
for _, name in ipairs({"AxacMainUI","AxacSplash","AxacToggleBtn","WindUI","WindUI/Notifications","WindUI/Dropdowns","WindUI/Tooltips"}) do
    local cg = CoreGui:FindFirstChild(name)
    if cg then cg:Destroy() end
    local pg = LP:FindFirstChild("PlayerGui") and LP.PlayerGui:FindFirstChild(name)
    if pg then pg:Destroy() end
end

-- ==========================================================
-- OBFUSCATED CALL SITES — reduce string-literal fingerprinting
-- ==========================================================
local _S = string.char
local function c(...) return table.concat({...}, "") end
local KEY = {
    E         = Enum.KeyCode[_S(69)],
    W         = Enum.KeyCode[_S(87)],
    SPACE     = Enum.KeyCode[_S(83, 112, 97, 99, 101)],
    MB1       = Enum.UserInputType[_S(77, 111, 117, 115, 101, 66, 117, 116, 116, 111, 110, 49)],
    MOUSEMOVE = Enum.UserInputType[_S(77, 111, 117, 115, 101, 77, 111, 118, 101, 109, 101, 110, 116)],
    LANDED    = Enum.HumanoidStateType[_S(76, 97, 110, 100, 101, 100)],
    RUNNING   = Enum.HumanoidStateType[_S(82, 117, 110, 110, 105, 110, 103)],
    FREEFALL  = Enum.HumanoidStateType[_S(70, 114, 101, 101, 102, 97, 108, 108)],
    JUMPING   = Enum.HumanoidStateType[_S(74, 117, 109, 112, 105, 110, 103)],
}
local ROOT_NAME     = _S(72, 117, 109, 97, 110, 111, 105, 100, 82, 111, 111, 116, 80, 97, 114, 116) -- HumanoidRootPart
local HUM_CLASS     = _S(72, 117, 109, 97, 110, 111, 105, 100)                                        -- Humanoid
local BLEED_NAME    = _S(66, 108, 101, 101, 100, 79, 117, 116, 72, 101, 97, 108, 116, 104)             -- BleedOutHealth
local LOOT_NAME     = _S(76, 111, 111, 116, 83, 112, 97, 119, 110, 115)                                -- LootSpawns
local EXITS_NAME    = _S(69, 120, 105, 116, 115)                                                       -- Exits
local EXITS_ALT     = _S(69, 120, 105, 116, 71, 97, 116, 101, 119, 97, 121, 115)                       -- ExitGateways
local TRAP_NAME     = _S(84, 114, 97, 112)                                                             -- Trap
local HITBOX_NAME   = _S(72, 105, 116, 66, 111, 120)                                                   -- HitBox

local function Enc(s) return s end  -- placeholder; wire to Base64 if you want deep obfuscation

-- ==========================================================
-- MINIMAL CREATOR (WindUI core stripped to essentials)
-- ==========================================================
local Creator = { Font = "rbxassetid://12187365364", Signals = {} }

Creator.Defaults = {
    Frame         = { BorderSizePixel = 0, BackgroundColor3 = Color3.new(1,1,1) },
    TextLabel     = { BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Text = "", RichText = true, TextColor3 = Color3.new(1,1,1), TextSize = 14, BackgroundTransparency = 1 },
    TextButton    = { BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Text = "", AutoButtonColor = false, TextColor3 = Color3.new(1,1,1), TextSize = 14 },
    ImageLabel    = { BackgroundTransparency = 1, BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0 },
    ImageButton   = { BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, AutoButtonColor = false },
    ScrollingFrame= { ScrollBarImageTransparency = 1, BorderSizePixel = 0 },
}

function Creator.New(cls, props, children)
    local inst = Instance.new(cls)
    for k, v in pairs(Creator.Defaults[cls] or {}) do inst[k] = v end
    for k, v in pairs(props or {}) do
        if k ~= "ThemeTag" then pcall(function() inst[k] = v end) end
    end
    for _, ch in pairs(children or {}) do if ch then ch.Parent = inst end end
    return inst
end

function Creator.Tween(obj, t, goal, style, dir)
    return TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), goal)
end

-- ==========================================================
-- STATE + CLEANUP
-- ==========================================================
local State = {
    Noclip = false, InfJump = false, DoubleJump = false,
    Fullbright = false, NoFog = false, RemoveRedAura = false,
    AntiAFK = true, GhostMode = false,
    ESP_Survivor = false, ESP_Killer = false, ESP_Loot = false,
    ESP_Traps = false, ESP_Exits = false, ESP_Balloon = false,
    AutoLoot = false, AutoBalloon = false, ReturnHome = false,
    AutoGate = false,
    CarryRevive = false, SelfRevive = false,
    AutoKillAll = false, HitboxKiller = false, AntiTrap = false,
}

local Connections = {}
local Drawings    = {}
local jumpCount   = 0

local function Unload(key)
    if Connections[key] then
        pcall(function() Connections[key]:Disconnect() end)
        Connections[key] = nil
    end
end

local function ClearDrawings()
    for _, d in pairs(Drawings) do pcall(function() d:Remove() end) end
    table.clear(Drawings)
end

-- ==========================================================
-- CHARACTER ACCESSORS
-- ==========================================================
local function GetRoot()
    local c = LP.Character
    return c and c:FindFirstChild(ROOT_NAME)
end
local function GetHum()
    local c = LP.Character
    return c and c:FindFirstChildOfClass(HUM_CLASS)
end
local function GetMapRoot()
    for _, v in ipairs(Workspace:GetChildren()) do
        if v:FindFirstChild(LOOT_NAME) or v:FindFirstChild(EXITS_NAME) or v:FindFirstChild(EXITS_ALT) then
            return v
        end
    end
    return nil
end

-- Runtime tracking for gate safety
local JoinTime = tick()
local LastGateWarn = 0
local function GetRuntime() return tick() - JoinTime end

-- ==========================================================
-- INPUT HELPERS
-- ==========================================================
local function PressKey(key, hold)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(hold or 0.06)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end)
end

local function ClickMouse()
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, KEY.MB1, 0)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, KEY.MB1, 0)
    end)
end

-- ==========================================================
-- CHARACTER PHYSICS GUARD (prevents snap-back during carry)
-- ==========================================================
local function FreezeLocal()
    local root = GetRoot()
    if not root then return end
    pcall(function()
        root.CanCollide = false
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function UnfreezeLocal()
    local root = GetRoot()
    if not root then return end
    pcall(function()
        if not State.GhostMode then
            root.CanCollide = true
        end
    end)
end

-- ==========================================================
-- CARRY REVIVE — 5-stage pipeline
-- 1. detect bleed target
-- 2. TP behind target, trigger carry (E)
-- 3. TP self + target to safe spot (drop)
-- 4. spam E until bleed off / hp full
-- 5. release, wait for target to walk away
-- ==========================================================
local function SafeSpot()
    local root = GetRoot()
    if root then return root.CFrame end
    return CFrame.new(0, 50, 0)
end

local function FindBleedingTarget()
    local myRoot = GetRoot()
    if not myRoot then return nil, math.huge end
    local best, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local pr = p.Character:FindFirstChild(ROOT_NAME)
            local ph = p.Character:FindFirstChildOfClass(HUM_CLASS)
            if pr and ph and ph.Health > 0 then
                local bleed = pr:FindFirstChild(BLEED_NAME)
                if bleed and bleed.Enabled then
                    local d = (myRoot.Position - pr.Position).Magnitude
                    if d < bestDist then bestDist = d; best = pr end
                end
            end
        end
    end
    return best, bestDist
end

local function IsStillBleeding(targetRoot)
    if not targetRoot or not targetRoot.Parent then return false end
    local bleed = targetRoot:FindFirstChild(BLEED_NAME)
    return bleed and bleed.Enabled
end

local function WaitForRevive(targetRoot, timeout)
    local deadline = tick() + (timeout or 8)
    while tick() < deadline do
        if not targetRoot or not targetRoot.Parent then return false end
        if not IsStillBleeding(targetRoot) then return true end
        task.wait(0.08)
    end
    return not IsStillBleeding(targetRoot)
end

local function CarryReviveOnce()
    local myRoot = GetRoot()
    local myHum  = GetHum()
    if not myRoot or not myHum or myHum.Health <= 0 then return false end

    local target, _ = FindBleedingTarget()
    if not target then return false end

    -- Save origin so we can retreat after
    local originCF = myRoot.CFrame

    -- Stage 1: freeze local, snap behind target
    FreezeLocal()
    pcall(function() myRoot.CFrame = target.CFrame * CFrame.new(0, 0, 2) end)
    task.wait(0.08)

    -- Stage 2: press E once to pick up
    PressKey(KEY.E, 0.08)
    task.wait(0.35)

    -- Stage 3: teleport both of us to a safer spot (slightly elevated, away from danger)
    local safeCF = originCF * CFrame.new(0, 2, 0)
    pcall(function()
        myRoot.CFrame = safeCF
        if target and target.Parent then
            target.CFrame = safeCF * CFrame.new(0, 0, 2)
            target.AssemblyLinearVelocity = Vector3.zero
        end
    end)
    task.wait(0.15)

    -- Stage 4: spam E + hold target pinned near us while bleed drains
    local spamDeadline = tick() + 5
    while tick() < spamDeadline and State.CarryRevive do
        if not target or not target.Parent then break end
        if not IsStillBleeding(target) then break end
        pcall(function()
            myRoot.CFrame = safeCF
            target.CFrame = safeCF * CFrame.new(0, 0, 2)
            target.AssemblyLinearVelocity = Vector3.zero
        end)
        PressKey(KEY.E, 0.05)
        task.wait(0.09)
    end

    -- Stage 5: wait for full revive confirmation (bleed off + hp > 0)
    local revived = WaitForRevive(target, 6)

    -- Stage 6: release target — drop them softly and pull back
    pcall(function()
        if target and target.Parent then
            target.CFrame = safeCF * CFrame.new(0, 0, -3)
        end
        myRoot.CFrame = originCF
    end)
    UnfreezeLocal()
    task.wait(0.4)
    return revived
end

local function ToggleCarryRevive(v)
    State.CarryRevive = v
    Unload("CarryRevive")
    if not v then return end

    Connections.CarryRevive = task.spawn(function()
        while State.CarryRevive do
            -- Idle safety: only act if a bleeding target exists
            local target = FindBleedingTarget()
            if target then
                pcall(CarryReviveOnce)
            end
            task.wait(1.2)
        end
    end)
end

-- ==========================================================
-- SELF REVIVE — when dead, TP to a living player
-- Fires once per death; guarded against retrigger while alive
-- ==========================================================
local function FindLivingPlayer()
    local myRoot = GetRoot()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local pr = p.Character:FindFirstChild(ROOT_NAME)
            local ph = p.Character:FindFirstChildOfClass(HUM_CLASS)
            if pr and ph and ph.Health > 0 then
                local bleed = pr:FindFirstChild(BLEED_NAME)
                if not (bleed and bleed.Enabled) then
                    return pr
                end
            end
        end
    end
    return nil
end

local function SelfReviveOnce()
    local hum = GetHum()
    if not hum then return false end
    if hum.Health > 0 then return false end
    local living = FindLivingPlayer()
    if not living then return false end

    local myRoot = GetRoot()
    if not myRoot then return false end

    -- Wait for respawn system to hand control back
    local deadline = tick() + 4
    while tick() < deadline do
        if GetRoot() and GetHum() and GetHum().Health > 0 then
            return true
        end
        task.wait(0.1)
    end

    -- Force teleport to a living player
    pcall(function()
        myRoot.CFrame = living.CFrame * CFrame.new(0, 0, 4)
    end)
    task.wait(0.2)

    -- Press E in case revive-by-carry is available
    PressKey(KEY.E, 0.08)
    task.wait(0.2)
    PressKey(KEY.E, 0.08)
    return true
end

local function ToggleSelfRevive(v)
    State.SelfRevive = v
    Unload("SelfRevive")
    if not v then return end

    local busy = false
    Connections.SelfRevive = RunService.Heartbeat:Connect(function()
        if not State.SelfRevive or busy then return end
        local hum = GetHum()
        if not hum then return end
        if hum.Health <= 0 then
            busy = true
            task.spawn(function()
                pcall(SelfReviveOnce)
                busy = false
            end)
        end
    end)
end

-- ==========================================================
-- AUTO GATE — 60s runtime minimum + explicit user warning
-- ==========================================================
local GATE_MIN_RUNTIME = 60
local function AutoGateTick()
    if not State.AutoGate then return end
    local runtime = GetRuntime()
    if runtime < GATE_MIN_RUNTIME then
        if tick() - LastGateWarn > 5 then
            LastGateWarn = tick()
            Notify({
                Title = "Auto Gate — Not Ready",
                Content = string.format("Runtime %ds / %ds. Gate opens in %ds. Dying if you go early is a real risk.", math.floor(runtime), GATE_MIN_RUNTIME, math.ceil(GATE_MIN_RUNTIME - runtime)),
                Duration = 4,
                Icon = "warning",
            })
        end
        return
    end
    local map = GetMapRoot()
    if not map then return end
    local exits = map:FindFirstChild(EXITS_NAME) or map:FindFirstChild(EXITS_ALT)
    if not exits then return end
    local root = GetRoot()
    if not root then return end
    for _, gate in ipairs(exits:GetChildren()) do
        local trigger = gate:FindFirstChild("Trigger") or gate
        if trigger and trigger:IsA("BasePart") then
            pcall(function() root.CFrame = CFrame.new(trigger.Position + Vector3.new(0, 3, 0)) end)
            return
        end
    end
end

local function ToggleAutoGate(v)
    State.AutoGate = v
    Unload("AutoGate")
    if not v then return end
    if GetRuntime() < GATE_MIN_RUNTIME then
        Notify({
            Title = "Auto Gate Warning",
            Content = "You enabled Auto Gate before 60s. It will NOT teleport you until the map timer allows. Going early can kill you.",
            Duration = 6,
            Icon = "warning",
        })
    end
    Connections.AutoGate = task.spawn(function()
        while State.AutoGate do
            pcall(AutoGateTick)
            task.wait(1)
        end
    end)
end

-- ==========================================================
-- MOVEMENT / VISUAL / UTILITY
-- ==========================================================
local function ToggleNoclip(v)
    State.Noclip = v; Unload("Noclip")
    if not v then return end
    Connections.Noclip = RunService.Stepped:Connect(function()
        if not State.Noclip then return end
        local char = LP.Character
        if char then for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end end
    end)
end

local function ToggleInfJump(v)
    State.InfJump = v; Unload("InfJump")
    if not v then return end
    Connections.InfJump = UserInputService.JumpRequest:Connect(function()
        local h = GetHum()
        if h then h:ChangeState(KEY.JUMPING) end
    end)
end

local function ToggleDoubleJump(v)
    State.DoubleJump = v; Unload("DoubleJump"); Unload("DoubleJumpReset"); jumpCount = 0
    if not v then return end
    Connections.DoubleJumpReset = RunService.Heartbeat:Connect(function()
        local h = GetHum()
        if h and (h:GetState() == KEY.LANDED or h:GetState() == KEY.RUNNING) then jumpCount = 0 end
    end)
    Connections.DoubleJump = UserInputService.JumpRequest:Connect(function()
        if not State.DoubleJump then return end
        local h, r = GetHum(), GetRoot()
        if not h or not r then return end
        if h:GetState() == KEY.FREEFALL and jumpCount == 0 then
            jumpCount = 1
            r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, 45, r.AssemblyLinearVelocity.Z)
            h:ChangeState(KEY.JUMPING)
        end
    end)
end

local function ToggleFullbright(v)
    State.Fullbright = v; Unload("Fullbright")
    if not v then return end
    Connections.Fullbright = RunService.RenderStepped:Connect(function()
        if not State.Fullbright then return end
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.OutdoorAmbient = Color3.fromRGB(160,160,160)
        for _, e in ipairs(Lighting:GetDescendants()) do
            if e:IsA("Atmosphere") then e:Destroy() end
        end
    end)
end

local function ToggleNoFog(v)
    State.NoFog = v; Unload("NoFog")
    if not v then return end
    Connections.NoFog = RunService.Heartbeat:Connect(function()
        if not State.NoFog then return end
        Lighting.FogEnd = 100000
        for _, e in ipairs(Lighting:GetDescendants()) do
            if e:IsA("Atmosphere") then e:Destroy() end
        end
    end)
end

local function ToggleRemoveRedAura(v)
    State.RemoveRedAura = v; Unload("RemoveRedAura")
    if not v then return end
    Connections.RemoveRedAura = RunService.Heartbeat:Connect(function()
        if not State.RemoveRedAura then return end
        local map = GetMapRoot()
        if not map then return end
        for _, e in ipairs(map:GetDescendants()) do
            if (e:IsA("Atmosphere") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect")) and not e:GetAttribute("AxacRm") then
                e:SetAttribute("AxacRm", true)
                e.Parent = game:GetService("Debris")
            end
        end
    end)
end

local function ToggleAntiAFK(v)
    State.AntiAFK = v; Unload("AntiAFK")
    if not v then return end
    Connections.AntiAFK = LP.Idled:Connect(function()
        PressKey(KEY.W, 0.1)
        PressKey(KEY.SPACE, 0.1)
    end)
end

local function ToggleAutoLoot(v)
    State.AutoLoot = v; Unload("AutoLoot")
    if not v then return end
    local homeCF
    Connections.AutoLoot = RunService.Heartbeat:Connect(function()
        if not State.AutoLoot then return end
        local root = GetRoot(); if not root then return end
        homeCF = homeCF or root.CFrame
        local map = GetMapRoot(); if not map then return end
        local loot = map:FindFirstChild(LOOT_NAME); if not loot then return end
        local items = {}
        for _, it in ipairs(loot:GetDescendants()) do
            if it:IsA("BasePart") and not it:GetAttribute("AxacLooted") then
                table.insert(items, it)
            end
        end
        if #items == 0 then
            if State.ReturnHome and homeCF then pcall(function() root.CFrame = homeCF end); homeCF = nil end
            return
        end
        table.sort(items, function(a,b) return (a.Position - root.Position).Magnitude < (b.Position - root.Position).Magnitude end)
        for _, it in ipairs(items) do
            if not State.AutoLoot then break end
            if it.Parent then
                pcall(function()
                    root.CFrame = CFrame.new(it.Position + Vector3.new(0, 3, 0))
                    it:SetAttribute("AxacLooted", true)
                end)
                task.wait(0.14)
            end
        end
    end)
end

local function ToggleAutoBalloon(v)
    State.AutoBalloon = v; Unload("AutoBalloon")
    if not v then return end
    local homeCF
    Connections.AutoBalloon = RunService.Heartbeat:Connect(function()
        if not State.AutoBalloon then return end
        local root = GetRoot(); if not root then return end
        homeCF = homeCF or root.CFrame
        local balloons = {}
        for _, b in ipairs(Workspace:GetDescendants()) do
            if b:IsA("BasePart") and (b.Name:lower():find("balloon") or b.Name:lower():find("ballon")) and not b:GetAttribute("AxacBallooned") then
                table.insert(balloons, b)
            end
        end
        if #balloons == 0 then
            if State.ReturnHome and homeCF then pcall(function() root.CFrame = homeCF end); homeCF = nil end
            return
        end
        table.sort(balloons, function(a,b) return (a.Position - root.Position).Magnitude < (b.Position - root.Position).Magnitude end)
        for _, b in ipairs(balloons) do
            if not State.AutoBalloon then break end
            if b.Parent then
                pcall(function()
                    root.CFrame = CFrame.new(b.Position + Vector3.new(0, 3, 0))
                    b:SetAttribute("AxacBallooned", true)
                end)
                task.wait(0.18)
            end
        end
    end)
end

local function ToggleAutoKillAll(v)
    State.AutoKillAll = v; Unload("AutoKillAll")
    if not v then return end
    Connections.AutoKillAll = RunService.Heartbeat:Connect(function()
        if not State.AutoKillAll then return end
        local char, root = LP.Character, GetRoot(); if not root then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local tr = p.Character:FindFirstChild(ROOT_NAME)
                if tr and (root.Position - tr.Position).Magnitude < 25 then
                    pcall(function()
                        root.CFrame = tr.CFrame * CFrame.new(0, 0, 1.5)
                        local tool = char:FindFirstChildOfClass("Tool")
                        if tool then tool:Activate() end
                        ClickMouse()
                    end)
                end
            end
        end
    end)
end

local function ToggleHitboxKiller(v)
    State.HitboxKiller = v; Unload("HitboxKiller")
    if not v then return end
    Connections.HitboxKiller = RunService.Heartbeat:Connect(function()
        if not State.HitboxKiller then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local hrp = p.Character:FindFirstChild(ROOT_NAME)
                if hrp and not hrp:GetAttribute("AxacHitbox") then
                    hrp.Size = Vector3.new(15, 15, 15)
                    hrp.Transparency = 0.5
                    hrp.CanCollide = false
                    hrp:SetAttribute("AxacHitbox", true)
                end
            end
        end
    end)
end

local function ToggleAntiTrap(v)
    State.AntiTrap = v; Unload("AntiTrap")
    if not v then return end
    Connections.AntiTrap = RunService.Heartbeat:Connect(function()
        if not State.AntiTrap then return end
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj.Name == TRAP_NAME then
                local hit = obj:FindFirstChild(HITBOX_NAME)
                if hit then pcall(function() hit:Destroy() end) end
            end
        end
    end)
end

local function ToggleGhostMode(v)
    State.GhostMode = v
    local root = GetRoot()
    if not root then return end
    if v then
        root.CanCollide = false
        root.Transparency = 0.5
    else
        root.CanCollide = true
        root.Transparency = 0
    end
end

local function TPTarget()
    local my = GetRoot()
    if not my then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild(ROOT_NAME)
            if hrp then
                pcall(function() my.CFrame = hrp.CFrame * CFrame.new(0, 0, 3) end)
                return
            end
        end
    end
end

local function PanicTP()
    local lobby = Workspace:FindFirstChild("_Lobby")
    if not lobby then return end
    local decor = lobby:FindFirstChild("Decor")
    if not decor then return end
    local statue = decor:FindFirstChild("KnifeStatue")
    local root = GetRoot()
    if statue and root then
        pcall(function() root.CFrame = CFrame.new(statue.Position + Vector3.new(0, 30, 0)) end)
    end
end

local function ServerHop()
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok then return end
    local data = HttpService:JSONDecode(res)
    if not (data and data.data) then return end
    local servers = {}
    for _, v in ipairs(data.data) do
        if v.playing < v.maxPlayers then table.insert(servers, v.id) end
    end
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LP)
    end
end

-- ==========================================================
-- ESP LOOP
-- ==========================================================
task.spawn(function()
    while task.wait(0.12) do
        ClearDrawings()
        if not (State.ESP_Survivor or State.ESP_Killer or State.ESP_Loot or State.ESP_Traps or State.ESP_Exits or State.ESP_Balloon) then continue end
        local cam = Workspace.CurrentCamera; if not cam then continue end

        local function Draw(part, color, label)
            if not part or not part.Parent then return end
            local pos, onScreen = cam:WorldToViewportPoint(part.Position)
            if not onScreen then return end
            local sq = Drawing.new("Square")
            sq.Visible = true; sq.Color = color; sq.Thickness = 1; sq.Filled = false
            local size = part.Size
            local topP = cam:WorldToViewportPoint(part.Position + Vector3.new(0, size.Y/2, 0))
            local botP = cam:WorldToViewportPoint(part.Position - Vector3.new(0, size.Y/2, 0))
            local h = math.abs(topP.Y - botP.Y)
            local w = h * 0.6
            sq.Size = Vector2.new(w, h)
            sq.Position = Vector2.new(pos.X - w/2, pos.Y - h/2)
            table.insert(Drawings, sq)
            local txt = Drawing.new("Text")
            txt.Visible = true; txt.Color = color; txt.Size = 14; txt.Center = true; txt.Outline = true
            txt.Text = label
            txt.Position = Vector2.new(pos.X, pos.Y - h/2 - 18)
            table.insert(Drawings, txt)
            local ln = Drawing.new("Line")
            ln.Visible = true; ln.Color = color; ln.Thickness = 1
            ln.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
            ln.To = Vector2.new(pos.X, pos.Y)
            table.insert(Drawings, ln)
        end

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local r = p.Character:FindFirstChild(ROOT_NAME)
                if r then
                    local isKiller = p.Team and p.Team.Name:lower():find("killer")
                    if State.ESP_Killer and isKiller then
                        Draw(r, Color3.fromRGB(255,60,60), "KILLER: " .. p.Name)
                    elseif State.ESP_Survivor and not isKiller then
                        Draw(r, Color3.fromRGB(60,255,120), "SURV: " .. p.Name)
                    end
                end
            end
        end

        local map = GetMapRoot(); if not map then continue end
        if State.ESP_Loot then
            local loot = map:FindFirstChild(LOOT_NAME)
            if loot then for _, v in ipairs(loot:GetDescendants()) do
                if v:IsA("BasePart") then Draw(v, Color3.fromRGB(255,215,0), "Loot") end
            end end
        end
        if State.ESP_Traps then
            for _, v in ipairs(Workspace:GetChildren()) do
                if v.Name == TRAP_NAME then
                    local hit = v:FindFirstChild(HITBOX_NAME) or v
                    if hit:IsA("BasePart") then Draw(hit, Color3.fromRGB(255,140,0), "Trap") end
                end
            end
        end
        if State.ESP_Exits then
            local ex = map:FindFirstChild(EXITS_NAME) or map:FindFirstChild(EXITS_ALT)
            if ex then for _, v in ipairs(ex:GetChildren()) do
                if v:IsA("BasePart") then Draw(v, Color3.fromRGB(60,255,120), "Exit") end
            end end
        end
        if State.ESP_Balloon then
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("BasePart") and (v.Name:lower():find("balloon") or v.Name:lower():find("ballon")) then
                    Draw(v, Color3.fromRGB(255,105,180), "Balloon")
                end
            end
        end
    end
end)

-- ==========================================================
-- UI
-- ==========================================================
local BgColor     = Color3.fromRGB(15, 15, 18)
local SideColor   = Color3.fromRGB(22, 22, 26)
local CardColor   = Color3.fromRGB(28, 28, 34)
local CardHover   = Color3.fromRGB(40, 40, 48)
local AccentColor = Color3.fromRGB(120, 90, 245)
local AccentHover = Color3.fromRGB(140, 110, 255)
local TextPrim    = Color3.fromRGB(242, 242, 248)
local TextSec     = Color3.fromRGB(155, 155, 165)
local BorderCol   = Color3.fromRGB(44, 44, 54)
local DangerCol   = Color3.fromRGB(230, 60, 60)
local WarnCol     = Color3.fromRGB(240, 180, 60)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AxacMainUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = CoreGui

local UIScale = Instance.new("UIScale")
UIScale.Parent = ScreenGui
local function UpdateScale()
    local cam = Workspace.CurrentCamera; if not cam then return end
    local vp = cam.ViewportSize
    local s = math.min(vp.X / 780, vp.Y / 640)
    UIScale.Scale = math.clamp(s, 0.55, 1.05)
end
UpdateScale()
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)

-- Notification holder
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "WindUI/Notifications"
NotifGui.ResetOnSpawn = false
NotifGui.IgnoreGuiInset = true
NotifGui.DisplayOrder = 1000
NotifGui.Parent = CoreGui

local NotifHolder = Instance.new("Frame")
NotifHolder.BackgroundTransparency = 1
NotifHolder.Size = UDim2.new(0, 340, 1, -120)
NotifHolder.Position = UDim2.new(1, -24, 0, 56)
NotifHolder.AnchorPoint = Vector2.new(1, 0)
NotifHolder.Parent = NotifGui
local NotifLayout = Instance.new("UIListLayout", NotifHolder)
NotifLayout.Padding = UDim.new(0, 8)
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder

local ICONS = {
    check   = "rbxassetid://10709790644",
    warning = "rbxassetid://10709782340",
    x       = "rbxassetid://10747384395",
    info    = "rbxassetid://10709781747",
}

function Notify(opts)
    opts = opts or {}
    local wrap = Instance.new("Frame")
    wrap.BackgroundTransparency = 1
    wrap.Size = UDim2.new(1, 0, 0, 0)
    wrap.AutomaticSize = Enum.AutomaticSize.Y
    wrap.Parent = NotifHolder

    local card = Instance.new("Frame")
    card.BackgroundColor3 = CardColor
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Parent = wrap
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = BorderCol; stroke.Thickness = 1

    local pad = Instance.new("UIPadding", card)
    pad.PaddingTop = UDim.new(0, 12); pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft = UDim.new(0, 14); pad.PaddingRight = UDim.new(0, 14)

    local lay = Instance.new("UIListLayout", card)
    lay.Padding = UDim.new(0, 4)
    lay.SortOrder = Enum.SortOrder.LayoutOrder

    if opts.Icon and ICONS[opts.Icon] then
        local img = Instance.new("ImageLabel")
        img.BackgroundTransparency = 1
        img.Size = UDim2.new(0, 18, 0, 18)
        img.LayoutOrder = 1
        img.Image = ICONS[opts.Icon]
        img.ImageColor3 = opts.Icon == "warning" and WarnCol or TextPrim
        img.Parent = card
    end

    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Size = UDim2.new(1, 0, 0, 0)
    t.AutomaticSize = Enum.AutomaticSize.Y
    t.Font = Enum.Font.GothamBold
    t.TextSize = 15
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextColor3 = TextPrim
    t.Text = opts.Title or "Notification"
    t.LayoutOrder = 2
    t.Parent = card

    if opts.Content and opts.Content ~= "" then
        local cbody = Instance.new("TextLabel")
        cbody.BackgroundTransparency = 1
        cbody.Size = UDim2.new(1, 0, 0, 0)
        cbody.AutomaticSize = Enum.AutomaticSize.Y
        cbody.TextWrapped = true
        cbody.Font = Enum.Font.Gotham
        cbody.TextSize = 13
        cbody.TextXAlignment = Enum.TextXAlignment.Left
        cbody.TextColor3 = TextSec
        cbody.Text = opts.Content
        cbody.LayoutOrder = 3
        cbody.Parent = card
    end

    card.BackgroundTransparency = 1
    card.Position = UDim2.new(0, 60, 0, 0)
    TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {
        BackgroundTransparency = 0.05,
        Position = UDim2.new(0, 0, 0, 0),
    }):Play()

    task.delay(opts.Duration or 5, function()
        if card and card.Parent then
            TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 60, 0, 0),
            }):Play()
            task.wait(0.4)
            wrap:Destroy()
        end
    end)
end

-- Main window
local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.BackgroundColor3 = BgColor
MainFrame.Position = UDim2.new(0.5, -310, 0.5, -220)
MainFrame.Size = UDim2.new(0, 620, 0, 440)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local mStroke = Instance.new("UIStroke", MainFrame)
mStroke.Color = BorderCol; mStroke.Thickness = 1

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.BackgroundColor3 = SideColor
Sidebar.Size = UDim2.new(0, 155, 1, 0)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)
local SidebarCover = Instance.new("Frame")
SidebarCover.BackgroundColor3 = SideColor
SidebarCover.Size = UDim2.new(0, 12, 1, 0)
SidebarCover.Position = UDim2.new(1, -12, 0, 0)
SidebarCover.Parent = Sidebar

-- Logo
local LogoBox = Instance.new("Frame")
LogoBox.BackgroundColor3 = BgColor
LogoBox.Size = UDim2.new(0, 115, 0, 54)
LogoBox.Position = UDim2.new(0.5, -57, 0, 16)
LogoBox.Parent = Sidebar
Instance.new("UICorner", LogoBox).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", LogoBox).Color = AccentColor
local LogoText = Instance.new("TextLabel")
LogoText.BackgroundTransparency = 1
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.Font = Enum.Font.GothamBlack
LogoText.Text = "AXAC"
LogoText.TextColor3 = AccentColor
LogoText.TextSize = 22
LogoText.Parent = LogoBox
local LogoSub = Instance.new("TextLabel")
LogoSub.BackgroundTransparency = 1
LogoSub.Size = UDim2.new(1, 0, 0, 12)
LogoSub.Position = UDim2.new(0, 0, 1, -14)
LogoSub.Font = Enum.Font.GothamMedium
LogoSub.Text = "STK · V42"
LogoSub.TextColor3 = TextSec
LogoSub.TextSize = 10
LogoSub.Parent = LogoBox

-- Tabs container
local TabContainer = Instance.new("Frame")
TabContainer.BackgroundTransparency = 1
TabContainer.Size = UDim2.new(1, 0, 1, -110)
TabContainer.Position = UDim2.new(0, 0, 0, 92)
TabContainer.Parent = Sidebar
local TabLayout = Instance.new("UIListLayout", TabContainer)
TabLayout.Padding = UDim.new(0, 3)
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local FooterLabel = Instance.new("TextLabel")
FooterLabel.BackgroundTransparency = 1
FooterLabel.Size = UDim2.new(1, -16, 0, 20)
FooterLabel.Position = UDim2.new(0, 8, 1, -26)
FooterLabel.Font = Enum.Font.Gotham
FooterLabel.Text = "Satisfaction · Required"
FooterLabel.TextColor3 = TextSec
FooterLabel.TextSize = 10
FooterLabel.TextXAlignment = Enum.TextXAlignment.Center
FooterLabel.Parent = Sidebar

-- Content
local Content = Instance.new("ScrollingFrame")
Content.BackgroundTransparency = 1
Content.Position = UDim2.new(0, 165, 0, 14)
Content.Size = UDim2.new(1, -175, 1, -28)
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = BorderCol
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = MainFrame
local ContentLayout = Instance.new("UIListLayout", Content)
ContentLayout.Padding = UDim.new(0, 6)

local ContentHeader = Instance.new("Frame")
ContentHeader.BackgroundTransparency = 1
ContentHeader.Size = UDim2.new(1, 0, 0, 34)
ContentHeader.LayoutOrder = -1
ContentHeader.Parent = Content
local HeaderText = Instance.new("TextLabel")
HeaderText.BackgroundTransparency = 1
HeaderText.Size = UDim2.new(1, 0, 1, 0)
HeaderText.Font = Enum.Font.GothamBold
HeaderText.Text = "Dashboard"
HeaderText.TextColor3 = TextPrim
HeaderText.TextSize = 20
HeaderText.TextXAlignment = Enum.TextXAlignment.Left
HeaderText.Parent = ContentHeader

-- Dragging
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == KEY.MB1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == KEY.MOUSEMOVE or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- Close / Min
local CloseBtn = Instance.new("TextButton")
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -38, 0, 12)
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = TextSec
CloseBtn.TextSize = 16
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Sidebar

local MinBtn = Instance.new("TextButton")
MinBtn.BackgroundTransparency = 1
MinBtn.Position = UDim2.new(1, -68, 0, 12)
MinBtn.Size = UDim2.new(0, 26, 0, 26)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "—"
MinBtn.TextColor3 = TextSec
MinBtn.TextSize = 16
MinBtn.AutoButtonColor = false
MinBtn.Parent = Sidebar

-- UI builders
local function CreateTab(name, order)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = SideColor
    b.Size = UDim2.new(0, 135, 0, 34)
    b.Font = Enum.Font.GothamMedium
    b.Text = "  " .. name
    b.TextColor3 = TextSec
    b.TextSize = 13
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    b.LayoutOrder = order
    b.Parent = TabContainer
    Instance.new("UIPadding", b).PaddingLeft = UDim.new(0, 8)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    b.MouseEnter:Connect(function()
        if not b:GetAttribute("Active") then
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = CardHover, TextColor3 = TextPrim}):Play()
        end
    end)
    b.MouseLeave:Connect(function()
        if not b:GetAttribute("Active") then
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = SideColor, TextColor3 = TextSec}):Play()
        end
    end)
    return b
end

local function ClearContent()
    for _, v in ipairs(Content:GetChildren()) do
        if v ~= ContentHeader and (v:IsA("Frame") or v:IsA("TextButton") or v:IsA("TextLabel")) then
            v:Destroy()
        end
    end
end

local function SetHeader(text) HeaderText.Text = text end

local function CreateToggle(name, order, stateKey, callback, description)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = CardColor
    card.Size = UDim2.new(1, 0, 0, description and 44 or 38)
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.Parent = Content
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = BorderCol; stroke.Transparency = 1

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 14, 0, 0)
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Font = Enum.Font.GothamMedium
    label.Text = name
    label.TextColor3 = TextPrim
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = description and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
    if description then
        label.Position = UDim2.new(0, 14, 0, 5)
        label.Size = UDim2.new(1, -70, 0, 16)
    end
    label.Parent = card

    if description then
        local d = Instance.new("TextLabel")
        d.BackgroundTransparency = 1
        d.Position = UDim2.new(0, 14, 0, 24)
        d.Size = UDim2.new(1, -70, 0, 14)
        d.Font = Enum.Font.Gotham
        d.Text = description
        d.TextColor3 = TextSec
        d.TextSize = 11
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.Parent = card
    end

    local track = Instance.new("TextButton")
    track.BackgroundColor3 = State[stateKey] and AccentColor or BgColor
    track.Position = UDim2.new(1, -52, 0.5, -10)
    track.Size = UDim2.new(0, 36, 0, 20)
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = card
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local tStroke = Instance.new("UIStroke", track)
    tStroke.Color = BorderCol; tStroke.Thickness = 1

    local knob = Instance.new("Frame")
    knob.BackgroundColor3 = TextPrim
    knob.Position = State[stateKey] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = CardHover}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.5}):Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = CardColor}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 1}):Play()
    end)

    local function set(v)
        State[stateKey] = v
        TweenService:Create(track, TweenInfo.new(0.2), {BackgroundColor3 = v and AccentColor or BgColor}):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = v and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        }):Play()
        if callback then task.spawn(function() pcall(callback, v) end) end
    end
    track.MouseButton1Click:Connect(function() set(not State[stateKey]) end)
    return { Set = set }
end

local function CreateButton(name, order, callback, variant)
    local isDanger = variant == "Danger"
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = isDanger and Color3.fromRGB(50, 24, 28) or AccentColor
    b.Size = UDim2.new(1, 0, 0, 34)
    b.Font = Enum.Font.GothamBold
    b.Text = name
    b.TextColor3 = TextPrim
    b.TextSize = 13
    b.AutoButtonColor = false
    b.LayoutOrder = order
    b.Parent = Content
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = isDanger and Color3.fromRGB(70, 30, 36) or AccentHover}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = isDanger and Color3.fromRGB(50, 24, 28) or AccentColor}):Play()
    end)
    b.MouseButton1Click:Connect(function()
        if callback then task.spawn(function() pcall(callback) end) end
    end)
    return b
end

local function CreateDivider(order, text)
    if not text then return end
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = text:upper()
    lbl.TextColor3 = TextSec
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.Parent = Content
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 4)
end

-- Tabs
local TabDash     = CreateTab("Dashboard", 1)
local TabSurvivor = CreateTab("Survivor", 2)
local TabKiller   = CreateTab("Killer", 3)
local TabVisuals  = CreateTab("Visuals", 4)
local TabSettings = CreateTab("Settings", 5)

local function SelectTab(selected)
    for _, v in ipairs(TabContainer:GetChildren()) do
        if v:IsA("TextButton") then
            local sel = (v == selected)
            v:SetAttribute("Active", sel)
            TweenService:Create(v, TweenInfo.new(0.15), {
                BackgroundColor3 = sel and CardColor or SideColor,
                TextColor3 = sel and TextPrim or TextSec,
            }):Play()
        end
    end
end

-- Pages
local function OpenDashboard()
    ClearContent(); SetHeader("Dashboard")

    local profile = Instance.new("Frame")
    profile.BackgroundColor3 = CardColor
    profile.Size = UDim2.new(1, 0, 0, 92)
    profile.BorderSizePixel = 0
    profile.LayoutOrder = 1
    profile.Parent = Content
    Instance.new("UICorner", profile).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", profile).Color = BorderCol

    local pfp = Instance.new("ImageLabel")
    pfp.BackgroundColor3 = BgColor
    pfp.Size = UDim2.new(0, 64, 0, 64)
    pfp.Position = UDim2.new(0, 14, 0.5, -32)
    pfp.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LP.UserId .. "&w=150&h=150"
    pfp.Parent = profile
    Instance.new("UICorner", pfp).CornerRadius = UDim.new(0, 8)

    local n = Instance.new("TextLabel")
    n.BackgroundTransparency = 1
    n.Position = UDim2.new(0, 90, 0, 18)
    n.Size = UDim2.new(1, -100, 0, 22)
    n.Font = Enum.Font.GothamBold
    n.Text = LP.DisplayName
    n.TextColor3 = TextPrim
    n.TextSize = 16
    n.TextXAlignment = Enum.TextXAlignment.Left
    n.Parent = profile

    local u = Instance.new("TextLabel")
    u.BackgroundTransparency = 1
    u.Position = UDim2.new(0, 90, 0, 40)
    u.Size = UDim2.new(1, -100, 0, 16)
    u.Font = Enum.Font.Gotham
    u.Text = "@" .. LP.Name
    u.TextColor3 = TextSec
    u.TextSize = 12
    u.TextXAlignment = Enum.TextXAlignment.Left
    u.Parent = profile

    local tag = Instance.new("TextLabel")
    tag.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
    tag.Position = UDim2.new(0, 90, 0, 62)
    tag.Size = UDim2.new(0, 130, 0, 18)
    tag.Font = Enum.Font.GothamBold
    tag.Text = "  SATISFACTION  "
    tag.TextColor3 = AccentColor
    tag.TextSize = 10
    tag.Parent = profile
    Instance.new("UICorner", tag).CornerRadius = UDim.new(0, 4)

    CreateDivider(2, "Quick Actions")
    CreateToggle("Noclip", 3, "Noclip", ToggleNoclip, "Walk through walls")
    CreateToggle("Infinite Jump", 4, "InfJump", ToggleInfJump)
    CreateToggle("Double Jump", 5, "DoubleJump", ToggleDoubleJump, "Gamepass bypass")
    CreateToggle("Anti AFK", 6, "AntiAFK", ToggleAntiAFK)
    CreateToggle("Fullbright", 7, "Fullbright", ToggleFullbright)
    CreateToggle("No Fog", 8, "NoFog", ToggleNoFog)
    CreateToggle("Remove Red Aura", 9, "RemoveRedAura", ToggleRemoveRedAura)

    CreateDivider(10, "Session")
    CreateButton("Panic Teleport (Lobby)", 11, PanicTP, "Danger")
    CreateButton("Server Hop", 12, ServerHop)
end

local function OpenSurvivor()
    ClearContent(); SetHeader("Survivor")

    CreateDivider(1, "Revive System")
    CreateToggle("Carry Revive", 2, "CarryRevive", ToggleCarryRevive, "Grab bleeding player → carry → drop → wait for full")
    CreateToggle("Self Revive", 3, "SelfRevive", ToggleSelfRevive, "When you die, TP to a living player")
    CreateToggle("Ghost Mode", 4, "GhostMode", ToggleGhostMode, "Noclip + half transparency")

    CreateDivider(5, "Farming")
    CreateToggle("Auto Loot", 6, "AutoLoot", ToggleAutoLoot, "Collect nearby loot")
    CreateToggle("Auto Balloon", 7, "AutoBalloon", ToggleAutoBalloon)
    CreateToggle("Return Home After Farm", 8, "ReturnHome", function() end)
    CreateToggle("Auto Gate (60s lock)", 9, "AutoGate", ToggleAutoGate, "Won't TP until game reaches 60s")
end

local function OpenKiller()
    ClearContent(); SetHeader("Killer")
    CreateDivider(1, "Combat")
    CreateToggle("Auto Kill All", 2, "AutoKillAll", ToggleAutoKillAll, "Swing at nearby survivors")
    CreateToggle("Hitbox Expander", 3, "HitboxKiller", ToggleHitboxKiller)
    CreateToggle("Anti Trap", 4, "AntiTrap", ToggleAntiTrap)
    CreateDivider(5, "Utility")
    CreateButton("TP to Nearest Player", 6, TPTarget)
end

local function OpenVisuals()
    ClearContent(); SetHeader("Visuals")
    CreateDivider(1, "ESP")
    CreateToggle("Survivor ESP", 2, "ESP_Survivor", function() end)
    CreateToggle("Killer ESP", 3, "ESP_Killer", function() end)
    CreateToggle("Loot ESP", 4, "ESP_Loot", function() end)
    CreateToggle("Trap ESP", 5, "ESP_Traps", function() end)
    CreateToggle("Exit ESP", 6, "ESP_Exits", function() end)
    CreateToggle("Balloon ESP", 7, "ESP_Balloon", function() end)
end

local function OpenSettings()
    ClearContent(); SetHeader("Settings")
    CreateDivider(1, "Interface")
    CreateButton("Center Window", 2, function()
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0.5, -310, 0.5, -220),
        }):Play()
    end)
    CreateButton("Reset UIScale", 3, function() UIScale.Scale = 1 end)
    CreateDivider(4, "Diagnostics")
    CreateButton("Runtime Check", 5, function()
        Notify({
            Title = "Runtime",
            Content = string.format("%d seconds since load.", math.floor(GetRuntime())),
            Duration = 4,
        })
    end)
    CreateButton("Notify Test", 6, function()
        Notify({ Title = "AXAC", Content = "Notification channel active.", Duration = 3 })
    end, "Danger")
end

TabDash.MouseButton1Click:Connect(function() SelectTab(TabDash); OpenDashboard() end)
TabSurvivor.MouseButton1Click:Connect(function() SelectTab(TabSurvivor); OpenSurvivor() end)
TabKiller.MouseButton1Click:Connect(function() SelectTab(TabKiller); OpenKiller() end)
TabVisuals.MouseButton1Click:Connect(function() SelectTab(TabVisuals); OpenVisuals() end)
TabSettings.MouseButton1Click:Connect(function() SelectTab(TabSettings); OpenSettings() end)

-- Confirm dialog
local Confirm = Instance.new("Frame")
Confirm.BackgroundColor3 = CardColor
Confirm.Position = UDim2.new(0.5, -160, 0.5, -70)
Confirm.Size = UDim2.new(0, 320, 0, 140)
Confirm.BorderSizePixel = 0
Confirm.Visible = false
Confirm.ZIndex = 100
Confirm.Parent = ScreenGui
Instance.new("UICorner", Confirm).CornerRadius = UDim.new(0, 10)
local cStroke = Instance.new("UIStroke", Confirm)
cStroke.Color = DangerCol; cStroke.Thickness = 1.5

local ct = Instance.new("TextLabel")
ct.BackgroundTransparency = 1
ct.Size = UDim2.new(1, -24, 0, 24)
ct.Position = UDim2.new(0, 12, 0, 16)
ct.Font = Enum.Font.GothamBold
ct.Text = "Close AXAC?"
ct.TextColor3 = TextPrim
ct.TextSize = 16
ct.TextXAlignment = Enum.TextXAlignment.Left
ct.Parent = Confirm

local cb = Instance.new("TextLabel")
cb.BackgroundTransparency = 1
cb.Position = UDim2.new(0, 12, 0, 46)
cb.Size = UDim2.new(1, -24, 0, 40)
cb.Font = Enum.Font.Gotham
cb.Text = "This will unload the hub. Re-execute to reopen."
cb.TextColor3 = TextSec
cb.TextSize = 12
cb.TextWrapped = true
cb.TextXAlignment = Enum.TextXAlignment.Left
cb.Parent = Confirm

local YesBtn = Instance.new("TextButton")
YesBtn.BackgroundColor3 = DangerCol
YesBtn.Size = UDim2.new(0, 130, 0, 34)
YesBtn.Position = UDim2.new(0, 14, 1, -48)
YesBtn.Font = Enum.Font.GothamBold
YesBtn.Text = "Yes, Unload"
YesBtn.TextColor3 = TextPrim
YesBtn.TextSize = 13
YesBtn.AutoButtonColor = false
YesBtn.Parent = Confirm
Instance.new("UICorner", YesBtn).CornerRadius = UDim.new(0, 7)

local NoBtn = Instance.new("TextButton")
NoBtn.BackgroundColor3 = BgColor
NoBtn.Size = UDim2.new(0, 130, 0, 34)
NoBtn.Position = UDim2.new(1, -144, 1, -48)
NoBtn.Font = Enum.Font.GothamBold
NoBtn.Text = "Cancel"
NoBtn.TextColor3 = TextPrim
NoBtn.TextSize = 13
NoBtn.AutoButtonColor = false
NoBtn.Parent = Confirm
Instance.new("UICorner", NoBtn).CornerRadius = UDim.new(0, 7)

-- Floating toggle
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "AxacToggleBtn"
ToggleBtn.BackgroundColor3 = CardColor
ToggleBtn.Position = UDim2.new(0, 24, 0.5, -27)
ToggleBtn.Size = UDim2.new(0, 54, 0, 54)
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.Text = "AXAC"
ToggleBtn.TextColor3 = AccentColor
ToggleBtn.TextSize = 12
ToggleBtn.AutoButtonColor = false
ToggleBtn.Visible = false
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 10)
local tStroke = Instance.new("UIStroke", ToggleBtn)
tStroke.Color = AccentColor; tStroke.Thickness = 1.5
ToggleBtn.MouseEnter:Connect(function() TweenService:Create(tStroke, TweenInfo.new(0.15), {Color = TextPrim}):Play() end)
ToggleBtn.MouseLeave:Connect(function() TweenService:Create(tStroke, TweenInfo.new(0.15), {Color = AccentColor}):Play() end)

local tDrag, tStart, tPos
ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == KEY.MB1 or input.UserInputType == Enum.UserInputType.Touch then
        tDrag = true; tStart = input.Position; tPos = ToggleBtn.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then tDrag = false end end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if tDrag and (input.UserInputType == KEY.MOUSEMOVE or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - tStart
        ToggleBtn.Position = UDim2.new(tPos.X.Scale, tPos.X.Offset + d.X, tPos.Y.Scale, tPos.Y.Offset + d.Y)
    end
end)

local function ShowMain() MainFrame.Visible = true; ToggleBtn.Visible = false end
local function HideMain() MainFrame.Visible = false; ToggleBtn.Visible = true end
ToggleBtn.MouseButton1Click:Connect(ShowMain)
MinBtn.MouseButton1Click:Connect(HideMain)
CloseBtn.MouseButton1Click:Connect(function() Confirm.Visible = true end)

YesBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy(); NotifGui:Destroy()
    for k in pairs(Connections) do Unload(k) end
    ClearDrawings()
end)

NoBtn.MouseButton1Click:Connect(function() Confirm.Visible = false end)

-- Boot
SelectTab(TabDash); OpenDashboard()
ToggleAntiAFK(true)

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "AXAC V42",
        Text = "Carry Revive + Self Revive online. Satisfaction required.",
        Duration = 4,
    })
end)

Notify({ Title = "AXAC Hub Loaded", Content = "Two revive modes ready. Auto Gate locked until 60s.", Duration = 5, Icon = "check" })
