-- =========================================================================
-- AXAC HUB — V25.0 (Clean Build, Fast TP, Dual Farm Logic)
-- =========================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- 1. BASE SETUP
pcall(function()
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("BlurEffect") then v.Enabled = false end
    end
end)
Lighting.ChildAdded:Connect(function(child)
    if child:IsA("BlurEffect") then task.wait(0.1) child.Enabled = false end
end)

local Theme = {
    Canvas = Color3.fromRGB(10, 10, 12), Elevated = Color3.fromRGB(16, 16, 19), Raised = Color3.fromRGB(22, 22, 26),
    Hairline = Color3.fromRGB(35, 35, 40), Faint = Color3.fromRGB(26, 26, 30), Text = Color3.fromRGB(230, 225, 216),
    Subtext = Color3.fromRGB(138, 132, 120), Muted = Color3.fromRGB(74, 70, 64), Accent = Color3.fromRGB(179, 18, 27),
    AccentDim = Color3.fromRGB(107, 12, 18), Gold = Color3.fromRGB(201, 162, 39),
}

-- 2. SAFE GUI INJECTION
local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("AxacHub")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AxacHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local function Make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

-- 3. STATE & TRACKERS
local Store = {
    Flags = {}, Settings = { CustomSpeed = 32, FlySpeed = 50, FarmRange = 150 },
    Toggles = {}, Sliders = {}, Connections = {}, Threads = {},
    NoclipParts = setmetatable({}, {__mode = "k"}),
    NotifGen = 0, IsMenuOpen = false
}

local function KillThreads()
    for _, data in pairs(Store.Threads) do if data.thread then pcall(function() task.cancel(data.thread) end) end end
    Store.Threads = {}
end
local function DisconnectAll()
    for _, conn in pairs(Store.Connections) do pcall(function() conn:Disconnect() end) end
    Store.Connections = {}; KillThreads()
    for _, slider in pairs(Store.Sliders) do pcall(function() slider:Destroy() end) end
    Store.Sliders = {}
end
local function RegisterThread(thread, flagName)
    for i = #Store.Threads, 1, -1 do
        local t = Store.Threads[i].thread
        if not t or (coroutine.status(t) ~= "running" and coroutine.status(t) ~= "suspended" and coroutine.status(t) ~= "normal") then table.remove(Store.Threads, i) end
    end
    table.insert(Store.Threads, { thread = thread, flag = flagName })
end

-- =========================================================================
-- 4. SPLASH SCREEN (CURTAIN)
-- =========================================================================
local Splash = Make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Canvas, BorderSizePixel = 0, ZIndex = 200 }, ScreenGui)
local SplashContainer = Make("Frame", { Size = UDim2.fromOffset(300, 100), Position = UDim2.new(0.5, -150, 0.5, -50), BackgroundTransparency = 1, ZIndex = 201 }, Splash)
local SplashText = Make("TextLabel", { Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, Text = "AXAC", Font = Enum.Font.Garamond, TextSize = 56, TextColor3 = Theme.Text, TextTransparency = 1 }, SplashContainer)
local SplashSub = Make("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 65), BackgroundTransparency = 1, Text = "STK HUB V25", Font = Enum.Font.Code, TextSize = 12, TextColor3 = Theme.Gold, TextTransparency = 1 }, SplashContainer)
local SplashLine = Make("Frame", { Size = UDim2.fromOffset(0, 1), Position = UDim2.new(0.5, 0, 0, 58), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0 }, SplashContainer)
local CurtainTop = Make("Frame", { Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Theme.Canvas, BorderSizePixel = 0, ZIndex = 202 }, Splash)
local CurtainBot = Make("Frame", { Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Theme.Canvas, BorderSizePixel = 0, ZIndex = 202 }, Splash)

task.spawn(function()
    task.wait(0.1)
    TweenService:Create(SplashText, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
    TweenService:Create(SplashSub, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
    TweenService:Create(SplashLine, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(200, 1) }):Play()
    task.wait(1.5) 
    TweenService:Create(SplashText, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
    TweenService:Create(SplashSub, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
    TweenService:Create(SplashLine, TweenInfo.new(0.3), { Size = UDim2.fromOffset(0, 1) }):Play()
    TweenService:Create(CurtainTop, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0, 0, 0.5, 0) }):Play()
    TweenService:Create(CurtainBot, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0, 0, 0.5, 0) }):Play()
    task.wait(0.4)
    Splash:Destroy()
    Store.IsMenuOpen = true
    if _G.AxacOpenMenu then _G.AxacOpenMenu() end
end)

