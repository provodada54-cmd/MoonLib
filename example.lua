local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
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

local function tw(obj, props, duration, style, dir)
    local ti = TweenInfo.new(
        duration or 0.25,
        style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(obj, ti, props)
    t:Play()
    return t
end

local function create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function addCorner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = parent
    })
end

local function addStroke(parent, color, thickness, transp)
    return create("UIStroke", {
        Color = color or T.border,
        Thickness = thickness or 1,
        Transparency = transp or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

local function addPadding(parent, top, right, bottom, left)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        Parent = parent
    })
end

local function sinkInput(guiObject)
    guiObject.InputBegan:Connect(function(input)
        input.UserInputState = Enum.UserInputState.End
    end)
    guiObject.InputChanged:Connect(function(input)
        input.UserInputState = Enum.UserInputState.End
    end)
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStartPos
    local frameStartPos
    local totalDelta = 0

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
            frameStartPos = frame.Position
            totalDelta = 0
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local currentPos = Vector2.new(input.Position.X, input.Position.Y)
        local delta = currentPos - dragStartPos
        totalDelta = totalDelta + delta.Magnitude
        frame.Position = UDim2.new(
            frameStartPos.X.Scale,
            frameStartPos.X.Offset + delta.X,
            frameStartPos.Y.Scale,
            frameStartPos.Y.Offset + delta.Y
        )
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return function()
        return totalDelta
    end
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

    local container = sg:FindFirstChild("__MoonNotifs")
    if not container then
        container = create("Frame", {
            Name = "__MoonNotifs",
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 260, 1, -20),
            Position = UDim2.new(1, -270, 0, 10),
            ZIndex = 200,
            Parent = sg
        })
        create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            VerticalAlignment = Enum.VerticalAlignment.Top,
            Parent = container
        })
    end

    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = T.bgSecondary,
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 201,
        Parent = container
    })
    addCorner(card, 8)
    addStroke(card, T.accent, 1, 0.4)

    create("Frame", {
        Size = UDim2.new(0, 3, 0.6, 0),
        Position = UDim2.new(0, 6, 0.2, 0),
        BackgroundColor3 = T.accent,
        BorderSizePixel = 0,
        ZIndex = 202,
        Parent = card
    })

    create("TextLabel", {
        Text = text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        ZIndex = 202,
        Parent = card
    })

    tw(card, {BackgroundTransparency = 0.05}, 0.3)

    task.delay(duration, function()
        if card and card.Parent then
            local t = tw(card, {BackgroundTransparency = 1}, 0.4)
            t.Completed:Wait()
            if card and card.Parent then card:Destroy() end
        end
    end)
end

