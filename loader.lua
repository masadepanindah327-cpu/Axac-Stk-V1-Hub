local URL = "https://raw.githubusercontent.com/masadepanindah327-cpu/Axac-Stk-V1-Hub/main/main.lua"
local ok, src = pcall(function() return game:HttpGet(URL) end)
if ok and src and #src > 100 then
    loadstring(src)()
else
    warn("[AXAC] Gagal load. Cek URL atau koneksi.")
end
