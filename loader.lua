local GITHUB_RAW = "https://raw.githubusercontent.com/provodada54-cmd/MoonLib/main/"

local function fetch(path)
    local url = GITHUB_RAW .. path .. "?v=" .. tostring(math.floor(tick() * 1000))
    return game:HttpGetAsync(url, true)
end

local MoonLib = loadstring(fetch("MoonLib.lua"))()

local addonFiles = {
    "addons/Config.lua",
    "addons/Keybinds.lua",
    "addons/SwordPreview.lua",
}

for _, path in ipairs(addonFiles) do
    local ok, result = pcall(function()
        local code = fetch(path)
        local addonModule = loadstring(code)()
        if addonModule and type(addonModule._register) == "function" then
            addonModule._register(MoonLib)
        end
    end)
end

return MoonLib
