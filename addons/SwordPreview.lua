local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SwordPreviewAddon = {}
SwordPreviewAddon._name = "SwordPreview"

function SwordPreviewAddon._register(MoonLib)
    local SP = {}
    SP._cache = {}
    SP._activeViewports = {}

    function SP:_prepareModel(modelName, opts)
        opts = opts or {}
        local cached = self._cache[modelName]
        if cached then return cached end
        local sf = opts.SourceFolder
        if not sf then
            local assets = ReplicatedStorage:FindFirstChild("Assets")
            if not assets then return nil end
            sf = assets:FindFirstChild("Swords")
        end
        if not sf then return nil end
        local model = sf:FindFirstChild(modelName)
        if not model then return nil end
        local prepared = model:Clone()
        for _, d in pairs(prepared:GetDescendants()) do
            if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end
            if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Fire") or d:IsA("Smoke") then d.Enabled = false end
        end
        local primary = prepared:FindFirstChild("Sword") or prepared:FindFirstChildWhichIsA("BasePart", true)
        if primary and primary:IsA("BasePart") then prepared.PrimaryPart = primary end
        if prepared.PrimaryPart then
            prepared:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0) * CFrame.Angles(math.rad(-25), 0, math.rad(45)))
        end
        local _, size = prepared:GetBoundingBox()
        self._cache[modelName] = {model = prepared, size = size}
        return self._cache[modelName]
    end

    function SP:Build(viewport, modelName, opts)
        opts = opts or {}
        for _, c in pairs(viewport:GetChildren()) do
            if c:IsA("Model") or c:IsA("BasePart") or c:IsA("Camera") or c:IsA("WorldModel") then c:Destroy() end
        end
        local cached = self:_prepareModel(modelName, opts)
        if not cached then return false end
        local clone = cached.model:Clone()
        clone.Parent = viewport
        local cam = Instance.new("Camera", viewport)
        viewport.CurrentCamera = cam
        local dist = math.max(cached.size.X, cached.size.Y, cached.size.Z) * 1.6
        cam.CFrame = CFrame.new(Vector3.new(0, 0, dist), Vector3.new(0, 0, 0))

        self._activeViewports[viewport] = modelName
        if not viewport:GetAttribute("_MoonSPTracked") then
            viewport:SetAttribute("_MoonSPTracked", true)
            viewport.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    self._activeViewports[viewport] = nil
                    self:_cleanupUnused()
                end
            end)
        end
        return true
    end

    function SP:_cleanupUnused()
        local usedModels = {}
        for vp, name in pairs(self._activeViewports) do
            if vp and vp.Parent then usedModels[name] = true end
        end
        for name in pairs(self._cache) do
            if not usedModels[name] then
                pcall(function() self._cache[name].model:Destroy() end)
                self._cache[name] = nil
            end
        end
    end

    function SP:AttachLazyLoader(scrollingFrame, opts)
        opts = opts or {}
        local function scan()
            local absPos = scrollingFrame.AbsolutePosition
            local absSize = scrollingFrame.AbsoluteSize
            for _, card in ipairs(scrollingFrame:GetChildren()) do
                if card:IsA("Frame") then
                    local vp = card:FindFirstChildOfClass("ViewportFrame")
                    if vp and not vp:GetAttribute("Loaded") then
                        local top = card.AbsolutePosition.Y - absPos.Y
                        local bot = top + card.AbsoluteSize.Y
                        if bot >= -100 and top <= absSize.Y + 100 then
                            vp:SetAttribute("Loaded", true)
                            local name = vp:GetAttribute("ModelName")
                            if name then task.spawn(function() pcall(function() SP:Build(vp, name, opts) end) end) end
                        end
                    end
                end
            end
        end
        scrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(scan)
        task.delay(0.1, scan)
        return scan
    end

    function SP:OpenPicker(pickerOpts)
        pickerOpts = pickerOpts or {}
        local items = pickerOpts.Items or {}
        local title = pickerOpts.Title or "Select"
        local displayFn = pickerOpts.DisplayFunction or function(n) return tostring(n) end
        local onSelect = pickerOpts.OnSelect
        local sourceFolder = pickerOpts.SourceFolder
        local includeNone = pickerOpts.IncludeNone
        local theme = MoonLib._theme

        local plr = game:GetService("Players").LocalPlayer
        local gui = plr.PlayerGui:FindFirstChild("MoonLibPickers")
        if not gui then
            gui = Instance.new("ScreenGui")
            gui.Name = "MoonLibPickers"; gui.ResetOnSpawn = false
            gui.IgnoreGuiInset = true; gui.DisplayOrder = 200
            gui.Parent = plr.PlayerGui
        end

        local overlay = Instance.new("Frame", gui)
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundColor3 = Color3.new(0, 0, 0)
        overlay.BackgroundTransparency = 0.5
        overlay.BorderSizePixel = 0

        local frame = Instance.new("Frame", overlay)
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Position = UDim2.new(0.5, 0, 0.5, 0)
        frame.Size = UDim2.new(0, 640, 0, 480)
        frame.BackgroundColor3 = theme.bg
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
        local st = Instance.new("UIStroke", frame); st.Color = theme.accent; st.Thickness = 1

        local titleBar = Instance.new("Frame", frame)
        titleBar.Size = UDim2.new(1, 0, 0, 36)
        titleBar.BackgroundColor3 = theme.bgSecondary
        titleBar.BorderSizePixel = 0
        Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

        local titleLbl = Instance.new("TextLabel", titleBar)
        titleLbl.Size = UDim2.new(1, -50, 1, 0)
        titleLbl.Position = UDim2.new(0, 14, 0, 0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 13
        titleLbl.TextColor3 = theme.accent
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Text = title

        local closeBtn = Instance.new("TextButton", titleBar)
        closeBtn.Size = UDim2.new(0, 26, 0, 26)
        closeBtn.Position = UDim2.new(1, -32, 0.5, -13)
        closeBtn.BackgroundTransparency = 1
        closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 16
        closeBtn.TextColor3 = theme.text
        closeBtn.Text = "×"
        closeBtn.AutoButtonColor = false

        local searchBox = Instance.new("TextBox", frame)
        searchBox.Size = UDim2.new(1, -20, 0, 26)
        searchBox.Position = UDim2.new(0, 10, 0, 44)
        searchBox.BackgroundColor3 = theme.bgTertiary
        searchBox.BorderSizePixel = 0
        searchBox.Font = Enum.Font.Gotham; searchBox.TextSize = 12
        searchBox.TextColor3 = theme.text
        searchBox.PlaceholderText = "Search..."; searchBox.PlaceholderColor3 = theme.textDim
        searchBox.Text = ""
        searchBox.TextXAlignment = Enum.TextXAlignment.Left
        searchBox.ClearTextOnFocus = false
        Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 4)
        local sp1 = Instance.new("UIPadding", searchBox); sp1.PaddingLeft = UDim.new(0, 8)

        local list = Instance.new("ScrollingFrame", frame)
        list.Size = UDim2.new(1, -20, 1, -84)
        list.Position = UDim2.new(0, 10, 0, 78)
        list.BackgroundTransparency = 1
        list.BorderSizePixel = 0
        list.ScrollBarThickness = 4
        list.ScrollBarImageColor3 = theme.accent
        list.CanvasSize = UDim2.new(0, 0, 0, 0)

        local grid = Instance.new("UIGridLayout", list)
        grid.CellSize = UDim2.new(0, 140, 0, 170)
        grid.CellPadding = UDim2.new(0, 6, 0, 6)
        grid.SortOrder = Enum.SortOrder.LayoutOrder
        grid.HorizontalAlignment = Enum.HorizontalAlignment.Center

        local function close() pcall(function() overlay:Destroy() end) end
        closeBtn.MouseButton1Click:Connect(close)

        local function populate(filter)
            for _, c in ipairs(list:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
            local pool = {}
            if includeNone then table.insert(pool, "__none__") end
            for _, it in ipairs(items) do table.insert(pool, it) end
            local lower = string.lower(filter)
            local shown = 0
            for idx, item in ipairs(pool) do
                local name = item == "__none__" and "None" or displayFn(item)
                local target = item == "__none__" and "none" or string.lower(tostring(item) .. " " .. name)
                if filter == "" or target:find(lower, 1, true) then
                    local card = Instance.new("Frame", list)
                    card.BackgroundColor3 = theme.bgSection
                    card.BorderSizePixel = 0
                    card.LayoutOrder = idx
                    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
                    local cs = Instance.new("UIStroke", card); cs.Color = theme.border; cs.Thickness = 1
                    if item ~= "__none__" then
                        local vp = Instance.new("ViewportFrame", card)
                        vp.Size = UDim2.new(1, -8, 0, 120)
                        vp.Position = UDim2.new(0, 4, 0, 4)
                        vp.BackgroundColor3 = theme.bg
                        vp.BorderSizePixel = 0
                        vp:SetAttribute("ModelName", item)
                        vp:SetAttribute("Loaded", false)
                        Instance.new("UICorner", vp).CornerRadius = UDim.new(0, 4)
                    end
                    local lbl = Instance.new("TextLabel", card)
                    lbl.BackgroundTransparency = 1
                    lbl.Size = UDim2.new(1, -8, 0, 36)
                    lbl.Position = UDim2.new(0, 4, 1, -40)
                    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
                    lbl.TextColor3 = theme.text
                    lbl.TextWrapped = true
                    lbl.Text = name
                    local btn = Instance.new("TextButton", card)
                    btn.Size = UDim2.new(1, 0, 1, 0)
                    btn.BackgroundTransparency = 1
                    btn.Text = ""
                    btn.AutoButtonColor = false
                    local cap = item
                    btn.MouseButton1Click:Connect(function()
                        if onSelect then pcall(onSelect, cap == "__none__" and nil or cap) end
                        close()
                    end)
                    shown = shown + 1
                end
            end
            local cols = math.max(1, math.floor((list.AbsoluteSize.X - 6) / 146))
            list.CanvasSize = UDim2.new(0, 0, 0, math.ceil(shown / cols) * 176 + 12)
        end

        searchBox:GetPropertyChangedSignal("Text"):Connect(function() populate(searchBox.Text) end)
        populate("")
        SP:AttachLazyLoader(list, {SourceFolder = sourceFolder})

        local dragging, dragStart, frameStart = false, nil, nil
        titleBar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = i.Position; frameStart = frame.Position
            end
        end)
        titleBar.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - dragStart
                frame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + d.X, frameStart.Y.Scale, frameStart.Y.Offset + d.Y)
            end
        end)

        return overlay
    end

    function SP:AttachSectionPreview(section, opts)
        opts = opts or {}
        local body = section:GetBody()
        local vp = Instance.new("ViewportFrame", body)
        vp.Size = UDim2.new(1, 0, 0, opts.Height or 120)
        vp.BackgroundColor3 = MoonLib._theme.bg
        vp.BorderSizePixel = 0
        vp.LayoutOrder = -1
        Instance.new("UICorner", vp).CornerRadius = UDim.new(0, 6)
        local api = {}
        function api:Set(modelName) if modelName then SP:Build(vp, modelName, opts) end end
        function api:GetViewport() return vp end
        return api
    end

    MoonLib:RegisterAddon("SwordPreview", SP)
end

return SwordPreviewAddon
