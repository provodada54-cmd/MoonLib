local SwordPreview = {}
SwordPreview._cache = {}
SwordPreview._moonlib = nil

local RunService = game:GetService("RunService")
local InsertService = game:GetService("InsertService")

local function clearViewport(viewport)
    for _, child in ipairs(viewport:GetChildren()) do
        if child:IsA("Model") or child:IsA("BasePart") or child:IsA("Camera") then
            child:Destroy()
        end
    end
end

local function setupCamera(viewport, model)
    local camera = Instance.new("Camera")
    camera.Parent = viewport
    viewport.CurrentCamera = camera

    local cf, size = model:GetBoundingBox()
    local maxDim = math.max(size.X, size.Y, size.Z)
    local dist = maxDim * 1.8

    camera.CFrame = CFrame.lookAt(
        cf.Position + Vector3.new(dist * 0.5, dist * 0.3, dist),
        cf.Position
    )

    return camera, cf
end

function SwordPreview:Build(viewport, modelName, opts)
    opts = opts or {}
    clearViewport(viewport)

    if self._cache[modelName] then
        local clone = self._cache[modelName]:Clone()
        clone.Parent = viewport
        setupCamera(viewport, clone)
        return clone
    end

    local model = nil

    if opts.AssetId then
        local ok, result = pcall(function()
            return InsertService:LoadAsset(opts.AssetId)
        end)
        if ok and result then
            model = result
            model.Parent = viewport
        end
    end

    if not model then
        local blade = Instance.new("Part")
        blade.Size = Vector3.new(1, 4, 0.3)
        blade.Color = Color3.fromRGB(180, 180, 200)
        blade.Material = Enum.Material.Metal
        blade.Anchored = true
        blade.CanCollide = false

        local handle = Instance.new("Part")
        handle.Size = Vector3.new(0.4, 1.2, 0.4)
        handle.Color = Color3.fromRGB(80, 50, 30)
        handle.Material = Enum.Material.Wood
        handle.Anchored = true
        handle.CanCollide = false
        handle.CFrame = blade.CFrame * CFrame.new(0, -2.6, 0)

        model = Instance.new("Model")
        blade.Parent = model
        handle.Parent = model
        model.PrimaryPart = blade
        model.Parent = viewport
    end

    self._cache[modelName] = model:Clone()
    setupCamera(viewport, model)

    viewport.AncestryChanged:Connect(function()
        if not viewport:IsDescendantOf(game) then
            if self._cache[modelName] then
                self._cache[modelName]:Destroy()
                self._cache[modelName] = nil
            end
        end
    end)

    return model
end

function SwordPreview:AttachLazyLoader(scrollingFrame, opts)
    opts = opts or {}
    local items = opts.Items or {}
    local vpSize = opts.ViewportSize or UDim2.new(0, 80, 0, 80)

    for _, itemName in ipairs(items) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(0, 90, 0, 100)
        card.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
        card.Parent = scrollingFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = card

        local vp = Instance.new("ViewportFrame")
        vp.Size = vpSize
        vp.Position = UDim2.new(0.5, -40, 0, 2)
        vp.BackgroundTransparency = 1
        vp.Parent = card

        local label = Instance.new("TextLabel")
        label.Text = itemName
        label.Font = Enum.Font.Gotham
        label.TextSize = 10
        label.TextColor3 = Color3.fromRGB(200, 200, 210)
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, 0, 0, 16)
        label.Position = UDim2.new(0, 0, 1, -16)
        label.Parent = card

        local loaded = false
        local conn
        conn = RunService.Heartbeat:Connect(function()
            if not loaded and vp.AbsolutePosition.Y < workspace.CurrentCamera.ViewportSize.Y + 100 then
                loaded = true
                self:Build(vp, itemName, opts.BuildOpts)
                conn:Disconnect()
            end
        end)
    end
end

function SwordPreview:OpenPicker(opts)
    if not self._moonlib then return end
    opts = opts or {}

    local popup = self._moonlib:CreateSubPopup({
        Title = opts.Title or "Select Sword",
        Width = 400,
        Height = 420
    })

    local items = opts.Items or {}

    if opts.IncludeNone then
        popup:AddButton({
            Name = "None",
            Callback = function()
                if opts.OnSelect then opts.OnSelect(nil) end
                popup:Close()
            end
        })
    end

    for _, itemName in ipairs(items) do
        popup:AddButton({
            Name = itemName,
            Callback = function()
                if opts.OnSelect then opts.OnSelect(itemName) end
                popup:Close()
            end
        })
    end
end

function SwordPreview:AttachSectionPreview(section, opts)
    opts = opts or {}
    local body = section:GetBody()

    local vpFrame = Instance.new("ViewportFrame")
    vpFrame.Size = UDim2.new(1, 0, 0, 100)
    vpFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    vpFrame.BackgroundTransparency = 0
    vpFrame.Parent = body

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = vpFrame

    if opts.ModelName then
        self:Build(vpFrame, opts.ModelName, opts.BuildOpts)
    end

    return vpFrame
end

function SwordPreview._register(MoonLib)
    SwordPreview._moonlib = MoonLib
    MoonLib:RegisterAddon("SwordPreview", SwordPreview)
end

return SwordPreview