function MoonLib:Prompt(opts)
    local sg = self._screenGui
    if not sg then return end

    local overlay = create("TextButton", {
        Text = "",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.4,
        AutoButtonColor = false,
        ZIndex = 300,
        Parent = sg
    })

    local popW = 340
    local popH = opts.Input and 200 or 155

    local popup = create("Frame", {
        Size = UDim2.new(0, popW, 0, popH),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = T.bg,
        ZIndex = 301,
        Parent = overlay
    })
    addCorner(popup, 12)
    addStroke(popup, T.accent, 2, 0.3)

    create("TextLabel", {
        Text = opts.Title or "Prompt",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = T.text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 10),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 302,
        Parent = popup
    })

    create("TextLabel", {
        Text = opts.Message or "",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = T.textDim,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 40),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        ZIndex = 302,
        Parent = popup
    })

    local inputBox = nil
    local btnY = 100

    if opts.Input then
        btnY = 145
        inputBox = create("TextBox", {
            Text = opts.Default or "",
            PlaceholderText = opts.Placeholder or "",
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = T.text,
            PlaceholderColor3 = T.textFaded,
            BackgroundColor3 = T.bgTertiary,
            Size = UDim2.new(1, -20, 0, 32),
            Position = UDim2.new(0, 10, 0, 78),
            ClearTextOnFocus = false,
            ZIndex = 302,
            Parent = popup
        })
        addCorner(inputBox, 6)
        addPadding(inputBox, 0, 8, 0, 8)
    end

    local function closePrompt()
        if overlay and overlay.Parent then overlay:Destroy() end
    end

    local okBtn = create("TextButton", {
        Text = opts.OkText or "OK",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.new(1, 1, 1),
        BackgroundColor3 = T.accent,
        Size = UDim2.new(0, 100, 0, 30),
        Position = UDim2.new(0.5, -105, 0, btnY),
        AutoButtonColor = false,
        ZIndex = 302,
        Parent = popup
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
        AutoButtonColor = false,
        ZIndex = 302,
        Parent = popup
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

    overlay.MouseButton1Click:Connect(function()
        closePrompt()
        if opts.OnCancel then opts.OnCancel() end
    end)
end

function MoonLib:CreateSubPopup(opts)
    local sg = self._screenGui
    if not sg then return end

    local w = opts.Width or 320
    local h = opts.Height or 340

    local overlay = create("TextButton", {
        Text = "",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.4,
        AutoButtonColor = false,
        ZIndex = 300,
        Parent = sg
    })

    local popup = create("Frame", {
        Size = UDim2.new(0, w, 0, h),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = T.bg,
        ZIndex = 301,
        Parent = overlay
    })
    addCorner(popup, 12)
    addStroke(popup, T.accent, 2, 0.3)

    create("TextLabel", {
        Text = opts.Title or "Settings",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = T.text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -40, 0, 36),
        Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 302,
        Parent = popup
    })

    local closeBtn = create("TextButton", {
        Text = "✕",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = T.textDim,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -34, 0, 3),
        AutoButtonColor = false,
        ZIndex = 303,
        Parent = popup
    })

    local content = create("ScrollingFrame", {
        Size = UDim2.new(1, -16, 1, -44),
        Position = UDim2.new(0, 8, 0, 40),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 302,
        Parent = popup
    })
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = content
    })
    addPadding(content, 4, 4, 4, 4)

    local api = {}

    local function closeFn()
        if overlay and overlay.Parent then overlay:Destroy() end
    end

    closeBtn.MouseButton1Click:Connect(closeFn)
    overlay.MouseButton1Click:Connect(closeFn)

    popup.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
        end
    end)

    function api:Close() closeFn() end

    function api:AddToggle(o)
        return MoonLib._makeToggle(content, o, 302)
    end

    function api:AddSlider(o)
        return MoonLib._makeSlider(content, o, 302)
    end

    function api:AddDropdown(o)
        return MoonLib._makeDropdown(content, o, 302)
    end

    function api:AddLabel(o)
        return MoonLib._makeLabel(content, o, 302)
    end

    function api:AddButton(o)
        return MoonLib._makeButton(content, o, 302)
    end

    return api
end

