-- =========================================================================
-- AXAC ULTIMATE v99.0 — UI & CORE
-- =========================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

pcall(function() StarterGui:SetCore("ResetButtonCallback", false) end)

local T = {
    bg = Color3.fromRGB(12, 12, 14),
    surface = Color3.fromRGB(18, 18, 21),
    hairline = Color3.fromRGB(38, 38, 44),
    ink = Color3.fromRGB(232, 228, 220),
    inkDim = Color3.fromRGB(140, 134, 122),
    accent = Color3.fromRGB(178, 22, 30),
    accentDim = Color3.fromRGB(90, 12, 16),
    gold = Color3.fromRGB(198, 162, 60),
    killer = Color3.fromRGB(232, 60, 60),
    survivor = Color3.fromRGB(80, 176, 255),
}
local FONT_UI = Enum.Font.Gotham
local FONT_MONO = Enum.Font.Code
local FONT_HEAD = Enum.Font.GothamBold

getgenv().S = {
    flags = {},
    cfg = { walkSpeed = 32, flySpeed = 55, espRefresh = 0.1, autoReviveRange = 15, targetName = "", autoHitDelay = 0.2, hitAction = "\23", reviveAction = "\16", interactAction = "y" },
    meta = { open = false, notifGen = 0, toggleReg = {}, conns = {}, threads = {}, processed = setmetatable({}, {__mode="k"}), noclipParts = setmetatable({}, {__mode="k"}), espFolder = nil },
}
local S = getgenv().S

local function regConn(c) if c then table.insert(S.meta.conns, c) end return c end
local function new(class, props, parent) local o = Instance.new(class) for k, v in pairs(props or {}) do o[k] = v end if parent then o.Parent = parent end return o end
local function tween(inst, props, dur, style, dir) local info = TweenInfo.new(dur or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out) local t = TweenService:Create(inst, info, props) t:Play() return t end

-- CURSOR
do
    local oldCur = LP:WaitForChild("PlayerGui"):FindFirstChild("AxacCursor")
    if oldCur then oldCur:Destroy() end
    local cGui = new("ScreenGui", {Name = "AxacCursor", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999}, LP:WaitForChild("PlayerGui"))
    pcall(function() UIS.MouseIconEnabled = false end)
    local orb = new("Frame", {Size = UDim2.fromOffset(28, 28), BackgroundColor3 = T.accent, BackgroundTransparency = 0.2, AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, ZIndex = 999}, cGui)
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, orb)
    new("UIStroke", {Color = T.ink, Thickness = 1.5}, orb)
    local core = new("Frame", {Size = UDim2.fromOffset(6, 6), BackgroundColor3 = T.ink, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0, ZIndex = 1000}, orb)
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, core)
    local currentPos, targetPos = Vector2.new(0,0), Vector2.new(0,0)
    UIS.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then targetPos = i.Position end end)
    UIS.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then targetPos = i.Position end end)
    RunService.RenderStepped:Connect(function(dt) currentPos = currentPos:Lerp(targetPos, math.min(1, dt * 25)); orb.Position = UDim2.fromOffset(currentPos.X, currentPos.Y) end)
end

-- GUI ROOT
local old = LP:WaitForChild("PlayerGui"):FindFirstChild("AxacHub")
if old then old:Destroy() end
local gui = new("ScreenGui", {Name = "AxacHub", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, IgnoreGuiInset = true}, LP:WaitForChild("PlayerGui"))
getgenv().AxacGui = gui

local uiScale = new("UIScale", {Scale = 1}, gui)
local function updateScale()
    local v = Camera.ViewportSize
    local s = 1
    if v.X < 700 then s = v.X / 700 end
    if v.Y < 500 then s = math.min(s, v.Y / 500) end
    uiScale.Scale = math.clamp(s, 0.55, 1)
end
updateScale(); regConn(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))

local espFolder = workspace:FindFirstChild("AxacESP") or Instance.new("Folder", workspace)
espFolder.Name = "AxacESP"; S.meta.espFolder = espFolder

