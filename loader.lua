-- =========================================================================
-- AXAC ULTIMATE v99.0 — LOADER
-- =========================================================================
local repoUser = "masadepanindah327-cpu"
local repoName = "Axac-Stk-V1-Hub"

local function fetch(file)
    local url = string.format("https://raw.githubusercontent.com/%s/%s/main/%s", repoUser, repoName, file)
    local success, res = pcall(function() return game:HttpGet(url) end)
    return success and res or nil
end

local StarterGui = game:GetService("StarterGui")
pcall(function() StarterGui:SetCore("SendNotification", {Title = "AXAC ULTIMATE", Text = "Loading modules...", Duration = 3}) end)

local uiCode = fetch("ui.lua")
local expCode = fetch("exploit.lua")

if not uiCode or not expCode then
    warn("Gagal download script dari GitHub. Cek koneksi lu.")
    return
end

-- Gabungin scriptnya
local masterCode = uiCode .. "\n\n" .. expCode
local func, err = loadstring(masterCode)

if func then
    pcall(func)
    pcall(function() StarterGui:SetCore("SendNotification", {Title = "AXAC ULTIMATE", Text = "Loaded. Use with caution.", Duration = 3}) end)
else
    warn("Syntax Error di script: " .. tostring(err))
    pcall(function() StarterGui:SetCore("SendNotification", {Title = "AXAC ERROR", Text = "Syntax Error: " .. tostring(err), Duration = 5}) end)
end
