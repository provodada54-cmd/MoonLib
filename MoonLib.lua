local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local MoonLib = {}
MoonLib._addons = {}
MoonLib._theme = {
    accent = Color3.fromRGB(230, 40, 75),
    accentDim = Color3.fromRGB(160, 25, 50),
    accentGlow = Color3.fromRGB(255, 70, 120),
    bg = Color3.fromRGB(17, 17, 22),
    bgSecondary = Color3.fromRGB(22, 22, 28),
    bgTertiary = Color3.fromRGB(28, 28, 36),
    bgSection = Color3.fromRGB(24, 24, 30),
    text = Color3.fromRGB(235, 235, 240),
    textDim = Color3.fromRGB(130, 130, 145),
    textFaded = Color3.fromRGB(90, 90, 105),
    border = Color3.fromRGB(40, 40, 50),
    borderGlow = Color3.fromRGB(120, 40, 70),
    toggle_on = Color3.fromRGB(230, 40, 75),
    toggle_off = Color3.fromRGB(50, 50, 60),
    slider_bg = Color3.fromRGB(45, 45, 55),
    green = Color3.fromRGB(0, 200, 80),
    red = Color3.fromRGB(230, 40, 75),
}

local T = MoonLib._theme

local function tween(obj, props, duration, style, dir)
    local ti = TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, ti, props)
    tw:Play()
    return tw
end

local function create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function addCorner(parent, radius)
    return create("UICorner", {CornerRadius = UDim.new(0, radius or 8), Parent = parent})
end

local function addStroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or T.border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        Parent = parent,
    })
end

local function addPadding(parent, top, right, bottom, left)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        Parent = parent,
    })
end

function MoonLib:RegisterAddon(name, addonTable)
    self._addons[name] = addonTable
end

function MoonLib:GetAddon(name)
    return self._addons[name]
end

function MoonLib:Notify(text, duration)
    duration = duration or 3
    local sg = self._screenGui
    if not sg then return end

    local notifContainer = sg:FindFirstChild("_MoonNotifs")
    if not notifContainer then
        notifContainer = create("Frame", {
            Name = "_MoonNotifs",
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 280, 1, 0),
            Position = UDim2.new(1, -290, 0, 10),
            Parent = sg,
        })
        create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            VerticalAlignment = Enum.VerticalAlignment.Top,
            Parent = notifContainer,
        })
    end

    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = T.bgSecondary,
        BackgroundTransparency = 0.05,
        Parent = notifContainer,
    })
    addCorner(card, 8)
    addStroke(card, T.accent, 1, 0.5)

    local accentBar = create("Frame", {
        Size = UDim2.new(0, 3, 0.6, 0),
        Position = UDim2.new(0, 8, 0.2, 0),
        BackgroundColor3 = T.accent,
        BorderSizePixel = 0,
        Parent = card,
    })
    addCorner(accentBar, 2)

    create("TextLabel", {
        Text = text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -28, 1, 0),
        Position = UDim2.new(0, 18, 0, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = card,
    })

    card.BackgroundTransparency = 1
    tween(card, {BackgroundTransparency = 0.05}, 0.3)

    task.delay(duration, function()
        local tw = tween(card, {BackgroundTransparency = 1}, 0.3)
        tw.Completed:Wait()
        card:Destroy()
    end)
end