local orb = new("TextButton", {Size = UDim2.fromOffset(56, 56), Position = UDim2.new(0, 18, 0.5, -28), BackgroundColor3 = T.bg, Text = "", AutoButtonColor = false, ZIndex = 150}, gui)
new("UICorner", {CornerRadius = UDim.new(1, 0)}, orb)
new("UIStroke", {Color = T.accent, Thickness = 1.5}, orb)
new("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "A", Font = FONT_HEAD, TextSize = 26, TextColor3 = T.accent}, orb)

local main = new("Frame", {Size = UDim2.fromOffset(560, 380), Position = UDim2.new(0.5, -280, 0.5, -190), BackgroundColor3 = T.bg, BorderSizePixel = 0, ClipsDescendants = true, Visible = false, BackgroundTransparency = 1, ZIndex = 10}, gui)
new("UICorner", {CornerRadius = UDim.new(0, 4)}, main)
new("UIStroke", {Color = T.hairline, Thickness = 1}, main)

local titleBar = new("Frame", {Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = T.surface}, main)
new("TextLabel", {Size = UDim2.new(0, 200, 1, 0), Position = UDim2.new(0, 20, 0, 0), BackgroundTransparency = 1, Text = "AXAC ULTIMATE", Font = FONT_HEAD, TextSize = 22, TextColor3 = T.ink, TextXAlignment = Enum.TextXAlignment.Left}, titleBar)
new("TextLabel", {Size = UDim2.new(0, 220, 1, 0), Position = UDim2.new(0, 160, 0, 1), BackgroundTransparency = 1, Text = "STK · v99.0", Font = FONT_MONO, TextSize = 11, TextColor3 = T.gold, TextXAlignment = Enum.TextXAlignment.Left}, titleBar)

local closeBtn = new("TextButton", {Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(1, -44, 0, 8), BackgroundTransparency = 1, Text = "X", Font = FONT_MONO, TextSize = 14, TextColor3 = T.inkDim}, titleBar)
closeBtn.MouseButton1Click:Connect(function() tween(main, {BackgroundTransparency = 1}, 0.2); task.delay(0.2, function() main.Visible = false; orb.Visible = true end) end)

local sidebar = new("ScrollingFrame", {Size = UDim2.new(0, 156, 1, -52), Position = UDim2.new(0, 0, 0, 52), BackgroundColor3 = T.bg, ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y}, main)
new("Frame", {Size = UDim2.new(0, 1, 1, -16), Position = UDim2.new(1, -1, 0, 8), BackgroundColor3 = T.hairline}, sidebar)
local content = new("Frame", {Size = UDim2.new(1, -156, 1, -52), Position = UDim2.new(0, 156, 0, 52), BackgroundColor3 = T.bg, ClipsDescendants = true}, main)

local pages, tabBtns = {}, {}
local function makePage(name)
    local p = new("ScrollingFrame", {Size = UDim2.new(1, -48, 1, -44), Position = UDim2.new(0, 26, 0, 22), BackgroundTransparency = 1, ScrollBarThickness = 2, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = (name == "Main")}, content)
    new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, p)
    pages[name] = p
end
local function section(p, label)
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = #p:GetChildren()}, p)
    new("Frame", {Size = UDim2.new(0, 8, 0, 1), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = T.accent}, row)
    new("TextLabel", {Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 18, 0, 0), BackgroundTransparency = 1, Text = string.upper(label), Font = FONT_UI, TextSize = 10, TextColor3 = T.inkDim, TextXAlignment = Enum.TextXAlignment.Left}, row)
end
local function toggle(p, id, label, default, cb)
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = #p:GetChildren()}, p)
    new("TextLabel", {Size = UDim2.new(1, -56, 1, 0), BackgroundTransparency = 1, Text = label, Font = FONT_UI, TextSize = 12, TextColor3 = T.ink, TextXAlignment = Enum.TextXAlignment.Left}, row)
    local track = new("Frame", {Size = UDim2.new(0, 36, 0, 18), Position = UDim2.new(1, -36, 0.5, -9), BackgroundColor3 = default and T.accentDim or T.hairline}, row)
    new("UICorner", {CornerRadius = UDim.new(0, 9)}, track)
    local thumb = new("Frame", {Size = UDim2.new(0, 14, 0, 14), Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = default and T.accent or T.ink}, track)
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, thumb)
    local state = default
    local function set(v)
        if state == v then return end; state = v
        tween(track, {BackgroundColor3 = state and T.accentDim or T.hairline}, 0.14)
        tween(thumb, {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = state and T.accent or T.ink}, 0.14)
        if cb then pcall(cb, state) end
    end
    new("TextButton", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = ""}, row).MouseButton1Click:Connect(function() set(not state) end)
    S.meta.toggleReg[id] = {Set = set}
