local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local MoonLib = {}
MoonLib._version = "2.3.0"
MoonLib._addons = {}
MoonLib._windows = {}
MoonLib._connections = {}

MoonLib._theme = {
    accent = Color3.fromRGB(230, 40, 75),
    accentDim = Color3.fromRGB(160, 25, 50),
    bg = Color3.fromRGB(17, 17, 22),
    bgSecondary = Color3.fromRGB(22, 22, 28),
    bgTertiary = Color3.fromRGB(28, 28, 36),
    bgSection = Color3.fromRGB(24, 24, 30),
    text = Color3.fromRGB(235, 235, 240),
    textDim = Color3.fromRGB(130, 130, 145),
    textFaded = Color3.fromRGB(90, 90, 105),
    border = Color3.fromRGB(40, 40, 50),
    toggle_on = Color3.fromRGB(230, 40, 75),
    toggle_off = Color3.fromRGB(50, 50, 60),
    slider_bg = Color3.fromRGB(45, 45, 55),
    green = Color3.fromRGB(0, 200, 80),
    red = Color3.fromRGB(230, 40, 75),
}

local TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MINI_SIZE = isMobile and 44 or 52
local BASE_SCREEN = 1080

local function tween(obj, props, dur)
    return TweenService:Create(obj, dur and TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) or TWEEN, props):Play()
end

local function create(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then pcall(function() obj[k] = v end) end
    end
    for _, child in ipairs(children or {}) do child.Parent = obj end
    if props and props.Parent then obj.Parent = props.Parent end
    return obj
end

local function corner(parent, r) return create("UICorner", {CornerRadius = UDim.new(0, r or 8), Parent = parent}) end
local function stroke(parent, color, thick) return create("UIStroke", {Color = color or MoonLib._theme.border, Thickness = thick or 1, Parent = parent}) end
local function padding(parent, t, b, l, r)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0), Parent = parent
    })
end

local function getScale()
    local vp = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    return math.clamp(vp.Y / BASE_SCREEN, 0.5, 2)
end

function MoonLib:RegisterAddon(name, addon) self._addons[name] = addon end
function MoonLib:GetAddon(name) return self._addons[name] end
function MoonLib:Connect(sig, fn) local c = sig:Connect(fn); table.insert(self._connections, c); return c end

function MoonLib:Notify(text, duration)
    duration = duration or 3
    local gui = player.PlayerGui:FindFirstChild("MoonLibNotify")
    if not gui then
        gui = create("ScreenGui", {Name = "MoonLibNotify", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, Parent = player.PlayerGui})
    end
    local cont = gui:FindFirstChild("Container")
    if not cont then
        cont = create("Frame", {Name = "Container", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16), Size = UDim2.new(0, 260, 1, -32), Parent = gui})
        create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = cont})
    end
    local n = create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = self._theme.bg, BackgroundTransparency = 0.05, Parent = cont})
    corner(n, 6); stroke(n, self._theme.accent, 1)
    create("Frame", {Size = UDim2.new(0, 3, 1, -8), Position = UDim2.new(0, 4, 0, 4), BackgroundColor3 = self._theme.accent, BorderSizePixel = 0, Parent = n})
    create("TextLabel", {Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = self._theme.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = text, Parent = n})
    task.delay(duration, function() tween(n, {BackgroundTransparency = 1}, 0.3); task.wait(0.35); pcall(function() n:Destroy() end) end)
end

function MoonLib:Prompt(opts)
    opts = opts or {}
    local theme = self._theme
    local gui = player.PlayerGui:FindFirstChild("MoonLibPrompts")
    if not gui then
        gui = create("ScreenGui", {Name = "MoonLibPrompts", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 500, Parent = player.PlayerGui})
    end
    local overlay = create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, BorderSizePixel = 0, Parent = gui})
    local frame = create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 320, 0, opts.Input and 160 or 130), BackgroundColor3 = theme.bg, BorderSizePixel = 0, Parent = overlay})
    corner(frame, 10); stroke(frame, theme.accent, 1)
    create("TextLabel", {Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 10), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = theme.accent, TextXAlignment = Enum.TextXAlignment.Left, Text = opts.Title or "Prompt", Parent = frame})
    create("TextLabel", {Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 36), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = theme.text, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Text = opts.Message or "", Parent = frame})

    local inputBox
    if opts.Input then
        inputBox = create("TextBox", {Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 72), BackgroundColor3 = theme.bgTertiary, BorderSizePixel = 0, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = theme.text, PlaceholderText = opts.Placeholder or "", PlaceholderColor3 = theme.textDim, Text = opts.Default or "", TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = frame})
        corner(inputBox, 4); padding(inputBox, 0, 0, 8, 8)
    end

    local btnY = opts.Input and 108 or 78
    local cancelBtn = create("TextButton", {Size = UDim2.new(0.5, -14, 0, 32), Position = UDim2.new(0, 10, 0, btnY), BackgroundColor3 = theme.bgTertiary, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = theme.text, Text = opts.CancelText or "Cancel", AutoButtonColor = false, BorderSizePixel = 0, Parent = frame})
    corner(cancelBtn, 6)
    local okBtn = create("TextButton", {Size = UDim2.new(0.5, -14, 0, 32), Position = UDim2.new(0.5, 4, 0, btnY), BackgroundColor3 = theme.accent, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = theme.text, Text = opts.OkText or "OK", AutoButtonColor = false, BorderSizePixel = 0, Parent = frame})
    corner(okBtn, 6)

    local function close() pcall(function() overlay:Destroy() end) end
    cancelBtn.MouseButton1Click:Connect(function() close(); if opts.OnCancel then pcall(opts.OnCancel) end end)
    okBtn.MouseButton1Click:Connect(function()
        local val = inputBox and inputBox.Text or nil
        close()
        if opts.OnConfirm then pcall(opts.OnConfirm, val) end
    end)
