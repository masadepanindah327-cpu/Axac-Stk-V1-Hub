-- =========================================================================
-- AXAC HUB — V19.0 (Curtain Splash, Smooth Orb UI)
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

-- 3. STATE
local Store = {
    Flags = {}, Settings = { CustomSpeed = 32, FlySpeed = 50, FarmRange = 150, FarmRate = 0.2 },
    Toggles = {}, Sliders = {}, Connections = {}, Threads = {},
    NoclipParts = setmetatable({}, {__mode = "k"}), Blacklist = setmetatable({}, {__mode = "k"}),
    NotifGen = 0, LastFarmWarn = 0, LastTargetFound = false, IsMenuOpen = false,
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
-- 4. SPLASH SCREEN (CURTAIN ANIMATION)
-- =========================================================================
local Splash = Make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Canvas, BorderSizePixel = 0, ZIndex = 200 }, ScreenGui)

-- Area Teks Splash
local SplashContainer = Make("Frame", {
    Size = UDim2.fromOffset(300, 100), Position = UDim2.new(0.5, -150, 0.5, -50),
    BackgroundTransparency = 1, ZIndex = 201
}, Splash)

local SplashText = Make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1, Text = "AXAC", Font = Enum.Font.Garamond, TextSize = 56,
    TextColor3 = Theme.Text, TextTransparency = 1,
}, SplashContainer)

local SplashSub = Make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 65),
    BackgroundTransparency = 1, Text = "STK HUB", Font = Enum.Font.Code, TextSize = 12,
    TextColor3 = Theme.Gold, TextTransparency = 1,
}, SplashContainer)

local SplashLine = Make("Frame", {
    Size = UDim2.fromOffset(0, 1), Position = UDim2.new(0.5, 0, 0, 58),
    BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
}, SplashContainer)

-- Tirai (Curtain) Atas & Bawah
local CurtainTop = Make("Frame", { Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Theme.Canvas, BorderSizePixel = 0, ZIndex = 202 }, Splash)
local CurtainBot = Make("Frame", { Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Theme.Canvas, BorderSizePixel = 0, ZIndex = 202 }, Splash)

task.spawn(function()
    task.wait(0.1)
    -- 1. Fade in teks & garis
    TweenService:Create(SplashText, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
    TweenService:Create(SplashSub, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
    TweenService:Create(SplashLine, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(200, 1) }):Play()
    
    task.wait(1.5) -- Tahan splash sebentar
    
    -- 2. Animasi tutup (Curtain): Tirai atas & bawah maju ke tengah
    TweenService:Create(SplashText, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
    TweenService:Create(SplashSub, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
    TweenService:Create(SplashLine, TweenInfo.new(0.3), { Size = UDim2.fromOffset(0, 1) }):Play()
    
    TweenService:Create(CurtainTop, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0, 0, 0.5, 0) }):Play()
    TweenService:Create(CurtainBot, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0, 0, 0.5, 0) }):Play()
    
    task.wait(0.4)
    Splash:Destroy()
    
    -- 3. Buka UI utama & Orb
    Store.IsMenuOpen = true
    if _G.AxacOpenMenu then _G.AxacOpenMenu() end
end)

-- =========================================================================
-- 5. UI BUILDER (ANTI-SLOP)
-- =========================================================================
local MainFrame = Make("Frame", { 
    Size = UDim2.fromOffset(604, 412), Position = UDim2.new(0.5, -302, 0.5, -150), -- Mulai dari bawah dikit
    BackgroundColor3 = Theme.Canvas, BorderSizePixel = 0, ClipsDescendants = false, 
    BackgroundTransparency = 1, ZIndex = 5, Visible = false 
}, ScreenGui)
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
Make("TextLabel", { BackgroundTransparency = 1, Text = "v3.1.0 · build 4192", Font = Enum.Font.Code, TextSize = 11, TextColor3 = Theme.Gold, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 150, 0, 21), Size = UDim2.new(0, 150, 0, 20) }, TitleBar)

