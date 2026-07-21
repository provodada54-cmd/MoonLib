local Keybinds = {}
Keybinds._binds = {}
Keybinds._panel = nil
Keybinds._panelList = nil
Keybinds._panelVisible = true
Keybinds._listening = false
Keybinds._onChangedCallbacks = {}
Keybinds._moonlib = nil

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

function Keybinds:Register(id, opts)
    self._binds[id] = {
        Name = opts.Name or id,
        Key = opts.Default or nil,
        Toggle = opts.Toggle or nil,
        Callback = opts.Callback or nil,
        Active = false,
    }
    self:_rebuildPanel()
end

function Keybinds:SetKey(id, keyName)
    if self._binds[id] then
        self._binds[id].Key = keyName
        self:_fireChanged()
        self:_rebuildPanel()
    end
end

function Keybinds:GetAllBinds()
    local result = {}
    for id, bind in pairs(self._binds) do
        result[id] = bind.Key
    end
    return result
end

function Keybinds:SetAllBinds(t)
    if type(t) ~= "table" then return end
    for id, key in pairs(t) do
        if self._binds[id] then
            self._binds[id].Key = key
        end
    end
    self:_rebuildPanel()
end

function Keybinds:OnChanged(cb)
    table.insert(self._onChangedCallbacks, cb)
end

function Keybinds:_fireChanged()
    for _, cb in ipairs(self._onChangedCallbacks) do cb() end
end

function Keybinds:CreatePanel(screenGui)
    if not self._moonlib then return end
    local T = self._moonlib._theme

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 210, 0, 0)
    panel.AutomaticSize = Enum.AutomaticSize.Y
    panel.Position = UDim2.new(0, 16, 1, -220)
    panel.BackgroundColor3 = T.bg
    panel.BackgroundTransparency = 0.05
    panel.ZIndex = 40
    panel.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = T.border
    stroke.Thickness = 1
    stroke.Transparency = 0.4
    stroke.Parent = panel

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = panel

    local title = Instance.new("TextLabel")
    title.Text = "Keybinds"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = T.text
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 22)
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.ZIndex = 41
    title.LayoutOrder = 0
    title.Parent = panel

    local line = Instance.new("Frame")
    line.Size = UDim2.new(0.8, 0, 0, 1)
    line.BackgroundColor3 = T.accent
    line.BorderSizePixel = 0
    line.ZIndex = 41
    line.LayoutOrder = 1
    line.Parent = panel

    self._panel = panel
    self._panelLayout = layout
    self:_rebuildPanel()
end

function Keybinds:_rebuildPanel()
    if not self._panel then return end
    local T = self._moonlib._theme

    for _, child in ipairs(self._panel:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "" and string.sub(child.Name, 1, 5) == "bind_" then
            child:Destroy()
        end
    end

    local order = 10
    for id, bind in pairs(self._binds) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 18)
        row.BackgroundTransparency = 1
        row.ZIndex = 42
        row.Name = "bind_" .. id
        row.LayoutOrder = order
        row.Parent = self._panel
        order = order + 1

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Text = bind.Name
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextSize = 12
        nameLabel.TextColor3 = T.text
        nameLabel.BackgroundTransparency = 1
        nameLabel.Size = UDim2.new(0.45, 0, 1, 0)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.ZIndex = 42
        nameLabel.Parent = row

        local keyLabel = Instance.new("TextLabel")
        keyLabel.Name = "KeyLabel"
        keyLabel.Text = bind.Key and ("[" .. bind.Key .. "]") or "[-]"
        keyLabel.Font = Enum.Font.GothamMedium
        keyLabel.TextSize = 11
        keyLabel.TextColor3 = T.accent
        keyLabel.BackgroundTransparency = 1
        keyLabel.Size = UDim2.new(0.25, 0, 1, 0)
        keyLabel.Position = UDim2.new(0.45, 0, 0, 0)
        keyLabel.ZIndex = 42
        keyLabel.Parent = row

        local stateLabel = Instance.new("TextLabel")
        stateLabel.Name = "StateLabel"
        stateLabel.Text = "Off"
        stateLabel.Font = Enum.Font.Gotham
        stateLabel.TextSize = 11
        stateLabel.TextColor3 = T.textDim
        stateLabel.BackgroundTransparency = 1
        stateLabel.Size = UDim2.new(0.3, 0, 1, 0)
        stateLabel.Position = UDim2.new(0.7, 0, 0, 0)
        stateLabel.TextXAlignment = Enum.TextXAlignment.Right
        stateLabel.ZIndex = 42
        stateLabel.Parent = row
    end
