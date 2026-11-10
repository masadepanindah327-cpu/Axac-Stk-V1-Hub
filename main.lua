-- =========================================================================
-- AXAC HUB v28.0 — Survive the Killer
-- Anti-slop pass: monochrome + accent, 8px grid, hairline 1px,
-- mono numbers, no emoji, no exclamation, no generic copy.
-- Animation-first: tab slide, panel fade+slide, toggle/slider easing,
-- orb pulse, notif slide-down. No Back easing, no bounce.
--@module CORE
-- =========================================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UIS              = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui       = game:GetService("StarterGui")

local LP = Players.LocalPlayer

-- Block starter-gui reset messages
pcall(function() StarterGui:SetCore("ResetButtonCallback", false) end)

-- =========================================================================
-- THEME
-- Warm monochrome. Accent red used only for state, never decoration.
-- =========================================================================
local T = {
    bg          = Color3.fromRGB(12, 12, 14),
    surface     = Color3.fromRGB(18, 18, 21),
    raised      = Color3.fromRGB(24, 24, 28),
    hairline    = Color3.fromRGB(38, 38, 44),
    faint       = Color3.fromRGB(28, 28, 32),
    ink         = Color3.fromRGB(232, 228, 220),
    inkDim      = Color3.fromRGB(140, 134, 122),
    inkMute     = Color3.fromRGB(78, 74, 68),
    accent      = Color3.fromRGB(178, 22, 30),
    accentDim   = Color3.fromRGB(90, 12, 16),
    gold        = Color3.fromRGB(198, 162, 60),
    killer      = Color3.fromRGB(232, 60, 60),
    survivor    = Color3.fromRGB(80, 176, 255),
    good        = Color3.fromRGB(80, 176, 120),
}
local FONT_UI   = Enum.Font.Gotham
local FONT_MONO = Enum.Font.Code
local FONT_HEAD = Enum.Font.Garamond

-- =========================================================================
-- STATE
-- =========================================================================
local S = {
    flags = {},
    cfg   = {
        walkSpeed   = 32,
        flySpeed    = 55,
        farmRange   = 150,
        tpBack      = true,
        espRefresh  = 0.1,
        tpMode      = "Safe",
        autoReviveRange = 15,
        tracersColor = T.killer,
    },
    meta  = {
        open        = false,
        activeTab   = "Main",
        notifGen    = 0,
        origLight   = {
            Brightness = Lighting.Brightness,
            ClockTime  = Lighting.ClockTime,
            Ambient    = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            FogEnd     = Lighting.FogEnd,
        },
        origCamera  = nil,
        toggleReg   = {},
        sliderReg   = {},
        threads     = {},
        conns       = {},
        processed   = setmetatable({}, {__mode="k"}),
        noclipParts = setmetatable({}, {__mode="k"}),
        flyBodyVel  = nil,
        flyGyro     = nil,
        flyConn     = nil,
        espFolder   = nil,
    },
}

-- =========================================================================
-- CONNECTION / THREAD REGISTRY
-- =========================================================================
local function regConn(c)
    if c then table.insert(S.meta.conns, c) end
    return c
end
local function regThread(t, name)
    table.insert(S.meta.threads, {thread = t, name = name})
    return t
end
local function killThreads()
    for _, rec in ipairs(S.meta.threads) do
        if rec.thread then pcall(function() task.cancel(rec.thread) end) end
    end
    S.meta.threads = {}
end
local function killConns()
    for _, c in ipairs(S.meta.conns) do pcall(function() c:Disconnect() end) end
    S.meta.conns = {}
end

-- =========================================================================
-- SPAWN SAFE — disable Blur injected by other gui
-- =========================================================================
local function killBlur()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("BlurEffect") then v.Enabled = false end
    end
end
killBlur()
regConn(Lighting.ChildAdded:Connect(function(c) if c:IsA("BlurEffect") then task.wait(0.05); c.Enabled = false end end))