end

function MoonLib:CreateSubPopup(opts)
    opts = opts or {}
    local theme = self._theme
    local gui = player.PlayerGui:FindFirstChild("MoonLibSubPopups")
    if not gui then
        gui = create("ScreenGui", {Name = "MoonLibSubPopups", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 300, Parent = player.PlayerGui})
    end

    local overlay = create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = gui})

    local frame = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, opts.Width or 300, 0, opts.Height or 340),
        BackgroundColor3 = theme.bg,
        BorderSizePixel = 0,
        Parent = overlay,
    })
    corner(frame, 10)
    stroke(frame, theme.accent, 1)

    local titleBar = create("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = theme.bgSecondary, BorderSizePixel = 0, Parent = frame})
    corner(titleBar, 10)
    create("Frame", {Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14), BackgroundColor3 = theme.bgSecondary, BorderSizePixel = 0, Parent = titleBar})

    create("TextLabel", {Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = theme.accent, TextXAlignment = Enum.TextXAlignment.Left, Text = opts.Title or "Settings", Parent = titleBar})

    local closeBtn = create("TextButton", {Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -30, 0.5, -12), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = theme.text, Text = "×", AutoButtonColor = false, Parent = titleBar})

    local body = create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -40),
        Position = UDim2.new(0, 0, 0, 38),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = frame,
    })
    create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = body})
    padding(body, 6, 10, 12, 12)

    local function close() pcall(function() overlay:Destroy() end) end
    closeBtn.MouseButton1Click:Connect(close)
    overlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mp = UserInputService:GetMouseLocation()
            local ap = frame.AbsolutePosition
            local as = frame.AbsoluteSize
            if mp.X < ap.X or mp.X > ap.X + as.X or mp.Y - 36 < ap.Y or mp.Y - 36 > ap.Y + as.Y then
                close()
            end
        end
    end)

    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(0, 0, 0, 0)
    tween(frame, {Size = UDim2.new(0, opts.Width or 300, 0, opts.Height or 340), BackgroundTransparency = 0}, 0.2)

    local API = {}
    API.body = body
    API.frame = frame
    API.overlay = overlay
    function API:Close() close() end

    function API:AddToggle(o)
        o = o or {}
        local T = {Value = o.Default or false, _callbacks = {}}
        local row = create("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = theme.bgSecondary, BorderSizePixel = 0, Parent = body})
        corner(row, 6)
        create("TextLabel", {Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = theme.text, TextXAlignment = Enum.TextXAlignment.Left, Text = o.Name or "Toggle", Parent = row})
        local tBg = create("Frame", {Size = UDim2.new(0, 30, 0, 14), Position = UDim2.new(1, -40, 0.5, -7), BackgroundColor3 = T.Value and theme.toggle_on or theme.toggle_off, BorderSizePixel = 0, Parent = row})
        corner(tBg, 7)
        local k = create("Frame", {Size = UDim2.new(0, 10, 0, 10), Position = T.Value and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Parent = tBg})
        corner(k, 5)
        local btn = create("TextButton", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = row})
        btn.MouseButton1Click:Connect(function()
            T.Value = not T.Value
            tween(tBg, {BackgroundColor3 = T.Value and theme.toggle_on or theme.toggle_off})
            tween(k, {Position = T.Value and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5)})
            for _, cb in ipairs(T._callbacks) do pcall(cb, T.Value) end
            if o.Callback then pcall(o.Callback, T.Value) end
        end)
        function T:Set(v) self.Value = v; tween(tBg, {BackgroundColor3 = v and theme.toggle_on or theme.toggle_off}); tween(k, {Position = v and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5)}); for _, cb in ipairs(self._callbacks) do pcall(cb, v) end end
        function T:OnChanged(cb) table.insert(self._callbacks, cb) end
        return T
    end

    function API:AddSlider(o)
        o = o or {}
        local mn, mx = o.Min or 0, o.Max or 100
        local dec = o.Decimals or 0
        local S = {Value = o.Default or mn, _callbacks = {}}
        local row = create("Frame", {Size = UDim2.new(1,0,0,42), BackgroundTransparency = 1, Parent = body})
        create("TextLabel", {Size = UDim2.new(0.6,0,0,16), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = theme.text, TextXAlignment = Enum.TextXAlignment.Left, Text = o.Name or "Slider", Parent = row})
        local valLbl = create("TextLabel", {Size = UDim2.new(0.4,0,0,16), Position = UDim2.new(0.6,0,0,0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = theme.accent, TextXAlignment = Enum.TextXAlignment.Right, Text = dec > 0 and string.format("%."..dec.."f", S.Value) or tostring(math.floor(S.Value)), Parent = row})
        local track = create("Frame", {Size = UDim2.new(1,0,0,5), Position = UDim2.new(0,0,0,26), BackgroundColor3 = theme.slider_bg, BorderSizePixel = 0, Parent = row})
        corner(track, 3)
        local fill = create("Frame", {Size = UDim2.new((S.Value - mn) / math.max(mx - mn, 0.001), 0, 1, 0), BackgroundColor3 = theme.accent, BorderSizePixel = 0, Parent = track})
        corner(fill, 3)
        local knob = create("Frame", {Size = UDim2.new(0,12,0,12), AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new((S.Value - mn) / math.max(mx - mn, 0.001), 0, 0.5, 0), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ZIndex = 2, Parent = track})
        corner(knob, 6)
        local sliding = false
        local function upd(pos)
            local rel = math.clamp((pos.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
            local v = mn + (mx - mn) * rel
            if dec > 0 then v = math.floor(v * (10^dec) + 0.5) / (10^dec) else v = math.floor(v + 0.5) end
            v = math.clamp(v, mn, mx); S.Value = v
            fill.Size = UDim2.new((v - mn) / math.max(mx - mn, 0.001), 0, 1, 0)
            knob.Position = UDim2.new((v - mn) / math.max(mx - mn, 0.001), 0, 0.5, 0)
            valLbl.Text = dec > 0 and string.format("%."..dec.."f", v) or tostring(math.floor(v))
            for _, cb in ipairs(S._callbacks) do pcall(cb, v) end
            if o.Callback then pcall(o.Callback, v) end
        end
        track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = true; upd(i.Position) end end)
        knob.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = true end end)
        MoonLib:Connect(UserInputService.InputChanged, function(i) if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i.Position) end end)
        MoonLib:Connect(UserInputService.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = false end end)
        function S:Set(v) v = math.clamp(v, mn, mx); self.Value = v; fill.Size = UDim2.new((v - mn) / math.max(mx - mn, 0.001), 0, 1, 0); knob.Position = UDim2.new((v - mn) / math.max(mx - mn, 0.001), 0, 0.5, 0); valLbl.Text = dec > 0 and string.format("%."..dec.."f", v) or tostring(math.floor(v)) end
        function S:OnChanged(cb) table.insert(self._callbacks, cb) end
        return S
    end

    function API:AddDropdown(o)
        o = o or {}
        local items = o.Items or {}
        local D = {Value = o.Default or (items[1] or ""), _callbacks = {}, _open = false, _items = items}
        local row = create("Frame", {Size = UDim2.new(1,0,0,42), BackgroundTransparency = 1, Parent = body})
        create("TextLabel", {Size = UDim2.new(1,0,0,16), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = theme.text, TextXAlignment = Enum.TextXAlignment.Left, Text = o.Name or "Dropdown", Parent = row})
        local dropBtn = create("TextButton", {Size = UDim2.new(1,0,0,22), Position = UDim2.new(0,0,0,20), BackgroundColor3 = theme.bgTertiary, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = theme.text, Text = tostring(D.Value).."  ▼", AutoButtonColor = false, BorderSizePixel = 0, Parent = row})
        corner(dropBtn, 4)
        local dropList = create("Frame", {Size = UDim2.new(1,0,0,0), Position = UDim2.new(0,0,1,2), BackgroundColor3 = theme.bgTertiary, BorderSizePixel = 0, ClipsDescendants = true, Visible = false, ZIndex = 100, Parent = dropBtn})
        corner(dropList, 4); stroke(dropList, theme.accent, 1)
        create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,1), Parent = dropList})
        for idx, it in ipairs(items) do
            local ib = create("TextButton", {Size = UDim2.new(1,0,0,20), BackgroundColor3 = theme.bg, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = theme.text, Text = tostring(it), AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = idx, ZIndex = 101, Parent = dropList})
            ib.MouseButton1Click:Connect(function()
                D.Value = it; dropBtn.Text = tostring(it).."  ▼"; dropList.Visible = false; D._open = false
                for _, cb in ipairs(D._callbacks) do pcall(cb, it) end
                if o.Callback then pcall(o.Callback, it) end
            end)
        end
        dropBtn.MouseButton1Click:Connect(function()
            D._open = not D._open; dropList.Visible = D._open
            dropList.Size = UDim2.new(1,0,0, D._open and (#D._items * 21) or 0)
        end)
        function D:Set(v) self.Value = v; dropBtn.Text = tostring(v).."  ▼" end
        function D:OnChanged(cb) table.insert(self._callbacks, cb) end
        return D
    end

    function API:AddLabel(o)
        o = o or {}
        local lbl = create("TextLabel", {Size = UDim2.new(1,0,0,16), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = theme.textDim, TextXAlignment = Enum.TextXAlignment.Left, Text = o.Text or "", Parent = body})
        function lbl:SetText(t) lbl.Text = t end
        return lbl
    end

    return API
end

function MoonLib:CreateWindow(options)
    options = options or {}
    local title = options.Title or "MOON"
    local icon = options.Icon or "rbxassetid://80973987032851"
    local size = options.Size or (isMobile and UDim2.new(0, 380, 0, 500) or UDim2.new(0, 480, 0, 560))

    local Window = {tabs = {}, activeTab = nil, open = true, _settingsOrder = 0}

    local screenGui = create("ScreenGui", {
        Name = "MoonLibUI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui")
    })
    table.insert(self._windows, screenGui)

    local uiScale = create("UIScale", {Scale = getScale(), Parent = screenGui})
    self:Connect(camera:GetPropertyChangedSignal("ViewportSize"), function() tween(uiScale, {Scale = getScale()}) end)

    local miniIcon = create("ImageButton", {
        Name = "MiniIcon",
        Size = UDim2.new(0, MINI_SIZE, 0, MINI_SIZE),
        Position = UDim2.new(0, 16, 0, 100),
        BackgroundColor3 = self._theme.bg,
        Image = icon,
        ScaleType = Enum.ScaleType.Fit,
        AutoButtonColor = false,
        Active = true,
        Parent = screenGui,
    })
    corner(miniIcon, 12)
    stroke(miniIcon, self._theme.accent, 2)
    padding(miniIcon, 4, 4, 4, 4)

    local mainFrame = create("Frame", {
        Name = "MainFrame",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = size,
        BackgroundColor3 = self._theme.bg,
        ClipsDescendants = true,
        Active = true,
        Parent = screenGui,
    })
    corner(mainFrame, 10)
    stroke(mainFrame, self._theme.border, 1)

    local titleBar = create("Frame", {Name = "TitleBar", Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = self._theme.bgSecondary, BorderSizePixel = 0, Parent = mainFrame})
    corner(titleBar, 10)
    create("Frame", {Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14), BackgroundColor3 = self._theme.bgSecondary, BorderSizePixel = 0, Parent = titleBar})

    create("ImageLabel", {Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(0, 14, 0.5, -11), BackgroundTransparency = 1, Image = icon, ScaleType = Enum.ScaleType.Fit, Parent = titleBar})
    create("TextLabel", {Size = UDim2.new(0, 250, 1, 0), Position = UDim2.new(0, 44, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = self._theme.accent, TextXAlignment = Enum.TextXAlignment.Left, Text = title, Parent = titleBar})
    create("TextLabel", {Size = UDim2.new(0, 140, 1, 0), Position = UDim2.new(1, -156, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = self._theme.textDim, TextXAlignment = Enum.TextXAlignment.Right, Text = player.DisplayName, Parent = titleBar})

    local tabBar = create("Frame", {Name = "TabBar", Size = UDim2.new(1, -16, 0, 32), Position = UDim2.new(0, 8, 0, 48), BackgroundTransparency = 1, Parent = mainFrame})
    local tabScroll = create("ScrollingFrame", {Size = UDim2.new(1, -40, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, Parent = tabBar})
    create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center, Parent = tabScroll})

    local settingsGear = create("ImageButton", {Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -30, 0.5, -12), BackgroundColor3 = self._theme.bgTertiary, BackgroundTransparency = 0.3, Image = "rbxassetid://7734053495", ImageColor3 = self._theme.textDim, AutoButtonColor = false, Parent = tabBar})
    corner(settingsGear, 6)

    local contentFrame = create("Frame", {Name = "Content", Size = UDim2.new(1, -16, 1, -92), Position = UDim2.new(0, 8, 0, 84), BackgroundTransparency = 1, ClipsDescendants = true, Parent = mainFrame})

    local settingsPanel = create("Frame", {Name = "SettingsPanel", Size = UDim2.new(1, -16, 1, -92), Position = UDim2.new(1, 8, 0, 84), BackgroundColor3 = self._theme.bgSection, BorderSizePixel = 0, ClipsDescendants = true, Parent = mainFrame})
    corner(settingsPanel, 8)
    local settingsScroll = create("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = self._theme.accent, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = settingsPanel})
    create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = settingsScroll})
    padding(settingsScroll, 12, 12, 14, 14)

    local settingsOpen = false
    local function toggleSettings()
        settingsOpen = not settingsOpen
        if settingsOpen then
            tween(contentFrame, {Position = UDim2.new(-1, -8, 0, 84)})
            tween(settingsPanel, {Position = UDim2.new(0, 8, 0, 84)})
            tween(settingsGear, {ImageColor3 = self._theme.accent, BackgroundColor3 = self._theme.accentDim})
        else
            tween(contentFrame, {Position = UDim2.new(0, 8, 0, 84)})
            tween(settingsPanel, {Position = UDim2.new(1, 8, 0, 84)})
            tween(settingsGear, {ImageColor3 = self._theme.textDim, BackgroundColor3 = self._theme.bgTertiary})
        end
    end
    settingsGear.MouseButton1Click:Connect(toggleSettings)

    local isTransitioning = false
    local function setOpen(state)
        if isTransitioning then return end
        Window.open = state
        isTransitioning = true
        if state then
            mainFrame.Visible = true
            mainFrame.Size = UDim2.new(0, 0, 0, 0)
            mainFrame.BackgroundTransparency = 1
            tween(mainFrame, {Size = size, BackgroundTransparency = 0}, 0.25)
            task.delay(0.26, function() isTransitioning = false end)
        else
            tween(mainFrame, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.2)
            task.delay(0.22, function()
                if not Window.open then mainFrame.Visible = false end
                isTransitioning = false
            end)
        end
    end

    do
        local dragging, dragStart, frameStart = false, nil, nil
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = input.Position; frameStart = mainFrame.Position
            end
        end)
        titleBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
        self:Connect(UserInputService.InputChanged, function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                mainFrame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + d.X, frameStart.Y.Scale, frameStart.Y.Offset + d.Y)
            end
        end)
    end

    do
        local mDragging = false
        local mDragStart = nil
        local mFrameStart = nil
        local mMoved = false
        local mActiveInputType = nil

        miniIcon.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                mDragging = true; mMoved = false
                mDragStart = input.Position; mFrameStart = miniIcon.Position
                mActiveInputType = input.UserInputType
            end
        end)

        self:Connect(UserInputService.InputChanged, function(input)
            if not mDragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local d = input.Position - mDragStart
                if math.abs(d.X) > 6 or math.abs(d.Y) > 6 then mMoved = true end
                if mMoved then
                    miniIcon.Position = UDim2.new(mFrameStart.X.Scale, mFrameStart.X.Offset + d.X, mFrameStart.Y.Scale, mFrameStart.Y.Offset + d.Y)
                end
            end
        end)

        self:Connect(UserInputService.InputEnded, function(input)
            if not mDragging then return end
            if input.UserInputType ~= mActiveInputType and input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local wasMoved = mMoved
            mDragging = false; mMoved = false; mActiveInputType = nil
            if not wasMoved then setOpen(not Window.open) end
        end)
    end

    function Window:AddSettingsSection(text, order)
        order = order or (Window._settingsOrder + 1)
        Window._settingsOrder = order
        return create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13,
            TextColor3 = MoonLib._theme.accent, TextXAlignment = Enum.TextXAlignment.Left, Text = text,
            LayoutOrder = order, Parent = settingsScroll
        })
    end

    function Window:AddSettingsToggle(text, default, order, callback)
        order = order or (Window._settingsOrder + 1)
        Window._settingsOrder = order
        local row = create("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = MoonLib._theme.bgSecondary, BorderSizePixel = 0, LayoutOrder = order, Parent = settingsScroll})
        corner(row, 6)
        create("TextLabel", {Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = MoonLib._theme.text, TextXAlignment = Enum.TextXAlignment.Left, Text = text, Parent = row})
        local state = default or false
        local tBg = create("Frame", {Size = UDim2.new(0, 34, 0, 16), Position = UDim2.new(1, -42, 0.5, -8), BackgroundColor3 = state and MoonLib._theme.toggle_on or MoonLib._theme.toggle_off, BorderSizePixel = 0, Parent = row})
        corner(tBg, 8)
        local knob = create("Frame", {Size = UDim2.new(0, 12, 0, 12), Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = tBg})
        corner(knob, 6)
        local btn = create("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = row})
        btn.MouseButton1Click:Connect(function()
            state = not state
            tween(tBg, {BackgroundColor3 = state and MoonLib._theme.toggle_on or MoonLib._theme.toggle_off})
            tween(knob, {Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)})
            if callback then callback(state) end
        end)
        return {
            Set = function(_, v) state = v; tween(tBg, {BackgroundColor3 = state and MoonLib._theme.toggle_on or MoonLib._theme.toggle_off}); tween(knob, {Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}) end,
            Get = function() return state end,
        }
    end

    function Window:AddSettingsButton(text, order, callback)
        order = order or (Window._settingsOrder + 1)
        Window._settingsOrder = order
        local btn = create("TextButton", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = MoonLib._theme.bgSecondary, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = MoonLib._theme.text, Text = text, AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = order, Parent = settingsScroll})
        corner(btn, 6)
        btn.MouseButton1Click:Connect(function()
            tween(btn, {BackgroundColor3 = MoonLib._theme.accent}, 0.1)
            task.delay(0.15, function() tween(btn, {BackgroundColor3 = MoonLib._theme.bgSecondary}, 0.1) end)
            if callback then callback() end
        end)
        return btn
    end

    function Window:AddSettingsContainer(order)
        order = order or (Window._settingsOrder + 1)
        Window._settingsOrder = order
        local frame = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = MoonLib._theme.bgSecondary,
            BorderSizePixel = 0,
            LayoutOrder = order,
            ClipsDescendants = true,
            Parent = settingsScroll
        })
        corner(frame, 6)
        create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = frame})
        padding(frame, 10, 10, 12, 12)
        return frame
    end

    function Window:GetSettingsScroll() return settingsScroll end
    function Window:GetScreenGui() return screenGui end
    function Window:GetMainFrame() return mainFrame end
    function Window:GetMiniIcon() return miniIcon end

    function Window:AddTab(tabOpts)
        tabOpts = tabOpts or {}
        local tabName = tabOpts.Name or "Tab"
        local tabIcon = tabOpts.Icon

        local Tab = {name = tabName, sections = {}}

        local btnText = tabIcon and ("  " .. tabName) or tabName
        local w = TextService:GetTextSize(btnText, 12, Enum.Font.GothamBold, Vector2.new(1000, 100)).X + (tabIcon and 24 or 20)
        local tabBtn = create("TextButton", {Size = UDim2.new(0, w, 0, 26), BackgroundColor3 = MoonLib._theme.bgTertiary, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = MoonLib._theme.textDim, Text = btnText, AutoButtonColor = false, BorderSizePixel = 0, Parent = tabScroll})
        corner(tabBtn, 6)
        if tabIcon then
            create("ImageLabel", {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 8, 0.5, -7), BackgroundTransparency = 1, Image = tabIcon, ImageColor3 = MoonLib._theme.textDim, Parent = tabBtn})
        end

        local tabPage = create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, Parent = contentFrame})

        local leftCol = create("ScrollingFrame", {Size = UDim2.new(0.5, -4, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = MoonLib._theme.accent, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = tabPage})
        create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = leftCol})
        padding(leftCol, 2, 6, 2, 4)

        local rightCol = create("ScrollingFrame", {Size = UDim2.new(0.5, -4, 1, 0), Position = UDim2.new(0.5, 4, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = MoonLib._theme.accent, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = tabPage})
        create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = rightCol})
        padding(rightCol, 2, 6, 4, 2)

        Tab.leftCol = leftCol; Tab.rightCol = rightCol; Tab.page = tabPage; Tab.button = tabBtn

        function Tab:AddSection(sOpts)
            sOpts = sOpts or {}
            local sName = sOpts.Name or "Section"
            local side = sOpts.Side or "Left"
            local parent = side == "Right" and rightCol or leftCol

            local Section = {_settingsCallback = nil}

            local secFrame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = MoonLib._theme.bgSection,
                BorderSizePixel = 0,
                LayoutOrder = #Tab.sections + 1,
                ClipsDescendants = false,
                Parent = parent
            })
            corner(secFrame, 8)
            stroke(secFrame, MoonLib._theme.border, 1)

            create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 0),
                FillDirection = Enum.FillDirection.Vertical,
                Parent = secFrame
            })

            local headerRow = create("Frame", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Parent = secFrame
            })

            create("TextLabel", {
                Size = UDim2.new(1, -80, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = MoonLib._theme.text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = sName,
                Parent = headerRow
            })

            local headerToggle
            if sOpts.Toggle then
                headerToggle = {Value = sOpts.Toggle.Default or false, _callbacks = {}}
                local tBg = create("Frame", {Size = UDim2.new(0, 30, 0, 14), Position = UDim2.new(1, -42, 0.5, -7), BackgroundColor3 = headerToggle.Value and MoonLib._theme.toggle_on or MoonLib._theme.toggle_off, BorderSizePixel = 0, Parent = headerRow})
                corner(tBg, 7)
                local k = create("Frame", {Size = UDim2.new(0, 10, 0, 10), Position = headerToggle.Value and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = tBg})
                corner(k, 5)
                local btn = create("TextButton", {Size = UDim2.new(0, 40, 1, 0), Position = UDim2.new(1, -46, 0, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = headerRow})
                btn.MouseButton1Click:Connect(function()
                    headerToggle.Value = not headerToggle.Value
                    tween(tBg, {BackgroundColor3 = headerToggle.Value and MoonLib._theme.toggle_on or MoonLib._theme.toggle_off})
                    tween(k, {Position = headerToggle.Value and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)})
                    for _, cb in ipairs(headerToggle._callbacks) do pcall(cb, headerToggle.Value) end
                    if sOpts.Toggle.Callback then pcall(sOpts.Toggle.Callback, headerToggle.Value) end
                end)
                function headerToggle:Set(v)
                    self.Value = v
                    tween(tBg, {BackgroundColor3 = v and MoonLib._theme.toggle_on or MoonLib._theme.toggle_off})
                    tween(k, {Position = v and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)})
                    for _, cb in ipairs(self._callbacks) do pcall(cb, v) end
                end
                function headerToggle:OnChanged(cb) table.insert(self._callbacks, cb) end
                Section.HeaderToggle = headerToggle
            end

            local gearButton
            if sOpts.OnSettings then
                local gearOffset = headerToggle and 74 or 34
                gearButton = create("ImageButton", {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -gearOffset, 0.5, -8), BackgroundTransparency = 1, Image = "rbxassetid://7734053495", ImageColor3 = MoonLib._theme.textFaded, AutoButtonColor = false, Parent = headerRow})
                gearButton.MouseButton1Click:Connect(function() pcall(sOpts.OnSettings, Section) end)
            end

            local body = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 2,
                Parent = secFrame
            })
            padding(body, 4, 10, 12, 12)
            create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8),
                Parent = body
            })

            local elemOrder = 0
            local function next_() elemOrder = elemOrder + 1; return elemOrder end

            function Section:AddToggle(opts)
                opts = opts or {}
                local T = {Value = opts.Default or false, _callbacks = {}}
                local row = create("Frame", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = next_(), Parent = body})
                create("TextLabel", {Size = UDim2.new(1, -42, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = MoonLib._theme.text, TextXAlignment = Enum.TextXAlignment.Left, Text = opts.Name or "Toggle", Parent = row})
                local tBg = create("Frame", {Size = UDim2.new(0, 30, 0, 14), Position = UDim2.new(1, -32, 0.5, -7), BackgroundColor3 = T.Value and MoonLib._theme.toggle_on or MoonLib._theme.toggle_off, BorderSizePixel = 0, Parent = row})
                corner(tBg, 7)
                local k = create("Frame", {Size = UDim2.new(0, 10, 0, 10), Position = T.Value and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = tBg})
                corner(k, 5)
                local btn = create("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = row})
                btn.MouseButton1Click:Connect(function()
                    T.Value = not T.Value
                    tween(tBg, {BackgroundColor3 = T.Value and MoonLib._theme.toggle_on or MoonLib._theme.toggle_off})
                    tween(k, {Position = T.Value and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)})
                    for _, cb in ipairs(T._callbacks) do pcall(cb, T.Value) end
                    if opts.Callback then pcall(opts.Callback, T.Value) end
                end)
                function T:Set(v) self.Value = v; tween(tBg, {BackgroundColor3 = v and MoonLib._theme.toggle_on or MoonLib._theme.toggle_off}); tween(k, {Position = v and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)}); for _, cb in ipairs(self._callbacks) do pcall(cb, v) end end
                function T:OnChanged(cb) table.insert(self._callbacks, cb) end
                return T
            end

            function Section:AddSlider(opts)
                opts = opts or {}
                local mn, mx = opts.Min or 0, opts.Max or 100
                local dec = opts.Decimals or 0
                local S = {Value = opts.Default or mn, _callbacks = {}}
                local row = create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, LayoutOrder = next_(), Parent = body})
                local nameLbl = create("TextLabel", {Size = UDim2.new(0.6, 0, 0, 16), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = MoonLib._theme.text, TextXAlignment = Enum.TextXAlignment.Left, Text = opts.Name or "Slider", Parent = row})
                local valLbl = create("TextLabel", {Size = UDim2.new(0.4, 0, 0, 16), Position = UDim2.new(0.6, 0, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = MoonLib._theme.accent, TextXAlignment = Enum.TextXAlignment.Right, Text = dec > 0 and string.format("%."..dec.."f", S.Value) or tostring(math.floor(S.Value)), Parent = row})
                local track = create("Frame", {Size = UDim2.new(1, 0, 0, 5), Position = UDim2.new(0, 0, 0, 24), BackgroundColor3 = MoonLib._theme.slider_bg, BorderSizePixel = 0, Parent = row})
                corner(track, 3)
                local fill = create("Frame", {Size = UDim2.new((S.Value - mn) / math.max(mx - mn, 0.001), 0, 1, 0), BackgroundColor3 = MoonLib._theme.accent, BorderSizePixel = 0, Parent = track})
                corner(fill, 3)
                local knob = create("Frame", {Size = UDim2.new(0, 12, 0, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((S.Value - mn) / math.max(mx - mn, 0.001), 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 2, Parent = track})
                corner(knob, 6)
                local sliding = false
                local function update(pos)
                    local rel = math.clamp((pos.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                    local v = mn + (mx - mn) * rel
                    if dec > 0 then v = math.floor(v * (10^dec) + 0.5) / (10^dec) else v = math.floor(v + 0.5) end
                    v = math.clamp(v, mn, mx)
                    S.Value = v
                    fill.Size = UDim2.new((v - mn) / math.max(mx - mn, 0.001), 0, 1, 0)
                    knob.Position = UDim2.new((v - mn) / math.max(mx - mn, 0.001), 0, 0.5, 0)
                    valLbl.Text = dec > 0 and string.format("%."..dec.."f", v) or tostring(math.floor(v))
                    for _, cb in ipairs(S._callbacks) do pcall(cb, v) end
                    if opts.Callback then pcall(opts.Callback, v) end
                end
                track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = true; update(i.Position) end end)
                knob.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = true end end)
                MoonLib:Connect(UserInputService.InputChanged, function(i) if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i.Position) end end)
                MoonLib:Connect(UserInputService.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = false end end)
                function S:Set(v) v = math.clamp(v, mn, mx); self.Value = v; fill.Size = UDim2.new((v - mn) / math.max(mx - mn, 0.001), 0, 1, 0); knob.Position = UDim2.new((v - mn) / math.max(mx - mn, 0.001), 0, 0.5, 0); valLbl.Text = dec > 0 and string.format("%."..dec.."f", v) or tostring(math.floor(v)) end
                function S:OnChanged(cb) table.insert(self._callbacks, cb) end
                return S
            end

            function Section:AddButton(opts)
                opts = opts or {}
                local btn = create("TextButton", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = MoonLib._theme.bgTertiary, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = MoonLib._theme.text, Text = opts.Name or "Button", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = next_(), Parent = body})
                corner(btn, 6)
                btn.MouseButton1Click:Connect(function()
                    tween(btn, {BackgroundColor3 = MoonLib._theme.accent}, 0.1)
                    task.delay(0.15, function() tween(btn, {BackgroundColor3 = MoonLib._theme.bgTertiary}, 0.1) end)
                    if opts.Callback then pcall(opts.Callback) end
                end)
                return btn
            end

            function Section:AddDropdown(opts)
                opts = opts or {}
                local items = opts.Items or {}
                local D = {Value = opts.Default or (items[1] or ""), _callbacks = {}, _open = false, _items = items}
                local row = create("Frame", {Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, LayoutOrder = next_(), ClipsDescendants = false, ZIndex = 10, Parent = body})
                create("TextLabel", {Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = MoonLib._theme.text, TextXAlignment = Enum.TextXAlignment.Left, Text = opts.Name or "Dropdown", Parent = row})
                local dropBtn = create("TextButton", {Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0, 20), BackgroundColor3 = MoonLib._theme.bgTertiary, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = MoonLib._theme.text, Text = tostring(D.Value) .. "  ▼", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 10, Parent = row})
                corner(dropBtn, 4)
                local dropList = create("Frame", {Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 2), BackgroundColor3 = MoonLib._theme.bgTertiary, BorderSizePixel = 0, ClipsDescendants = true, Visible = false, ZIndex = 200, Parent = dropBtn})
                corner(dropList, 4); stroke(dropList, MoonLib._theme.accent, 1)
                create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1), Parent = dropList})

                local function rebuild()
                    for _, c in ipairs(dropList:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    for idx, it in ipairs(D._items) do
                        local ib = create("TextButton", {Size = UDim2.new(1, 0, 0, 20), BackgroundColor3 = MoonLib._theme.bg, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = MoonLib._theme.text, Text = tostring(it), AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = idx, ZIndex = 201, Parent = dropList})
                        ib.MouseButton1Click:Connect(function()
                            D.Value = it; dropBtn.Text = tostring(it) .. "  ▼"; dropList.Visible = false; D._open = false
                            for _, cb in ipairs(D._callbacks) do pcall(cb, it) end
                            if opts.Callback then pcall(opts.Callback, it) end
                        end)
                    end
                end
                rebuild()

                dropBtn.MouseButton1Click:Connect(function()
                    D._open = not D._open
                    dropList.Visible = D._open
                    dropList.Size = UDim2.new(1, 0, 0, D._open and (#D._items * 21) or 0)
                end)
                function D:Set(v) self.Value = v; dropBtn.Text = tostring(v) .. "  ▼" end
                function D:SetItems(newItems) self._items = newItems or {}; rebuild() end
                function D:OnChanged(cb) table.insert(self._callbacks, cb) end
                return D
            end

            function Section:AddInput(opts)
                opts = opts or {}
                local I = {Value = opts.Default or "", _callbacks = {}}
                local row = create("Frame", {Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, LayoutOrder = next_(), Parent = body})
                create("TextLabel", {Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = MoonLib._theme.text, TextXAlignment = Enum.TextXAlignment.Left, Text = opts.Name or "Input", Parent = row})
                local box = create("TextBox", {Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0, 20), BackgroundColor3 = MoonLib._theme.bgTertiary, BorderSizePixel = 0, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = MoonLib._theme.text, PlaceholderText = opts.Placeholder or "", PlaceholderColor3 = MoonLib._theme.textDim, Text = I.Value, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = row})
                corner(box, 4); padding(box, 0, 0, 6, 6)
                box:GetPropertyChangedSignal("Text"):Connect(function()
                    I.Value = box.Text
                    for _, cb in ipairs(I._callbacks) do pcall(cb, I.Value) end
                    if opts.Callback then pcall(opts.Callback, I.Value) end
                end)
                function I:Set(v) box.Text = v; self.Value = v end
                function I:OnChanged(cb) table.insert(self._callbacks, cb) end
                return I
            end

            function Section:AddLabel(opts)
                opts = opts or {}
                local lbl = create("TextLabel", {Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = MoonLib._theme.textDim, TextXAlignment = Enum.TextXAlignment.Left, Text = opts.Text or "", LayoutOrder = next_(), Parent = body})
                function lbl:SetText(t) lbl.Text = t end
                return lbl
            end

            function Section:GetBody() return body end
            function Section:GetFrame() return secFrame end

            table.insert(Tab.sections, Section)
            return Section
        end

        local function activate()
            for _, t in ipairs(Window.tabs) do
                if t.page then t.page.Visible = false end
                if t.button then
                    tween(t.button, {BackgroundTransparency = 1, TextColor3 = MoonLib._theme.textDim})
                    local ic = t.button:FindFirstChildOfClass("ImageLabel")
                    if ic then tween(ic, {ImageColor3 = MoonLib._theme.textDim}) end
                end
            end
            tabPage.Visible = true
            tween(tabBtn, {BackgroundTransparency = 0, BackgroundColor3 = MoonLib._theme.accentDim, TextColor3 = MoonLib._theme.text})
            local ic = tabBtn:FindFirstChildOfClass("ImageLabel")
            if ic then tween(ic, {ImageColor3 = MoonLib._theme.accent}) end
            Window.activeTab = Tab
            if settingsOpen then
                settingsOpen = false
                tween(contentFrame, {Position = UDim2.new(0, 8, 0, 84)})
                tween(settingsPanel, {Position = UDim2.new(1, 8, 0, 84)})
                tween(settingsGear, {ImageColor3 = MoonLib._theme.textDim, BackgroundColor3 = MoonLib._theme.bgTertiary})
            end
        end
        tabBtn.MouseButton1Click:Connect(activate)
        table.insert(Window.tabs, Tab)
        if #Window.tabs == 1 then activate() end
        return Tab
    end

    function Window:Destroy() pcall(function() screenGui:Destroy() end) end

    return Window
end

return MoonLib