local CloseBtn = Make("TextButton", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -34, 0, 31), BackgroundTransparency = 1, Text = "X", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Subtext }, TitleBar)
CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = Theme.Accent end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = Theme.Subtext end)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local Sidebar = Make("Frame", { Size = UDim2.new(0, 155, 1, -6), Position = UDim2.new(0, 0, 0, 52), BackgroundColor3 = Theme.Canvas, BorderSizePixel = 0 }, MainFrame)

local TabData = {
    { Name = "Main", Prefix = "·" }, { Name = "Farm", Prefix = "··" }, { Name = "Killer", Prefix = "··" },
    { Name = "Survivor", Prefix = "··" }, { Name = "ESP", Prefix = "·" }, { Name = "Player", Prefix = "·" },
    { Name = "Config", Prefix = "·" }
}
local ActiveTab = "Main"
local TabElements = {}

for i, data in ipairs(TabData) do
    local TabBtn = Make("TextButton", { Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, (i - 1) * 36), BackgroundColor3 = Theme.Canvas, BorderSizePixel = 0, Text = "  " .. data.Name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Subtext, TextXAlignment = Enum.TextXAlignment.Left }, Sidebar)
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

-- =========================================================================
-- 6. FLOATING ORB (SMOOTH TRANSITION)
-- =========================================================================
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
        MainFrame.Position = UDim2.new(0.5, -302, 0.5, -150) -- Posisi awal agak ke bawah
        -- Animasi naik & pudar masuk
        TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { BackgroundTransparency = 0, Position = UDim2.new(0.5, -302, 0.5, -206) }):Play()
    else
        -- Animasi turun & pudar keluar
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
-- 8. FEATURE LOGIC & BACKGROUND LOOPS (Sama dengan V18)
-- =========================================================================
local KILLER_TOOLS = {["Knife"]=true, ["Axe"]=true, ["Bat"]=true, ["Cleaver"]=true, ["Scythe"]=true}
local function checkIsKiller(p)
    if not p or not p.Character then return false end
    if p:FindFirstChild("Role") and tostring(p.Role.Value):lower():find("killer") then return true end
    local charTool = p.Character:FindFirstChildWhichIsA("Tool")
    if charTool and (KILLER_TOOLS[charTool.Name] or charTool.Name:lower():find("knife") or charTool.Name:lower():find("weapon")) then return true end
    if p:FindFirstChild("Backpack") then
        local backTool = p.Backpack:FindFirstChildWhichIsA("Tool")
        if backTool and (KILLER_TOOLS[backTool.Name] or backTool.Name:lower():find("knife") or backTool.Name:lower():find("weapon")) then return true end
    end
    return false
end
local function getRootPart() local char = LocalPlayer.Character; return char and char:FindFirstChild("HumanoidRootPart") end
local function isPlayerDowned(char)
    if not char then return true end
    local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return true end
    local bleed = hrp:FindFirstChild("BleedOutHealth")
    return (bleed and bleed.Enabled) or hum.PlatformStand or (hum.Health <= 0)
end

local ESPFolder = Instance.new("Folder"); ESPFolder.Name = "AxacESPFolder"; ESPFolder.Parent = ScreenGui