function MoonLib._makeToggle(parent, opts, zBase)
    zBase = zBase or 10
    local value = opts.Default or false

    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        ZIndex = zBase,
        Parent = parent
    })

    create("TextLabel", {
        Text = opts.Name or "Toggle",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = T.text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -50, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = zBase,
        Parent = row
    })

    local pillW, pillH = 32, 16
    local knobSz = 12

    local pill = create("TextButton", {
        Text = "",
        Size = UDim2.new(0, pillW, 0, pillH),
        Position = UDim2.new(1, -pillW, 0.5, -pillH / 2),
        BackgroundColor3 = value and T.toggle_on or T.toggle_off,
        AutoButtonColor = false,
        ZIndex = zBase + 1,
        Parent = row
    })
    addCorner(pill, pillH / 2)

    local knob = create("Frame", {
        Size = UDim2.new(0, knobSz, 0, knobSz),
        Position = value
            and UDim2.new(1, -knobSz - 2, 0.5, -knobSz / 2)
            or UDim2.new(0, 2, 0.5, -knobSz / 2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = zBase + 2,
        Parent = pill
    })
    addCorner(knob, knobSz / 2)

    local element = { Value = value, _callbacks = {} }

    local function updateVisual(v)
        tw(pill, { BackgroundColor3 = v and T.toggle_on or T.toggle_off }, 0.2)
        tw(knob, {
            Position = v
                and UDim2.new(1, -knobSz - 2, 0.5, -knobSz / 2)
                or UDim2.new(0, 2, 0.5, -knobSz / 2)
        }, 0.2)
    end

    local function setValue(v, fromUser)
        value = v
        element.Value = v
        updateVisual(v)
        if fromUser and opts.Callback then
            opts.Callback(v)
        end
        for _, cb in ipairs(element._callbacks) do
            cb(v)
        end
    end

    pill.MouseButton1Click:Connect(function()
        setValue(not value, true)
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
    local value = math.clamp(opts.Default or min, min, max)

    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        ZIndex = zBase,
        Parent = parent
    })

    create("TextLabel", {
        Text = opts.Name or "Slider",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = T.text,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.6, 0, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = zBase,
        Parent = row
    })

    local function fmtVal(v)
        if decimals <= 0 then
            return tostring(math.floor(v + 0.5))
        end
        return string.format("%." .. decimals .. "f", v)
    end

    local valueLabel = create("TextLabel", {
        Text = fmtVal(value),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = T.textDim,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.4, 0, 0, 18),
        Position = UDim2.new(0.6, 0, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = zBase,
        Parent = row
    })

    local trackH = 5
    local trackBtn = create("TextButton", {
        Text = "",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        ZIndex = zBase + 3,
        Parent = row
    })

    local track = create("Frame", {
        Size = UDim2.new(1, 0, 0, trackH),
        Position = UDim2.new(0, 0, 0.5, -trackH / 2),
        BackgroundColor3 = T.slider_bg,
        ZIndex = zBase + 1,
        Parent = trackBtn
    })
    addCorner(track, trackH / 2)

    local fill = create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = T.accent,
        ZIndex = zBase + 2,
        Parent = track
    })
    addCorner(fill, trackH / 2)

    local knobSz = 14
    local knobFrame = create("Frame", {
        Size = UDim2.new(0, knobSz, 0, knobSz),
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = zBase + 4,
        Parent = track
    })
    addCorner(knobFrame, knobSz / 2)

    local element = { Value = value, _callbacks = {} }

    local function updateVisual(v)
        local pct = math.clamp((v - min) / (max - min), 0, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knobFrame.Position = UDim2.new(pct, -knobSz / 2, 0.5, -knobSz / 2)
        valueLabel.Text = fmtVal(v)
    end

    local function setValue(v, fromUser)
        v = math.clamp(v, min, max)
        if decimals <= 0 then
            v = math.floor(v + 0.5)
        else
            local m = 10 ^ decimals
            v = math.floor(v * m + 0.5) / m
        end
        value = v
        element.Value = v
        updateVisual(v)
        if fromUser and opts.Callback then opts.Callback(v) end
        for _, cb in ipairs(element._callbacks) do cb(v) end
    end

    updateVisual(value)

    local sliding = false

    local function processInput(inputPos)
        local absX = track.AbsolutePosition.X
        local absW = track.AbsoluteSize.X
        if absW <= 0 then return end
        local rel = math.clamp((inputPos.X - absX) / absW, 0, 1)
        local newVal = min + (max - min) * rel
        setValue(newVal, true)
    end

    trackBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            processInput(input.Position)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not sliding then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            processInput(input.Position)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
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

    local containerH_closed = 54
    local itemH = 28
    local listH = #items * itemH
    local containerH_open = containerH_closed + listH

    local container = create("Frame", {
        Size = UDim2.new(1, 0, 0, containerH_closed),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        ZIndex = zBase,
        Parent = parent
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
        Parent = container
    })

    local dropBody = create("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundColor3 = T.bgTertiary,
        ClipsDescendants = true,
        ZIndex = zBase + 1,
        Parent = container
    })
    addCorner(dropBody, 6)
    addStroke(dropBody, T.border, 1, 0.5)

    local selectedLabel = create("TextLabel", {
        Text = tostring(value),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = T.text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -34, 0, 34),
        Position = UDim2.new(0, 10, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = zBase + 5,
        Parent = dropBody
    })

    local arrow = create("TextLabel", {
        Text = "▼",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = T.textDim,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 0, 34),
        Position = UDim2.new(1, -26, 0, 0),
        ZIndex = zBase + 5,
        Rotation = 0,
        Parent = dropBody
    })

    local listFrame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 34),
        BackgroundColor3 = T.bgTertiary,
        ClipsDescendants = true,
        ZIndex = zBase + 2,
        BorderSizePixel = 0,
        Parent = dropBody
    })

    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 0),
        Parent = listFrame
    })

    local itemButtons = {}
    local element = { Value = value, _callbacks = {} }

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

    local function toggleExpand()
        expanded = not expanded
        if expanded then
            tw(dropBody, { Size = UDim2.new(1, 0, 0, 34 + listH) }, 0.25, Enum.EasingStyle.Quart)
            tw(listFrame, { Size = UDim2.new(1, 0, 0, listH) }, 0.25, Enum.EasingStyle.Quart)
            tw(container, { Size = UDim2.new(1, 0, 0, containerH_open) }, 0.25, Enum.EasingStyle.Quart)
            tw(arrow, { Rotation = 180 }, 0.25)
        else
            tw(dropBody, { Size = UDim2.new(1, 0, 0, 34) }, 0.25, Enum.EasingStyle.Quart)
            tw(listFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.25, Enum.EasingStyle.Quart)
            tw(container, { Size = UDim2.new(1, 0, 0, containerH_closed) }, 0.25, Enum.EasingStyle.Quart)
            tw(arrow, { Rotation = 0 }, 0.25)
        end
    end

    for i, item in ipairs(items) do
        local btn = create("TextButton", {
            Text = tostring(item),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = (tostring(item) == tostring(value)) and T.accent or T.text,
            BackgroundColor3 = T.bgTertiary,
            BackgroundTransparency = 0,
            Size = UDim2.new(1, 0, 0, itemH),
            AutoButtonColor = false,
            ZIndex = zBase + 3,
            Parent = listFrame
        })
        btn.MouseEnter:Connect(function()
            tw(btn, { BackgroundColor3 = T.border }, 0.12)
        end)
        btn.MouseLeave:Connect(function()
            tw(btn, { BackgroundColor3 = T.bgTertiary }, 0.12)
        end)
        btn.MouseButton1Click:Connect(function()
            setValue(tostring(item), true)
            toggleExpand()
        end)
        table.insert(itemButtons, btn)
    end

    local headerClick = create("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        AutoButtonColor = false,
        ZIndex = zBase + 6,
        Parent = dropBody
    })
    headerClick.MouseButton1Click:Connect(toggleExpand)

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
        AutoButtonColor = false,
        ZIndex = zBase + 1,
        Parent = parent
    })
    addCorner(btn, 6)
    addStroke(btn, T.border, 1, 0.7)

    btn.MouseEnter:Connect(function()
        tw(btn, { BackgroundColor3 = T.border }, 0.12)
    end)
    btn.MouseLeave:Connect(function()
        tw(btn, { BackgroundColor3 = T.bgTertiary }, 0.12)
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
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        ZIndex = zBase,
        Parent = parent
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
        Parent = row
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
        Parent = row
    })
    addCorner(box, 6)
    addPadding(box, 0, 8, 0, 8)
    addStroke(box, T.border, 1, 0.6)

    local element = { Value = value, _callbacks = {} }

    box.FocusLost:Connect(function()
        value = box.Text
        element.Value = value
        if opts.Callback then opts.Callback(value) end
        for _, cb in ipairs(element._callbacks) do cb(value) end
    end)

    function element:Set(v)
        value = v
        element.Value = v
        box.Text = tostring(v)
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
        Parent = parent
    })
    local element = { Value = opts.Text }
    function element:Set(t)
        lbl.Text = t
        element.Value = t
    end
    function element:Get() return element.Value end
    function element:OnChanged() end
    return element
