local GITHUB_RAW = "https://raw.githubusercontent.com/provodada54-cmd/MoonLib/main/"

local function httpGet(url)
    local ok, result = pcall(function() return game:HttpGetAsync(url) end)
    if ok and result then return result end
    if request then
        ok, result = pcall(function() return request({Url = url, Method = "GET"}).Body end)
        if ok and result then return result end
    end
    if syn and syn.request then
        ok, result = pcall(function() return syn.request({Url = url, Method = "GET"}).Body end)
        if ok and result then return result end
    end
    error("Failed to fetch: " .. url)
end

local function load(path)
    local src = httpGet(GITHUB_RAW .. path)
    local fn, err = loadstring(src, path)
    if not fn then error("Load error in "..path..": "..tostring(err)) end
    return fn()
end

local MoonLib = load("MoonLib.lua")

-- регистрируем аддоны
local addons = {"Config", "Keybinds", "SwordPreview"}
for _, name in ipairs(addons) do
    local ok, err = pcall(function()
        local addon = load("addons/" .. name .. ".lua")
        if addon and addon._register then
            addon._register(MoonLib)
        end
    end)
    if not ok then warn("[MoonLib] Failed to load addon "..name..": "..tostring(err)) end
end

return MoonLib