local MainPage = CreatePage("Main")
AddSection(MainPage, "Round pressure")
AddToggle(MainPage, "AutoRevive", "Instant Auto Revive", false, function(v)
    Store.Flags.AutoRevive = v
    if v then
        local thread = task.spawn(function()
            while Store.Flags.AutoRevive do
                pcall(function()
                    if isPlayerDowned(LocalPlayer.Character) then return end
                    local myRoot = getRootPart()
                    if myRoot then
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Character and isPlayerDowned(p.Character) and not checkIsKiller(p) then
                                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                                if hrp and (myRoot.Position - hrp.Position).Magnitude < 15 then
                                    myRoot.CFrame = hrp.CFrame + Vector3.new(0, 2, 0); task.wait(0.05)
                                    for _, obj in pairs(p.Character:GetDescendants()) do if obj:IsA("ProximityPrompt") then fireproximityprompt(obj) end end
                                end
                            end
                        end
                    end
                end); task.wait(0.1)
            end
        end)
        RegisterThread(thread, "AutoRevive")
    end
end)
AddToggle(MainPage, "KillerAlert", "Killer Proximity Alert", false, function(v)
    Store.Flags.KillerAlert = v
    if v then
        local thread = task.spawn(function()
            local lastAlert = 0
            while Store.Flags.KillerAlert do
                pcall(function()
                    local myRoot = getRootPart()
                    if myRoot then
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and checkIsKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                                local dist = math.floor((myRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude)
                                if dist <= 75 and (tick() - lastAlert > 4) then
                                    lastAlert = tick(); ShowNotif("KILLER: " .. p.Name .. " (" .. dist .. "m)")
                                end
                            end
                        end
                    end
                end); task.wait(0.5)
            end
        end)
        RegisterThread(thread, "KillerAlert")
    end
end)
AddToggle(MainPage, "AntiTrap", "Anti Trap", false, function(v) Store.Flags.AntiTrap = v end)
AddToggle(MainPage, "AntiAFK", "Anti AFK", false, function(v)
    Store.Flags.AntiAFK = v
    if v then
        local thread = task.spawn(function()
            while Store.Flags.AntiAFK do
                pcall(function()
                    if VirtualInputManager then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game); task.wait(0.1)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                    end
                end)
                for _ = 1, 60 do if not Store.Flags.AntiAFK then return end task.wait(1) end
            end
        end)
        RegisterThread(thread, "AntiAFK")
    end
end)

local FarmPage = CreatePage("Farm")
AddSection(FarmPage, "Pickup")
AddToggle(FarmPage, "AutoLoot", "Auto Candy", false, function(v) Store.Flags.AutoLoot = v end)
AddToggle(FarmPage, "AutoBalloon", "Auto Balloon", false, function(v) Store.Flags.AutoBalloon = v end)
AddSlider(FarmPage, "FarmRange", "Max Range", 50, 250, 150, false, function(v) Store.Settings.FarmRange = v end)
AddSlider(FarmPage, "FarmRate", "Rate (sec)", 0.05, 2.0, 0.2, true, function(v) Store.Settings.FarmRate = v end)

local farmThread = task.spawn(function()
    local lastHadTarget = false
    while true do
        local rate = Store.Settings.FarmRate
        if not rate or rate <= 0 then rate = 0.2 end
        task.wait(rate)

        if not Store.Flags.AutoLoot and not Store.Flags.AutoBalloon then continue end
        if isPlayerDowned(LocalPlayer.Character) then continue end

        local myRoot = getRootPart()
        if not myRoot then continue end

        local names = {}
        if Store.Flags.AutoLoot then table.insert(names, "candy"); table.insert(names, "sweet"); table.insert(names, "treat"); table.insert(names, "present") end
        if Store.Flags.AutoBalloon then table.insert(names, "balloon") end

        local nearest, minDist = nil, math.huge
        local now = tick()

        for _, obj in pairs(workspace:GetDescendants()) do
            if not obj.Parent then continue end
            local match = false
            for _, name in ipairs(names) do if obj.Name:lower():find(name) then match = true; break end end
            if not match then continue end

            local targetPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or (obj:IsA("BasePart") and obj)
            if not targetPart then continue end

            if Store.Blacklist[obj] and Store.Blacklist[obj] > now then continue end

            local d = (myRoot.Position - targetPart.Position).Magnitude
            if d > 5 and d < Store.Settings.FarmRange and d < minDist then
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then minDist = d; nearest = { obj = obj, part = targetPart, prompt = prompt, type = obj.Name:lower():find("balloon") and "balloon" or "candy" } end
            end
        end

        if nearest then
            lastHadTarget = true
            local offset = nearest.type == "balloon" and Vector3.new(0, 0, 0) or Vector3.new(0, 2, 0)
            myRoot.CFrame = CFrame.new(nearest.part.Position + offset)
            task.wait(0.15)
            for i = 1, 3 do fireproximityprompt(nearest.prompt); task.wait(0.2) end
            task.wait(0.3)
            if nearest.obj.Parent then Store.Blacklist[nearest.obj] = tick() + 5 end
        else
            if lastHadTarget and tick() - Store.LastFarmWarn > 60 then
                Store.LastFarmWarn = tick(); ShowNotif("[Farm] No target found.")
            end
            lastHadTarget = false
        end
    end
end)
RegisterThread(farmThread, "Farm")