-- =========================================================================
-- 5. UI BUILDER (ANTI-SLOP)
-- =========================================================================
local MainFrame = Make("Frame", { Size = UDim2.fromOffset(604, 412), Position = UDim2.new(0.5, -302, 0.5, -150), BackgroundColor3 = Theme.Canvas, BorderSizePixel = 0, ClipsDescendants = false, BackgroundTransparency = 1, ZIndex = 5, Visible = false }, ScreenGui)
Make("UICorner", { TopLeftRadius = UDim.new(0, 4), BottomRightRadius = UDim.new(0, 4), TopRightRadius = UDim.new(0, 0), BottomLeftRadius = UDim.new(0, 0) }, MainFrame)
Make("UIStroke", { Color = Theme.Hairline, Thickness = 1 }, MainFrame)

local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

local TitleBar = Make("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = Theme.Elevated, BorderSizePixel = 0 }, MainFrame)
Make("TextLabel", { BackgroundTransparency = 1, Text = "AXAC HUB", Font = Enum.Font.Garamond, TextSize = 22, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(1, -100, 1, 0) }, TitleBar)
Make("Frame", { BackgroundColor3 = Theme.Hairline, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, -14, 0, 1) }, TitleBar)
Make("TextLabel", { BackgroundTransparency = 1, Text = "v3.5.0 · build 9500", Font = Enum.Font.Code, TextSize = 11, TextColor3 = Theme.Gold, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 150, 0, 21), Size = UDim2.new(0, 150, 0, 20) }, TitleBar)

local CloseBtn = Make("TextButton", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -34, 0, 31), BackgroundTransparency = 1, Text = "X", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Subtext }, TitleBar)
CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = Theme.Accent end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = Theme.Subtext end)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local Sidebar = Make("Frame", { Size = UDim2.new(0, 155, 1, -6), Position = UDim2.new(0, 0, 0, 52), BackgroundColor3 = Theme.Canvas, BorderSizePixel = 0 }, MainFrame)

local TabData = {
    { Name = "Main", Prefix = "·" }, { Name = "Farm", Prefix = "··" }, { Name = "ESP", Prefix = "··" }, 
    { Name = "Player", Prefix = "·" }, { Name = "Teleport", Prefix = "·" }, { Name = "Effects", Prefix = "·" }, { Name = "Config", Prefix = "·" }
}
local ActiveTab = "Main"
local TabElements = {}

for i, data in ipairs(TabData) do
    local TabBtn = Make("TextButton", { Size = UDim2.new(1, 0, 0, 32), Position = UDim2.new(0, 0, 0, (i - 1) * 32), BackgroundColor3 = Theme.Canvas, BorderSizePixel = 0, Text = "  " .. data.Name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Subtext, TextXAlignment = Enum.TextXAlignment.Left }, Sidebar)
    Make("TextLabel", { BackgroundTransparency = 1, Text = data.Prefix, Font = Enum.Font.Code, TextSize = 10, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0, 25, 1, 0), Position = UDim2.new(0, -30, 0, 0) }, TabBtn)
    local ActiveBar = Make("Frame", { BackgroundColor3 = Theme.Gold, BorderSizePixel = 0, Size = UDim2.new(0, 2, 1, 0), Position = UDim2.new(0, 0, 0, 0), Visible = false }, TabBtn)

    TabBtn.MouseButton1Click:Connect(function()
        ActiveTab = data.Name
        for name, el in pairs(TabElements) do
            if el.content then el.content.Visible = (name == ActiveTab) end
            el.bar.Visible = (name == ActiveTab)
            el.btn.TextColor3 = (name == ActiveTab) and Theme.Text or Theme.Subtext
        end
    end)
    TabElements[data.Name] = { btn = TabBtn, bar = ActiveBar }
end
TabElements["Main"].bar.Visible = true
TabElements["Main"].btn.TextColor3 = Theme.Text

local ContentArea = Make("Frame", { Size = UDim2.new(1, -155, 1, -52), Position = UDim2.new(0, 155, 0, 52), BackgroundColor3 = Theme.Canvas, BorderSizePixel = 0 }, MainFrame)

