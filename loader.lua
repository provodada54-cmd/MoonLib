local GITHUB_USER = "provodada54-cmd"
local GITHUB_REPO = "MoonLib"
local GITHUB_BRANCH = "main"
local GITHUB_RAW = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/" .. GITHUB_BRANCH .. "/"

local function bust(url)
    local sep = url:find("?", 1, true) and "&" or "?"
    return url .. sep .. "v=" .. tostring(math.floor(tick() * 1000))
end

local function httpGet(url)
    url = bust(url)
    local ok, result = pcall(function() return game:HttpGetAsync(url, true) end)
    if ok and result then return result end
    if request then
        ok, result = pcall(function() return request({Url = url, Method = "GET", Headers = {["Cache-Control"] = "no-cache", ["Pragma"] = "no-cache"}}).Body end)
        if ok and result then return result end
    end
    if syn and syn.request then
        ok, result = pcall(function() return syn.request({Url = url, Method = "GET", Headers = {["Cache-Control"] = "no-cache"}}).Body end)
        if ok and result then return result end
    end
    error("Failed to fetch: " .. url)
end

local function load(path)
    local src = httpGet(GITHUB_RAW .. path)
    local fn, err = loadstring(src, path)
    if not fn then error("Load error in " .. path .. ": " .. tostring(err)) end
    return fn()
end

local MoonLib = load("MoonLib.lua")

local addons = {"Config", "Keybinds", "SwordPreview"}
for _, name in ipairs(addons) do
    local ok, err = pcall(function()
        local addon = load("addons/" .. name .. ".lua")
        if addon and addon._register then
            addon._register(MoonLib)
        end
    end)
    if not ok then warn("[MoonLib] Failed to load addon " .. name .. ": " .. tostring(err)) end
end

return MoonLib
