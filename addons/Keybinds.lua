local Keybinds = {}
Keybinds._binds = {}
Keybinds._panel = nil
Keybinds._panelVisible = true
Keybinds._listening = false
Keybinds._onChangedCallbacks = {}
Keybinds._moonlib = nil

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local function tween(obj, props, dur)
    local ti = TweenInfo.new(dur or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(obj, ti, props):Play()
end

function Keybinds:Register(id, opts)
    self._binds[id] = {
        Name = opts.Name or id,
        Key = opts.Default or nil,
        Toggle = opts.Toggle or nil,
        Callback = opts.Callback or nil,
        Active = false,
    }
end

function Keybinds:SetKey(id, keyName)
    if self._binds[id] then
        self._binds[id].Key = keyName
        self:_fireChanged()
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
    for id, key in pairs(t) do
        if self._binds[id] then
            self._binds[id].Key = key
        end
    end
end

function Keybinds:OnChanged(cb)
    table.insert(self._onChangedCallbacks, cb)
end

function Keybinds:_fireChanged()
    for _, cb in ipairs(self._onChangedCallbacks) do
        cb()
    end
end

function Keybinds:CreatePanel(screenGui)
    local T = self._moonlib._theme

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 200, 0, 0)
    panel.AutomaticSize = Enum.AutomaticSize.Y
    panel.Position = UDim2.new(0, 16, 1, -200)
    panel.BackgroundColor3 = T.bg
    panel.BackgroundTransparency = 0.1
    panel.ZIndex = 40
    panel.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = T.border
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.Text = "Keybinds"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = T.text
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 28)
    title.ZIndex = 41
    title.Parent = panel

    local line = Instance.new("Frame")
    line.Size = UDim2.new(0.8, 0, 0, 1)
    line.Position = UDim2.new(0.1, 0, 0, 28)
    line.BackgroundColor3 = T.accent
    line.BorderSizePixel = 0
    line.ZIndex = 41
    line.Parent = panel

    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(1, -16, 0, 0)
    listFrame.AutomaticSize = Enum.AutomaticSize.Y
    listFrame.Position = UDim2.new(0, 8, 0, 34)
    listFrame.BackgroundTransparency = 1
    listFrame.ZIndex = 41
    listFrame.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)
    layout.Parent = listFrame

    self._panel = panel
    self._panelList = listFrame
    self:_rebuildPanel()
end

function Keybinds:_rebuildPanel()
    if not self._panelList then return end
    local T = self._moonlib._theme

    for _, child in ipairs(self._panelList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for id, bind in pairs(self._binds) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 20)
        row.BackgroundTransparency = 1
        row.ZIndex = 42
        row.Name = "bind_" .. id
        row.Parent = self._panelList

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Text = bind.Name
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextSize = 12
        nameLabel.TextColor3 = T.text
        nameLabel.BackgroundTransparency = 1
        nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
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
        keyLabel.Position = UDim2.new(0.5, 0, 0, 0)
        keyLabel.ZIndex = 42
        keyLabel.Parent = row

        local stateLabel = Instance.new("TextLabel")
        stateLabel.Name = "StateLabel"
        stateLabel.Text = "Off"
        stateLabel.Font = Enum.Font.Gotham
        stateLabel.TextSize = 11
        stateLabel.TextColor3 = T.textDim
        stateLabel.BackgroundTransparency = 1
        stateLabel.Size = UDim2.new(0.25, 0, 1, 0)
        stateLabel.Position = UDim2.new(0.75, 0, 0, 0)
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
                    local current = bind.Toggle:Get()
                    bind.Toggle:Set(not current)
                    bind.Active = not current
                end
                if bind.Callback then
                    bind.Callback(bind.Active)
                end
            end
        end
    end)
end

function Keybinds:UpdateStates()
    if not self._panelList then return end
    local T = self._moonlib._theme

    for id, bind in pairs(self._binds) do
        local row = self._panelList:FindFirstChild("bind_" .. id)
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
    if self._panel then
        self._panel.Visible = visible
    end
end

function Keybinds:SetupSettingsUI(Window)
    Window:AddSettingsSection("Keybinds", 200)

    Window:AddSettingsToggle("Show Keybinds Panel", true, 201, function(v)
        self:SetPanelVisible(v)
    end)

    Window:AddSettingsButton("Rebind Keys", 202, function()
        if not self._moonlib then return end
        local popup = self._moonlib:CreateSubPopup({Title = "Keybinds", Width = 300, Height = 300})

        for id, bind in pairs(self._binds) do
            popup:AddButton({
                Name = bind.Name .. ": " .. (bind.Key or "None"),
                Callback = function()
                    self._moonlib:Prompt({
                        Title = "Set Key",
                        Message = "Press any key for " .. bind.Name,
                        Input = true,
                        Placeholder = "Key name (e.g. E, T, F)",
                        Default = bind.Key or "",
                        OnConfirm = function(val)
                            if val and val ~= "" then
                                self:SetKey(id, val)
                                self:_rebuildPanel()
                                popup:Close()
                            end
                        end,
                    })
                end,
            })
        end
    end)
end

function Keybinds._register(MoonLib)
    Keybinds._moonlib = MoonLib
    MoonLib:RegisterAddon("Keybinds", Keybinds)
end

return Keybinds