function MoonLib:Prompt(opts)
    local sg = self._screenGui
    if not sg then return end

    local overlay = create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.5,
        ZIndex = 100,
        Parent = sg,
    })

    local popW = 340
    local popH = opts.Input and 200 or 160

    local popup = create("Frame", {
        Size = UDim2.new(0, popW, 0, popH),
        Position = UDim2.new(0.5, -popW / 2, 0.5, -popH / 2),
        BackgroundColor3 = T.bg,
        ZIndex = 101,
        Parent = overlay,
    })
    addCorner(popup, 12)
    addStroke(popup, T.accent, 2, 0.4)

    create("TextLabel", {
        Text = opts.Title or "Prompt",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = T.text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 10),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 102,
        Parent = popup,
    })

    create("TextLabel", {
        Text = opts.Message or "",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = T.textDim,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 42),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        ZIndex = 102,
        Parent = popup,
    })

    local inputBox = nil
    local btnY = opts.Input and 140 or 100

    if opts.Input then
        inputBox = create("TextBox", {
            Text = opts.Default or "",
            PlaceholderText = opts.Placeholder or "",
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = T.text,
            PlaceholderColor3 = T.textFaded,
            BackgroundColor3 = T.bgTertiary,
            Size = UDim2.new(1, -20, 0, 32),
            Position = UDim2.new(0, 10, 0, 80),
            ClearTextOnFocus = false,
            ZIndex = 102,
            Parent = popup,
        })
        addCorner(inputBox, 6)
        addPadding(inputBox, 0, 8, 0, 8)
    end

    local function closePrompt()
        overlay:Destroy()
    end

    local okBtn = create("TextButton", {
        Text = opts.OkText or "OK",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.new(1, 1, 1),
        BackgroundColor3 = T.accent,
        Size = UDim2.new(0, 100, 0, 30),
        Position = UDim2.new(0.5, -105, 0, btnY),
        ZIndex = 102,
        Parent = popup,
    })
    addCorner(okBtn, 6)

    local cancelBtn = create("TextButton", {
        Text = opts.CancelText or "Cancel",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = T.textDim,
        BackgroundColor3 = T.bgTertiary,
        Size = UDim2.new(0, 100, 0, 30),
        Position = UDim2.new(0.5, 5, 0, btnY),
        ZIndex = 102,
        Parent = popup,
    })
    addCorner(cancelBtn, 6)

    okBtn.MouseButton1Click:Connect(function()
        closePrompt()
        if opts.OnConfirm then
            opts.OnConfirm(inputBox and inputBox.Text or nil)
        end
    end)

    cancelBtn.MouseButton1Click:Connect(function()
        closePrompt()
        if opts.OnCancel then opts.OnCancel() end
    end)
end

function MoonLib:CreateSubPopup(opts)
    local sg = self._screenGui
    if not sg then return end

    local w = opts.Width or 320
    local h = opts.Height or 340

    local overlay = create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.5,
        ZIndex = 100,
        Parent = sg,
    })

    local popup = create("Frame", {
        Size = UDim2.new(0, w, 0, h),
        Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2),
        BackgroundColor3 = T.bg,
        ZIndex = 101,
        Parent = overlay,
    })
    addCorner(popup, 12)
    addStroke(popup, T.accent, 2, 0.4)

    local titleBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        ZIndex = 102,
        Parent = popup,
    })

    create("TextLabel", {
        Text = opts.Title or "Settings",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = T.text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 102,
        Parent = titleBar,
    })

    local closeBtn = create("TextButton", {
        Text = "✕",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = T.textDim,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -34, 0, 3),
        ZIndex = 102,
        Parent = titleBar,
    })

    local content = create("ScrollingFrame", {
        Size = UDim2.new(1, -16, 1, -44),
        Position = UDim2.new(0, 8, 0, 40),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 102,
        Parent = popup,
    })
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = content,
    })
    addPadding(content, 4, 4, 4, 4)

    local api = {}

    local function closeFn()
        overlay:Destroy()
    end

    closeBtn.MouseButton1Click:Connect(closeFn)

    function api:Close()
        closeFn()
    end

    function api:AddToggle(o)
        return MoonLib._makeToggle(content, o, 102)
    end

    function api:AddSlider(o)
        return MoonLib._makeSlider(content, o, 102)
    end

    function api:AddDropdown(o)
        return MoonLib._makeDropdown(content, o, 102)
    end

    function api:AddLabel(o)
        return MoonLib._makeLabel(content, o, 102)
    end

    return api
end