local NotifLabel = Make("TextLabel", {
    Size = UDim2.new(0, 300, 0, 34), Position = UDim2.new(0.5, -150, 0, -40),
    BackgroundColor3 = Theme.AccentDim, BackgroundTransparency = 0.1, BorderSizePixel = 0,
    Text = "", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Text, ZIndex = 100, Visible = false,
}, MainFrame)
Make("UICorner", { CornerRadius = UDim.new(0, 4) }, NotifLabel)
Make("Frame", { BackgroundColor3 = Theme.Accent, Size = UDim2.new(0, 2, 1, 0), Position = UDim2.new(0, 0, 0, 0) }, NotifLabel)

local function ShowNotif(text)
    Store.NotifGen = (Store.NotifGen or 0) + 1
    local myGen = Store.NotifGen
    NotifLabel.Text = text; NotifLabel.Visible = true
    TweenService:Create(NotifLabel, TweenInfo.new(0.14), { Position = UDim2.new(0.5, -150, 0, 10) }):Play()
    task.delay(3, function()
        if Store.NotifGen ~= myGen then return end
        TweenService:Create(NotifLabel, TweenInfo.new(0.14), { Position = UDim2.new(0.5, -150, 0, -40) }):Play()
        task.wait(0.14)
        if Store.NotifGen == myGen and NotifLabel then NotifLabel.Visible = false end
    end)
end
_G.AxacNotify = ShowNotif

-- 6. FLOATING ORB
local Orb = Make("TextButton", {
    Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, 20, 0.5, -23),
    BackgroundColor3 = Theme.Canvas, Text = "A", Font = Enum.Font.Garamond, TextSize = 24,
    TextColor3 = Theme.Accent, AutoButtonColor = false, ZIndex = 150, Visible = false 
}, ScreenGui)
Make("UICorner", { CornerRadius = UDim.new(1, 0) }, Orb)
Make("UIStroke", { Color = Theme.Accent, Thickness = 1.5 }, Orb)

Orb.MouseEnter:Connect(function() TweenService:Create(Orb, TweenInfo.new(0.14), { BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text }):Play() end)
Orb.MouseLeave:Connect(function() TweenService:Create(Orb, TweenInfo.new(0.14), { BackgroundColor3 = Theme.Canvas, TextColor3 = Theme.Accent }):Play() end)

local function ToggleGUI(show)
    Store.IsMenuOpen = show
    if show then
        Orb.Visible = false
        MainFrame.Visible = true
        MainFrame.Position = UDim2.new(0.5, -302, 0.5, -150) 
        TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { BackgroundTransparency = 0, Position = UDim2.new(0.5, -302, 0.5, -206) }):Play()
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1, Position = UDim2.new(0.5, -302, 0.5, -150) }):Play()
        task.delay(0.2, function() 
            if not Store.IsMenuOpen then 
                MainFrame.Visible = false
                Orb.Visible = true 
            end 
        end)
    end
end

_G.AxacOpenMenu = function() ToggleGUI(true) end
Orb.MouseButton1Click:Connect(function() ToggleGUI(true) end)
CloseBtn.MouseButton1Click:Connect(function() ToggleGUI(false) end)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
        ToggleGUI(not Store.IsMenuOpen)
    end
end)

-- =========================================================================
-- 7. HELPER & UI COMPONENTS
-- =========================================================================
local function CreatePage(name)
    local Page = Make("ScrollingFrame", {
        Size = UDim2.new(1, -44, 1, -48), Position = UDim2.new(0, 24, 0, 20),
        BackgroundTransparency = 1, ScrollBarThickness = 2, CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = (name == "Main"),
    }, ContentArea)
    Make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, Page)
    TabElements[name].content = Page
    return Page
end

local function AddSection(parent, title)
    local frame = Make("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = #parent:GetChildren() }, parent)
    Make("Frame", { BackgroundColor3 = Theme.Accent, Size = UDim2.new(0, 8, 0, 1), Position = UDim2.new(0, 0, 0, 15) }, frame)
    Make("TextLabel", { BackgroundTransparency = 1, Text = string.upper(title), Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Subtext, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 18, 0, 0), Size = UDim2.new(1, 0, 0, 30) }, frame)
    return frame
end

