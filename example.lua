local MoonLib = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/provodada54-cmd/MoonLib/main/loader.lua"))()

local Config = MoonLib:GetAddon("Config")
local Keybinds = MoonLib:GetAddon("Keybinds")
local SwordPreview = MoonLib:GetAddon("SwordPreview")

Config:SetFolder("MoonLib")
Config:SetDefaults({
    toggles = {aimbot = false, esp = false, fullbright = true},
    settings = {fov = 16, walkSpeed = 25, flySpeed = 150},
    binds = {},
    selectedSword = nil,
})
Config:Load()

local Window = MoonLib:CreateWindow({Title = "MOON"})

if Config.SetupSettingsUI then Config:SetupSettingsUI(Window) end
if Keybinds.SetupSettingsUI then Keybinds:SetupSettingsUI(Window) end
if SwordPreview.SetupSettingsUI then SwordPreview:SetupSettingsUI(Window) end

local HomeTab = Window:AddTab({Name = "Home"})

local aimbotSection = HomeTab:AddSection({
    Name = "Aimbot", Side = "Left",
    Toggle = {Default = false},
    OnSettings = function() MoonLib:Notify("Aimbot settings") end,
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
