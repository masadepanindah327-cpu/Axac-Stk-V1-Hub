-- =========================================================================
-- AXAC HUB - GITHUB RAW LOADER
-- =========================================================================

local RAW_URL = "https://raw.githubusercontent.com/masadepanindah327-cpu/Axac-Stk-V1-Hub/refs/heads/main/main.lua"

local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AxacLoaderGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = (gethui and gethui()) or CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 300, 0, 100)
Main.Position = UDim2.new(0.5, -150, 0.5, -50)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner", Main)
Corner.CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(250, 204, 21)
Stroke.Thickness = 1.5

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "AXAC LOADER"
Title.TextColor3 = Color3.fromRGB(250, 204, 21)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18
Title.Parent = Main

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0, 45)
Status.BackgroundTransparency = 1
Status.Text = "Connecting to GitHub..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.Font = Enum.Font.GothamMedium
Status.TextSize = 12
Status.Parent = Main

local BarBG = Instance.new("Frame")
BarBG.Size = UDim2.new(0.8, 0, 0, 4)
BarBG.Position = UDim2.new(0.1, 0, 0, 80)
BarBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
BarBG.BorderSizePixel = 0
BarBG.Parent = Main

local UICornerBar = Instance.new("UICorner", BarBG)
UICornerBar.CornerRadius = UDim.new(0, 2)

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(250, 204, 21)
BarFill.BorderSizePixel = 0
BarFill.Parent = BarBG

local UICornerFill = Instance.new("UICorner", BarFill)
UICornerFill.CornerRadius = UDim.new(0, 2)

local function SetStatus(txt)
    Status.Text = txt
end

local function SetProgress(p)
    BarFill:TweenSize(UDim2.new(p, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
end

task.spawn(function()
    SetProgress(0.3)
    SetStatus("Fetching script...")
    task.wait(0.3)

    local success, source = pcall(function()
        return game:HttpGet(RAW_URL, true)
    end)

    if not success or not source or #source == 0 then
        SetProgress(0)
        SetStatus("Failed to fetch. Check URL/connection.")
        task.wait(3)
        ScreenGui:Destroy()
        return
    end

    SetProgress(0.7)
    SetStatus("Compiling script...")
    task.wait(0.3)

    local compiled, err = pcall(function()
        local f = loadstring(source)
        if not f then error("Compilation failed.") end
        f()
    end)

    SetProgress(1)
    if compiled then
        SetStatus("Loaded!")
        task.wait(0.5)
    else
        SetStatus("Execution error.")
        warn("[Axac Loader] " .. tostring(err))
        task.wait(2)
    end

    ScreenGui:Destroy()
end)
