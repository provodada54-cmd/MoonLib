--[[ MoonLib Keybinds Addon ]]

local UserInputService = game:GetService("UserInputService")

local KeybindsAddon = {}
KeybindsAddon._name = "Keybinds"

function KeybindsAddon._register(MoonLib)
    local Keybinds = {}
    Keybinds._binds = {}
    Keybinds._listening = false
    Keybinds._listenTarget = nil
    Keybinds._callbacks = {}
    Keybinds._panelVisible = true
    Keybinds._panelFrame = nil
    Keybinds._rows = {}
    Keybinds._inputConn = nil

    function Keybinds:Register(id, opts)
        opts = opts or {}
        self._binds[id] = {name = opts.Name or id, key = opts.Default or "None", callback = opts.Callback, toggle = opts.Toggle, state = false}
        self:_refreshPanel()
    end

    function Keybinds:SetKey(id, keyName)
        if not self._binds[id] then return end
        self._binds[id].key = keyName or "None"
        self:_refreshPanel()
        for _, cb in ipairs(self._callbacks) do pcall(cb, id, keyName) end
    end

    function Keybinds:GetKey(id) return self._binds[id] and self._binds[id].key or "None" end
    function Keybinds:OnChanged(cb) table.insert(self._callbacks, cb) end

    function Keybinds:GetAllBinds()
        local r = {}
        for id, d in pairs(self._binds) do r[id] = d.key end
        return r
    end

    function Keybinds:SetAllBinds(binds)
        for id, key in pairs(binds or {}) do
            if self._binds[id] then self._binds[id].key = key end
        end
        self:_refreshPanel()
    end

    function Keybinds:CreatePanel(screenGui)
        local theme = MoonLib._theme
        local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

        local panel = Instance.new("Frame")
        panel.Name = "KeybindsPanel"
        panel.Size = UDim2.new(0, isMobile and 150 or 180, 0, 0)
        panel.AutomaticSize = Enum.AutomaticSize.Y
        panel.Position = UDim2.new(0, 12, 0.5, 0)
        panel.AnchorPoint = Vector2.new(0, 0.5)
        panel.BackgroundColor3 = theme.bg
        panel.BackgroundTransparency = 0.05
        panel.BorderSizePixel = 0
        panel.Parent = screenGui
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
        local s = Instance.new("UIStroke", panel); s.Color = theme.border; s.Thickness = 1

        local layout = Instance.new("UIListLayout", panel)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 2)

        local pad = Instance.new("UIPadding", panel)
        pad.PaddingTop = UDim.new(0, 6); pad.PaddingBottom = UDim.new(0, 6)
        pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)

        local header = Instance.new("TextLabel", panel)
        header.Size = UDim2.new(1, 0, 0, 22)
        header.BackgroundTransparency = 1
        header.Font = Enum.Font.GothamBold
        header.TextSize = 12
        header.TextColor3 = theme.text
        header.Text = "Keybinds"
        header.LayoutOrder = 0

        self._panelFrame = panel

        local dragging, dragStart, frameStart = false, nil, nil
        panel.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = i.Position; frameStart = panel.Position end end)
        panel.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - dragStart
                panel.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + d.X, frameStart.Y.Scale, frameStart.Y.Offset + d.Y)
            end
        end)

        self:_refreshPanel()
        return panel
    end

    function Keybinds:_refreshPanel()
        if not self._panelFrame then return end
        local theme = MoonLib._theme
        for _, row in pairs(self._rows) do pcall(function() row:Destroy() end) end
        self._rows = {}
        local order = 1
        for id, data in pairs(self._binds) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 18)
            row.BackgroundTransparency = 1
            row.LayoutOrder = order
            row.Parent = self._panelFrame
            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Size = UDim2.new(0.55, 0, 1, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Enum.Font.Gotham; nameLbl.TextSize = 10
            nameLbl.TextColor3 = theme.text
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Text = data.name
            local keyBtn = Instance.new("TextButton", row)
            keyBtn.Size = UDim2.new(0, 34, 0, 14)
            keyBtn.Position = UDim2.new(0.56, 0, 0.5, -7)
            keyBtn.BackgroundColor3 = theme.bgTertiary
            keyBtn.Font = Enum.Font.GothamBold; keyBtn.TextSize = 9
            keyBtn.TextColor3 = theme.accent
            keyBtn.Text = "[" .. (data.key == "None" and "—" or data.key) .. "]"
            keyBtn.AutoButtonColor = false; keyBtn.BorderSizePixel = 0
            Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 3)
            local stateLbl = Instance.new("TextLabel", row)
            stateLbl.Size = UDim2.new(0, 28, 1, 0)
            stateLbl.Position = UDim2.new(1, -28, 0, 0)
            stateLbl.BackgroundTransparency = 1
            stateLbl.Font = Enum.Font.GothamBold; stateLbl.TextSize = 9
            stateLbl.TextXAlignment = Enum.TextXAlignment.Right
            stateLbl.Name = "StateLabel"
            local isOn = data.toggle and data.toggle.Value or data.state
            stateLbl.Text = isOn and "On" or "Off"
            stateLbl.TextColor3 = isOn and theme.green or theme.textDim
            local capId = id
            keyBtn.MouseButton1Click:Connect(function()
                keyBtn.Text = "[...]"
                self._listening = true; self._listenTarget = capId
            end)
            self._rows[id] = row
            order = order + 1
        end
    end

    function Keybinds:UpdateStates()
        if not self._panelFrame then return end
        local theme = MoonLib._theme
        for id, row in pairs(self._rows) do
            local data = self._binds[id]
            local stateLbl = row:FindFirstChild("StateLabel")
            if data and stateLbl then
                local isOn = data.toggle and data.toggle.Value or data.state
                stateLbl.Text = isOn and "On" or "Off"
                stateLbl.TextColor3 = isOn and theme.green or theme.textDim
            end
        end
    end

    function Keybinds:SetState(id, state) if self._binds[id] then self._binds[id].state = state end; self:UpdateStates() end

    function Keybinds:StartListening()
        if self._inputConn then return end
        self._inputConn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if self._listening and self._listenTarget then
                self:SetKey(self._listenTarget, input.KeyCode.Name)
                self._listening = false; self._listenTarget = nil
                self:_refreshPanel()
                local cfg = MoonLib:GetAddon("Config")
                if cfg then cfg:Set("binds", self:GetAllBinds()) end
                return
            end
            for id, data in pairs(self._binds) do
                if data.key ~= "None" and data.key == input.KeyCode.Name then
                    if data.callback then pcall(data.callback) end
                    if data.toggle then data.toggle:Set(not data.toggle.Value) end
                end
            end
        end)
    end

    function Keybinds:SetPanelVisible(v)
        self._panelVisible = v
        if self._panelFrame then self._panelFrame.Visible = v end
    end

    function Keybinds:SetupSettingsUI(Window)
        Window:AddSettingsSection("Keybinds", 200)
        Window:AddSettingsToggle("Show Keybinds Panel", true, 201, function(v) self:SetPanelVisible(v) end)
    end

    MoonLib:RegisterAddon("Keybinds", Keybinds)
end

return KeybindsAddon