local function AddToggle(parent, id, text, default, callback)
    local Row = Make("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = #parent:GetChildren() }, parent)
    Make("TextLabel", { BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -40, 1, 0) }, Row)
    local Track = Make("Frame", { Size = UDim2.new(0, 26, 0, 12), Position = UDim2.new(1, -26, 0.5, -6), BackgroundColor3 = default and Theme.AccentDim or Theme.Hairline, BorderSizePixel = 0 }, Row)
    Make("UICorner", { CornerRadius = UDim.new(0, 2) }, Track)
    local Thumb = Make("Frame", { Size = UDim2.new(0, 10, 0, 10), Position = default and UDim2.new(1, -11, 0, 1) or UDim2.new(0, 1, 0, 1), BackgroundColor3 = default and Theme.Accent or Theme.Text, BorderSizePixel = 0 }, Track)
    Make("UICorner", { CornerRadius = UDim.new(0, 1) }, Thumb)

    local state = default
    local function Update(v)
        if state == v then return end
        state = v
        TweenService:Create(Track, TweenInfo.new(0.12), { BackgroundColor3 = state and Theme.AccentDim or Theme.Hairline }):Play()
        TweenService:Create(Thumb, TweenInfo.new(0.12), { Position = state and UDim2.new(1, -11, 0, 1) or UDim2.new(0, 1, 0, 1), BackgroundColor3 = state and Theme.Accent or Theme.Text }):Play()
        if callback then callback(state) end
    end
    Make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "" }, Row).MouseButton1Click:Connect(function() Update(not state) end)
    local handle = { Set = function(v) Update(v) end }
    Store.Toggles[id] = handle
    return handle
end

local function AddSlider(parent, id, text, min, max, default, isDecimal, callback)
    local Row = Make("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = #parent:GetChildren() }, parent)
    local Lbl = Make("TextLabel", { BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -50, 0, 20) }, Row)
    local defaultStr = isDecimal and string.format("%.2fs", default) or tostring(default)
    local ValLbl = Make("TextLabel", { BackgroundTransparency = 1, Text = defaultStr, Font = Enum.Font.Code, TextSize = 11, TextColor3 = Theme.Gold, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0, 50, 0, 20), Position = UDim2.new(1, -50, 0, 0) }, Row)
    local BarBg = Make("Frame", { Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 0, 25), BackgroundColor3 = Theme.Hairline, BorderSizePixel = 0 }, Row)
    local Fill = Make("Frame", { Size = UDim2.new((default - min)/(max - min), 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0 }, BarBg)

    local draggingSlider = false
    local function Update(v)
        local clamped = math.clamp(v, min, max)
        local relX = (clamped - min) / (max - min)
        Fill.Size = UDim2.new(relX, 0, 1, 0)
        if isDecimal then ValLbl.Text = string.format("%.2fs", clamped) else ValLbl.Text = tostring(math.floor(clamped)) end
        if callback then callback(clamped) end
    end
    local conn1 = BarBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = true end end)
    local conn2 = UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end end)
    local conn3 = UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local relX = math.clamp((input.Position.X - BarBg.AbsolutePosition.X) / BarBg.AbsoluteSize.X, 0, 1)
            Update(min + (max - min) * relX)
        end
    end)
    local handle = { Set = function(v) Update(v) end, Destroy = function() conn1:Disconnect(); conn2:Disconnect(); conn3:Disconnect() end }
    Store.Sliders[id] = handle
    return handle
end

local function AddButton(parent, text, callback, isDestructive)
    local Btn = Make("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = string.upper(text), Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Subtext, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = #parent:GetChildren() }, parent)
    local Underline = Make("Frame", { BackgroundColor3 = Theme.Hairline, Size = UDim2.new(0.6, 0, 0, 1), Position = UDim2.new(0, 0, 1, -2) }, Btn)
    if isDestructive then Make("Frame", { BackgroundColor3 = Theme.Accent, Size = UDim2.new(0, 1, 0, 10), Position = UDim2.new(0, -10, 0.5, -5) }, Btn) end
    Btn.MouseEnter:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.14), { TextColor3 = Theme.Accent }):Play(); TweenService:Create(Underline, TweenInfo.new(0.14), { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Accent }):Play() end)
    Btn.MouseLeave:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.14), { TextColor3 = Theme.Subtext }):Play(); TweenService:Create(Underline, TweenInfo.new(0.14), { Size = UDim2.new(0.6, 0, 0, 1), BackgroundColor3 = Theme.Hairline }):Play() end)
    Btn.MouseButton1Click:Connect(function() if callback then callback() end end)
end

