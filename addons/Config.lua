local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local ConfigAddon = {}
ConfigAddon._name = "Config"

function ConfigAddon._register(MoonLib)
    local Config = {}
    Config._data = {}
    Config._defaults = {}
    Config._folder = "MoonLib"
    Config._defaultFile = "_default.json"
    Config._metaFile = "_meta.json"
    Config._suppressSave = false
    Config._version = 1
    Config._callbacks = {}
    Config._bindings = {}
    Config._autoLoadCallbacks = {}
    Config._autoSave = true
    Config._autoLoadConfig = nil
    Config._currentConfig = nil
    Config._listChangedCallbacks = {}

    local function ensureFolder()
        if not isfolder then return end
        if not isfolder(Config._folder) then
            pcall(function() makefolder(Config._folder) end)
        end
    end

    local function filePath(name)
        return Config._folder .. "/" .. name
    end

    function Config:SetFolder(name) self._folder = name; ensureFolder() end
    function Config:SetDefaults(d) self._defaults = d; self._data = self:_deepClone(d) end

    function Config:_deepClone(t)
        if type(t) ~= "table" then return t end
        local c = {}
        for k, v in pairs(t) do c[k] = self:_deepClone(v) end
        return c
    end

    function Config:_merge(base, override)
        if type(base) ~= "table" or type(override) ~= "table" then return override end
        local r = self:_deepClone(base)
        for k, v in pairs(override) do
            if type(r[k]) == "table" and type(v) == "table" then r[k] = self:_merge(r[k], v)
            else r[k] = self:_deepClone(v) end
        end
        return r
    end

    function Config:_readMeta()
        ensureFolder()
        if not isfile then return {autoSave = true, autoLoad = nil} end
        local p = filePath(self._metaFile)
        if not isfile(p) then return {autoSave = true, autoLoad = nil} end
        local ok, d = pcall(function() return HttpService:JSONDecode(readfile(p)) end)
        if ok and d then return d end
        return {autoSave = true, autoLoad = nil}
    end

    function Config:_writeMeta(m)
        ensureFolder()
        if not writefile then return end
        pcall(function() writefile(filePath(self._metaFile), HttpService:JSONEncode(m)) end)
    end

    function Config:_readFile(name)
        if not isfile then return nil end
        local p = filePath(name)
        if not isfile(p) then return nil end
        local ok, d = pcall(function() return HttpService:JSONDecode(readfile(p)) end)
        if ok then return d end
        return nil
    end

    function Config:_writeFile(name, data)
        ensureFolder()
        if not writefile then return end
        pcall(function() writefile(filePath(name), HttpService:JSONEncode(data)) end)
    end

    function Config:_deleteFile(name)
        if not delfile then return end
        local p = filePath(name)
        if isfile and isfile(p) then pcall(function() delfile(p) end) end
    end

    function Config:GetAutoSave() return self._autoSave end

    function Config:SetAutoSave(state)
        self._autoSave = state
        local m = self:_readMeta()
        m.autoSave = state
        self:_writeMeta(m)
        if state then self:Save() end
    end

    function Config:GetAutoLoad() return self._autoLoadConfig end

    function Config:SetAutoLoad(n)
        self._autoLoadConfig = n
        local m = self:_readMeta()
        m.autoLoad = n
        self:_writeMeta(m)
    end

    function Config:GetCurrentConfig() return self._currentConfig end

    function Config:ListConfigs()
        local r = {}
        if not listfiles then return r end
        ensureFolder()
        local ok, files = pcall(function() return listfiles(self._folder) end)
        if not ok or not files then return r end
        for _, f in ipairs(files) do
            local name = f:match("([^/\\]+)%.json$")
            if name and name ~= "_default" and name ~= "_meta" then table.insert(r, name) end
        end
        table.sort(r)
        return r
    end

    function Config:CreateConfig(name)
        if not name or name == "" then return false, "Name required" end
        name = name:gsub("[^%w_%-]", "_")
        local fn = name .. ".json"
        if isfile and isfile(filePath(fn)) then return false, "Already exists" end
        local d = self:_deepClone(self._data)
        d._version = self._version
        self:_writeFile(fn, d)
        self._currentConfig = name
        self:_fireListChanged()
        return true, name
    end

    function Config:DeleteConfig(name)
        if not name then return false end
        self:_deleteFile(name .. ".json")
        if self._autoLoadConfig == name then self:SetAutoLoad(nil) end
        if self._currentConfig == name then self._currentConfig = nil end
        self:_fireListChanged()
        return true
    end

    function Config:SaveConfig(name)
        if not name or name == "" then return false end
        local d = self:_deepClone(self._data)
        d._version = self._version
        self:_writeFile(name .. ".json", d)
        self._currentConfig = name
        return true
    end

    function Config:LoadConfig(name)
        if not name then return false end
        local d = self:_readFile(name .. ".json")
        if not d then return false end
        if d._version and d._version < self._version then d = self:_migrate(d) end
        self._data = self:_merge(self._defaults, d)
        self._currentConfig = name
        self:ApplyAll()
        return true
    end

    function Config:OnListChanged(cb) table.insert(self._listChangedCallbacks, cb) end
    function Config:_fireListChanged() for _, cb in ipairs(self._listChangedCallbacks) do pcall(cb) end end

    function Config:Load()
        ensureFolder()
        local m = self:_readMeta()
        self._autoSave = m.autoSave ~= false
        self._autoLoadConfig = m.autoLoad
        if self._autoSave then
            local d = self:_readFile(self._defaultFile)
            if d then
                if d._version and d._version < self._version then d = self:_migrate(d) end
                self._data = self:_merge(self._defaults, d)
            end
            self._currentConfig = nil
        else
            if self._autoLoadConfig then
                local d = self:_readFile(self._autoLoadConfig .. ".json")
                if d then
                    if d._version and d._version < self._version then d = self:_migrate(d) end
                    self._data = self:_merge(self._defaults, d)
                    self._currentConfig = self._autoLoadConfig
                end
            end
        end
        return true
    end

    function Config:Save()
        if self._suppressSave then return end
        if not self._autoSave then return end
        ensureFolder()
        local d = self:_deepClone(self._data)
        d._version = self._version
        self:_writeFile(self._defaultFile, d)
    end

    function Config:_migrate(d) d._version = self._version; return d end

    function Config:Get(path, default)
        local parts = string.split(path, ".")
        local c = self._data
        for _, p in ipairs(parts) do
            if type(c) ~= "table" then return default end
            c = c[p]
            if c == nil then return default end
        end
        return c
    end

    function Config:Set(path, value)
        local parts = string.split(path, ".")
        local c = self._data
        for i = 1, #parts - 1 do
            if type(c[parts[i]]) ~= "table" then c[parts[i]] = {} end
            c = c[parts[i]]
        end
        c[parts[#parts]] = value
        self:Save()
        for _, cb in ipairs(self._callbacks) do pcall(cb, path, value) end
    end

    function Config:OnChanged(cb) table.insert(self._callbacks, cb) end
    function Config:GetAll() return self:_deepClone(self._data) end
    function Config:Reset() self._data = self:_deepClone(self._defaults); self:Save(); self:ApplyAll() end

    function Config:Bind(path, element)
        self._bindings[path] = element
        local s = self:Get(path)
        if s ~= nil and element.Set then
            self._suppressSave = true
            pcall(function() element:Set(s) end)
            self._suppressSave = false
        end
        if element.OnChanged then
            element:OnChanged(function(v) if not self._suppressSave then self:Set(path, v) end end)
        end
    end

    function Config:ApplyAll()
        self._suppressSave = true
        for path, element in pairs(self._bindings) do
            local v = self:Get(path)
            if v ~= nil and element.Set then pcall(function() element:Set(v) end) end
        end
        self._suppressSave = false
        for _, cb in ipairs(self._autoLoadCallbacks) do pcall(cb, self._data) end
    end

    function Config:OnAutoLoad(cb) table.insert(self._autoLoadCallbacks, cb) end
    function Config:LoadAndApply() self:Load(); self:ApplyAll() end

    function Config:SetupSettingsUI(Window)
        Window:AddSettingsSection("Config", 100)

        Window:AddSettingsToggle("Auto-Save", self._autoSave, 101, function(v)
            self:SetAutoSave(v)
            self:_animateManager()
        end)

        local managerFrame = Window:AddSettingsContainer(102)
        managerFrame.Visible = not self._autoSave
        managerFrame.Size = UDim2.new(1, 0, 0, self._autoSave and 0 or 0)
        self._managerFrame = managerFrame

        self:_buildManagerUI(managerFrame)

        function self:_animateManager()
            if not self._managerFrame then return end
            if not self._autoSave then
                self._managerFrame.Visible = true
                self._managerFrame.BackgroundTransparency = 1
                for _, c in ipairs(self._managerFrame:GetChildren()) do
                    if c:IsA("GuiObject") then c.BackgroundTransparency = 1 end
                    if c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("TextBox") then
                        c.TextTransparency = 1
                    end
                end
                task.wait()
                TweenService:Create(self._managerFrame, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
                for _, c in ipairs(self._managerFrame:GetChildren()) do
                    if c:IsA("GuiObject") and c.BackgroundColor3 ~= Color3.new(0,0,0) then
                        pcall(function() TweenService:Create(c, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play() end)
                    end
                    if c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("TextBox") then
                        pcall(function() TweenService:Create(c, TweenInfo.new(0.25), {TextTransparency = 0}):Play() end)
                    end
                end
            else
                TweenService:Create(self._managerFrame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                for _, c in ipairs(self._managerFrame:GetChildren()) do
                    if c:IsA("GuiObject") then
                        pcall(function() TweenService:Create(c, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play() end)
                    end
                    if c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("TextBox") then
                        pcall(function() TweenService:Create(c, TweenInfo.new(0.2), {TextTransparency = 1}):Play() end)
                    end
                end
                task.delay(0.22, function()
                    if self._autoSave and self._managerFrame then self._managerFrame.Visible = false end
                end)
            end
        end
    end

    function Config:_buildManagerUI(container)
        local theme = MoonLib._theme

        local currentLabel = Instance.new("TextLabel", container)
        currentLabel.Size = UDim2.new(1, 0, 0, 16)
        currentLabel.BackgroundTransparency = 1
        currentLabel.Font = Enum.Font.Gotham
        currentLabel.TextSize = 11
        currentLabel.TextColor3 = theme.textDim
        currentLabel.TextXAlignment = Enum.TextXAlignment.Left
        currentLabel.LayoutOrder = 0
        local function refreshCurrent() currentLabel.Text = "Current: " .. (self:GetCurrentConfig() or "none") end
        refreshCurrent()

        local dropBtn = Instance.new("TextButton", container)
        dropBtn.Size = UDim2.new(1, 0, 0, 24)
        dropBtn.BackgroundColor3 = theme.bgTertiary
        dropBtn.Font = Enum.Font.Gotham
        dropBtn.TextSize = 11
        dropBtn.TextColor3 = theme.text
        dropBtn.Text = "Select config...  ▼"
        dropBtn.AutoButtonColor = false
        dropBtn.BorderSizePixel = 0
        dropBtn.LayoutOrder = 1
        Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 4)

        local dropList = Instance.new("Frame", dropBtn)
        dropList.Size = UDim2.new(1, 0, 0, 0)
        dropList.Position = UDim2.new(0, 0, 1, 2)
        dropList.BackgroundColor3 = theme.bgTertiary
        dropList.BorderSizePixel = 0
        dropList.ClipsDescendants = true
        dropList.Visible = false
        dropList.ZIndex = 50
        Instance.new("UICorner", dropList).CornerRadius = UDim.new(0, 4)
        local ds = Instance.new("UIStroke", dropList); ds.Color = theme.accent; ds.Thickness = 1
        Instance.new("UIListLayout", dropList).SortOrder = Enum.SortOrder.LayoutOrder

        local selected = nil
        local isOpen = false

        local function rebuildList()
            for _, c in ipairs(dropList:GetChildren()) do
                if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
            end
            local list = self:ListConfigs()
            if #list == 0 then
                local empty = Instance.new("TextLabel", dropList)
                empty.Size = UDim2.new(1, 0, 0, 20)
                empty.BackgroundColor3 = theme.bg
                empty.BorderSizePixel = 0
                empty.Font = Enum.Font.Gotham
                empty.TextSize = 10
                empty.TextColor3 = theme.textDim
                empty.Text = "No configs"
                empty.ZIndex = 51
                return 1
            end
            for idx, name in ipairs(list) do
                local ib = Instance.new("TextButton", dropList)
                ib.Size = UDim2.new(1, 0, 0, 20)
                ib.BackgroundColor3 = theme.bg
                ib.Font = Enum.Font.Gotham
                ib.TextSize = 11
                ib.TextColor3 = theme.text
                ib.Text = name
                ib.AutoButtonColor = false
                ib.BorderSizePixel = 0
                ib.LayoutOrder = idx
                ib.ZIndex = 51
                ib.MouseButton1Click:Connect(function()
                    selected = name
                    dropBtn.Text = name .. "  ▼"
                    dropList.Visible = false
                    isOpen = false
                end)
            end
            return #list
        end

        dropBtn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            local count = rebuildList()
            dropList.Size = UDim2.new(1, 0, 0, isOpen and (count * 21) or 0)
            dropList.Visible = isOpen
        end)

        local function makeRowBtn(text, layoutOrder)
            local b = Instance.new("TextButton", container)
            b.Size = UDim2.new(1, 0, 0, 26)
            b.BackgroundColor3 = theme.bgTertiary
            b.Font = Enum.Font.GothamBold
            b.TextSize = 11
            b.TextColor3 = theme.text
            b.Text = text
            b.AutoButtonColor = false
            b.BorderSizePixel = 0
            b.LayoutOrder = layoutOrder
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
            b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = theme.bgSection}):Play() end)
            b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = theme.bgTertiary}):Play() end)
            return b
        end

        local loadBtn = makeRowBtn("Load selected", 2)
        local saveBtn = makeRowBtn("Save to selected", 3)
        local newBtn = makeRowBtn("Create new", 4)
        local delBtn = makeRowBtn("Delete selected", 5)
        local setAlBtn = makeRowBtn("Set as Auto-Load", 6)
        local clearAlBtn = makeRowBtn("Clear Auto-Load", 7)

        local alLabel = Instance.new("TextLabel", container)
        alLabel.Size = UDim2.new(1, 0, 0, 16)
        alLabel.BackgroundTransparency = 1
        alLabel.Font = Enum.Font.Gotham
        alLabel.TextSize = 11
        alLabel.TextColor3 = theme.textDim
        alLabel.TextXAlignment = Enum.TextXAlignment.Left
        alLabel.LayoutOrder = 8
        local function refreshAl() alLabel.Text = "Auto-Load: " .. (self:GetAutoLoad() or "none") end
        refreshAl()

        loadBtn.MouseButton1Click:Connect(function()
            if not selected then MoonLib:Notify("Select a config first"); return end
            if self:LoadConfig(selected) then
                MoonLib:Notify("Loaded: " .. selected); refreshCurrent()
            else MoonLib:Notify("Failed to load") end
        end)

        saveBtn.MouseButton1Click:Connect(function()
            if not selected then MoonLib:Notify("Select a config first"); return end
            self:SaveConfig(selected)
            MoonLib:Notify("Saved: " .. selected); refreshCurrent()
        end)

        newBtn.MouseButton1Click:Connect(function()
            MoonLib:Prompt({
                Title = "New Config", Message = "Enter name:", Input = true, Placeholder = "config name",
                OnConfirm = function(name)
                    if not name or name == "" then return end
                    local ok, res = self:CreateConfig(name)
                    if ok then
                        MoonLib:Notify("Created: " .. res)
                        selected = res; dropBtn.Text = res .. "  ▼"; refreshCurrent()
                    else MoonLib:Notify(res or "Failed") end
                end,
            })
        end)

        delBtn.MouseButton1Click:Connect(function()
            if not selected then MoonLib:Notify("Select a config first"); return end
            MoonLib:Prompt({
                Title = "Delete Config", Message = "Delete '" .. selected .. "'?", OkText = "Delete",
                OnConfirm = function()
                    self:DeleteConfig(selected)
                    MoonLib:Notify("Deleted: " .. selected)
                    selected = nil; dropBtn.Text = "Select config...  ▼"
                    refreshCurrent(); refreshAl()
                end,
            })
        end)

        setAlBtn.MouseButton1Click:Connect(function()
            if not selected then MoonLib:Notify("Select a config first"); return end
            self:SetAutoLoad(selected)
            refreshAl()
            MoonLib:Notify("Auto-Load: " .. selected)
        end)

        clearAlBtn.MouseButton1Click:Connect(function()
            self:SetAutoLoad(nil)
            refreshAl()
            MoonLib:Notify("Auto-Load cleared")
        end)

        self:OnListChanged(function() refreshCurrent(); refreshAl() end)
    end

    MoonLib:RegisterAddon("Config", Config)
end

return ConfigAddon
