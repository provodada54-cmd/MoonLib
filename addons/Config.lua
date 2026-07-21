local HttpService = game:GetService("HttpService")

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

    function Config:SetFolder(name)
        self._folder = name
        ensureFolder()
    end

    function Config:SetDefaults(defaults)
        self._defaults = defaults
        self._data = self:_deepClone(defaults)
    end

    function Config:_deepClone(t)
        if type(t) ~= "table" then return t end
        local c = {}
        for k, v in pairs(t) do c[k] = self:_deepClone(v) end
        return c
    end

    function Config:_merge(base, override)
        if type(base) ~= "table" or type(override) ~= "table" then return override end
        local result = self:_deepClone(base)
        for k, v in pairs(override) do
            if type(result[k]) == "table" and type(v) == "table" then
                result[k] = self:_merge(result[k], v)
            else
                result[k] = self:_deepClone(v)
            end
        end
        return result
    end

    function Config:_readMeta()
        ensureFolder()
        if not isfile then return {autoSave = true, autoLoad = nil} end
        local path = filePath(self._metaFile)
        if not isfile(path) then return {autoSave = true, autoLoad = nil} end
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if ok and data then return data end
        return {autoSave = true, autoLoad = nil}
    end

    function Config:_writeMeta(meta)
        ensureFolder()
        if not writefile then return end
        pcall(function() writefile(filePath(self._metaFile), HttpService:JSONEncode(meta)) end)
    end

    function Config:_readFile(name)
        if not isfile then return nil end
        local path = filePath(name)
        if not isfile(path) then return nil end
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if ok then return data end
        return nil
    end

    function Config:_writeFile(name, data)
        ensureFolder()
        if not writefile then return end
        pcall(function() writefile(filePath(name), HttpService:JSONEncode(data)) end)
    end

    function Config:_deleteFile(name)
        if not delfile then return end
        local path = filePath(name)
        if isfile and isfile(path) then pcall(function() delfile(path) end) end
    end

    function Config:GetAutoSave() return self._autoSave end

    function Config:SetAutoSave(state)
        self._autoSave = state
        local meta = self:_readMeta()
        meta.autoSave = state
        self:_writeMeta(meta)
        if state then
            self:Save()
        end
    end

    function Config:GetAutoLoad() return self._autoLoadConfig end

    function Config:SetAutoLoad(configName)
        self._autoLoadConfig = configName
        local meta = self:_readMeta()
        meta.autoLoad = configName
        self:_writeMeta(meta)
    end

    function Config:GetCurrentConfig() return self._currentConfig end

    function Config:ListConfigs()
        local result = {}
        if not listfiles then return result end
        ensureFolder()
        local ok, files = pcall(function() return listfiles(self._folder) end)
        if not ok or not files then return result end
        for _, f in ipairs(files) do
            local name = f:match("([^/\\]+)%.json$")
            if name and name ~= "_default" and name ~= "_meta" then
                table.insert(result, name)
            end
        end
        table.sort(result)
        return result
    end

    function Config:CreateConfig(name)
        if not name or name == "" then return false, "Name required" end
        name = name:gsub("[^%w_%-]", "_")
        local fname = name .. ".json"
        if isfile and isfile(filePath(fname)) then return false, "Already exists" end
        local saveData = self:_deepClone(self._data)
        saveData._version = self._version
        self:_writeFile(fname, saveData)
        self._currentConfig = name
        self:_fireListChanged()
        return true
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
        local saveData = self:_deepClone(self._data)
        saveData._version = self._version
        self:_writeFile(name .. ".json", saveData)
        self._currentConfig = name
        return true
    end

    function Config:LoadConfig(name)
        if not name then return false end
        local data = self:_readFile(name .. ".json")
        if not data then return false end
        if data._version and data._version < self._version then
            data = self:_migrate(data)
        end
        self._data = self:_merge(self._defaults, data)
        self._currentConfig = name
        self:ApplyAll()
        return true
    end

    function Config:OnListChanged(cb) table.insert(self._listChangedCallbacks, cb) end

    function Config:_fireListChanged()
        for _, cb in ipairs(self._listChangedCallbacks) do pcall(cb) end
    end

    function Config:Load()
        ensureFolder()
        local meta = self:_readMeta()
        self._autoSave = meta.autoSave ~= false
        self._autoLoadConfig = meta.autoLoad
        if self._autoSave then
            local data = self:_readFile(self._defaultFile)
            if data then
                if data._version and data._version < self._version then
                    data = self:_migrate(data)
                end
                self._data = self:_merge(self._defaults, data)
            end
            self._currentConfig = nil
        else
            if self._autoLoadConfig then
                local data = self:_readFile(self._autoLoadConfig .. ".json")
                if data then
                    if data._version and data._version < self._version then
                        data = self:_migrate(data)
                    end
                    self._data = self:_merge(self._defaults, data)
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
        local saveData = self:_deepClone(self._data)
        saveData._version = self._version
        self:_writeFile(self._defaultFile, saveData)
    end

    function Config:_migrate(data)
        data._version = self._version
        return data
    end

    function Config:Get(path, default)
        local parts = string.split(path, ".")
        local current = self._data
        for _, part in ipairs(parts) do
            if type(current) ~= "table" then return default end
            current = current[part]
            if current == nil then return default end
        end
        return current
    end

    function Config:Set(path, value)
        local parts = string.split(path, ".")
        local current = self._data
        for i = 1, #parts - 1 do
            if type(current[parts[i]]) ~= "table" then current[parts[i]] = {} end
            current = current[parts[i]]
        end
        current[parts[#parts]] = value
        self:Save()
        for _, cb in ipairs(self._callbacks) do pcall(cb, path, value) end
    end

    function Config:OnChanged(cb) table.insert(self._callbacks, cb) end

    function Config:GetAll() return self:_deepClone(self._data) end

    function Config:Reset()
        self._data = self:_deepClone(self._defaults)
        self:Save()
        self:ApplyAll()
    end

    function Config:Bind(path, element)
        self._bindings[path] = element
        local saved = self:Get(path)
        if saved ~= nil and element.Set then
            self._suppressSave = true
            pcall(function() element:Set(saved) end)
            self._suppressSave = false
        end
        if element.OnChanged then
            element:OnChanged(function(v)
                if not self._suppressSave then self:Set(path, v) end
            end)
        end
    end

    function Config:ApplyAll()
        self._suppressSave = true
        for path, element in pairs(self._bindings) do
            local v = self:Get(path)
            if v ~= nil and element.Set then
                pcall(function() element:Set(v) end)
            end
        end
        self._suppressSave = false
        for _, cb in ipairs(self._autoLoadCallbacks) do pcall(cb, self._data) end
    end

    function Config:OnAutoLoad(cb) table.insert(self._autoLoadCallbacks, cb) end

    function Config:LoadAndApply()
        self:Load()
        self:ApplyAll()
    end

    function Config:SetupSettingsUI(Window)
        Window:AddSettingsSection("Config", 100)

        local autoSaveToggle = Window:AddSettingsToggle("Auto-Save", self._autoSave, 101, function(v)
            self:SetAutoSave(v)
            self:_refreshManagerVisibility()
        end)

        local managerFrame = Window:AddSettingsContainer(102)
        managerFrame.Visible = not self._autoSave
        self._managerFrame = managerFrame

        create_manager_ui(self, managerFrame, Window)

        function self:_refreshManagerVisibility()
            if self._managerFrame then self._managerFrame.Visible = not self._autoSave end
        end
    end

    function create_manager_ui(configAddon, container, Window)
        local theme = MoonLib._theme

        local currentLabel = Instance.new("TextLabel", container)
        currentLabel.Size = UDim2.new(1, 0, 0, 16)
        currentLabel.BackgroundTransparency = 1
        currentLabel.Font = Enum.Font.Gotham
        currentLabel.TextSize = 11
        currentLabel.TextColor3 = theme.textDim
        currentLabel.TextXAlignment = Enum.TextXAlignment.Left
        currentLabel.LayoutOrder = 0

        local function refreshCurrent()
            currentLabel.Text = "Current: " .. (configAddon:GetCurrentConfig() or "none")
        end
        refreshCurrent()

        local dropRow = Instance.new("Frame", container)
        dropRow.Size = UDim2.new(1, 0, 0, 24)
        dropRow.BackgroundTransparency = 1
        dropRow.LayoutOrder = 1

        local dropBtn = Instance.new("TextButton", dropRow)
        dropBtn.Size = UDim2.new(1, 0, 1, 0)
        dropBtn.BackgroundColor3 = theme.bgTertiary
        dropBtn.Font = Enum.Font.Gotham
        dropBtn.TextSize = 11
        dropBtn.TextColor3 = theme.text
        dropBtn.Text = "Select config...  ▼"
        dropBtn.AutoButtonColor = false
        dropBtn.BorderSizePixel = 0
        Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 4)

        local dropList = Instance.new("Frame", dropBtn)
        dropList.Size = UDim2.new(1, 0, 0, 0)
        dropList.Position = UDim2.new(0, 0, 1, 2)
        dropList.BackgroundColor3 = theme.bgTertiary
        dropList.BorderSizePixel = 0
        dropList.ClipsDescendants = true
        dropList.Visible = false
        dropList.ZIndex = 20
        Instance.new("UICorner", dropList).CornerRadius = UDim.new(0, 4)
        local ds = Instance.new("UIStroke", dropList); ds.Color = theme.accent; ds.Thickness = 1
        Instance.new("UIListLayout", dropList).SortOrder = Enum.SortOrder.LayoutOrder

        local selected = nil
        local isOpen = false

        local function rebuildList()
            for _, c in ipairs(dropList:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            local list = configAddon:ListConfigs()
            if #list == 0 then
                local empty = Instance.new("TextLabel", dropList)
                empty.Size = UDim2.new(1, 0, 0, 20)
                empty.BackgroundColor3 = theme.bg
                empty.BorderSizePixel = 0
                empty.Font = Enum.Font.Gotham
                empty.TextSize = 10
                empty.TextColor3 = theme.textDim
                empty.Text = "No configs"
                empty.ZIndex = 21
                return 0
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
                ib.ZIndex = 21
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
            if count == 0 then count = 1 end
            dropList.Size = UDim2.new(1, 0, 0, isOpen and (count * 21) or 0)
            dropList.Visible = isOpen
        end)

        local btnGrid = Instance.new("Frame", container)
        btnGrid.Size = UDim2.new(1, 0, 0, 26)
        btnGrid.BackgroundTransparency = 1
        btnGrid.LayoutOrder = 2

        local function makeSmallBtn(text, color, xScale, xOffset)
            local b = Instance.new("TextButton", btnGrid)
            b.Size = UDim2.new(xScale, xOffset, 1, 0)
            b.BackgroundColor3 = color
            b.Font = Enum.Font.GothamBold
            b.TextSize = 10
            b.TextColor3 = theme.text
            b.Text = text
            b.AutoButtonColor = false
            b.BorderSizePixel = 0
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
            return b
        end

        local loadBtn = makeSmallBtn("Load", theme.bgTertiary, 0.5, -2)
        loadBtn.Position = UDim2.new(0, 0, 0, 0)
        local saveBtn = makeSmallBtn("Save", theme.bgTertiary, 0.5, -2)
        saveBtn.Position = UDim2.new(0.5, 2, 0, 0)

        local btnGrid2 = Instance.new("Frame", container)
        btnGrid2.Size = UDim2.new(1, 0, 0, 26)
        btnGrid2.BackgroundTransparency = 1
        btnGrid2.LayoutOrder = 3

        local function makeSmallBtn2(text, color, xScale, xOffset)
            local b = Instance.new("TextButton", btnGrid2)
            b.Size = UDim2.new(xScale, xOffset, 1, 0)
            b.BackgroundColor3 = color
            b.Font = Enum.Font.GothamBold
            b.TextSize = 10
            b.TextColor3 = theme.text
            b.Text = text
            b.AutoButtonColor = false
            b.BorderSizePixel = 0
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
            return b
        end

        local newBtn = makeSmallBtn2("New", theme.accentDim, 0.5, -2)
        newBtn.Position = UDim2.new(0, 0, 0, 0)
        local delBtn = makeSmallBtn2("Delete", Color3.fromRGB(100, 30, 30), 0.5, -2)
        delBtn.Position = UDim2.new(0.5, 2, 0, 0)

        local alRow = Instance.new("Frame", container)
        alRow.Size = UDim2.new(1, 0, 0, 24)
        alRow.BackgroundTransparency = 1
        alRow.LayoutOrder = 4

        local alLbl = Instance.new("TextLabel", alRow)
        alLbl.Size = UDim2.new(0.5, 0, 1, 0)
        alLbl.BackgroundTransparency = 1
        alLbl.Font = Enum.Font.Gotham
        alLbl.TextSize = 11
        alLbl.TextColor3 = theme.text
        alLbl.TextXAlignment = Enum.TextXAlignment.Left
        alLbl.Text = "Auto-Load:"

        local alValue = Instance.new("TextLabel", alRow)
        alValue.Size = UDim2.new(0.5, -30, 1, 0)
        alValue.Position = UDim2.new(0.5, 0, 0, 0)
        alValue.BackgroundTransparency = 1
        alValue.Font = Enum.Font.GothamBold
        alValue.TextSize = 11
        alValue.TextColor3 = theme.accent
        alValue.TextXAlignment = Enum.TextXAlignment.Right
        alValue.Text = configAddon:GetAutoLoad() or "none"

        local alSetBtn = Instance.new("TextButton", alRow)
        alSetBtn.Size = UDim2.new(0, 24, 0, 20)
        alSetBtn.Position = UDim2.new(1, -26, 0.5, -10)
        alSetBtn.BackgroundColor3 = theme.bgTertiary
        alSetBtn.Font = Enum.Font.GothamBold
        alSetBtn.TextSize = 10
        alSetBtn.TextColor3 = theme.text
        alSetBtn.Text = "×"
        alSetBtn.AutoButtonColor = false
        alSetBtn.BorderSizePixel = 0
        Instance.new("UICorner", alSetBtn).CornerRadius = UDim.new(0, 4)

        alSetBtn.MouseButton1Click:Connect(function()
            configAddon:SetAutoLoad(nil)
            alValue.Text = "none"
        end)

        local btnGrid3 = Instance.new("Frame", container)
        btnGrid3.Size = UDim2.new(1, 0, 0, 26)
        btnGrid3.BackgroundTransparency = 1
        btnGrid3.LayoutOrder = 5

        local setAlBtn = Instance.new("TextButton", btnGrid3)
        setAlBtn.Size = UDim2.new(1, 0, 1, 0)
        setAlBtn.BackgroundColor3 = theme.bgTertiary
        setAlBtn.Font = Enum.Font.GothamBold
        setAlBtn.TextSize = 10
        setAlBtn.TextColor3 = theme.text
        setAlBtn.Text = "Set selected as Auto-Load"
        setAlBtn.AutoButtonColor = false
        setAlBtn.BorderSizePixel = 0
        Instance.new("UICorner", setAlBtn).CornerRadius = UDim.new(0, 4)

        setAlBtn.MouseButton1Click:Connect(function()
            if not selected then MoonLib:Notify("Select a config first"); return end
            configAddon:SetAutoLoad(selected)
            alValue.Text = selected
            MoonLib:Notify("Auto-Load: " .. selected)
        end)

        loadBtn.MouseButton1Click:Connect(function()
            if not selected then MoonLib:Notify("Select a config first"); return end
            if configAddon:LoadConfig(selected) then
                MoonLib:Notify("Loaded: " .. selected)
                refreshCurrent()
            else
                MoonLib:Notify("Failed to load")
            end
        end)

        saveBtn.MouseButton1Click:Connect(function()
            if not selected then MoonLib:Notify("Select a config first"); return end
            configAddon:SaveConfig(selected)
            MoonLib:Notify("Saved: " .. selected)
            refreshCurrent()
        end)

        newBtn.MouseButton1Click:Connect(function()
            MoonLib:Prompt({
                Title = "New Config",
                Message = "Enter name for new config:",
                Input = true,
                Placeholder = "config name",
                OnConfirm = function(name)
                    if not name or name == "" then return end
                    local ok, err = configAddon:CreateConfig(name)
                    if ok then
                        MoonLib:Notify("Created: " .. name)
                        selected = name:gsub("[^%w_%-]", "_")
                        dropBtn.Text = selected .. "  ▼"
                        refreshCurrent()
                    else
                        MoonLib:Notify(err or "Failed")
                    end
                end
            })
        end)

        delBtn.MouseButton1Click:Connect(function()
            if not selected then MoonLib:Notify("Select a config first"); return end
            MoonLib:Prompt({
                Title = "Delete Config",
                Message = "Delete '" .. selected .. "'?",
                OkText = "Delete",
                OnConfirm = function()
                    configAddon:DeleteConfig(selected)
                    MoonLib:Notify("Deleted: " .. selected)
                    selected = nil
                    dropBtn.Text = "Select config...  ▼"
                    alValue.Text = configAddon:GetAutoLoad() or "none"
                    refreshCurrent()
                end
            })
        end)

        configAddon:OnListChanged(refreshCurrent)
    end

    MoonLib:RegisterAddon("Config", Config)
end

return ConfigAddon