-- =========================================================================
-- 8. LOGIKA ASLI & KILLER PREDICT
-- =========================================================================
local function checkIsKiller(p)
    if not p or not p.Character then return false end
    local charTools = p.Character:FindFirstChildWhichIsA("Tool")
    local backTools = p:FindFirstChild("Backpack") and p.Backpack:FindFirstChildWhichIsA("Tool")
    if charTools or backTools then return true end
    if p.Character:FindFirstChild("Knife") or p.Character:FindFirstChild("Killer") or p.Character:FindFirstChild("KillerScript") then return true end
    if p:FindFirstChild("Role") and tostring(p.Role.Value):lower():find("killer") then return true end
    return false
end

-- KILLER PREDICT UI
local PredictFrame = Make("TextLabel", {
    Size = UDim2.new(0, 280, 0, 36), Position = UDim2.new(0.5, -140, 0, 12),
    BackgroundColor3 = Theme.AccentDim, BackgroundTransparency = 0.15, BorderSizePixel = 0,
    Text = "PREDICT: —", Font = Enum.Font.Code, TextSize = 13, TextColor3 = Theme.Text, ZIndex = 150, Visible = true
}, ScreenGui)
Make("UICorner", { CornerRadius = UDim.new(0, 4) }, PredictFrame)
Make("UIStroke", { Color = Theme.Accent, Thickness = 1 }, PredictFrame)

local KILLER_TOOLS = {["Knife"]=true, ["Axe"]=true, ["Bat"]=true, ["Cleaver"]=true, ["Scythe"]=true, ["Machete"]=true, ["Pipe"]=true, ["Wrench"]=true}
local function predictKiller()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            for _, name in ipairs({"Role", "role", "Team", "IsKiller", "Killer"}) do
                local val = p:GetAttribute(name)
                if val and tostring(val):lower():find("killer") then return p end
            end
            if p.Team and (p.Team.Name:lower():find("killer") or p.Team.TeamColor == BrickColor.new("Really red")) then return p end
            if p.Character then
                local tool = p.Character:FindFirstChildWhichIsA("Tool")
                if tool and KILLER_TOOLS[tool.Name] then return p end
            end
            if p:FindFirstChild("Backpack") then
                local tool = p.Backpack:FindFirstChildWhichIsA("Tool")
                if tool and KILLER_TOOLS[tool.Name] then return p end
            end
        end
    end
    return nil
end

task.spawn(function()
    while task.wait(0.2) do
        if not Store.Flags.PredictKiller then PredictFrame.Visible = false; continue end
        PredictFrame.Visible = true
        local k = predictKiller()
        if k then
            PredictFrame.Text = "PREDICT: " .. k.Name
            PredictFrame.TextColor3 = Theme.Accent
        else
            PredictFrame.Text = "PREDICT: Scanning..."
            PredictFrame.TextColor3 = Theme.Text
        end
    end
end)

local ESPFolder = workspace:FindFirstChild("AxacESPFolder") or Instance.new("Folder", workspace)
ESPFolder.Name = "AxacESPFolder"

