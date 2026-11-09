--[[
    AxacHub Loader
    Fetches the hub from GitHub raw and injects it into the current executor.
    Repo: masadepanindah327-cpu/Axac-Stk-V1-Hub
    Target file: main.lua
--]]

local CONFIG = {
    Name        = "AxacHub",
    RawURL      = "https://raw.githubusercontent.com/masadepanindah327-cpu/Axac-Stk-V1-Hub/main/main.lua",
    FallbackURL = "https://raw.githubusercontent.com/masadepanindah327-cpu/Axac-Stk-V1-Hub/refs/heads/main/main.lua",
    LogPrefix   = "[AxacLoader]",
}

--=====================================================================
-- ENVIRONMENT
--=====================================================================
local StarterGui = game:GetService("StarterGui")

local function log(msg)
    warn(string.format("%s %s", CONFIG.LogPrefix, msg))
end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text  = text,
            Duration = 4,
        })
    end)
end

--=====================================================================
-- FETCH
--=====================================================================
local function fetch(url)
    local ok, result = pcall(function()
        if syn and syn.request then
            local res = syn.request({ Url = url, Method = "GET" })
            if res.StatusCode ~= 200 then error("http " .. tostring(res.StatusCode)) end
            return res.Body
        elseif http and http.request then
            local res = http.request({ Url = url, Method = "GET" })
            if res.StatusCode ~= 200 then error("http " .. tostring(res.StatusCode)) end
            return res.Body
        elseif request then
            local res = request({ Url = url, Method = "GET" })
            if res.StatusCode ~= 200 then error("http " .. tostring(res.StatusCode)) end
            return res.Body
        elseif game.HttpGet then
            return game:HttpGet(url, true)
        elseif game.HttpGetAsync then
            return game:HttpGetAsync(url)
        end
        error("no HttpGet available in this executor")
    end)
    if not ok then
        return nil, tostring(result)
    end
    if type(result) ~= "string" or #result < 32 then
        return nil, "empty or truncated response"
    end
    return result
end

--=====================================================================
-- VALIDATE
--=====================================================================
local function validate(source)
    if not source or type(source) ~= "string" then
        return false, "source is not a string"
    end
    if #source < 500 then
        return false, "source too small (" .. #source .. " bytes)"
    end
    if source:find("<html", 1, true) or source:find("<!DOCTYPE", 1, true) then
        return false, "received an HTML page, not raw Lua (URL likely wrong)"
    end
    if source:find("404: Not Found", 1, true) then
        return false, "github returned 404 for the raw file"
    end
    if not source:find("AXAC HUB", 1, true) and not source:find("AxacHub", 1, true) then
        return false, "source does not contain the hub signature"
    end
    return true
end

--=====================================================================
-- EXECUTE
--=====================================================================
local function run(source)
    local fn, err = loadstring(source)
    if not fn then
        return false, "loadstring failed: " .. tostring(err)
    end
    local ok, runErr = pcall(fn)
    if not ok then
        return false, "runtime error: " .. tostring(runErr)
    end
    return true
end

--=====================================================================
-- MAIN
--=====================================================================
local function main()
    log("fetching " .. CONFIG.RawURL)

    local source, fetchErr = fetch(CONFIG.RawURL)
    if not source then
        log("primary fetch failed: " .. tostring(fetchErr))
        log("trying fallback: " .. CONFIG.FallbackURL)
        source, fetchErr = fetch(CONFIG.FallbackURL)
        if not source then
            log("fallback failed: " .. tostring(fetchErr))
            notify(CONFIG.Name, "Loader could not reach GitHub. Check URL or connection.")
            return
        end
    end

    local valid, validErr = validate(source)
    if not valid then
        log("validation failed: " .. tostring(validErr))
        notify(CONFIG.Name, "Hub source invalid: " .. tostring(validErr))
        return
    end

    log(string.format("fetched %d bytes, executing", #source))

    local ok, runErr = run(source)
    if not ok then
        log("execute failed: " .. tostring(runErr))
        notify(CONFIG.Name, "Hub crashed on execute. Check console for details.")
        return
    end

    log("hub loaded successfully")
end

main()