-- =========================================================================
-- UI PRIMITIVES
-- =========================================================================
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function tween(inst, props, dur, style, dir)
    local info = TweenInfo.new(dur or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

-- =========================================================================
-- ROOT GUI
-- =========================================================================
local old = LP:WaitForChild("PlayerGui"):FindFirstChild("AxacHub")
if old then old:Destroy() end

local gui = new("ScreenGui", {
    Name             = "AxacHub",
    ResetOnSpawn     = false,
    ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
    DisplayOrder     = 999,
    IgnoreGuiInset   = true,
}, LP:WaitForChild("PlayerGui"))

-- ESP folder
local espFolder = workspace:FindFirstChild("AxacESP") or Instance.new("Folder", workspace)
espFolder.Name = "AxacESP"
S.meta.espFolder = espFolder

-- =========================================================================
-- ORB (floating open trigger)
-- =========================================================================
local orb = new("TextButton", {
    Size             = UDim2.fromOffset(44, 44),
    Position         = UDim2.new(0, 18, 0.5, -22),
    BackgroundColor3 = T.bg,
    Text             = "",
    TextSize         = 0,
    AutoButtonColor  = false,
    ZIndex           = 150,
}, gui)
new("UICorner", {CornerRadius = UDim.new(1, 0)}, orb)
local orbStroke = new("UIStroke", {Color = T.accent, Thickness = 1.5}, orb)
local orbMark = new("TextLabel", {
    Size             = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text             = "A",
    Font             = FONT_HEAD,
    TextSize         = 22,
    TextColor3       = T.accent,
}, orb)

-- Orb pulse
task.spawn(function()
    while orb.Parent do
        tween(orbStroke, {Thickness = 2.4, Transparency = 0.2}, 1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.4)
        tween(orbStroke, {Thickness = 1.5, Transparency = 0}, 1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.4)
    end
end)

orb.MouseEnter:Connect(function()
    tween(orb, {BackgroundColor3 = T.accent}, 0.14)
    tween(orbMark, {TextColor3 = T.ink}, 0.14)
end)
orb.MouseLeave:Connect(function()
    tween(orb, {BackgroundColor3 = T.bg}, 0.14)
    tween(orbMark, {TextColor3 = T.accent}, 0.14)
end)

-- =========================================================================
-- SPLASH (first open only)
-- =========================================================================
local splash = new("Frame", {
    Size             = UDim2.fromScale(1, 1),
    BackgroundColor3 = T.bg,
    BorderSizePixel  = 0,
    ZIndex           = 300,
}, gui)
local splashBox = new("Frame", {
    Size             = UDim2.fromOffset(260, 84),
    Position         = UDim2.new(0.5, -130, 0.5, -42),
    BackgroundTransparency = 1,
    ZIndex           = 301,
}, splash)
local spTitle = new("TextLabel", {
    Size             = UDim2.new(1, 0, 0, 46),
    BackgroundTransparency = 1,
    Text             = "AXAC",
    Font             = FONT_HEAD,
    TextSize         = 52,
    TextColor3       = T.ink,
    TextTransparency = 1,
}, splashBox)
local spRule = new("Frame", {
    Size             = UDim2.fromOffset(0, 1),
    Position         = UDim2.new(0.5, 0, 0, 52),
    BackgroundColor3 = T.accent,
    BorderSizePixel  = 0,
}, splashBox)
local spSub = new("TextLabel", {
    Size             = UDim2.new(1, 0, 0, 16),
    Position         = UDim2.new(0, 0, 0, 60),
    BackgroundTransparency = 1,
    Text             = "STK · v28",
    Font             = FONT_MONO,
    TextSize         = 11,
    TextColor3       = T.inkDim,
    TextTransparency = 1,
}, splashBox)

task.spawn(function()
    tween(spTitle, {TextTransparency = 0}, 0.55, Enum.EasingStyle.Quint)
    tween(spSub, {TextTransparency = 0}, 0.55, Enum.EasingStyle.Quint)
    tween(spRule, {Size = UDim2.fromOffset(180, 1)}, 0.7, Enum.EasingStyle.Quint)
    task.wait(1.2)
    tween(spTitle, {TextTransparency = 1}, 0.3)
    tween(spSub, {TextTransparency = 1}, 0.3)
    tween(spRule, {Size = UDim2.fromOffset(0, 1)}, 0.3)
    tween(splash, {BackgroundTransparency = 1}, 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    task.wait(0.35)
    splash:Destroy()
end)

-- =========================================================================
-- MAIN FRAME
-- =========================================================================
local main = new("Frame", {
    Size             = UDim2.fromOffset(616, 420),
    Position         = UDim2.new(0.5, -308, 0.5, -210),
    BackgroundColor3 = T.bg,
    BorderSizePixel  = 0,
    ClipsDescendants = true,
    Visible          = false,
    BackgroundTransparency = 1,
    ZIndex           = 10,
}, gui)
new("UICorner", {CornerRadius = UDim.new(0, 4)}, main)
new("UIStroke", {Color = T.hairline, Thickness = 1}, main)

-- Drag
do
    local dragging, dragStart, startPos
    main.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, i.Position, main.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

-- Title bar
local titleBar = new("Frame", {
    Size             = UDim2.new(1, 0, 0, 52),
    BackgroundColor3 = T.surface,
    BorderSizePixel  = 0,
}, main)
new("TextLabel", {
    Size             = UDim2.new(0, 200, 1, 0),
    Position         = UDim2.new(0, 20, 0, 0),
    BackgroundTransparency = 1,
    Text             = "AXAC HUB",
    Font             = FONT_HEAD,
    TextSize         = 22,
    TextColor3       = T.ink,
    TextXAlignment   = Enum.TextXAlignment.Left,
}, titleBar)
new("TextLabel", {
    Size             = UDim2.new(0, 220, 1, 0),
    Position         = UDim2.new(0, 160, 0, 1),
    BackgroundTransparency = 1,
    Text             = "STK  ·  v28.0",
    Font             = FONT_MONO,
    TextSize         = 11,
    TextColor3       = T.gold,
    TextXAlignment   = Enum.TextXAlignment.Left,
}, titleBar)
new("Frame", {
    Size             = UDim2.new(1, -16, 0, 1),
    Position         = UDim2.new(0, 8, 1, -1),
    BackgroundColor3 = T.hairline,
    BorderSizePixel  = 0,
}, titleBar)

local closeBtn = new("TextButton", {
    Size             = UDim2.new(0, 20, 0, 20),
    Position         = UDim2.new(1, -34, 0, 31),
    BackgroundTransparency = 1,
    Text             = "X",
    Font             = FONT_MONO,
    TextSize         = 11,
    TextColor3       = T.inkDim,
}, titleBar)
closeBtn.MouseEnter:Connect(function() tween(closeBtn, {TextColor3 = T.accent}, 0.12) end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn, {TextColor3 = T.inkDim}, 0.12) end)

-- Sidebar
local sidebar = new("Frame", {
    Size             = UDim2.new(0, 156, 1, -52),
    Position         = UDim2.new(0, 0, 0, 52),
    BackgroundColor3 = T.bg,
    BorderSizePixel  = 0,
}, main)
new("Frame", {
    Size             = UDim2.new(0, 1, 1, -16),
    Position         = UDim2.new(1, -1, 0, 8),
    BackgroundColor3 = T.hairline,
    BorderSizePixel  = 0,
}, sidebar)

-- Content area
local content = new("Frame", {
    Size             = UDim2.new(1, -156, 1, -52),
    Position         = UDim2.new(0, 156, 0, 52),
    BackgroundColor3 = T.bg,
    BorderSizePixel  = 0,
    ClipsDescendants = true,
}, main)

-- =========================================================================
-- NOTIFICATION
-- =========================================================================
local notif = new("Frame", {
    Size             = UDim2.new(0, 320, 0, 34),
    Position         = UDim2.new(0.5, -160, 0, -44),
    BackgroundColor3 = T.raised,
    BorderSizePixel  = 0,
    ZIndex           = 200,
}, gui)
new("UICorner", {CornerRadius = UDim.new(0, 3)}, notif)
new("Frame", {
    Size             = UDim2.new(0, 2, 1, 0),
    BackgroundColor3 = T.accent,
    BorderSizePixel  = 0,
}, notif)
local notifText = new("TextLabel", {
    Size             = UDim2.new(1, -20, 1, 0),
    Position         = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text             = "",
    Font             = FONT_UI,
    TextSize         = 12,
    TextColor3       = T.ink,
    TextXAlignment   = Enum.TextXAlignment.Left,
}, notif)

local function notify(msg)
    S.meta.notifGen = S.meta.notifGen + 1
    local gen = S.meta.notifGen
    notifText.Text = msg
    tween(notif, {Position = UDim2.new(0.5, -160, 0, 12)}, 0.16)
    task.delay(3, function()
        if S.meta.notifGen ~= gen then return end
        tween(notif, {Position = UDim2.new(0.5, -160, 0, -44)}, 0.16)
    end)
end
_G.AxacNotify = notify

-- =========================================================================
-- OPEN/CLOSE
-- =========================================================================
local function openMenu()
    S.meta.open = true
    orb.Visible = false
    main.Visible = true
    main.Position = UDim2.new(0.5, -308, 0.5, -210)
    tween(main, {BackgroundTransparency = 0, Position = UDim2.new(0.5, -308, 0.5, -260)}, 0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
end
local function closeMenu()
    S.meta.open = false
    tween(main, {BackgroundTransparency = 1, Position = UDim2.new(0.5, -308, 0.5, -210)}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    task.delay(0.2, function()
        if not S.meta.open then
            main.Visible = false
            orb.Visible = true
        end
    end)
end
_G.AxacOpenMenu = openMenu
orb.MouseButton1Click:Connect(openMenu)
closeBtn.MouseButton1Click:Connect(closeMenu)
UIS.InputBegan:Connect(function(i, p)
    if p then return end
    if i.KeyCode == Enum.KeyCode.RightControl then
        if S.meta.open then closeMenu() else openMenu() end
    end
end)

-- =========================================================================
-- UI COMPONENTS
-- =========================================================================
local pages = {}
local tabBtns = {}

local function makePage(name)
    local page = new("ScrollingFrame", {
        Size             = UDim2.new(1, -48, 1, -44),
        Position         = UDim2.new(0, 26, 0, 22),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = T.hairline,
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible          = (name == "Main"),
        ClipsDescendants = false,
    }, content)
    new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, page)
    pages[name] = page
    return page
end

local function section(page, label)
    local row = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        LayoutOrder      = #page:GetChildren(),
    }, page)
    new("Frame", {
        Size             = UDim2.new(0, 8, 0, 1),
        Position         = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = T.accent,
        BorderSizePixel  = 0,
    }, row)
    new("TextLabel", {
        Size             = UDim2.new(1, -20, 1, 0),
        Position         = UDim2.new(0, 18, 0, 0),
        BackgroundTransparency = 1,
        Text             = string.upper(label),
        Font             = FONT_UI,
        TextSize         = 10,
        TextColor3       = T.inkDim,
        TextXAlignment   = Enum.TextXAlignment.Left,
    }, row)