-- [MAIN TAB]
local MainPage = CreatePage("Main")
AddSection(MainPage, "Round pressure")
AddToggle(MainPage, "PredictKiller", "Real-Time Killer Predict", false, function(v) Store.Flags.PredictKiller = v end)
AddToggle(MainPage, "AutoRevive", "Auto Revive Downed Players", false, function(v)
    Store.Flags.AutoRevive = v
    if v then
        local thread = task.spawn(function()
            while Store.Flags.AutoRevive do
                pcall(function()
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
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
        RegisterThread(thread, "AutoRevive")
    end
end)
AddToggle(MainPage, "KillerAlert", "Killer Proximity Alert (<75m)", false, function(v)
    Store.Flags.KillerAlert = v
    if v then
        local thread = task.spawn(function()
            local lastAlert = 0
            while Store.Flags.KillerAlert do
                pcall(function()
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot then
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and checkIsKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                                local dist = math.floor((myRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude)
                                if dist <= 75 and (tick() - lastAlert > 4) then
                                    lastAlert = tick()
                                    ShowNotif("KILLER: " .. p.Name .. " (" .. dist .. "m)")
                                end
                            end
                        end
                    end
                end)
                task.wait(0.5)
            end
        end)
        RegisterThread(thread, "KillerAlert")
    end
end)

-- [FARM TAB - SPLIT LOGIC]
local FarmPage = CreatePage("Farm")
AddSection(FarmPage, "Candy Collect")
AddToggle(FarmPage, "AutoCandy", "Auto Candy / Sweet", false, function(v) Store.Flags.AutoCandy = v end)

AddSection(FarmPage, "Balloon Pop")
AddToggle(FarmPage, "AutoBalloon", "Auto Balloon", false, function(v) Store.Flags.AutoBalloon = v end)

-- Loop Auto Candy (Cepat & Berhenti Sendiri)
local candyThread = task.spawn(function()
    local isSearching = true
    while task.wait(0.01) do
        if not Store.Flags.AutoCandy then isSearching = true; continue end
        local myChar = LocalPlayer.Character
        if not myChar then continue end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then continue end

        local nearest, minDist = nil, math.huge
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name:lower():find("candy") or obj.Name:lower():find("sweet") then
                local targetPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or (obj:IsA("BasePart") and obj)
                if targetPart then
                    local d = (myRoot.Position - targetPart.Position).Magnitude
                    if d < 150 and d < minDist then
                        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then minDist = d; nearest = { part = targetPart, prompt = prompt } end
                    end
                end
            end
        end

        if nearest then
            isSearching = false
            myRoot.CFrame = CFrame.new(nearest.part.Position + Vector3.new(0, 2, 0))
            task.wait(0.05)
            fireproximityprompt(nearest.prompt)
        else
            if not isSearching then
                isSearching = true
                ShowNotif("[Candy] Semua candy habis/diambil. Menunggu respawn...")
            end
        end
    end
end)
RegisterThread(candyThread, "AutoCandy")

-- Loop Auto Balloon (Cepat & Berhenti Sendiri)
local balloonThread = task.spawn(function()
    local isSearching = true
    while task.wait(0.01) do
        if not Store.Flags.AutoBalloon then isSearching = true; continue end
        local myChar = LocalPlayer.Character
        if not myChar then continue end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then continue end

        local nearest, minDist = nil, math.huge
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name:lower():find("balloon") then
                local targetPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or (obj:IsA("BasePart") and obj)
                if targetPart then
                    local d = (myRoot.Position - targetPart.Position).Magnitude
                    if d < 150 and d < minDist then
                        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then minDist = d; nearest = { part = targetPart, prompt = prompt } end
                    end
                end
            end
        end

        if nearest then
            isSearching = false
            myRoot.CFrame = CFrame.new(nearest.part.Position)
            task.wait(0.05)
            fireproximityprompt(nearest.prompt)
        else
            if not isSearching then
                isSearching = true
                ShowNotif("[Balloon] Semua balloon habis/pecah. Menunggu respawn...")
            end
        end
    end
end)
RegisterThread(balloonThread, "AutoBalloon")

-- [ESP TAB]
local ESPPage = CreatePage("ESP")
AddSection(ESPPage, "Visuals")
AddToggle(ESPPage, "ESP_Active", "Player Highlight", false, function(v) Store.Flags.ESP_Active = v; if not v then ESPFolder:ClearAllChildren() end end)
AddToggle(ESPPage, "Tracers_Killer", "Tracer to Killer (Red)", false, function(v) Store.Flags.Tracers_Killer = v; if not v then for _, c in pairs(ESPFolder:GetChildren()) do if c.Name:find("Tracer_Killer_") then c:Destroy() end end end end)
AddToggle(ESPPage, "Tracers_Survivors", "Tracer to Survivors (Blue)", false, function(v) Store.Flags.Tracers_Survivors = v; if not v then for _, c in pairs(ESPFolder:GetChildren()) do if c.Name:find("Tracer_Survivor_") then c:Destroy() end end end end)
AddToggle(ESPPage, "ESP_Names", "Show Names & Distance", false, function(v) Store.Flags.ESP_Names = v; if not v then for _, c in pairs(ESPFolder:GetChildren()) do if c.Name:find("Tag_") then c:Destroy() end end end end)

local espThread = task.spawn(function()
    while task.wait(0.1) do
        if not Store.Flags.ESP_Active and not Store.Flags.Tracers_Killer and not Store.Flags.Tracers_Survivors and not Store.Flags.ESP_Names then continue end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local isKiller = checkIsKiller(p)
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local dist = myRoot and math.floor((myRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude) or 0

                if Store.Flags.ESP_Active then
                    local hl = ESPFolder:FindFirstChild("Player_" .. p.Name)
                    if not hl then hl = Instance.new("Highlight"); hl.Name = "Player_" .. p.Name; hl.Adornee = p.Character; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = ESPFolder end
                    hl.FillColor = isKiller and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 120, 255)
                    hl.FillTransparency = isKiller and 0.2 or 0.5
                end
                if myRoot then
                    if Store.Flags.Tracers_Killer and isKiller then
                        local beam = ESPFolder:FindFirstChild("Tracer_Killer_" .. p.Name)
                        if not beam then
                            local a0 = Instance.new("Attachment", myRoot); local a1 = Instance.new("Attachment", p.Character.HumanoidRootPart)
                            beam = Instance.new("Beam"); beam.Name = "Tracer_Killer_" .. p.Name; beam.Attachment0 = a0; beam.Attachment1 = a1; beam.Width0 = 0.12; beam.Width1 = 0.12; beam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0)); beam.FaceCamera = true; beam.Parent = ESPFolder
                        end
                    end
                    if Store.Flags.Tracers_Survivors and not isKiller then
                        local beam = ESPFolder:FindFirstChild("Tracer_Survivor_" .. p.Name)
                        if not beam then
                            local a0 = Instance.new("Attachment", myRoot); local a1 = Instance.new("Attachment", p.Character.HumanoidRootPart)
                            beam = Instance.new("Beam"); beam.Name = "Tracer_Survivor_" .. p.Name; beam.Attachment0 = a0; beam.Attachment1 = a1; beam.Width0 = 0.08; beam.Width1 = 0.08; beam.Color = ColorSequence.new(Color3.fromRGB(0, 170, 255)); beam.FaceCamera = true; beam.Parent = ESPFolder
                        end
                    end
                end
                if Store.Flags.ESP_Names then
                    local bbg = ESPFolder:FindFirstChild("Tag_" .. p.Name)
                    if not bbg then
                        bbg = Instance.new("BillboardGui"); bbg.Name = "Tag_" .. p.Name; bbg.Adornee = p.Character:FindFirstChild("Head") or p.Character.HumanoidRootPart; bbg.Size = UDim2.new(0, 150, 0, 30); bbg.StudsOffset = Vector3.new(0, 2.5, 0); bbg.AlwaysOnTop = true
                        local label = Instance.new("TextLabel", bbg); label.Name = "Label"; label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamBold; label.TextSize = 12; label.TextStrokeTransparency = 0; label.Parent = bbg
                        bbg.Parent = ESPFolder
                    end
                    local label = bbg:FindFirstChild("Label")
                    if label then label.Text = p.Name .. " [" .. dist .. "m]"; label.TextColor3 = isKiller and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(100, 200, 255) end
                end
            end
        end
    end
end)
RegisterThread(espThread, "ESP")

-- [PLAYER TAB]
local PlayerPage = CreatePage("Player")
AddSection(PlayerPage, "Body control")
AddToggle(PlayerPage, "SpeedBoost", "Speed Boost", false, function(v)
    Store.Flags.SpeedBoost = v
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v and Store.Settings.CustomSpeed or 16 end
end)
AddSlider(PlayerPage, "Speed", "Walk Speed", 16, 120, 32, false, function(v)
    Store.Settings.CustomSpeed = v
    if Store.Flags.SpeedBoost then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
end)
AddToggle(PlayerPage, "Noclip", "Noclip", false, function(v) Store.Flags.Noclip = v end)
AddToggle(PlayerPage, "InfJump", "Infinite Jump", false, function(v) Store.Flags.InfJump = v end)

AddToggle(PlayerPage, "SelfRevive", "Self Revive (Safe TP)", false, function(v)
    Store.Flags.SelfRevive = v
    if v then
        local thread = task.spawn(function()
            local last = 0
            while Store.Flags.SelfRevive do
                pcall(function()
                    local myChar = LocalPlayer.Character
                    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
                    local bleed = myChar.HumanoidRootPart:FindFirstChild("BleedOutHealth") or myChar:FindFirstChild("BleedOutHealth", true)
                    local isDowned = (bleed and bleed.Enabled) or (myChar:FindFirstChildOfClass("Humanoid") and myChar.Humanoid.PlatformStand)
                    
                    if isDowned and (tick() - last > 5) then
                        local myRoot = myChar.HumanoidRootPart
                        
                        local safePos = myRoot.Position + Vector3.new(math.random(-100, 100), 5, math.random(-100, 100))
                        local killerRoot = nil
                        
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and checkIsKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                                killerRoot = p.Character.HumanoidRootPart
                                break
                            end
                        end

                        if killerRoot then
                            local dirAway = (myRoot.Position - killerRoot.Position).Unit
                            safePos = myRoot.Position + (dirAway * 40) + Vector3.new(math.random(-20, 20), 5, math.random(-20, 20))
                        end
                        
                        myRoot.CFrame = CFrame.new(safePos)
                        last = tick()
                        ShowNotif("Self Revive: TP Safe")
                    end
                end)
                task.wait(0.5)
            end
        end)
        RegisterThread(thread, "SelfRevive")
    end
end)

-- [TELEPORT TAB]
local TeleportPage = CreatePage("Teleport")
AddSection(TeleportPage, "Navigation")
AddButton(TeleportPage, "TP to Spawn / Lobby", function()
    local spawnLoc = workspace:FindFirstChild("SpawnLocation", true) or workspace:FindFirstChild("Lobby", true)
    if spawnLoc and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = spawnLoc.CFrame + Vector3.new(0, 5, 0)
    end
end)
AddButton(TeleportPage, "TP to Exit Doors", function()
    local exits = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Exit" or obj.Name == "Gate" or obj.Name == "Escape" or obj.Name == "ExitDoor" then table.insert(exits, obj) end
    end
    if #exits > 0 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local target = exits[math.random(1, #exits)]
        LocalPlayer.Character.HumanoidRootPart.CFrame = (target:IsA("Model") and target.PrimaryPart or target).CFrame
    end
end)

-- [EFFECTS TAB]
local EffectsPage = CreatePage("Effects")
AddSection(EffectsPage, "Visual")
local originalBrightness = Lighting.Brightness
local originalClockTime = Lighting.ClockTime
local originalAmbient = Lighting.Ambient
local originalFogEnd = Lighting.FogEnd

AddToggle(EffectsPage, "FullBright", "Full Brightness", false, function(v)
    Lighting.Brightness = v and 3 or originalBrightness
    Lighting.ClockTime = v and 12 or originalClockTime
end)
AddToggle(EffectsPage, "Ambient", "Ambient Light", false, function(v)
    Lighting.Ambient = v and Color3.fromRGB(180, 180, 180) or originalAmbient
end)
AddToggle(EffectsPage, "NoFog", "No Fog", false, function(v)
    Lighting.FogEnd = v and 999999 or originalFogEnd
end)
AddSlider(EffectsPage, "FOV", "FOV", 70, 120, 70, false, function(v)
    workspace.CurrentCamera.FieldOfView = v
end)
AddToggle(EffectsPage, "XRay", "X-Ray (Transparency)", false, function(v)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Parent:FindFirstChildOfClass("Humanoid") then
            if v then
                if not obj:GetAttribute("OrigTrans") then obj:SetAttribute("OrigTrans", obj.Transparency) end
                obj.Transparency = 0.5
            else
                local orig = obj:GetAttribute("OrigTrans")
                if orig then obj.Transparency = orig end
            end
        end
    end
end)

-- [CONFIG TAB]
local ConfigPage = CreatePage("Config")
AddSection(ConfigPage, "System")
AddButton(ConfigPage, "Unload Hub", function()
    for k in pairs(Store.Flags) do Store.Flags[k] = false end
    DisconnectAll()
    if ScreenGui then ScreenGui:Destroy() end
end, true)

-- =========================================================================
-- 9. BACKGROUND LOOPS
-- =========================================================================
local logicThread = task.spawn(function()
    while task.wait(0.1) do
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                if Store.Flags.SpeedBoost then hum.WalkSpeed = Store.Settings.CustomSpeed
                elseif not Store.Flags.SpeedBoost and hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
            end
            if Store.Flags.Noclip then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if not Store.NoclipParts[part] then Store.NoclipParts[part] = part.CanCollide end
                        part.CanCollide = false
                    end
                end
            else
                local toReset = {}
                for part, orig in pairs(Store.NoclipParts) do
                    if part and part.Parent then part.CanCollide = orig end
                    table.insert(toReset, part)
                end
                for _, part in ipairs(toReset) do Store.NoclipParts[part] = nil end
            end
        end
    end
end)
RegisterThread(logicThread, "Logic")

UserInputService.JumpRequest:Connect(function()
    if Store.Flags.InfJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.2)
    for part, orig in pairs(Store.NoclipParts) do
        if part and part.Parent then part.CanCollide = orig end
    end
    Store.NoclipParts = setmetatable({}, {__mode = "k"})
    if Store.Flags.Fly then Store.Toggles["Fly"]:Set(false) end
    if Store.Flags.Noclip then Store.Toggles["Noclip"]:Set(false) end
    if Store.Flags.AutoM1 then Store.Toggles["AutoM1"]:Set(false) end
end)