local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle = handle or frame

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function MoonLib._makeToggle(parent, opts, zBase)
    zBase = zBase or 10
    local value = opts.Default or false

    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        ZIndex = zBase,
        Parent = parent,
    })

    create("TextLabel", {
        Text = opts.Name or "Toggle",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = T.text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = zBase,
        Parent = row,
    })

    local pillW, pillH = 32, 16
    local knobSize = 12

    local pill = create("Frame", {
        Size = UDim2.new(0, pillW, 0, pillH),
        Position = UDim2.new(1, -pillW, 0.5, -pillH / 2),
        BackgroundColor3 = value and T.toggle_on or T.toggle_off,
        ZIndex = zBase + 1,
        Parent = row,
    })
    addCorner(pill, pillH / 2)

    local knob = create("Frame", {
        Size = UDim2.new(0, knobSize, 0, knobSize),
        Position = value and UDim2.new(1, -knobSize - 2, 0.5, -knobSize / 2) or UDim2.new(0, 2, 0.5, -knobSize / 2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = zBase + 2,
        Parent = pill,
    })
    addCorner(knob, knobSize / 2)

    local element = {Value = value, _callbacks = {}}

    local function updateVisual(v, animate)
        if animate then
            tween(pill, {BackgroundColor3 = v and T.toggle_on or T.toggle_off}, 0.2)
            tween(knob, {Position = v and UDim2.new(1, -knobSize - 2, 0.5, -knobSize / 2) or UDim2.new(0, 2, 0.5, -knobSize / 2)}, 0.2)
        else
            pill.BackgroundColor3 = v and T.toggle_on or T.toggle_off
            knob.Position = v and UDim2.new(1, -knobSize - 2, 0.5, -knobSize / 2) or UDim2.new(0, 2, 0.5, -knobSize / 2)
        end
    end

    local function setValue(v, fromUser)
        value = v
        element.Value = v
        updateVisual(v, true)
        if fromUser and opts.Callback then opts.Callback(v) end
        for _, cb in ipairs(element._callbacks) do cb(v) end
    end

    pill.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            setValue(not value, true)
        end
    end)

    function element:Set(v)
        setValue(v, false)
    end

    function element:Get()
        return value
    end

    function element:OnChanged(cb)
        table.insert(self._callbacks, cb)
    end

    return element
end

