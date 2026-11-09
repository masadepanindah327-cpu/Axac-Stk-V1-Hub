--[[
    AxacHub Loader — Delta Official Safe
    Taruh di: loader.lua (GitHub)
    Tugas: Nge-fetch main.lua dari raw GitHub, lalu eksekusi.
--]]

local CONFIG = {
    Name        = "AxacHub",
    RawURL      = "https://raw.githubusercontent.com/masadepanindah327-cpu/Axac-Stk-V1-Hub/main/main.lua",
    FallbackURL = "https://raw.githubusercontent.com/masadepanindah327-cpu/Axac-Stk-V1-Hub/refs/heads/main/main.lua",
    LogPrefix   = "[AxacLoader]",
}

local StarterGui = game:GetService("StarterGui")

local function log(msg)
    warn(string.format("%s %s", CONFIG.LogPrefix, msg))
end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 5 })
    end)
end

-- 1. FETCH (Gunakan game:HttpGet standar yang paling stabil di Delta)
local function fetch(url)
    local ok, result = pcall(function()
        -- Delta punya game:HttpGet, ini paling aman
        if game.HttpGet then
            return game:HttpGet(url)
        elseif game.HttpGetAsync then
            return game:HttpGetAsync(url)
        elseif typeof(request) == "function" then
            local res = request({ Url = url, Method = "GET" })
            return res.Body
        elseif typeof(http_request) == "function" then
            local res = http_request({ Url = url, Method = "GET" })
            return res.Body
        end
        error("Executor tidak mendukung HTTP request.")
    end)
    
    if not ok then return nil, tostring(result) end
    if type(result) ~= "string" or #result < 100 then
        return nil, "Response kosong atau terlalu pendek."
    end
    return result
end

-- 2. VALIDATE
local function validate(source)
    if type(source) ~= "string" then return false, "Source bukan string." end
    if source:find("<html", 1, true) or source:find("<!DOCTYPE", 1, true) then
        return false, "URL mengembalikan halaman HTML (bukan raw Lua)."
    end
    if source:find("404: Not Found", 1, true) then
        return false, "File tidak ditemukan di GitHub (404)."
    end
    if not source:find("AXAC HUB", 1, true) and not source:find("AxacHub", 1, true) then
        return false, "File tidak mengandung signature AxacHub."
    end
    return true
end

-- 3. RUN
local function run(source)
    local ok, fn = pcall(loadstring, source)
    if not ok then return false, "Loadstring error: " .. tostring(fn) end
    if type(fn) ~= "function" then return false, "Syntax error di main.lua." end
    
    local rok, runErr = pcall(fn)
    if not rok then return false, "Runtime error: " .. tostring(runErr) end
    return true
end

-- 4. MAIN
local function main()
    log("Fetching " .. CONFIG.RawURL)
    local source, err = fetch(CONFIG.RawURL)
    
    if not source then
        log("Primary failed: " .. tostring(err) .. ". Trying fallback...")
        source, err = fetch(CONFIG.FallbackURL)
        if not source then
            log("Fallback failed: " .. tostring(err))
            notify(CONFIG.Name, "Gagal fetch hub.")
            return
        end
    end

    local valid, validErr = validate(source)
    if not valid then
        log("Validate failed: " .. tostring(validErr))
        notify(CONFIG.Name, "Source invalid: " .. tostring(validErr))
        return
    end

    log(string.format("Fetched %d bytes. Executing...", #source))
    local ok, runErr = run(source)
    
    if not ok then
        log("Execute failed: " .. tostring(runErr))
        -- Tampilkan error di notif biar lo gak perlu buka console
        notify(CONFIG.Name, tostring(runErr):sub(1, 100)) 
        return
    end
    
    log("Hub loaded successfully.")
end

main()