end
local function slider(p, id, label, min, max, default, decimal, cb)
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, LayoutOrder = #p:GetChildren()}, p)
    new("TextLabel", {Size = UDim2.new(1, -60, 0, 18), BackgroundTransparency = 1, Text = label, Font = FONT_UI, TextSize = 12, TextColor3 = T.ink, TextXAlignment = Enum.TextXAlignment.Left}, row)
    local val = new("TextLabel", {Size = UDim2.new(0, 60, 0, 18), Position = UDim2.new(1, -60, 0, 0), BackgroundTransparency = 1, Text = decimal and string.format("%.2f", default) or tostring(math.floor(default)), Font = FONT_MONO, TextSize = 11, TextColor3 = T.gold, TextXAlignment = Enum.TextXAlignment.Right}, row)
    local track = new("Frame", {Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0, 32), BackgroundColor3 = T.hairline}, row)
    local fill = new("Frame", {Size = UDim2.new((default-min)/(max-min), 0, 1, 0), BackgroundColor3 = T.accent}, track)
    local dot = new("Frame", {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new((default-min)/(max-min), -7, 0.5, -7), BackgroundColor3 = T.ink}, track)
    new("UICorner", {CornerRadius = UDim.new(1,0)}, dot)
    local dragging = false
    local function set(v, fromUser)
        v = math.clamp(v, min, max); local rel = (v - min) / (max - min)
        tween(fill, {Size = UDim2.new(rel, 0, 1, 0)}, fromUser and 0.02 or 0.16)
        tween(dot, {Position = UDim2.new(rel, -7, 0.5, -7)}, fromUser and 0.02 or 0.16)
        val.Text = decimal and string.format("%.2f", v) or tostring(math.floor(v))
        if cb then pcall(cb, v) end
    end
    local function handleInput(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1); set(min + (max - min) * rel, true) end end
    track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; handleInput(i) end end)
    regConn(UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end))
    regConn(UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then handleInput(i) end end))
end
local function button(p, label, cb, destructive)
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, LayoutOrder = #p:GetChildren()}, p)
    local btn = new("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = string.upper(label), Font = FONT_UI, TextSize = 11, TextColor3 = destructive and T.killer or T.inkDim, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false}, row)
    local ul = new("Frame", {Size = UDim2.new(0.55, 0, 0, 1), Position = UDim2.new(0, 0, 1, -3), BackgroundColor3 = T.hairline}, btn)
    btn.MouseEnter:Connect(function() tween(btn, {TextColor3 = T.accent}, 0.14); tween(ul, {Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.accent}, 0.14) end)
    btn.MouseLeave:Connect(function() tween(btn, {TextColor3 = destructive and T.killer or T.inkDim}, 0.14); tween(ul, {Size = UDim2.new(0.55, 0, 0, 1), BackgroundColor3 = T.hairline}, 0.14) end)
    btn.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
end
local function input(p, id, label, default, placeholder, cb)
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1, LayoutOrder = #p:GetChildren()}, p)
    new("TextLabel", {Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = label, Font = FONT_UI, TextSize = 11, TextColor3 = T.inkDim, TextXAlignment = Enum.TextXAlignment.Left}, row)
    local box = new("TextBox", {Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 22), BackgroundColor3 = T.surface, Text = default or "", PlaceholderText = placeholder or "", Font = FONT_MONO, TextSize = 12, TextColor3 = T.ink, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left}, row)
    new("UICorner", {CornerRadius = UDim.new(0, 3)}, box)
    new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, box)
    box.FocusLost:Connect(function(enter) if cb then pcall(cb, box.Text, enter) end end)
end

getgenv().S.UI = { pages = pages, tabBtns = tabBtns, makePage = makePage, section = section, toggle = toggle, slider = slider, button = button, input = input, main = main, orb = orb, closeBtn = closeBtn, sidebar = sidebar, gui = gui }

-- TABS SETUP
local tabs = {"Main", "Player", "ESP", "Farm", "Teleport", "Remote", "Visuals", "Server", "Misc", "Config"}
for i, name in ipairs(tabs) do
    local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, (i-1)*36), BackgroundColor3 = T.bg, Text = "  " .. name, Font = FONT_UI, TextSize = 13, TextColor3 = T.inkDim, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false}, sidebar)
    local bar = new("Frame", {Size = UDim2.new(0, 2, 1, -8), Position = UDim2.new(0, 0, 0, 4), BackgroundColor3 = T.gold, Visible = (i==1)}, btn)
    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(pages) do p.Visible = false end
        for _, b in pairs(tabBtns) do b.bar.Visible = false; tween(b.btn, {TextColor3 = T.inkDim}, 0.12) end
        if pages[name] then pages[name].Visible = true end
        bar.Visible = true; tween(btn, {TextColor3 = T.ink}, 0.12)
    end)
    tabBtns[name] = {btn = btn, bar = bar}
end
for _, name in ipairs(tabs) do makePage(name) end

orb.MouseButton1Click:Connect(function() main.Visible = true; tween(main, {BackgroundTransparency = 0}, 0.2); orb.Visible = false end)