function MoonLib._makeSlider(parent, opts, zBase)
    zBase = zBase or 10
    local min = opts.Min or 0
    local max = opts.Max or 100
    local decimals = opts.Decimals or 0
    local value = opts.Default or min

    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        ZIndex = zBase,
        Parent = parent,
    })

    create("TextLabel", {
        Text = opts.Name or "Slider",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = T.text,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.6, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = zBase,
        Parent = row,
    })

    local valueLabel = create("TextLabel", {
        Text = tostring(value),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = T.textDim,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.4, 0, 0, 18),
        Position = UDim2.new(0.6, 0, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = zBase,
        Parent = row,
    })

    local trackH = 5
    local track = create("Frame", {
        Size = UDim2.new(1, 0, 0, trackH),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundColor3 = T.slider_bg,
        ZIndex = zBase + 1,
        Parent = row,
    })
    addCorner(track, trackH / 2)

    local fill = create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = T.accent,
        ZIndex = zBase + 2,
        Parent = track,
    })
    addCorner(fill, trackH / 2)

    local knobSize = 14
    local knobFrame = create("Frame", {
        Size = UDim2.new(0, knobSize, 0, knobSize),
        Position = UDim2.new(0, 0, 0.5, -knobSize / 2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = zBase + 3,
        Parent = track,
    })
    addCorner(knobFrame, knobSize / 2)

    local element = {Value = value, _callbacks = {}}

    local function formatVal(v)
        if decimals == 0 then return tostring(math.floor(v + 0.5)) end
        return string.format("%." .. decimals .. "f", v)
    end

    local function updateVisual(v)
        local pct = math.clamp((v - min) / (max - min), 0, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knobFrame.Position = UDim2.new(pct, -knobSize / 2, 0.5, -knobSize / 2)
        valueLabel.Text = formatVal(v)
    end

    local function setValue(v, fromUser)
        v = math.clamp(v, min, max)
        if decimals == 0 then v = math.floor(v + 0.5) end
        value = v
        element.Value = v
        updateVisual(v)
        if fromUser and opts.Callback then opts.Callback(v) end
        for _, cb in ipairs(element._callbacks) do cb(v) end
    end

    updateVisual(value)

    local sliding = false

    local function handleInput(input)
        local absPos = track.AbsolutePosition.X
        local absSize = track.AbsoluteSize.X
        local x = math.clamp(input.Position.X - absPos, 0, absSize)
        local pct = x / absSize
        local newVal = min + (max - min) * pct
        setValue(newVal, true)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            handleInput(input)
        end
    end)

    knobFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            handleInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    function element:Set(v)
        setValue(v, false)
    end

    function element:Get()
        return value
    end

    function element:OnChanged(cb)
        table.insert(self._callbacks, cb)
    end

    return element
end

function MoonLib._makeDropdown(parent, opts, zBase)
    zBase = zBase or 10
    local items = opts.Items or {}
    local value = opts.Default or (items[1] or "")
    local expanded = false

    local container = create("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = zBase,
        Parent = parent,
    })

    create("TextLabel", {
        Text = opts.Name or "Dropdown",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = T.text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = zBase,
        Parent = container,
    })

    local dropBody = create("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundColor3 = T.bgTertiary,
        ZIndex = zBase + 1,
        ClipsDescendants = true,
        Parent = container,
    })
    addCorner(dropBody, 6)
    addStroke(dropBody, T.border, 1, 0.6)

    local selectedLabel = create("TextLabel", {
        Text = tostring(value),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = T.text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 0, 32),
        Position = UDim2.new(0, 10, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = zBase + 2,
        Parent = dropBody,
    })

    local arrow = create("TextLabel", {
        Text = "▼",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = T.textDim,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 0, 32),
        Position = UDim2.new(1, -24, 0, 0),
        ZIndex = zBase + 2,
        Parent = dropBody,
    })

    local listFrame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 32),
        BackgroundTransparency = 1,
        ZIndex = zBase + 3,
        Parent = dropBody,
    })

    local listLayout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 0),
        Parent = listFrame,
    })

    local itemButtons = {}

    local element = {Value = value, _callbacks = {}}

    local function setValue(v, fromUser)
        value = v
        element.Value = v
        selectedLabel.Text = tostring(v)
        for _, btn in ipairs(itemButtons) do
            btn.TextColor3 = (btn.Text == tostring(v)) and T.accent or T.text
        end
        if fromUser and opts.Callback then opts.Callback(v) end
        for _, cb in ipairs(element._callbacks) do cb(v) end
    end

    for i, item in ipairs(items) do
        local btn = create("TextButton", {
            Text = tostring(item),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = (tostring(item) == tostring(value)) and T.accent or T.text,
            BackgroundColor3 = T.bgTertiary,
            BackgroundTransparency = 0,
            Size = UDim2.new(1, 0, 0, 28),
            ZIndex = zBase + 4,
            Parent = listFrame,
        })
        btn.MouseEnter:Connect(function()
            tween(btn, {BackgroundColor3 = T.border}, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, {BackgroundColor3 = T.bgTertiary}, 0.15)
        end)
        btn.MouseButton1Click:Connect(function()
            setValue(tostring(item), true)
            toggleExpand()
        end)
        table.insert(itemButtons, btn)
    end

    local listHeight = #items * 28
    local collapsedContainerH = 52
    local expandedContainerH = 52 + listHeight

    local collapsedBodyH = 32
    local expandedBodyH = 32 + listHeight

    function toggleExpand()
        expanded = not expanded
        if expanded then
            tween(container, {Size = UDim2.new(1, 0, 0, expandedContainerH)}, 0.25, Enum.EasingStyle.Quart)
            tween(dropBody, {Size = UDim2.new(1, 0, 0, expandedBodyH)}, 0.25, Enum.EasingStyle.Quart)
            tween(listFrame, {Size = UDim2.new(1, 0, 0, listHeight)}, 0.25, Enum.EasingStyle.Quart)
            tween(arrow, {Rotation = 180}, 0.25)
        else
            tween(container, {Size = UDim2.new(1, 0, 0, collapsedContainerH)}, 0.25, Enum.EasingStyle.Quart)
            tween(dropBody, {Size = UDim2.new(1, 0, 0, collapsedBodyH)}, 0.25, Enum.EasingStyle.Quart)
            tween(listFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.25, Enum.EasingStyle.Quart)
            tween(arrow, {Rotation = 0}, 0.25)
        end
    end

    local headerBtn = create("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        ZIndex = zBase + 5,
        Parent = dropBody,
    })
    headerBtn.MouseButton1Click:Connect(toggleExpand)

    function element:Set(v)
        setValue(v, false)
    end

    function element:Get()
        return value
    end

    function element:OnChanged(cb)
        table.insert(self._callbacks, cb)
    end

    return element
end

function MoonLib._makeButton(parent, opts, zBase)
    zBase = zBase or 10

    local btn = create("TextButton", {
        Text = opts.Name or "Button",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = T.text,
        BackgroundColor3 = T.bgTertiary,
        Size = UDim2.new(1, 0, 0, 30),
        ZIndex = zBase + 1,
        Parent = parent,
    })
    addCorner(btn, 6)
    addStroke(btn, T.border, 1, 0.7)

    btn.MouseEnter:Connect(function()
        tween(btn, {BackgroundColor3 = T.border}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, {BackgroundColor3 = T.bgTertiary}, 0.15)
    end)

    btn.MouseButton1Click:Connect(function()
        if opts.Callback then opts.Callback() end
    end)

    local element = {}
    function element:Set() end
    function element:Get() return nil end
    function element:OnChanged() end
    return element