local KillerPage = CreatePage("Killer")
AddSection(KillerPage, "Against the knife")
AddToggle(KillerPage, "AutoM1", "Auto M1 (Click Spam)", false, function(v)
    Store.Flags.AutoM1 = v
    if v then
        local thread = task.spawn(function()
            while Store.Flags.AutoM1 do
                pcall(function()
                    if not checkIsKiller(LocalPlayer) then return end
                    local target = nil
                    local myChar = LocalPlayer.Character
                    if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                        local closestDist = math.huge
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Character and not checkIsKiller(p) and p.Character:FindFirstChild("HumanoidRootPart") then
                                local d = (myChar.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                                if d < 15 and d < closestDist then closestDist = d; target = p.Character.HumanoidRootPart end
                            end
                        end
                    end
                    local cam = workspace.CurrentCamera
                    if target and cam then
                        local screenPos, onScreen = cam:WorldToViewportPoint(target.Position)
                        if onScreen then
                            if VirtualInputManager then
                                VirtualInputManager:SendMouseButtonEvent(math.floor(screenPos.X), math.floor(screenPos.Y), 0, true, game, 1)
                                task.wait(0.05)
                                VirtualInputManager:SendMouseButtonEvent(math.floor(screenPos.X), math.floor(screenPos.Y), 0, false, game, 1)
                            end
                        end
                    end
                end); task.wait(0.05)
            end
        end)
        RegisterThread(thread, "AutoM1")
    end
end)

local SurvivorPage = CreatePage("Survivor")
AddSection(SurvivorPage, "If you go down")
AddToggle(SurvivorPage, "AutoCrawl", "Auto Crawl to Helper", false, function(v)
    Store.Flags.AutoCrawl = v
    if v then
        local thread = task.spawn(function()
            local last = 0
            while Store.Flags.AutoCrawl do
                pcall(function()
                    if isPlayerDowned(LocalPlayer.Character) and (tick() - last > 5) then
                        local myRoot = getRootPart()
                        if myRoot then
                            local targetPos = nil
                            for _, p in pairs(Players:GetPlayers()) do
                                if p ~= LocalPlayer and p.Character and not isPlayerDowned(p.Character) and not checkIsKiller(p) then
                                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                                    if hrp then targetPos = hrp; break end
                                end
                            end
                            if targetPos then myRoot.CFrame = targetPos.CFrame + Vector3.new(0, 0, 5) end
                            last = tick()
                        end
                    end
                end); task.wait(0.5)
            end
        end)
        RegisterThread(thread, "AutoCrawl")
    end
end)
AddToggle(SurvivorPage, "SafeMode", "Escape killer (Blink)", false, function(v)
    Store.Flags.SafeMode = v
    if v then
        local thread = task.spawn(function()
            while Store.Flags.SafeMode do
                pcall(function()
                    local myRoot = getRootPart()
                    if myRoot then
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and checkIsKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                                if (myRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude < 30 then
                                    myRoot.CFrame = myRoot.CFrame + Vector3.new(math.random(-50, 50), 15, math.random(-50, 50)); task.wait(1)
                                end
                            end
                        end
                    end
                end); task.wait(0.3)
            end
        end)
        RegisterThread(thread, "SafeMode")
    end
end)

local ESPPage = CreatePage("ESP")
AddSection(ESPPage, "See the map")
AddToggle(ESPPage, "ESP_Active", "Player Highlight", false, function(v) Store.Flags.ESP_Active = v; if not v then ESPFolder:ClearAllChildren() end end)
AddToggle(ESPPage, "Tracer_Killer", "Tracer to Killer", false, function(v) Store.Flags.Tracer_Killer = v end)
AddToggle(ESPPage, "ESP_Dist", "Show Distance", false, function(v) Store.Flags.ESP_Dist = v end)

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
        local hum = getRootPart() and getRootPart().Parent:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
end)
AddToggle(PlayerPage, "Fly", "Fly", false, function(v)
    Store.Flags.Fly = v
    local hrp = getRootPart()
    if not hrp then return end
    if v then
        local lv = Instance.new("LinearVelocity", hrp); lv.Name = "AxacFly"; lv.MaxForce = math.huge; lv.Velocity = Vector3.zero
        local ao = Instance.new("AlignOrientation", hrp); ao.Name = "AxacFlyAlign"; ao.MaxTorque = math.huge; ao.Responsiveness = 200
        local att = Instance.new("Attachment", hrp); att.Name = "AxacAttach"
        lv.Attachment0 = att; ao.Attachment0 = att
        if Store.Connections.Fly then Store.Connections.Fly:Disconnect() end
        Store.Connections.Fly = RunService.RenderStepped:Connect(function()
            if not Store.Flags.Fly or not hrp.Parent then
                if Store.Connections.Fly then Store.Connections.Fly:Disconnect() end
                for _, n in ipairs({"AxacFly", "AxacFlyAlign", "AxacAttach"}) do local o = hrp:FindFirstChild(n); if o then o:Destroy() end end
                return
            end
            local cam = workspace.CurrentCamera
            if not cam then return end
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end
            lv.VectorVelocity = dir.Magnitude > 0 and (dir.Unit * Store.Settings.FlySpeed) or Vector3.zero
            ao.CFrame = cam.CFrame
        end)
    end
end)
AddSlider(PlayerPage, "FlySpeed", "Fly Speed", 10, 300, 50, false, function(v) Store.Settings.FlySpeed = v end)
AddToggle(PlayerPage, "Noclip", "Noclip", false, function(v) Store.Flags.Noclip = v end)
AddToggle(PlayerPage, "InfJump", "Infinite Jump", false, function(v) Store.Flags.InfJump = v end)

local ConfigPage = CreatePage("Config")
AddSection(ConfigPage, "Last rites")
AddButton(ConfigPage, "Rejoin Server", function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end)
AddButton(ConfigPage, "Reset All Flags", function()
    for k in pairs(Store.Flags) do Store.Flags[k] = false end
    for _, toggle in pairs(Store.Toggles) do toggle:Set(false) end
    ShowNotif("All flags disabled.")
end)
AddButton(ConfigPage, "Save Config", function()
    local data = {}
    for k, v in pairs(Store.Flags) do data[k] = v end
    for k, v in pairs(Store.Settings) do data[k] = v end
    pcall(function() writefile("axac_config.json", game:GetService("HttpService"):JSONEncode(data)) end)
    ShowNotif("Config saved.")
end)
AddButton(ConfigPage, "Load Config", function()
    local success, content = pcall(function() return readfile("axac_config.json") end)
    if success and content then
        local data = game:GetService("HttpService"):JSONDecode(content)
        for k, v in pairs(data) do
            if Store.Flags[k] ~= nil then Store.Flags[k] = v; if Store.Toggles[k] then Store.Toggles[k]:Set(v) end end
            if Store.Settings[k] ~= nil then Store.Settings[k] = v; if Store.Sliders[k] then Store.Sliders[k]:Set(v) end end
        end
        ShowNotif("Config loaded.")
    end
end)
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
                        if not Store.NoclipParts[part] then
                            Store.NoclipParts[part] = part.CanCollide
                        end
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

local espThread = task.spawn(function()
    while task.wait(0.1) do
        if Store.Flags.ESP_Active or Store.Flags.Tracer_Killer or Store.Flags.ESP_Dist then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local isKiller = checkIsKiller(p)
                    local myRoot = getRootPart()
                    local dist = myRoot and math.floor((myRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude) or 0

                    if Store.Flags.ESP_Active then
                        local hl = ESPFolder:FindFirstChild("Player_" .. p.Name)
                        if not hl then hl = Instance.new("Highlight"); hl.Name = "Player_" .. p.Name; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = ESPFolder end
                        if hl.Adornee ~= p.Character then hl.Adornee = p.Character end
                        hl.FillColor = isKiller and Theme.Accent or Color3.fromRGB(0, 120, 255)
                        hl.FillTransparency = isKiller and 0.2 or 0.5
                    end

                    if Store.Flags.Tracer_Killer and isKiller and myRoot then
                        local beam = ESPFolder:FindFirstChild("Tracer_" .. p.Name)
                        if not beam then
                            local a0 = Instance.new("Attachment", myRoot); local a1 = Instance.new("Attachment", p.Character.HumanoidRootPart)
                            beam = Instance.new("Beam"); beam.Name = "Tracer_" .. p.Name; beam.Attachment0 = a0; beam.Attachment1 = a1
                            beam.Width0 = 0.12; beam.Width1 = 0.12; beam.Color = ColorSequence.new(Theme.Accent); beam.FaceCamera = true; beam.Parent = ESPFolder
                        end
                    end

                    if Store.Flags.ESP_Dist then
                        local bbg = ESPFolder:FindFirstChild("Tag_" .. p.Name)
                        if not bbg then
                            bbg = Instance.new("BillboardGui"); bbg.Name = "Tag_" .. p.Name; bbg.Size = UDim2.new(0, 150, 0, 30); bbg.StudsOffset = Vector3.new(0, 2.5, 0); bbg.AlwaysOnTop = true
                            local label = Instance.new("TextLabel", bbg); label.Name = "Label"; label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamBold; label.TextSize = 12; label.TextColor3 = isKiller and Theme.Accent or Color3.fromRGB(100, 200, 255); label.Parent = bbg
                            bbg.Parent = ESPFolder
                        end
                        if bbg.Adornee ~= p.Character:FindFirstChild("Head") and bbg.Adornee ~= p.Character.HumanoidRootPart then bbg.Adornee = p.Character:FindFirstChild("Head") or p.Character.HumanoidRootPart end
                        local lbl = bbg:FindFirstChild("Label")
                        if lbl then lbl.Text = p.Name .. " [" .. tostring(dist) .. "m]" end
                    end
                else
                    local hl = ESPFolder:FindFirstChild("Player_" .. p.Name); if hl then hl:Destroy() end
                    local beam = ESPFolder:FindFirstChild("Tracer_" .. p.Name); if beam then beam:Destroy() end
                    local bbg = ESPFolder:FindFirstChild("Tag_" .. p.Name); if bbg then bbg:Destroy() end
                end
            end
        end
    end
end)
RegisterThread(espThread, "ESP")

local antiTrapThread = task.spawn(function()
    while task.wait(1) do
        if Store.Flags.AntiTrap then
            for _, obj in pairs(workspace:GetChildren()) do
                if obj.Name == "Trap" and obj:FindFirstChild("HitBox") and obj.HitBox:IsDescendantOf(workspace) then obj.HitBox:Destroy() end
            end
        end
    end
end)
RegisterThread(antiTrapThread, "AntiTrap")

Store.Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.2)
    for part, orig in pairs(Store.NoclipParts) do
        if part and part.Parent then part.CanCollide = orig end
    end
    Store.NoclipParts = setmetatable({}, {__mode = "k"})
    if Store.Connections.Fly then
        pcall(function() Store.Connections.Fly:Disconnect() end)
        Store.Connections.Fly = nil
    end
    if Store.Flags.Fly then Store.Toggles["Fly"]:Set(false) end
    if Store.Flags.Noclip then Store.Toggles["Noclip"]:Set(false) end
    if Store.Flags.AutoM1 then Store.Toggles["AutoM1"]:Set(false) end
    if Store.Flags.AutoCrawl then Store.Toggles["AutoCrawl"]:Set(false) end
    if Store.Flags.SafeMode then Store.Toggles["SafeMode"]:Set(false) end
    for _, obj in pairs(ESPFolder:GetChildren()) do obj:Destroy() end
end)

UserInputService.JumpRequest:Connect(function()
    if Store.Flags.InfJump and LocalPlayer.Character then
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
