local MoonLib = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/provodada54-cmd/moonlib/main/loader.lua"))()

local Config = MoonLib:GetAddon("Config")
local Keybinds = MoonLib:GetAddon("Keybinds")
local SwordPreview = MoonLib:GetAddon("SwordPreview")

Config:SetFolder("MoonLib")
Config:SetDefaults({
    toggles = {aimbot = false, esp = false},
    settings = {
        fov = 16, walkSpeed = 25, flySpeed = 150,
        showFov = true, fovColor = "Red", smoothness = 1.0,
    },
    binds = {},
})
Config:Load()

local Window = MoonLib:CreateWindow({Title = "MOON"})

if Config.SetupSettingsUI then Config:SetupSettingsUI(Window) end
if Keybinds.SetupSettingsUI then Keybinds:SetupSettingsUI(Window) end

local HomeTab = Window:AddTab({Name = "Home"})

local aimbotSection = HomeTab:AddSection({
    Name = "Aimbot", Side = "Left",
    Toggle = {Default = false},
    OnSettings = function()
        local popup = MoonLib:CreateSubPopup({Title = "Aimbot Settings", Width = 320, Height = 320})
        local showFov = popup:AddToggle({Name = "Show FOV", Default = Config:Get("settings.showFov", true)})
        Config:Bind("settings.showFov", showFov)
        local fovSize = popup:AddSlider({Name = "FOV Size", Min = 10, Max = 500, Default = Config:Get("settings.fov", 16), Decimals = 0})
        Config:Bind("settings.fov", fovSize)
        local smoothness = popup:AddSlider({Name = "Smoothness", Min = 0.1, Max = 5, Default = Config:Get("settings.smoothness", 1.0), Decimals = 1})
        Config:Bind("settings.smoothness", smoothness)
        local color = popup:AddDropdown({Name = "FOV Color", Items = {"Red", "Green", "Blue", "Yellow", "White"}, Default = Config:Get("settings.fovColor", "Red")})
        Config:Bind("settings.fovColor", color)
    end,
})
local fovSlider = aimbotSection:AddSlider({Name = "FOV", Min = 0, Max = 360, Decimals = 0})
Config:Bind("settings.fov", fovSlider)
aimbotSection:AddDropdown({Name = "Target Part", Items = {"Head", "Torso", "Random"}, Default = "Head"})

local moveSection = HomeTab:AddSection({Name = "Movement", Side = "Right"})
local walkSlider = moveSection:AddSlider({Name = "Walk Speed", Min = 16, Max = 200, Decimals = 0})
Config:Bind("settings.walkSpeed", walkSlider)
local flySlider = moveSection:AddSlider({Name = "Fly Speed", Min = 50, Max = 1000, Decimals = 0})
Config:Bind("settings.flySpeed", flySlider)

local aimbotToggle = aimbotSection.HeaderToggle
if aimbotToggle then
    Keybinds:Register("aimbot", {Name = "Aimbot", Toggle = aimbotToggle})
end

Keybinds:SetAllBinds(Config:Get("binds", {}))
Keybinds:OnChanged(function() Config:Set("binds", Keybinds:GetAllBinds()) end)
Keybinds:CreatePanel(Window:GetScreenGui())
Keybinds:StartListening()

game:GetService("RunService").Heartbeat:Connect(function()
    Keybinds:UpdateStates()
end)

Config:ApplyAll()
MoonLib:Notify("MOON loaded")