end

function MoonLib:CreateWindow(opts)
    local windowW = isMobile and 380 or (opts.Size and opts.Size.X.Offset or 480)
    local windowH = isMobile and 500 or (opts.Size and opts.Size.Y.Offset or 560)

    local screenGui = create("ScreenGui", {
        Name = "MoonLib",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 999
    })

    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(screenGui)
        end
    end)

    screenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    self._screenGui = screenGui

    local inputBlocker = create("Frame", {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 1,
        Parent = screenGui
    })

    local miniIcon = create("TextButton", {
        Text = "",
        Size = UDim2.new(0, 52, 0, 52),
        Position = UDim2.new(0, 16, 0.5, -26),
        BackgroundColor3 = T.bg,
        AutoButtonColor = false,
        ZIndex = 50,
        Parent = screenGui
    })
    addCorner(miniIcon, 12)
    addStroke(miniIcon, T.accent, 2, 0.4)

    if opts.Icon then
        create("ImageLabel", {
            Image = opts.Icon,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(0.5, -15, 0.5, -15),
            ZIndex = 52,
            Parent = miniIcon
        })
    else
        create("TextLabel", {
            Text = "M",
            Font = Enum.Font.GothamBold,
            TextSize = 22,
            TextColor3 = T.accent,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 51,
            Parent = miniIcon
        })
    end

    local getDelta = makeDraggable(miniIcon)

    local mainFrame = create("Frame", {
        Size = UDim2.new(0, windowW, 0, windowH),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = T.bg,
        Visible = false,
        ZIndex = 10,
        Parent = screenGui
    })
    addCorner(mainFrame, 12)

    local mainInputSink = create("TextButton", {
        Text = "",
        Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.new(0, -20, 0, -20),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        ZIndex = 9,
        Parent = mainFrame
    })

    local glowLayers = {}

    local function makeGlowLayer(expand, thick, color, baseTransp)
        local f = create("Frame", {
            Size = UDim2.new(1, expand, 1, expand),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ZIndex = 8,
            Parent = mainFrame
        })
        addCorner(f, 12 + expand / 2)
        local s = addStroke(f, color, thick, baseTransp)
        table.insert(glowLayers, { stroke = s, baseTransp = baseTransp })
        return f, s
    end

    local mainStroke = addStroke(mainFrame, T.accent, 2, 0.2)
    table.insert(glowLayers, { stroke = mainStroke, baseTransp = 0.2 })

    makeGlowLayer(8, 2, T.accentGlow, 0.5)
    makeGlowLayer(18, 2, T.accentDim, 0.65)
    makeGlowLayer(30, 2, T.accentDim, 0.78)
    makeGlowLayer(44, 1, T.accentDim, 0.88)

    local glowPhase = 0
    RunService.Heartbeat:Connect(function(dt)
        if not mainFrame or not mainFrame.Parent then return end
        if not mainFrame.Visible then return end
        glowPhase = glowPhase + dt * 1.2
        local pulse = (math.sin(glowPhase) + 1) / 2
        for _, layer in ipairs(glowLayers) do
            local low = layer.baseTransp
            local high = math.min(low + 0.2, 0.98)
            layer.stroke.Transparency = low + (high - low) * (1 - pulse)
        end
    end)

    local titleBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = T.bgSecondary,
        ZIndex = 11,
        Parent = mainFrame
    })
    addCorner(titleBar, 12)

    create("Frame", {
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 1, -16),
        BackgroundColor3 = T.bgSecondary,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = titleBar
    })

    makeDraggable(mainFrame, titleBar)

    local titleStartX = 14
    if opts.Icon then
        create("ImageLabel", {
            Image = opts.Icon,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(0, 14, 0.5, -12),
            ZIndex = 12,
            Parent = titleBar
        })
        titleStartX = 44
    end

    create("TextLabel", {
        Text = opts.Title or "MOON",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = T.accent,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 150, 1, 0),
        Position = UDim2.new(0, titleStartX, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
        Parent = titleBar
    })

    create("TextLabel", {
        Text = player and player.Name or "Player",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = T.textDim,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 120, 1, 0),
        Position = UDim2.new(1, -130, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 12,
        Parent = titleBar
    })

    local tabBarH = 36
    local tabBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, tabBarH),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundColor3 = T.bgSecondary,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = mainFrame
    })

    create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.border,
        BorderSizePixel = 0,
        ZIndex = 12,
        Parent = tabBar
    })

    local tabScroll = create("ScrollingFrame", {
        Size = UDim2.new(1, -8, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollingDirection = Enum.ScrollingDirection.X,
        ZIndex = 12,
        Parent = tabBar
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = tabScroll
    })
    addPadding(tabScroll, 0, 4, 0, 8)

    local contentArea = create("Frame", {
        Size = UDim2.new(1, 0, 1, -(44 + tabBarH)),
        Position = UDim2.new(0, 0, 0, 44 + tabBarH),
        BackgroundTransparency = 1,
        ZIndex = 10,
        ClipsDescendants = true,
        Parent = mainFrame
    })

    local settingsPanel = create("ScrollingFrame", {
        Size = UDim2.new(0, 260, 1, -(44 + tabBarH + 10)),
        Position = UDim2.new(1, 5, 0, 44 + tabBarH + 5),
        BackgroundColor3 = T.bgSecondary,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 60,
        ClipsDescendants = true,
        Parent = mainFrame
    })
    addCorner(settingsPanel, 10)
    addStroke(settingsPanel, T.border, 1, 0.4)
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = settingsPanel
    })
    addPadding(settingsPanel, 8, 10, 12, 10)

    local settingsOpen = false
    local settingsTargetX_open = -265
    local settingsTargetX_closed = 5

    local settingsGear = create("TextButton", {
        Text = "⚙",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = T.textDim,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 36, 0, tabBarH),
        Position = UDim2.new(1, -38, 0, 44),
        AutoButtonColor = false,
        ZIndex = 13,
        Parent = mainFrame
    })

    settingsGear.MouseButton1Click:Connect(function()
        settingsOpen = not settingsOpen
        if settingsOpen then
            settingsPanel.Visible = true
            settingsPanel.Position = UDim2.new(1, settingsTargetX_closed, 0, 44 + tabBarH + 5)
            tw(settingsPanel, {
                Position = UDim2.new(1, settingsTargetX_open, 0, 44 + tabBarH + 5)
            }, 0.3, Enum.EasingStyle.Quart)
            tw(settingsGear, { TextColor3 = T.accent }, 0.2)
        else
            tw(settingsPanel, {
                Position = UDim2.new(1, settingsTargetX_closed, 0, 44 + tabBarH + 5)
            }, 0.3, Enum.EasingStyle.Quart).Completed:Connect(function()
                if not settingsOpen then settingsPanel.Visible = false end
            end)
            tw(settingsGear, { TextColor3 = T.textDim }, 0.2)
        end
    end)

    local windowOpen = false

    local function showWindow()
        if windowOpen then return end
        windowOpen = true
        mainFrame.Visible = true
        mainFrame.Size = UDim2.new(0, windowW, 0, 0)
        mainFrame.BackgroundTransparency = 1
        tw(mainFrame, {
            Size = UDim2.new(0, windowW, 0, windowH),
            BackgroundTransparency = 0
        }, 0.35, Enum.EasingStyle.Quart)
    end

    local function hideWindow()
        if not windowOpen then return end
        windowOpen = false
        local t = tw(mainFrame, {
            Size = UDim2.new(0, windowW, 0, 0),
            BackgroundTransparency = 1
        }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        t.Completed:Connect(function()
            if not windowOpen then mainFrame.Visible = false end
        end)
    end

    miniIcon.MouseButton1Click:Connect(function()
        local delta = getDelta()
        if delta < 6 then
            if windowOpen then
                hideWindow()
            else
                showWindow()
            end
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
        create("TextLabel", {
            Text = text,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = T.text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 26),
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = order or 0,
            ZIndex = 61,
            Parent = settingsPanel
        })
        create("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = T.border,
            BorderSizePixel = 0,
            LayoutOrder = (order or 0) + 1,
            ZIndex = 61,
            Parent = settingsPanel
        })
    end

    function Window:AddSettingsToggle(text, default, order, cb)
        local row = create("Frame", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            LayoutOrder = order or 0,
            ZIndex = 61,
            Parent = settingsPanel
        })
        create("TextLabel", {
            Text = text,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = T.text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -50, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 61,
            Parent = row
        })

        local pillW, pillH = 32, 16
        local knobSz = 12
        local val = default or false

        local pill = create("TextButton", {
            Text = "",
            Size = UDim2.new(0, pillW, 0, pillH),
            Position = UDim2.new(1, -pillW, 0.5, -pillH / 2),
            BackgroundColor3 = val and T.toggle_on or T.toggle_off,
            AutoButtonColor = false,
            ZIndex = 62,
            Parent = row
        })
        addCorner(pill, pillH / 2)

        local knob = create("Frame", {
            Size = UDim2.new(0, knobSz, 0, knobSz),
            Position = val
                and UDim2.new(1, -knobSz - 2, 0.5, -knobSz / 2)
                or UDim2.new(0, 2, 0.5, -knobSz / 2),
            BackgroundColor3 = Color3.new(1, 1, 1),
            ZIndex = 63,
            Parent = pill
        })
        addCorner(knob, knobSz / 2)

        pill.MouseButton1Click:Connect(function()
            val = not val
            tw(pill, { BackgroundColor3 = val and T.toggle_on or T.toggle_off }, 0.2)
            tw(knob, {
                Position = val
                    and UDim2.new(1, -knobSz - 2, 0.5, -knobSz / 2)
                    or UDim2.new(0, 2, 0.5, -knobSz / 2)
            }, 0.2)
            if cb then cb(val) end
        end)

        return {
            Value = val,
            Set = function(_, v)
                val = v
                pill.BackgroundColor3 = v and T.toggle_on or T.toggle_off
                knob.Position = v
                    and UDim2.new(1, -knobSz - 2, 0.5, -knobSz / 2)
                    or UDim2.new(0, 2, 0.5, -knobSz / 2)
            end
        }
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
            AutoButtonColor = false,
            ZIndex = 61,
            Parent = settingsPanel
        })
        addCorner(btn, 6)
        btn.MouseButton1Click:Connect(function()
            if cb then cb() end
        end)
    end

    function Window:AddSettingsContainer(order)
        local c = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = order or 0,
            ZIndex = 61,
            Parent = settingsPanel
        })
        return c
    end

    local function selectTab(tabData)
        for _, td in ipairs(tabs) do
            td.content.Visible = false
            td.button.BackgroundTransparency = 1
            td.button.TextColor3 = T.textDim
        end
        tabData.content.Visible = true
        tabData.button.TextColor3 = T.text
        tw(tabData.button, { BackgroundTransparency = 0.7 }, 0.2)
        activeTab = tabData
    end

    function Window:AddTab(tabOpts)
        local tabContent = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = T.accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false,
            ZIndex = 10,
            Parent = contentArea
        })
        addPadding(tabContent, 8, 10, 8, 10)

        local leftCol = create("Frame", {
            Size = UDim2.new(0.5, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            ZIndex = 10,
            Parent = tabContent
        })
        create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = leftCol
        })

        local rightCol = create("Frame", {
            Size = UDim2.new(0.5, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(0.5, 5, 0, 0),
            BackgroundTransparency = 1,
            ZIndex = 10,
            Parent = tabContent
        })
        create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = rightCol
        })

        local function updateCanvas()
            task.defer(function()
                if not tabContent or not tabContent.Parent then return end
                local lh = leftCol.AbsoluteSize.Y
                local rh = rightCol.AbsoluteSize.Y
                tabContent.CanvasSize = UDim2.new(0, 0, 0, math.max(lh, rh) + 24)
            end)
        end

        leftCol:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)
        rightCol:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)

        local tabButton = create("TextButton", {
            Text = tabOpts.Name or "Tab",
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextColor3 = T.textDim,
            BackgroundColor3 = T.bgTertiary,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 28),
            AutomaticSize = Enum.AutomaticSize.X,
            AutoButtonColor = false,
            ZIndex = 13,
            Parent = tabScroll
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
            selectTab(tabData)
            updateCanvas()
        end)

        if #tabs == 1 then
            selectTab(tabData)
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
                Parent = col
            })
            addCorner(sectionFrame, 8)
            addStroke(sectionFrame, T.border, 1, 0.6)

            local sectionHeader = create("Frame", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1,
                ZIndex = 11,
                Parent = sectionFrame
            })

            create("TextLabel", {
                Text = secOpts.Name or "Section",
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = T.text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -90, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 11,
                Parent = sectionHeader
            })

            local Section = {}
            Section.HeaderToggle = nil

            local rightOffset = -8

            if secOpts.OnSettings then
                local gearBtn = create("TextButton", {
                    Text = "⚙",
                    Font = Enum.Font.GothamBold,
                    TextSize = 14,
                    TextColor3 = T.textDim,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(1, rightOffset - 24, 0.5, -12),
                    AutoButtonColor = false,
                    ZIndex = 12,
                    Parent = sectionHeader
                })
                rightOffset = rightOffset - 28
                gearBtn.MouseButton1Click:Connect(function()
                    secOpts.OnSettings(Section)
                end)
            end

            if secOpts.Toggle then
                local pillW, pillH = 32, 16
                local knobSz = 12
                local toggleVal = secOpts.Toggle.Default or false

                local toggleContainer = create("Frame", {
                    Size = UDim2.new(0, pillW, 0, pillH),
                    Position = UDim2.new(1, rightOffset - pillW, 0.5, -pillH / 2),
                    BackgroundTransparency = 1,
                    ZIndex = 12,
                    Parent = sectionHeader
                })

                local pill = create("TextButton", {
                    Text = "",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = toggleVal and T.toggle_on or T.toggle_off,
                    AutoButtonColor = false,
                    ZIndex = 13,
                    Parent = toggleContainer
                })
                addCorner(pill, pillH / 2)

                local knob = create("Frame", {
                    Size = UDim2.new(0, knobSz, 0, knobSz),
                    Position = toggleVal
                        and UDim2.new(1, -knobSz - 2, 0.5, -knobSz / 2)
                        or UDim2.new(0, 2, 0.5, -knobSz / 2),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    ZIndex = 14,
                    Parent = pill
                })
                addCorner(knob, knobSz / 2)

                local toggleElement = { Value = toggleVal, _callbacks = {} }

                local function setToggle(v, fromUser)
                    toggleVal = v
                    toggleElement.Value = v
                    tw(pill, { BackgroundColor3 = v and T.toggle_on or T.toggle_off }, 0.2)
                    tw(knob, {
                        Position = v
                            and UDim2.new(1, -knobSz - 2, 0.5, -knobSz / 2)
                            or UDim2.new(0, 2, 0.5, -knobSz / 2)
                    }, 0.2)
                    if fromUser and secOpts.Toggle.Callback then
                        secOpts.Toggle.Callback(v)
                    end
                    for _, cb in ipairs(toggleElement._callbacks) do cb(v) end
                end

                pill.MouseButton1Click:Connect(function()
                    setToggle(not toggleVal, true)
                end)

                function toggleElement:Set(v) setToggle(v, false) end
                function toggleElement:Get() return toggleVal end
                function toggleElement:OnChanged(cb) table.insert(self._callbacks, cb) end

                Section.HeaderToggle = toggleElement
            end

            local sectionBody = create("Frame", {
                Size = UDim2.new(1, -16, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0, 8, 0, 34),
                BackgroundTransparency = 1,
                ZIndex = 10,
                Parent = sectionFrame
            })
            create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
                Parent = sectionBody
            })

            create("Frame", {
                Size = UDim2.new(1, 0, 0, 6),
                BackgroundTransparency = 1,
                LayoutOrder = 99999,
                Parent = sectionBody
            })

            function Section:GetBody() return sectionBody end
            function Section:GetFrame() return sectionFrame end

            function Section:AddToggle(o)
                local e = MoonLib._makeToggle(sectionBody, o, 10)
                task.defer(updateCanvas)
                return e
            end

            function Section:AddSlider(o)
                local e = MoonLib._makeSlider(sectionBody, o, 10)
                task.defer(updateCanvas)
                return e
            end

            function Section:AddButton(o)
                local e = MoonLib._makeButton(sectionBody, o, 10)
                task.defer(updateCanvas)
                return e
            end

            function Section:AddDropdown(o)
                local e = MoonLib._makeDropdown(sectionBody, o, 10)
                task.defer(updateCanvas)
                return e
            end

            function Section:AddInput(o)
                local e = MoonLib._makeInput(sectionBody, o, 10)
                task.defer(updateCanvas)
                return e
            end

            function Section:AddLabel(o)
                local e = MoonLib._makeLabel(sectionBody, o, 10)
                task.defer(updateCanvas)
                return e
            end

            task.defer(updateCanvas)
            return Section
        end

        return Tab
    end

    return Window
end

return MoonLib