end

function MoonLib._makeInput(parent, opts, zBase)
    zBase = zBase or 10
    local value = opts.Default or ""

    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        ZIndex = zBase,
        Parent = parent,
    })

    create("TextLabel", {
        Text = opts.Name or "Input",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = T.text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = zBase,
        Parent = row,
    })

    local box = create("TextBox", {
        Text = value,
        PlaceholderText = opts.Placeholder or "",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = T.text,
        PlaceholderColor3 = T.textFaded,
        BackgroundColor3 = T.bgTertiary,
        Size = UDim2.new(1, 0, 0, 28),
        Position = UDim2.new(0, 0, 0, 20),
        ClearTextOnFocus = false,
        ZIndex = zBase + 1,
        Parent = row,
    })
    addCorner(box, 6)
    addPadding(box, 0, 8, 0, 8)

    local element = {Value = value, _callbacks = {}}

    box.FocusLost:Connect(function()
        value = box.Text
        element.Value = value
        if opts.Callback then opts.Callback(value) end
        for _, cb in ipairs(element._callbacks) do cb(value) end
    end)

    function element:Set(v)
        value = v
        element.Value = v
        box.Text = v
    end

    function element:Get()
        return value
    end

    function element:OnChanged(cb)
        table.insert(self._callbacks, cb)
    end

    return element
end

function MoonLib._makeLabel(parent, opts, zBase)
    zBase = zBase or 10
    local lbl = create("TextLabel", {
        Text = opts.Text or "",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = T.textDim,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        ZIndex = zBase,
        Parent = parent,
    })
    local element = {Value = opts.Text}
    function element:Set(t)
        lbl.Text = t
        element.Value = t
    end
    function element:Get() return element.Value end
    function element:OnChanged() end
    return element
end