end

local function toggle(page, id, label, default, cb)
    local row = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        LayoutOrder      = #page:GetChildren(),
    }, page)
    new("TextLabel", {
        Size             = UDim2.new(1, -46, 1, 0),
        BackgroundTransparency = 1,
        Text             = label,
        Font             = FONT_UI,
        TextSize         = 12,
        TextColor3       = T.ink,
        TextXAlignment   = Enum.TextXAlignment.Left,
    }, row)
    local track = new("Frame", {
        Size             = UDim2.new(0, 26, 0, 12),
        Position         = UDim2.new(1, -26, 0.5, -6),
        BackgroundColor3 = default and T.accentDim or T.hairline,
        BorderSizePixel  = 0,
    }, row)
    new("UICorner", {CornerRadius = UDim.new(0, 2)}, track)
    local thumb = new("Frame", {
        Size             = UDim2.new(0, 10, 0, 10),
        Position         = default and UDim2.new(1, -11, 0, 1) or UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = default and T.accent or T.ink,
        BorderSizePixel  = 0,
    }, track)
    new("UICorner", {CornerRadius = UDim.new(0, 1)}, thumb)

    local state = default
    local function set(v)
        if state == v then return end
        state = v
        tween(track, {BackgroundColor3 = state and T.accentDim or T.hairline}, 0.14)
        tween(thumb, {
            Position         = state and UDim2.new(1, -11, 0, 1) or UDim2.new(0, 1, 0, 1),
            BackgroundColor3 = state and T.accent or T.ink,
        }, 0.14)
        if cb then pcall(cb, state) end
    end
    local hit = new("TextButton", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = ""}, row)
    hit.MouseButton1Click:Connect(function() set(not state) end)
    S.meta.toggleReg[id] = {Set = set, Get = function() return state end}
end

local function slider(page, id, label, min, max, default, decimal, cb)
    local row = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        LayoutOrder      = #page:GetChildren(),
    }, page)
    new("TextLabel", {
        Size             = UDim2.new(1, -60, 0, 18),
        BackgroundTransparency = 1,
        Text             = label,
        Font             = FONT_UI,
        TextSize         = 12,
        TextColor3       = T.ink,
        TextXAlignment   = Enum.TextXAlignment.Left,
    }, row)
    local val = new("TextLabel", {
        Size             = UDim2.new(0, 60, 0, 18),
        Position         = UDim2.new(1, -60, 0, 0),
        BackgroundTransparency = 1,
        Text             = decimal and string.format("%.2f", default) or tostring(math.floor(default)),
        Font             = FONT_MONO,
        TextSize         = 11,
        TextColor3       = T.gold,
        TextXAlignment   = Enum.TextXAlignment.Right,
    }, row)
    local track = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        Position         = UDim2.new(0, 0, 0, 28),
        BackgroundColor3 = T.hairline,
        BorderSizePixel  = 0,
    }, row)
    local fill = new("Frame", {
        Size             = UDim2.new((default-min)/(max-min), 0, 1, 0),
        BackgroundColor3 = T.accent,
        BorderSizePixel  = 0,
    }, track)
    local dot = new("Frame", {
        Size             = UDim2.new(0, 8, 0, 8),
        Position         = UDim2.new((default-min)/(max-min), -4, 0.5, -4),
        BackgroundColor3 = T.ink,
        BorderSizePixel  = 0,
    }, track)
    new("UICorner", {CornerRadius = UDim.new(1,0)}, dot)

    local dragging = false
    local function set(v, fromUser)
        v = math.clamp(v, min, max)
        local rel = (v - min) / (max - min)
        tween(fill, {Size = UDim2.new(rel, 0, 1, 0)}, fromUser and 0.02 or 0.16)
        tween(dot,  {Position = UDim2.new(rel, -4, 0.5, -4)}, fromUser and 0.02 or 0.16)
        val.Text = decimal and string.format("%.2f", v) or tostring(math.floor(v))
        if cb then pcall(cb, v) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            set(min + (max - min) * rel, true)
        end
    end)
    regConn(UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end))
    regConn(UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            set(min + (max - min) * rel, true)
        end
    end))
    S.meta.sliderReg[id] = {Set = set}
end

local function button(page, label, cb, destructive)
    local row = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        LayoutOrder      = #page:GetChildren(),
    }, page)
    local btn = new("TextButton", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text             = string.upper(label),
        Font             = FONT_UI,
        TextSize         = 10,
        TextColor3       = destructive and T.accentDim or T.inkDim,
        TextXAlignment   = Enum.TextXAlignment.Left,
        AutoButtonColor  = false,
    }, row)
    local ul = new("Frame", {
        Size             = UDim2.new(0.55, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -3),
        BackgroundColor3 = T.hairline,
        BorderSizePixel  = 0,
    }, btn)
    if destructive then
        new("Frame", {
            Size             = UDim2.new(0, 1, 0, 10),
            Position         = UDim2.new(0, -10, 0.5, -5),
            BackgroundColor3 = T.accent,
            BorderSizePixel  = 0,
        }, btn)
    end
    btn.MouseEnter:Connect(function()
        tween(btn, {TextColor3 = T.accent}, 0.14)
        tween(ul, {Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.accent}, 0.14)
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, {TextColor3 = destructive and T.accentDim or T.inkDim}, 0.14)
        tween(ul, {Size = UDim2.new(0.55, 0, 0, 1), BackgroundColor3 = T.hairline}, 0.14)
    end)
    btn.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
end

