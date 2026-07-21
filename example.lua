local MoonLib = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/provodada54-cmd/MoonLib/main/loader.lua"))()

local Config = MoonLib:GetAddon("Config")
local Keybinds = MoonLib:GetAddon("Keybinds")
local SwordPreview = MoonLib:GetAddon("SwordPreview")

Config:SetFile("MoonConfig.json")
Config:SetDefaults({
    toggles = {aimbot = false, esp = false, fullbright = true, triggerbot = false},
    settings = {fov = 16, flashPower = 35, triggerDelay = 340, espColor = "Red"},
    binds = {},
    selectedSword = nil,
})
Config:Load()

local Window = MoonLib:CreateWindow({Title = "MOON"})

-- settings UI аддонов (безопасный вызов)
if Config.SetupSettingsUI then Config:SetupSettingsUI(Window) end
if Keybinds.SetupSettingsUI then Keybinds:SetupSettingsUI(Window) end
if SwordPreview.SetupSettingsUI then SwordPreview:SetupSettingsUI(Window) end

-- ================ HOME TAB ================
local HomeTab = Window:AddTab({Name = "Home", Icon = "rbxassetid://7733960981"})

-- Aimbot section (с шестерёнкой и header-тумблером как на скрине)
local aimbotSection = HomeTab:AddSection({
    Name = "Aimbot",
    Side = "Left",
    Toggle = {Default = false, Callback = function(v) print("Aimbot:", v) end},
    OnSettings = function() MoonLib:Notify("Aimbot settings clicked") end,
})

local fovSlider = aimbotSection:AddSlider({Name = "FOV", Min = 0, Max = 360, Default = 16, Decimals = 0})
Config:Bind("settings.fov", fovSlider)

local flashSlider = aimbotSection:AddSlider({Name = "Flash Power", Min = 0, Max = 100, Default = 35, Decimals = 0})
Config:Bind("settings.flashPower", flashSlider)

aimbotSection:AddDropdown({Name = "Target Part", Items = {"Head", "Torso", "Random"}, Default = "Head"})
aimbotSection:AddButton({Name = "Reset", Callback = function() MoonLib:Notify("Reset clicked") end})

-- Triggerbot section
local trigSection = HomeTab:AddSection({
    Name = "Triggerbot",
    Side = "Left",
    Toggle = {Default = false},
})
local delaySlider = trigSection:AddSlider({Name = "Delay", Min = 0, Max = 1000, Default = 340, Decimals = 0})
Config:Bind("settings.triggerDelay", delaySlider)
trigSection:AddButton({Name = "Apply"})

-- ESP section справа
local espSection = HomeTab:AddSection({
    Name = "ESP", Side = "Right",
    Toggle = {Default = false},
    OnSettings = function() MoonLib:Notify("ESP settings clicked") end,
})
espSection:AddDropdown({Name = "Features", Items = {"Box, Name", "Box only", "Name only"}, Default = "Box, Name"})
espSection:AddDropdown({Name = "Shader", Items = {"Upper Corners", "Grid Shader", "Full Box"}, Default = "Grid Shader"})
espSection:AddInput({Name = "Target", Placeholder = "username"})

-- Fullbright
local visSection = HomeTab:AddSection({Name = "Visuals", Side = "Right", Toggle = {Default = true}})
visSection:AddLabel({Text = "Quality settings coming soon..."})

-- ================ SWORDS TAB (с превью через аддон) ================
local SwordsTab = Window:AddTab({Name = "Swords", Icon = "rbxassetid://7734053495"})

local swordSection = SwordsTab:AddSection({Name = "Selected Sword", Side = "Left"})

-- аттачим маленькое превью в секцию (аддон)
local sectionPreview = SwordPreview:AttachSectionPreview(swordSection, {Height = 140})

local selectedLabel = swordSection:AddLabel({Text = "None selected"})

swordSection:AddButton({
    Name = "Choose Sword",
    Callback = function()
        -- собираем список моделей (пример, замени под свои источники)
        local items = {}
        local assets = game.ReplicatedStorage:FindFirstChild("Assets")
        if assets then
            local sw = assets:FindFirstChild("Swords")
            if sw then
                for _, m in pairs(sw:GetChildren()) do if m:IsA("Model") then table.insert(items, m.Name) end end
                table.sort(items)
            end
        end
        if #items == 0 then MoonLib:Notify("No swords found in ReplicatedStorage.Assets.Swords"); return end
        SwordPreview:OpenPicker({
            Title = "Select Sword",
            Items = items,
            OnSelect = function(name)
                Config:Set("selectedSword", name)
                sectionPreview:Set(name)
                selectedLabel:SetText("Selected: " .. tostring(name))
            end,
        })
    end,
})

swordSection:AddButton({
    Name = "Remove",
    Callback = function()
        Config:Set("selectedSword", nil)
        selectedLabel:SetText("None selected")
    end,
})

-- восстановим выбор из конфига
local savedSword = Config:Get("selectedSword")
if savedSword then
    sectionPreview:Set(savedSword)
    selectedLabel:SetText("Selected: " .. tostring(savedSword))
end

-- ================ KEYBINDS ================
local aimbotToggleRef = aimbotSection.HeaderToggle
if aimbotToggleRef then
    Keybinds:Register("aimbot", {Name = "Aimbot", Toggle = aimbotToggleRef})
end
local espToggleRef = espSection.HeaderToggle
if espToggleRef then
    Keybinds:Register("esp", {Name = "ESP", Toggle = espToggleRef})
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