end

function Keybinds:StartListening()
    if self._listening then return end
    self._listening = true

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

        local keyName = input.KeyCode.Name

        for id, bind in pairs(self._binds) do
            if bind.Key and bind.Key == keyName then
                if bind.Toggle then
                    local cur = bind.Toggle:Get()
                    bind.Toggle:Set(not cur)
                    bind.Active = not cur
                end
                if bind.Callback then
                    bind.Callback(bind.Active)
                end
            end
        end
    end)
end

function Keybinds:UpdateStates()
    if not self._panel then return end
    local T = self._moonlib._theme

    for id, bind in pairs(self._binds) do
        local row = self._panel:FindFirstChild("bind_" .. id)
        if row then
            local stateLabel = row:FindFirstChild("StateLabel")
            if stateLabel then
                local isOn = false
                if bind.Toggle then
                    isOn = bind.Toggle:Get()
                    bind.Active = isOn
                end
                if isOn then
                    stateLabel.Text = "Toggled"
                    stateLabel.TextColor3 = T.green
                else
                    stateLabel.Text = "Off"
                    stateLabel.TextColor3 = T.textDim
                end
            end
            local keyLabel = row:FindFirstChild("KeyLabel")
            if keyLabel then
                keyLabel.Text = bind.Key and ("[" .. bind.Key .. "]") or "[-]"
            end
        end
    end
end

function Keybinds:SetPanelVisible(visible)
    self._panelVisible = visible
    if self._panel then self._panel.Visible = visible end
end

function Keybinds:SetupSettingsUI(Window)
    local keybindsTab = Window:AddTab({ Name = "Keybinds" })

    local settingsSection = keybindsTab:AddSection({ Name = "Settings", Side = "Left" })

    settingsSection:AddToggle({
        Name = "Show Keybinds Panel",
        Default = true,
        Callback = function(v)
            self:SetPanelVisible(v)
        end
    })

    local bindsSection = keybindsTab:AddSection({ Name = "Binds", Side = "Right" })

    bindsSection:AddButton({
        Name = "Rebind Keys",
        Callback = function()
            if not self._moonlib then return end
            local popup = self._moonlib:CreateSubPopup({
                Title = "Rebind Keys",
                Width = 320,
                Height = 340
            })
            for id, bind in pairs(self._binds) do
                popup:AddButton({
                    Name = bind.Name .. ": " .. (bind.Key or "None"),
                    Callback = function()
                        self._moonlib:Prompt({
                            Title = "Set Key",
                            Message = "Enter key name for " .. bind.Name,
                            Input = true,
                            Placeholder = "E, T, F, etc.",
                            Default = bind.Key or "",
                            OnConfirm = function(val)
                                if val and val ~= "" then
                                    self:SetKey(id, val)
                                    popup:Close()
                                end
                            end
                        })
                    end
                })
            end
        end
    })

    bindsSection:AddButton({
        Name = "Clear All Binds",
        Callback = function()
            for id, bind in pairs(self._binds) do
                bind.Key = nil
            end
            self:_fireChanged()
            self:_rebuildPanel()
            if self._moonlib then
                self._moonlib:Notify("All keybinds cleared", 2)
            end
        end
    })
end

function Keybinds._register(MoonLib)
    Keybinds._moonlib = MoonLib
    MoonLib:RegisterAddon("Keybinds", Keybinds)
end

return Keybinds