local function input(page, id, label, default, placeholder, cb)
    local row = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 46),
        BackgroundTransparency = 1,
        LayoutOrder      = #page:GetChildren(),
    }, page)
    new("TextLabel", {
        Size             = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text             = label,
        Font             = FONT_UI,
        TextSize         = 11,
        TextColor3       = T.inkDim,
        TextXAlignment   = Enum.TextXAlignment.Left,
    }, row)
    local box = new("TextBox", {
        Size             = UDim2.new(1, 0, 0, 26),
        Position         = UDim2.new(0, 0, 0, 20),
        BackgroundColor3 = T.faint,
        BorderSizePixel  = 0,
        Text             = default or "",
        PlaceholderText  = placeholder or "",
        Font             = FONT_MONO,
        TextSize         = 12,
        TextColor3       = T.ink,
        ClearTextOnFocus = false,
        TextXAlignment   = Enum.TextXAlignment.Left,
    }, row)
    new("UICorner", {CornerRadius = UDim.new(0, 3)}, box)
    local pad = new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, box)
    box.FocusLost:Connect(function(enter)
        if cb then pcall(cb, box.Text, enter) end
    end)
end

-- =========================================================================
-- SIDEBAR TABS + SLIDING ANIMATION
-- =========================================================================
local tabs = {
    {Name = "Main"},
    {Name = "Farm"},
    {Name = "ESP"},
    {Name = "Player"},
    {Name = "Teleport"},
    {Name = "Event"},
    {Name = "Gamepass"},
    {Name = "Effects"},
    {Name = "Config"},
}
for i, t in ipairs(tabs) do
    local btn = new("TextButton", {
        Size             = UDim2.new(1, 0, 0, 30),
        Position         = UDim2.new(0, 0, 0, (i-1)*30),
        BackgroundColor3 = T.bg,
        BorderSizePixel  = 0,
        Text             = "  " .. t.Name,
        Font             = FONT_UI,
        TextSize         = 12,
        TextColor3       = T.inkDim,
        TextXAlignment   = Enum.TextXAlignment.Left,
        AutoButtonColor  = false,
    }, sidebar)
    local bar = new("Frame", {
        Size             = UDim2.new(0, 2, 1, -8),
        Position         = UDim2.new(0, 0, 0, 4),
        BackgroundColor3 = T.gold,
        BorderSizePixel  = 0,
        Visible          = false,
    }, btn)

    btn.MouseButton1Click:Connect(function()
        if S.meta.activeTab == t.Name then return end
        -- slide out old page
        local oldPage = pages[S.meta.activeTab]
        if oldPage then
            tween(oldPage, {Position = UDim2.new(0, 16, 0, 22), BackgroundTransparency = 1}, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.delay(0.12, function() if oldPage then oldPage.Visible = false end end)
        end
        -- update tabs
        for name, rec in pairs(tabBtns) do
            rec.bar.Visible = (name == t.Name)
            tween(rec.btn, {TextColor3 = (name == t.Name) and T.ink or T.inkDim}, 0.12)
        end
        S.meta.activeTab = t.Name
        local newPage = pages[t.Name]
        if newPage then
            newPage.Visible = true
            newPage.Position = UDim2.new(0, 40, 0, 22)
            task.wait(0.01)
            tween(newPage, {Position = UDim2.new(0, 26, 0, 22)}, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        end
    end)
    btn.MouseEnter:Connect(function()
        if S.meta.activeTab ~= t.Name then tween(btn, {TextColor3 = T.ink}, 0.1) end
    end)
    btn.MouseLeave:Connect(function()
        if S.meta.activeTab ~= t.Name then tween(btn, {TextColor3 = T.inkDim}, 0.1) end
    end)
    tabBtns[t.Name] = {btn = btn, bar = bar}
end
tabBtns["Main"].bar.Visible = true
tabBtns["Main"].btn.TextColor3 = T.ink

-- Create all pages
for _, t in ipairs(tabs) do makePage(t.Name) end

-- =========================================================================
-- KILLER DETECTION
-- =========================================================================
local KILLER_TOOLS = {
    Knife=true, Axe=true, Bat=true, Cleaver=true, Scythe=true, Machete=true,
    Pipe=true, Wrench=true, Shovel=true, Dagger=true, Crowbar=true,
    Screwdriver=true, Spear=true, Sword=true, Chainsaw=true,
}

local function isKiller(p)
    if not p or not p.Character then return false end
    -- tool check (char + backpack)
    local charTool = p.Character:FindFirstChildWhichIsA("Tool")
    if charTool and KILLER_TOOLS[charTool.Name] then return true end
    local bp = p:FindFirstChild("Backpack")
    if bp then
        local bpTool = bp:FindFirstChildWhichIsA("Tool")
        if bpTool and KILLER_TOOLS[bpTool.Name] then return true end
    end
    -- name flags
    if p.Character:FindFirstChild("Knife") or p.Character:FindFirstChild("KillerTag") then return true end
    -- attributes
    for _, n in ipairs({"Role","role","Team","IsKiller","Killer","Alignment","RoleName"}) do
        local a = p:GetAttribute(n)
        if a and tostring(a):lower():find("killer") then return true end
    end
    -- team
    if p.Team and (p.Team.Name:lower():find("killer") or p.Team.TeamColor == BrickColor.new("Really red")) then return true end
    -- character attribute
    for _, n in ipairs({"Role","role"}) do
        local a = p.Character:GetAttribute(n)
        if a and tostring(a):lower():find("killer") then return true end
    end
    return false
end

local function predictKiller()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isKiller(p) then return p end
    end
    return nil
end

-- =========================================================================
-- PREDICT BANNER
-- =========================================================================
local predBanner = new("Frame", {
    Size             = UDim2.new(0, 260, 0, 30),
    Position         = UDim2.new(0.5, -130, 0, 14),
    BackgroundColor3 = T.raised,
    BorderSizePixel  = 0,
    Visible          = false,
    ZIndex           = 100,
}, gui)
new("UICorner", {CornerRadius = UDim.new(0, 3)}, predBanner)
new("UIStroke", {Color = T.accent, Thickness = 1}, predBanner)
local predText = new("TextLabel", {
    Size             = UDim2.new(1, -20, 1, 0),
    Position         = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text             = "—",
    Font             = FONT_MONO,
    TextSize         = 12,
    TextColor3       = T.ink,
    TextXAlignment   = Enum.TextXAlignment.Left,
}, predBanner)
local predDot = new("Frame", {
    Size             = UDim2.new(0, 6, 0, 6),
    Position         = UDim2.new(1, -16, 0.5, -3),
    BackgroundColor3 = T.killer,
    BorderSizePixel  = 0,
}, predBanner)
new("UICorner", {CornerRadius = UDim.new(1,0)}, predDot)

regThread(task.spawn(function()
    while gui.Parent do
        task.wait(0.25)
        if not S.flags.predictKiller then
            predBanner.Visible = false
            continue
        end
        local k = predictKiller()
        if k then
            predBanner.Visible = true
            predText.Text = "KILLER · " .. k.Name
            predText.TextColor3 = T.killer
            predDot.BackgroundColor3 = T.killer
            tween(predDot, {BackgroundTransparency = 0.4}, 0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.5)
            tween(predDot, {BackgroundTransparency = 0}, 0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        else
            predBanner.Visible = true
            predText.Text = "KILLER · scanning"
            predText.TextColor3 = T.inkDim
            predDot.BackgroundColor3 = T.inkMute
        end
    end
end), "Predict")

-- =========================================================================
-- FARM: CANDY / BALLOON / PUMPKIN / GIFT — event + fallback
-- =========================================================================
local function getRoot(obj)
    if obj:IsA("Model") then return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") end
    if obj:IsA("BasePart") then return obj end
end

local function firePrompt(p)
    if not p or not p.Parent then return false end
    local ok = pcall(function()
        if type(fireproximityprompt) == "function" then fireproximityprompt(p) end
    end)
    if ok then return true end
    pcall(function()
        local oh = p.HoldDuration
        p.HoldDuration = 0
        pcall(function() p:InputHoldBegin() end)
        task.wait(0.05)
        pcall(function() p:InputHoldEnd() end)
        task.delay(0.2, function() if p and p.Parent then p.HoldDuration = oh end end)
    end)
    return true
end

local function farmTarget(obj)
    if not obj or not obj.Parent or S.meta.processed[obj] then return end
    S.meta.processed[obj] = true
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then S.meta.processed[obj] = nil; return end
    local part = getRoot(obj)
    if not part then S.meta.processed[obj] = nil; return end
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not prompt then S.meta.processed[obj] = nil; return end

    -- range check
    local range = S.cfg.farmRange
    if (hrp.Position - part.Position).Magnitude > range then S.meta.processed[obj] = nil; return end

    local oldCF = hrp.CFrame
    hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
    local t0 = os.clock()
    while os.clock() - t0 < 0.35 do
        if hum.FloorMaterial ~= Enum.Material.Air then break end
        task.wait(0.03)
    end
    firePrompt(prompt)
    task.wait(0.08)
    if S.cfg.tpBack and hrp.Parent then hrp.CFrame = oldCF end
    task.delay(30, function() S.meta.processed[obj] = nil end)
end

local function nameMatch(n, kind)
    local l = n:lower()
    if kind == "candy" then return l:find("candy") or l:find("sweet") end
    if kind == "balloon" then return l:find("balloon") end
    if kind == "pumpkin" then return l:find("pumpkin") end
    if kind == "gift" then return l:find("gift") or l:find("present") end
    return false
end

local function scanFarm()
    local kinds = {}
    if S.flags.autoCandy then table.insert(kinds, "candy") end
    if S.flags.autoBalloon then table.insert(kinds, "balloon") end
    if S.flags.autoPumpkin then table.insert(kinds, "pumpkin") end
    if S.flags.autoGift then table.insert(kinds, "gift") end
    if #kinds == 0 then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        for _, k in ipairs(kinds) do
            if nameMatch(obj.Name, k) and not S.meta.processed[obj] then
                task.spawn(farmTarget, obj)
                break
            end
        end
    end
end

regConn(workspace.DescendantAdded:Connect(function(obj)
    for _, k in ipairs({"candy","balloon","pumpkin","gift"}) do
        if S.flags["auto"..k:gsub("^%l", string.upper)] and nameMatch(obj.Name, k) then
            task.spawn(farmTarget, obj)
            break
        end
    end
end))

regThread(task.spawn(function()
    while task.wait(1.5) do pcall(scanFarm) end
end), "FarmFallback")

-- =========================================================================
-- REVIVE / SELF REVIVE
-- =========================================================================
local function downed(p)
    if not p or not p.Character then return false end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local bleed = hrp:FindFirstChild("BleedOutHealth") or p.Character:FindFirstChild("BleedOutHealth", true)
    if bleed and bleed.Enabled then return true end
    local h = p.Character:FindFirstChildOfClass("Humanoid")
    if h and h.PlatformStand then return true end
    return false
end

regThread(task.spawn(function()
    while task.wait(0.2) do
        if not S.flags.autoRevive then continue end
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and downed(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                if (hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude <= S.cfg.autoReviveRange then
                    local prompt = p.Character:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then firePrompt(prompt) end
                end
            end
        end
    end
end), "AutoRevive")

-- =========================================================================
-- PLAYER: SPEED / NOCLIP / INFJUMP / FLY / SELF REVIVE
-- =========================================================================
regThread(task.spawn(function()
    while task.wait(0.1) do
        local char = LP.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if S.flags.speed then hum.WalkSpeed = S.cfg.walkSpeed end
        end
        if S.flags.noclip then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if S.meta.noclipParts[part] == nil then S.meta.noclipParts[part] = part.CanCollide end
                    part.CanCollide = false
                end
            end
        else
            for part, orig in pairs(S.meta.noclipParts) do
                if part and part.Parent then part.CanCollide = orig end
                S.meta.noclipParts[part] = nil
            end
        end
    end
end), "PlayerLogic")

regConn(UIS.JumpRequest:Connect(function()
    if S.flags.infJump and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

regConn(LP.CharacterAdded:Connect(function()
    task.wait(0.2)
    for part, orig in pairs(S.meta.noclipParts) do
        if part and part.Parent then part.CanCollide = orig end
    end
    S.meta.noclipParts = setmetatable({}, {__mode="k"})
    if S.meta.toggleReg.noclip then S.meta.toggleReg.noclip.Set(false) end
end))

-- =========================================================================
-- SELF REVIVE
-- =========================================================================
regThread(task.spawn(function()
    local last = 0
    while task.wait(0.4) do
        if not S.flags.selfRevive then continue end
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        if downed(LP) and (os.clock() - last > 4) then
            local safe = hrp.Position + Vector3.new(0, 5, 0)
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and isKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local kp = p.Character.HumanoidRootPart.Position
                    local away = (hrp.Position - kp).Unit
                    safe = hrp.Position + away * 45 + Vector3.new(math.random(-15,15), 5, math.random(-15,15))
                    break
                end
            end
            hrp.CFrame = CFrame.new(safe)
            last = os.clock()
            notify("Self revive · tp safe")
        end
    end
end), "SelfRevive")

-- =========================================================================
-- FLY
-- =========================================================================
local function startFly()
    if S.meta.flyConn then return end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bv = Instance.new("BodyVelocity", hrp)
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.zero
    bv.P = 1250
    local gyro = Instance.new("BodyGyro", hrp)
    gyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    gyro.P = 1250
    gyro.CFrame = hrp.CFrame
    local cam = workspace.CurrentCamera
    S.meta.flyBodyVel = bv
    S.meta.flyGyro = gyro
    S.meta.flyConn = RunService.RenderStepped:Connect(function()
        if not S.flags.fly then return end
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0) end
        if dir.Magnitude > 0 then dir = dir.Unit end
        bv.Velocity = dir * S.cfg.flySpeed
        gyro.CFrame = cam.CFrame
    end)
end

local function stopFly()
    if S.meta.flyConn then S.meta.flyConn:Disconnect(); S.meta.flyConn = nil end
    if S.meta.flyBodyVel then S.meta.flyBodyVel:Destroy(); S.meta.flyBodyVel = nil end
    if S.meta.flyGyro then S.meta.flyGyro:Destroy(); S.meta.flyGyro = nil end
end

-- =========================================================================
-- ESP SYSTEM (full rewrite — highlight, tracer, name, box)
-- =========================================================================
local espState = {}

local function clearESP()
    for _, c in ipairs(espFolder:GetChildren()) do c:Destroy() end
    espState = {}
end

local function updateESP()
    local anyOn = S.flags.espHighlight or S.flags.espTracerKiller or S.flags.espTracerAll or S.flags.espName
    if not anyOn then
        if next(espState) then clearESP() end
        return
    end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local isK = isKiller(p)
            local dist = hrp and math.floor((hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude) or 0
            local rec = espState[p] or {}
            espState[p] = rec

            -- Highlight
            if S.flags.espHighlight then
                if not rec.hl then
                    rec.hl = Instance.new("Highlight")
                    rec.hl.Name = "HL_" .. p.Name
                    rec.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    rec.hl.Parent = espFolder
                end
                rec.hl.Adornee = p.Character
                rec.hl.FillColor = isK and T.killer or T.survivor
                rec.hl.OutlineColor = isK and T.killer or T.survivor
                rec.hl.FillTransparency = isK and 0.15 or 0.55
                rec.hl.OutlineTransparency = 0
            elseif rec.hl then
                rec.hl:Destroy(); rec.hl = nil
            end

            -- Tracer
            local wantTracer = (S.flags.espTracerKiller and isK) or S.flags.espTracerAll
            if wantTracer and hrp then
                if not rec.tracer then
                    local a0 = Instance.new("Attachment", hrp)
                    local a1 = Instance.new("Attachment", p.Character.HumanoidRootPart)
                    local beam = Instance.new("Beam")
                    beam.Name = "TR_" .. p.Name
                    beam.Attachment0 = a0
                    beam.Attachment1 = a1
                    beam.Width0 = 0.1
                    beam.Width1 = 0.1
                    beam.FaceCamera = true
                    beam.LightEmission = 1
                    beam.Parent = espFolder
                    rec.tracer = beam
                    rec.tracerA0 = a0
                    rec.tracerA1 = a1
                end
                rec.tracer.Color = ColorSequence.new(isK and T.killer or T.survivor)
            elseif rec.tracer then
                rec.tracer:Destroy(); if rec.tracerA0 then rec.tracerA0:Destroy() end; if rec.tracerA1 then rec.tracerA1:Destroy() end
                rec.tracer = nil
            end

            -- Name
            if S.flags.espName then
                if not rec.tag then
                    local bbg = Instance.new("BillboardGui")
                    bbg.Name = "TAG_" .. p.Name
                    bbg.Size = UDim2.new(0, 140, 0, 26)
                    bbg.StudsOffset = Vector3.new(0, 2.6, 0)
                    bbg.AlwaysOnTop = true
                    local lbl = Instance.new("TextLabel")
                    lbl.Name = "L"
                    lbl.Size = UDim2.fromScale(1, 1)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = FONT_MONO
                    lbl.TextSize = 11
                    lbl.TextStrokeTransparency = 0
                    lbl.Parent = bbg
                    bbg.Parent = espFolder
                    rec.tag = bbg
                end
                rec.tag.Adornee = p.Character:FindFirstChild("Head") or p.Character.HumanoidRootPart
                local lbl = rec.tag:FindFirstChild("L")
                if lbl then
                    lbl.Text = p.Name .. " · " .. dist .. "m"
                    lbl.TextColor3 = isK and T.killer or T.survivor
                end
            elseif rec.tag then
                rec.tag:Destroy(); rec.tag = nil
            end
        end
    end

    -- cleanup leaving players
    for p, rec in pairs(espState) do
        if not p.Parent or not p.Character then
            if rec.hl then rec.hl:Destroy() end
            if rec.tracer then rec.tracer:Destroy() end
            if rec.tracerA0 then rec.tracerA0:Destroy() end
            if rec.tracerA1 then rec.tracerA1:Destroy() end
            if rec.tag then rec.tag:Destroy() end
            espState[p] = nil
        end
    end
end

regThread(task.spawn(function()
    while task.wait(S.cfg.espRefresh) do pcall(updateESP) end
end), "ESP")

-- =========================================================================
-- KILLER ALERT
-- =========================================================================
regThread(task.spawn(function()
    local last = 0
    while task.wait(0.5) do
        if not S.flags.killerAlert then continue end
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and isKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local d = math.floor((hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude)
                if d <= 75 and (os.clock() - last > 5) then
                    last = os.clock()
                    notify("Killer · " .. p.Name .. " · " .. d .. "m")
                end
            end
        end
    end
end), "KillerAlert")

-- =========================================================================
-- TELEPORT HELPERS
-- =========================================================================
local function tpTo(pos)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and pos then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
end

local function findExits()
    local list = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if n == "exit" or n == "exitdoor" or n == "gate" or n == "escape" or n:find("exitdoor") or n:find("escapezone") then
            local root = getRoot(obj) or obj
            if root and root:IsA("BasePart") then table.insert(list, root) end
        end
    end
    return list
end

-- =========================================================================
-- GAMEPASS DETECTION + DOUBLE JUMP
-- =========================================================================
local hasDoubleJump = false
pcall(function()
    hasDoubleJump = LP:GetAttribute("DoubleJump") or LP:GetAttribute("HasDoubleJump") or LP:GetAttribute("DoubleJumpOwned") or false
    -- also check for gamepass id 0 as fallback (add real id when known)
end)

-- Double jump is a body action; our implementation mirrors gamepass behavior
local djState = {used = false}
regConn(LP.CharacterAdded:Connect(function()
    djState.used = false
end))

regConn(UIS.JumpRequest:Connect(function()
    if not (S.flags.doubleJump or hasDoubleJump) then return end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    -- if not on ground and not already double jumped
    if hum.FloorMaterial == Enum.Material.Air and not djState.used then
        djState.used = true
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local bv = Instance.new("BodyVelocity", hrp)
            bv.MaxForce = Vector3.new(0, 1e4, 0)
            bv.Velocity = Vector3.new(0, 55, 0)
            task.delay(0.15, function() bv:Destroy() end)
        end
    end
    -- ground touch resets
    task.delay(0.1, function()
        if hum.FloorMaterial ~= Enum.Material.Air then djState.used = false end
    end)
end))

-- =========================================================================
-- MAIN PAGE
-- =========================================================================
local pMain = pages["Main"]
section(pMain, "Round Pressure")
toggle(pMain, "predictKiller", "Real-time Killer Predict", false, function(v) S.flags.predictKiller = v end)
toggle(pMain, "killerAlert", "Killer Proximity Alert · 75m", false, function(v) S.flags.killerAlert = v end)
toggle(pMain, "autoRevive", "Auto Revive Downed Players", false, function(v) S.flags.autoRevive = v end)
slider(pMain, "reviveRange", "Revive Radius", 5, 30, 15, false, function(v) S.cfg.autoReviveRange = v end)
toggle(pMain, "selfRevive", "Self Revive · Safe TP", false, function(v) S.flags.selfRevive = v end)

section(pMain, "Exit Coverage")
button(pMain, "List Exit Doors", function()
    local ex = findExits()
    notify(#ex .. " exit point(s) found")
end)
button(pMain, "Teleport to Nearest Exit", function()
    local ex = findExits()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or #ex == 0 then notify("No exit"); return end
    local best, bestD = nil, math.huge
    for _, e in ipairs(ex) do
        local d = (hrp.Position - e.Position).Magnitude
        if d < bestD then bestD, best = d, e end
    end
    tpTo(best.Position)
    notify("Exit · " .. math.floor(bestD) .. "m")
end)

-- =========================================================================
-- FARM PAGE
-- =========================================================================
local pFarm = pages["Farm"]
section(pFarm, "Collectibles")
toggle(pFarm, "autoCandy", "Auto Candy / Sweet", false, function(v) S.flags.autoCandy = v; if v then task.spawn(scanFarm) end end)
toggle(pFarm, "autoBalloon", "Auto Balloon", false, function(v) S.flags.autoBalloon = v; if v then task.spawn(scanFarm) end end)
toggle(pFarm, "autoPumpkin", "Auto Pumpkin · Halloween", false, function(v) S.flags.autoPumpkin = v; if v then task.spawn(scanFarm) end end)
toggle(pFarm, "autoGift", "Auto Gift · Christmas", false, function(v) S.flags.autoGift = v; if v then task.spawn(scanFarm) end end)

section(pFarm, "Farm Tuning")
toggle(pFarm, "tpBack", "TP Back After Collect", true, function(v) S.cfg.tpBack = v end)
slider(pFarm, "farmRange", "Farm Radius · studs", 50, 500, 150, false, function(v) S.cfg.farmRange = v end)

section(pFarm, "Coin Multiplier")
toggle(pFarm, "coinMulti", "Show 2x Coin Status", false, function(v)
    if v then
        local owned = LP:GetAttribute("2xCoins") or false
        notify(owned and "2x Coins active" or "2x Coins · not detected")
    end
end)

-- =========================================================================
-- ESP PAGE
-- =========================================================================
local pESP = pages["ESP"]
section(pESP, "Player Overlay")
toggle(pESP, "espHighlight", "Highlight Players", false, function(v) S.flags.espHighlight = v end)
toggle(pESP, "espTracerKiller", "Tracer · Killer Only", false, function(v) S.flags.espTracerKiller = v end)
toggle(pESP, "espTracerAll", "Tracer · All Players", false, function(v) S.flags.espTracerAll = v end)
toggle(pESP, "espName", "Name + Distance Tag", false, function(v) S.flags.espName = v end)
slider(pESP, "espRate", "Refresh Rate · seconds", 0.05, 0.5, 0.1, true, function(v) S.cfg.espRefresh = v end)
button(pESP, "Clear ESP Cache", function() clearESP(); notify("ESP cleared") end)

-- =========================================================================
-- PLAYER PAGE
-- =========================================================================
local pPlayer = pages["Player"]
section(pPlayer, "Movement")
toggle(pPlayer, "speed", "Speed Boost", false, function(v) S.flags.speed = v end)
slider(pPlayer, "walkSpeed", "Walk Speed", 16, 150, 32, false, function(v) S.cfg.walkSpeed = v end)
toggle(pPlayer, "noclip", "Noclip", false, function(v) S.flags.noclip = v end)
toggle(pPlayer, "infJump", "Infinite Jump", false, function(v) S.flags.infJump = v end)
toggle(pPlayer, "doubleJump", "Double Jump · gamepass", false, function(v) S.flags.doubleJump = v end)
toggle(pPlayer, "fly", "Fly", false, function(v)
    S.flags.fly = v
    if v then startFly() else stopFly() end
end)
slider(pPlayer, "flySpeed", "Fly Speed", 20, 200, 55, false, function(v) S.cfg.flySpeed = v end)

section(pPlayer, "Character")
toggle(pPlayer, "jumpPower", "Boost Jump Power", false, function(v)
    S.flags.jumpPower = v
    if not v then
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h.UseJumpPower = true; h.JumpPower = 50 end
    end
end)
slider(pPlayer, "jumpPowerVal", "Jump Power", 50, 250, 80, false, function(v)
    if S.flags.jumpPower then
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h.UseJumpPower = true; h.JumpPower = v end
    end
end)
toggle(pPlayer, "hipHeight", "Lower Hip Height", false, function(v)
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.HipHeight = v and 0 or 2 end
end)

-- =========================================================================
-- TELEPORT PAGE
-- =========================================================================
local pTP = pages["Teleport"]
section(pTP, "Fixed Points")
button(pTP, "Teleport to Spawn", function()
    local sp = workspace:FindFirstChild("SpawnLocation", true)
    if sp then tpTo(sp.Position); notify("Spawn") else notify("No spawn") end
end)
button(pTP, "Teleport to Random Exit", function()
    local ex = findExits()
    if #ex > 0 then local e = ex[math.random(1,#ex)]; tpTo(e.Position); notify("Exit · random") else notify("No exit") end
end)
button(pTP, "Teleport to Killer", function()
    local k = predictKiller()
    if k and k.Character and k.Character:FindFirstChild("HumanoidRootPart") then
        tpTo(k.Character.HumanoidRootPart.Position); notify("Killer · " .. k.Name)
    else notify("Killer not found") end
end)
button(pTP, "Teleport to Random Survivor", function()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and not isKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(list, p)
        end
    end
    if #list > 0 then
        local p = list[math.random(1,#list)]
        tpTo(p.Character.HumanoidRootPart.Position)
        notify("Survivor · " .. p.Name)
    else notify("No survivor") end
end)

section(pTP, "Custom")
input(pTP, "tpX", "X", "", "0", function(v) S.cfg.tpX = tonumber(v) end)
input(pTP, "tpY", "Y", "", "0", function(v) S.cfg.tpY = tonumber(v) end)
input(pTP, "tpZ", "Z", "", "0", function(v) S.cfg.tpZ = tonumber(v) end)
button(pTP, "Teleport to Coordinates", function()
    if S.cfg.tpX and S.cfg.tpY and S.cfg.tpZ then
        tpTo(Vector3.new(S.cfg.tpX, S.cfg.tpY, S.cfg.tpZ))
        notify("Coord teleport")
    end
end)

-- =========================================================================
-- EVENT PAGE
-- =========================================================================
local pEvent = pages["Event"]
section(pEvent, "Active Seasonal Events")
button(pEvent, "Scan Event Spawns", function()
    local counts = {candy=0, balloon=0, pumpkin=0, gift=0}
    for _, o in ipairs(workspace:GetDescendants()) do
        for k in pairs(counts) do
            if nameMatch(o.Name, k) then counts[k] = counts[k] + 1 end
        end
    end
    notify("candy " .. counts.candy .. " · balloon " .. counts.balloon .. " · pumpkin " .. counts.pumpkin .. " · gift " .. counts.gift)
end)
button(pEvent, "Collect All Visible", function()
    for _, o in ipairs(workspace:GetDescendants()) do
        for _, k in ipairs({"candy","balloon","pumpkin","gift"}) do
            if nameMatch(o.Name, k) then task.spawn(farmTarget, o); break end
        end
    end
    notify("Collecting all visible")
end)

section(pEvent, "Crate Roller")
toggle(pEvent, "autoRoll", "Auto Roll Crate", false, function(v)
    S.flags.autoRoll = v
    if v then
        regThread(task.spawn(function()
            while S.flags.autoRoll do
                task.wait(3)
                pcall(function()
                    local remote = ReplicatedStorage:FindFirstChild("RollCrate") or ReplicatedStorage:FindFirstChild("Roll")
                    if remote and remote:IsA("RemoteEvent") then remote:FireServer() end
                end)
            end
        end), "AutoRoll")
    end
end)
slider(pEvent, "rollInterval", "Roll Interval · seconds", 1, 30, 3, true, function(v) S.cfg.rollInterval = v end)

-- =========================================================================
-- GAMEPASS PAGE
-- =========================================================================
local pGP = pages["Gamepass"]
section(pGP, "Status")
button(pGP, "Read Gamepass Attributes", function()
    local keys = {"DoubleJump","HasDoubleJump","DoubleJumpOwned","VIP","2xCoins","2xXP","2xXPActive","ExtraSurvivorSlot","Gamepasses"}
    local found = {}
    for _, k in ipairs(keys) do
        local v = LP:GetAttribute(k)
        if v ~= nil then table.insert(found, k .. "=" .. tostring(v)) end
    end
    notify(#found > 0 and table.concat(found, " · ") or "no gamepass attributes")
end)

section(pGP, "Gamepass Emulation")
toggle(pGP, "gpDoubleJump", "Emulate Double Jump", false, function(v) S.flags.doubleJump = v end)
toggle(pGP, "gpFly", "Emulate Fly (any gamepass)", false, function(v)
    S.flags.fly = v
    if v then startFly() else stopFly() end
end)
toggle(pGP, "gpSpeed", "Emulate Speed Boost", false, function(v) S.flags.speed = v end)

section(pGP, "Presets")
button(pGP, "Preset · Farm", function()
    S.flags.autoCandy = true
    S.meta.toggleReg.autoCandy.Set(true)
    S.flags.tpBack = true
    notify("Preset farm applied")
end)
button(pGP, "Preset · Combat", function()
    S.flags.speed = true; S.meta.toggleReg.speed.Set(true)
    S.flags.noclip = true; S.meta.toggleReg.noclip.Set(true)
    S.flags.infJump = true; S.meta.toggleReg.infJump.Set(true)
    notify("Preset combat applied")
end)
button(pGP, "Preset · Stealth", function()
    S.flags.espTracerKiller = true; S.meta.toggleReg.espTracerKiller.Set(true)
    S.flags.killerAlert = true; S.meta.toggleReg.killerAlert.Set(true)
    S.flags.selfRevive = true; S.meta.toggleReg.selfRevive.Set(true)
    notify("Preset stealth applied")
end)

-- =========================================================================
-- EFFECTS PAGE
-- =========================================================================
local pFX = pages["Effects"]
section(pFX, "Lighting")
toggle(pFX, "fullBright", "Full Brightness", false, function(v)
    Lighting.Brightness = v and 3 or S.meta.origLight.Brightness
    Lighting.ClockTime  = v and 12 or S.meta.origLight.ClockTime
end)
toggle(pFX, "ambient", "Ambient Light", false, function(v)
    Lighting.Ambient = v and Color3.fromRGB(180,180,180) or S.meta.origLight.Ambient
    Lighting.OutdoorAmbient = v and Color3.fromRGB(180,180,180) or S.meta.origLight.OutdoorAmbient
end)
toggle(pFX, "noFog", "Remove Fog", false, function(v)
    Lighting.FogEnd = v and 1e6 or S.meta.origLight.FogEnd
end)
section(pFX, "Camera")
slider(pFX, "fov", "Field of View", 70, 120, 70, false, function(v)
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = v end
end)

section(pFX, "X-Ray")
toggle(pFX, "xray", "X-Ray Mode", false, function(v)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Parent:FindFirstChildOfClass("Humanoid") then
            if v then
                if not obj:GetAttribute("AxacOrigTrans") then obj:SetAttribute("AxacOrigTrans", obj.Transparency) end
                obj.Transparency = 0.5
            else
                local o = obj:GetAttribute("AxacOrigTrans")
                if o then obj.Transparency = o end
            end
        end
    end
end)

-- =========================================================================
-- CONFIG PAGE
-- =========================================================================
local pCfg = pages["Config"]
section(pCfg, "Session")
button(pCfg, "Reset All Flags", function()
    for k in pairs(S.flags) do
        S.flags[k] = false
        local t = S.meta.toggleReg[k]
        if t then t.Set(false) end
    end
    notify("Flags reset")
end)
button(pCfg, "Unload Hub", function()
    for k in pairs(S.flags) do S.flags[k] = false end
    killConns(); killThreads()
    stopFly()
    clearESP()
    Lighting.Brightness = S.meta.origLight.Brightness
    Lighting.ClockTime  = S.meta.origLight.ClockTime
    Lighting.Ambient    = S.meta.origLight.Ambient
    Lighting.OutdoorAmbient = S.meta.origLight.OutdoorAmbient
    Lighting.FogEnd     = S.meta.origLight.FogEnd
    if gui then gui:Destroy() end
end, true)

section(pCfg, "Keybind")
input(pCfg, "hotkey", "Open Key · default RCtrl", "RightControl", "KeyCode", function(v)
    S.cfg.hotkey = v
    notify("Keybind saved · " .. v)
end)

-- =========================================================================
-- READY
-- =========================================================================
notify("Hub loaded · RightCtrl to open")
