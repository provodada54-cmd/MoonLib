local MoonLib = loadstring(game:HttpGetAsync(
    "https://raw.githubusercontent.com/provodada54-cmd/MoonLib/main/loader.lua?v=" .. tick()
))()

local Config = MoonLib:GetAddon("Config")
local Keybinds = MoonLib:GetAddon("Keybinds")

Config:SetFolder("MoonLib")
Config:SetDefaults({
    toggles = { aimbot = false },
    settings = {
        fov = 90,
        showFov = true,
        fovColor = "Red",
        smoothness = 1.0,
        walkSpeed = 25,
        flySpeed = 150
    },
    binds = {},
})
Config:Load()

local Window = MoonLib:CreateWindow({ Title = "MOON" })
Config:SetupSettingsUI(Window)
Keybinds:SetupSettingsUI(Window)

local HomeTab = Window:AddTab({ Name = "Home" })

local aimbotSection = HomeTab:AddSection({
    Name = "Aimbot",
    Side = "Left",
    Toggle = { Default = false },
    OnSettings = function()
        local popup = MoonLib:CreateSubPopup({
            Title = "Aimbot Settings",
            Width = 320,
            Height = 320
        })
        local showFov = popup:AddToggle({
            Name = "Show FOV",
            Default = Config:Get("settings.showFov", true)
        })
        Config:Bind("settings.showFov", showFov)
        local fovSize = popup:AddSlider({
            Name = "FOV Size",
            Min = 10,
            Max = 500,
            Default = Config:Get("settings.fov", 90),
            Decimals = 0
        })
        Config:Bind("settings.fov", fovSize)
    end,
})

aimbotSection:AddDropdown({
    Name = "Target Part",
    Items = { "Head", "Torso", "Random" },
    Default = "Head"
})
local fovSlider = aimbotSection:AddSlider({
    Name = "FOV",
    Min = 0,
    Max = 360,
    Decimals = 0
})
Config:Bind("settings.fov", fovSlider)

local moveSection = HomeTab:AddSection({ Name = "Movement", Side = "Right" })
local walkSlider = moveSection:AddSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 200,
    Decimals = 0
})
Config:Bind("settings.walkSpeed", walkSlider)
local flySlider = moveSection:AddSlider({
    Name = "Fly Speed",
    Min = 50,
    Max = 1000,
    Decimals = 0
})
Config:Bind("settings.flySpeed", flySlider)

local aimbotToggle = aimbotSection.HeaderToggle
if aimbotToggle then
    Keybinds:Register("aimbot", {
        Name = "Aimbot",
        Toggle = aimbotToggle
    })
end

Keybinds:SetAllBinds(Config:Get("binds", {}))
Keybinds:OnChanged(function()
    Config:Set("binds", Keybinds:GetAllBinds())
end)
Keybinds:CreatePanel(Window:GetScreenGui())
Keybinds:StartListening()

game:GetService("RunService").Heartbeat:Connect(function()
    Keybinds:UpdateStates()
end)

Config:ApplyAll()
MoonLib:Notify("MOON loaded")