function MoonLib:CreateWindow(opts)
    local windowWidth = isMobile and 380 or (opts.Size and opts.Size.X.Offset or 480)
    local windowHeight = isMobile and 500 or (opts.Size and opts.Size.Y.Offset or 560)

    local screenGui = create("ScreenGui", {
        Name = "MoonLib",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })

    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
    end
    screenGui.Parent = game:GetService("CoreGui")
    self._screenGui = screenGui

    local miniIcon = create("Frame", {
        Size = UDim2.new(0, 52, 0, 52),
        Position = UDim2.new(0, 16, 0.5, -26),
        BackgroundColor3 = T.bg,
        ZIndex = 50,
        Parent = screenGui,
    })
    addCorner(miniIcon, 12)
    addStroke(miniIcon, Color3.new(0, 0, 0), 2)

    local miniIconInner = create("TextLabel", {
        Text = "M",
        Font = Enum.Font.GothamBold,
        TextSize = 22,
        TextColor3 = T.accent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 51,
        Parent = miniIcon,
    })

    if opts.Icon then
        local iconImg = create("ImageLabel", {
            Image = opts.Icon,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(0.5, -15, 0.5, -15),
            ZIndex = 52,
            Parent = miniIcon,
        })
        miniIconInner.Visible = false
    end

    makeDraggable(miniIcon)

    local mainFrame = create("Frame", {
        Size = UDim2.new(0, windowWidth, 0, windowHeight),
        Position = UDim2.new(0.5, -windowWidth / 2, 0.5, -windowHeight / 2),
        BackgroundColor3 = T.bg,
        Visible = false,
        ZIndex = 10,
        Parent = screenGui,
    })
    addCorner(mainFrame, 12)

    local glowStroke = addStroke(mainFrame, T.accent, 2, 0.3)

    local outerGlow1 = create("Frame", {
        Size = UDim2.new(1, 12, 1, 12),
        Position = UDim2.new(0, -6, 0, -6),
        BackgroundTransparency = 1,
        ZIndex = 9,
        Parent = mainFrame,
    })
    addCorner(outerGlow1, 16)
    local gStroke1 = addStroke(outerGlow1, T.accentGlow, 1, 0.6)

    local outerGlow2 = create("Frame", {
        Size = UDim2.new(1, 20, 1, 20),
        Position = UDim2.new(0, -10, 0, -10),
        BackgroundTransparency = 1,
        ZIndex = 8,
        Parent = mainFrame,
    })
    addCorner(outerGlow2, 20)
    local gStroke2 = addStroke(outerGlow2, T.accentDim, 1, 0.75)

    local outerGlow3 = create("Frame", {
        Size = UDim2.new(1, 30, 1, 30),
        Position = UDim2.new(0, -15, 0, -15),
        BackgroundTransparency = 1,
        ZIndex = 7,
        Parent = mainFrame,
    })
    addCorner(outerGlow3, 24)
    local gStroke3 = addStroke(outerGlow3, T.accentDim, 1, 0.87)

    task.spawn(function()
        while mainFrame and mainFrame.Parent do
            tween(glowStroke, {Transparency = 0.15}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            tween(gStroke1, {Transparency = 0.45}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            tween(gStroke2, {Transparency = 0.6}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            tween(gStroke3, {Transparency = 0.78}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.5)
            tween(glowStroke, {Transparency = 0.5}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            tween(gStroke1, {Transparency = 0.7}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            tween(gStroke2, {Transparency = 0.82}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            tween(gStroke3, {Transparency = 0.92}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.5)
        end
    end)

    local titleBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = T.bgSecondary,
        ZIndex = 11,
        Parent = mainFrame,
    })
    addCorner(titleBar, 12)
    local titleBarFix = create("Frame", {
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 1, -14),
        BackgroundColor3 = T.bgSecondary,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = titleBar,
    })

    makeDraggable(mainFrame, titleBar)

    if opts.Icon then
        create("ImageLabel", {
            Image = opts.Icon,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(0, 14, 0.5, -12),
            ZIndex = 12,
            Parent = titleBar,
        })
    end

    local titleText = create("TextLabel", {
        Text = opts.Title or "MOON",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = T.accent,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 150, 1, 0),
        Position = UDim2.new(0, opts.Icon and 44 or 14, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
        Parent = titleBar,
    })

    local userName = create("TextLabel", {
        Text = player and player.Name or "Player",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = T.textDim,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 120, 1, 0),
        Position = UDim2.new(1, -134, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 12,
        Parent = titleBar,
    })

    local tabBarHeight = 36
    local tabBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, tabBarHeight),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundColor3 = T.bgSecondary,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = mainFrame,
    })

    local tabBarInner = create("ScrollingFrame", {
        Size = UDim2.new(1, -40, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollingDirection = Enum.ScrollingDirection.X,
        ZIndex = 12,
        Parent = tabBar,
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = tabBarInner,
    })
    addPadding(tabBarInner, 0, 4, 0, 8)

    local settingsGear = create("TextButton", {
        Text = "⚙",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = T.textDim,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(1, -38, 0, 0),
        ZIndex = 13,
        Parent = tabBar,
    })

    local contentArea = create("Frame", {
        Size = UDim2.new(1, 0, 1, -(44 + tabBarHeight)),
        Position = UDim2.new(0, 0, 0, 44 + tabBarHeight),
        BackgroundTransparency = 1,
        ZIndex = 10,
        ClipsDescendants = true,
        Parent = mainFrame,
    })

    local settingsPanel = create("ScrollingFrame", {
        Size = UDim2.new(0, 260, 1, -10),
        Position = UDim2.new(1, 0, 0, 5),
        BackgroundColor3 = T.bgSecondary,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 20,
        Parent = mainFrame,
    })
    addCorner(settingsPanel, 10)
    addStroke(settingsPanel, T.border, 1, 0.5)
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = settingsPanel,
    })
    addPadding(settingsPanel, 8, 10, 12, 10)

    local settingsOpen = false

    settingsGear.MouseButton1Click:Connect(function()
        settingsOpen = not settingsOpen
        if settingsOpen then
            settingsPanel.Visible = true
            tween(settingsPanel, {Position = UDim2.new(1, -265, 0, 5)}, 0.3, Enum.EasingStyle.Quart)
        else
            local tw = tween(settingsPanel, {Position = UDim2.new(1, 0, 0, 5)}, 0.3, Enum.EasingStyle.Quart)
            tw.Completed:Connect(function()
                if not settingsOpen then settingsPanel.Visible = false end
            end)
        end
    end)

    local windowOpen = false

    local function toggleWindow()
        if windowOpen then
            local tw = tween(mainFrame, {Size = UDim2.new(0, windowWidth, 0, 0), BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            tw.Completed:Connect(function()
                if not windowOpen then mainFrame.Visible = false end
            end)
            windowOpen = false
        else
            mainFrame.Visible = true
            mainFrame.Size = UDim2.new(0, windowWidth, 0, 0)
            mainFrame.BackgroundTransparency = 1
            tween(mainFrame, {Size = UDim2.new(0, windowWidth, 0, windowHeight), BackgroundTransparency = 0}, 0.35, Enum.EasingStyle.Quart)
            windowOpen = true
        end
    end

    miniIcon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local startPos = input.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    local delta = (input.Position - startPos).Magnitude
                    if delta < 5 then
                        toggleWindow()
                    end
                end
            end)
        end
    end)

    local tabs = {}
    local activeTab = nil

    local Window = {}

    function Window:GetScreenGui()
        return screenGui
    end

    function Window:GetMainFrame()
        return mainFrame
    end

    function Window:GetMiniIcon()
        return miniIcon
    end

    function Window:Destroy()
        screenGui:Destroy()
    end

    function Window:AddSettingsSection(text, order)
        local header = create("TextLabel", {
            Text = text,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = T.text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 26),
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = order or 0,
            ZIndex = 21,
            Parent = settingsPanel,
        })
        local line = create("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = T.border,
            BorderSizePixel = 0,
            LayoutOrder = (order or 0) + 1,
            ZIndex = 21,
            Parent = settingsPanel,
        })
    end

    function Window:AddSettingsToggle(text, default, order, cb)
        local row = create("Frame", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            LayoutOrder = order or 0,
            ZIndex = 21,
            Parent = settingsPanel,
        })
        create("TextLabel", {
            Text = text,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = T.text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -50, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 21,
            Parent = row,
        })

        local pillW, pillH = 32, 16
        local knobSize = 12
        local val = default or false

        local pill = create("Frame", {
            Size = UDim2.new(0, pillW, 0, pillH),
            Position = UDim2.new(1, -pillW, 0.5, -pillH / 2),
            BackgroundColor3 = val and T.toggle_on or T.toggle_off,
            ZIndex = 22,
            Parent = row,
        })
        addCorner(pill, pillH / 2)

        local knob = create("Frame", {
            Size = UDim2.new(0, knobSize, 0, knobSize),
            Position = val and UDim2.new(1, -knobSize - 2, 0.5, -knobSize / 2) or UDim2.new(0, 2, 0.5, -knobSize / 2),
            BackgroundColor3 = Color3.new(1, 1, 1),
            ZIndex = 23,
            Parent = pill,
        })
        addCorner(knob, knobSize / 2)

        pill.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                val = not val
                tween(pill, {BackgroundColor3 = val and T.toggle_on or T.toggle_off}, 0.2)
                tween(knob, {Position = val and UDim2.new(1, -knobSize - 2, 0.5, -knobSize / 2) or UDim2.new(0, 2, 0.5, -knobSize / 2)}, 0.2)
                if cb then cb(val) end
            end
        end)

        return {Value = val, Set = function(_, v) val = v; pill.BackgroundColor3 = v and T.toggle_on or T.toggle_off; knob.Position = v and UDim2.new(1, -knobSize - 2, 0.5, -knobSize / 2) or UDim2.new(0, 2, 0.5, -knobSize / 2) end}
    end

    function Window:AddSettingsButton(text, order, cb)
        local btn = create("TextButton", {
            Text = text,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextColor3 = T.text,
            BackgroundColor3 = T.bgTertiary,
            Size = UDim2.new(1, 0, 0, 30),
            LayoutOrder = order or 0,
            ZIndex = 21,
            Parent = settingsPanel,
        })
        addCorner(btn, 6)
        btn.MouseButton1Click:Connect(function()
            if cb then cb() end
        end)
    end

    function Window:AddSettingsContainer(order)
        local container = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = order or 0,
            ZIndex = 21,
            Parent = settingsPanel,
        })
        return container
    end

    function Window:AddTab(tabOpts)
        local tabContent = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = T.accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            ZIndex = 10,
            Parent = contentArea,
        })
        addPadding(tabContent, 8, 10, 8, 10)

        local leftCol = create("Frame", {
            Size = UDim2.new(0.5, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            ZIndex = 10,
            Parent = tabContent,
        })
        create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = leftCol,
        })

        local rightCol = create("Frame", {
            Size = UDim2.new(0.5, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(0.5, 5, 0, 0),
            BackgroundTransparency = 1,
            ZIndex = 10,
            Parent = tabContent,
        })
        create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = rightCol,
        })

        local function updateCanvasFromColumns()
            task.defer(function()
                local lh = leftCol.AbsoluteSize.Y
                local rh = rightCol.AbsoluteSize.Y
                local maxH = math.max(lh, rh) + 20
                tabContent.CanvasSize = UDim2.new(0, 0, 0, maxH)
            end)
        end

        leftCol:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvasFromColumns)
        rightCol:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvasFromColumns)

        local tabButton = create("TextButton", {
            Text = tabOpts.Name or "Tab",
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextColor3 = T.textDim,
            BackgroundColor3 = T.bgTertiary,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 28),
            AutomaticSize = Enum.AutomaticSize.X,
            ZIndex = 13,
            Parent = tabBarInner,
        })
        addCorner(tabButton, 6)
        addPadding(tabButton, 0, 14, 0, 14)

        local tabData = {
            button = tabButton,
            content = tabContent,
            leftCol = leftCol,
            rightCol = rightCol,
        }
        table.insert(tabs, tabData)

        tabButton.MouseButton1Click:Connect(function()
            for _, t in ipairs(tabs) do
                t.content.Visible = false
                t.button.TextColor3 = T.textDim
                t.button.BackgroundTransparency = 1
            end
            tabData.content.Visible = true
            tabData.button.TextColor3 = T.text
            tween(tabData.button, {BackgroundTransparency = 0.7}, 0.2)
            activeTab = tabData
            updateCanvasFromColumns()
        end)

        if #tabs == 1 then
            tabData.content.Visible = true
            tabData.button.TextColor3 = T.text
            tabData.button.BackgroundTransparency = 0.7
            activeTab = tabData
        end

        local Tab = {}

        function Tab:AddSection(secOpts)
            local side = secOpts.Side or "Left"
            local col = (side == "Right") and rightCol or leftCol

            local sectionFrame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = T.bgSection,
                ZIndex = 10,
                Parent = col,
            })
            addCorner(sectionFrame, 8)
            addStroke(sectionFrame, T.border, 1, 0.7)

            local sectionHeader = create("Frame", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                ZIndex = 11,
                Parent = sectionFrame,
            })

            create("TextLabel", {
                Text = secOpts.Name or "Section",
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = T.text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -80, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 11,
                Parent = sectionHeader,
            })

            local headerRightX = -8
            local Section = {}
            Section.HeaderToggle = nil

            if secOpts.OnSettings then
                local gearBtn = create("TextButton", {
                    Text = "⚙",
                    Font = Enum.Font.GothamBold,
                    TextSize = 14,
                    TextColor3 = T.textDim,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(1, headerRightX - 24, 0.5, -12),
                    ZIndex = 12,
                    Parent = sectionHeader,
                })
                headerRightX = headerRightX - 28
                gearBtn.MouseButton1Click:Connect(function()
                    secOpts.OnSettings(Section)
                end)
            end

            if secOpts.Toggle then
                local toggleElement = MoonLib._makeToggle(sectionHeader, {
                    Name = "",
                    Default = secOpts.Toggle.Default or false,
                    Callback = secOpts.Toggle.Callback,
                }, 12)

                local pill = sectionHeader:FindFirstChildWhichIsA("Frame")
                if pill then
                    pill.Position = UDim2.new(1, headerRightX - 32, 0.5, -8)
                end
                Section.HeaderToggle = toggleElement
            end

            local sectionBody = create("Frame", {
                Size = UDim2.new(1, -16, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0, 8, 0, 32),
                BackgroundTransparency = 1,
                ZIndex = 10,
                Parent = sectionFrame,
            })
            create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
                Parent = sectionBody,
            })

            local spacer = create("Frame", {
                Size = UDim2.new(1, 0, 0, 6),
                BackgroundTransparency = 1,
                LayoutOrder = 99999,
                Parent = sectionBody,
            })

            function Section:GetBody()
                return sectionBody
            end

            function Section:GetFrame()
                return sectionFrame
            end

            function Section:AddToggle(o)
                return MoonLib._makeToggle(sectionBody, o, 10)
            end

            function Section:AddSlider(o)
                return MoonLib._makeSlider(sectionBody, o, 10)
            end

            function Section:AddButton(o)
                return MoonLib._makeButton(sectionBody, o, 10)
            end

            function Section:AddDropdown(o)
                return MoonLib._makeDropdown(sectionBody, o, 10)
            end

            function Section:AddInput(o)
                return MoonLib._makeInput(sectionBody, o, 10)
            end

            function Section:AddLabel(o)
                return MoonLib._makeLabel(sectionBody, o, 10)
            end

            task.defer(updateCanvasFromColumns)

            return Section
        end

        return Tab
    end

    return Window
end

return MoonLib
