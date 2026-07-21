local Config = {}
Config._folder = "MoonLib"
Config._defaults = {}
Config._data = {}
Config._binds = {}
Config._autoLoadCallbacks = {}
Config._autoSave = true
Config._autoLoadName = nil
Config._metaFile = "_meta.json"
Config._defaultFile = "_default.json"

local HttpService = game:GetService("HttpService")

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = deepCopy(v)
    end
    return copy
end

local function deepMerge(base, over)
    local result = deepCopy(base)
    for k, v in pairs(over) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = deepMerge(result[k], v)
        else
            result[k] = deepCopy(v)
        end
    end
    return result
end

local function ensureFolder(name)
    if isfolder and not isfolder(name) then
        makefolder(name)
    end
end

local function filePath(folder, name)
    return folder .. "/" .. name
end

local function readJson(path)
    if isfile and isfile(path) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        if ok then return data end
    end
    return nil
end

local function writeJson(path, data)
    if writefile then
        pcall(function()
            writefile(path, HttpService:JSONEncode(data))
        end)
    end
end

function Config:_metaPath()
    return filePath(self._folder, self._metaFile)
end

function Config:_defaultPath()
    return filePath(self._folder, self._defaultFile)
end

function Config:_loadMeta()
    local meta = readJson(self:_metaPath())
    if meta then
        self._autoSave = meta.autoSave ~= false
        self._autoLoadName = meta.autoLoad
    end
end

function Config:_saveMeta()
    writeJson(self:_metaPath(), {
        autoSave = self._autoSave,
        autoLoad = self._autoLoadName,
    })
end

function Config:SetFolder(name)
    self._folder = name
    ensureFolder(name)
end

function Config:SetDefaults(t)
    self._defaults = deepCopy(t)
    self._data = deepCopy(t)
end

function Config:Load()
    ensureFolder(self._folder)
    self:_loadMeta()

    local loadName = nil
    if self._autoSave then
        loadName = self._defaultFile
    elseif self._autoLoadName then
        loadName = self._autoLoadName .. ".json"
    end

    if loadName then
        local path = filePath(self._folder, loadName)
        local saved = readJson(path)
        if saved then
            self._data = deepMerge(self._defaults, saved)
        end
    end
end

function Config:Save()
    if not self._autoSave then return end
    ensureFolder(self._folder)
    writeJson(self:_defaultPath(), self._data)
    self:_saveMeta()
end

function Config:Get(path, default)
    local parts = string.split(path, ".")
    local current = self._data
    for _, key in ipairs(parts) do
        if type(current) ~= "table" then return default end
        current = current[key]
        if current == nil then return default end
    end
    return current
end

function Config:Set(path, value)
    local parts = string.split(path, ".")
    local current = self._data
    for i = 1, #parts - 1 do
        if type(current[parts[i]]) ~= "table" then
            current[parts[i]] = {}
        end
        current = current[parts[i]]
    end
    current[parts[#parts]] = value

    if self._autoSave then
        self:Save()
    end
end

function Config:Bind(path, element)
    table.insert(self._binds, {path = path, element = element})

    local savedVal = self:Get(path)
    if savedVal ~= nil then
        element:Set(savedVal)
    end

    element:OnChanged(function(v)
        self:Set(path, v)
    end)
end

function Config:OnAutoLoad(callback)
    table.insert(self._autoLoadCallbacks, callback)
end

function Config:ApplyAll()
    for _, bind in ipairs(self._binds) do
        local v = self:Get(bind.path)
        if v ~= nil then
            bind.element:Set(v)
        end
    end
    for _, cb in ipairs(self._autoLoadCallbacks) do
        cb(self._data)
    end
end

function Config:ListConfigs()
    local list = {}
    if listfiles then
        for _, f in ipairs(listfiles(self._folder)) do
            local name = string.match(f, "([^/\\]+)$")
            if name and not string.match(name, "^_") and string.match(name, "%.json$") then
                table.insert(list, string.gsub(name, "%.json$", ""))
            end
        end
    end
    return list
end

function Config:CreateConfig(name)
    ensureFolder(self._folder)
    writeJson(filePath(self._folder, name .. ".json"), self._data)
end

function Config:LoadConfig(name)
    local path = filePath(self._folder, name .. ".json")
    local saved = readJson(path)
    if saved then
        self._data = deepMerge(self._defaults, saved)
        self:ApplyAll()
    end
end

function Config:SaveConfig(name)
    ensureFolder(self._folder)
    writeJson(filePath(self._folder, name .. ".json"), self._data)
end

function Config:DeleteConfig(name)
    local path = filePath(self._folder, name .. ".json")
    if isfile and isfile(path) and delfile then
        delfile(path)
    end
end

function Config:SetAutoLoad(name)
    self._autoLoadName = name
    self:_saveMeta()
end

function Config:ClearAutoLoad()
    self._autoLoadName = nil
    self:_saveMeta()
end

function Config:SetupSettingsUI(Window)
    Window:AddSettingsSection("Config", 100)

    local autoSaveToggle = Window:AddSettingsToggle("Auto-Save", self._autoSave, 101, function(v)
        self._autoSave = v
        self:_saveMeta()
        if v then
            self:Save()
        end
    end)

    local configContainer = Window:AddSettingsContainer(102)

    if not self._autoSave then
        self:_buildConfigManager(configContainer, Window)
    end

    local MoonLib = self._moonlib
    if MoonLib then
        local oldAutoSaveCb = nil
    end
end

function Config:_buildConfigManager(container, Window)
    local TweenService = game:GetService("TweenService")

    for _, child in ipairs(container:GetChildren()) do
        child:Destroy()
    end

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = container

    local configs = self:ListConfigs()

    local dropdownItems = configs
    if #dropdownItems == 0 then
        dropdownItems = {"(none)"}
    end

    local selectedConfig = dropdownItems[1]

    local dropLabel = Instance.new("TextLabel")
    dropLabel.Text = "Config: " .. selectedConfig
    dropLabel.Font = Enum.Font.Gotham
    dropLabel.TextSize = 13
    dropLabel.TextColor3 = Color3.fromRGB(235, 235, 240)
    dropLabel.BackgroundTransparency = 1
    dropLabel.Size = UDim2.new(1, 0, 0, 22)
    dropLabel.TextXAlignment = Enum.TextXAlignment.Left
    dropLabel.ZIndex = 21
    dropLabel.Parent = container

    local function makeBtn(text, order, cb)
        local btn = Instance.new("TextButton")
        btn.Text = text
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 12
        btn.TextColor3 = Color3.fromRGB(235, 235, 240)
        btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
        btn.Size = UDim2.new(1, 0, 0, 26)
        btn.LayoutOrder = order
        btn.ZIndex = 21
        btn.Parent = container
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn
        btn.MouseButton1Click:Connect(cb)
        return btn
    end

    makeBtn("Load", 2, function()
        if selectedConfig ~= "(none)" then
            self:LoadConfig(selectedConfig)
        end
    end)

    makeBtn("Save", 3, function()
        if selectedConfig ~= "(none)" then
            self:SaveConfig(selectedConfig)
        end
    end)

    makeBtn("New Config", 4, function()
        if self._moonlib then
            self._moonlib:Prompt({
                Title = "New Config",
                Message = "Enter config name:",
                Input = true,
                Placeholder = "my_config",
                OnConfirm = function(name)
                    if name and name ~= "" then
                        self:CreateConfig(name)
                        self:_buildConfigManager(container, Window)
                    end
                end,
            })
        end
    end)

    makeBtn("Delete", 5, function()
        if selectedConfig ~= "(none)" then
            self:DeleteConfig(selectedConfig)
            self:_buildConfigManager(container, Window)
        end
    end)

    makeBtn("Set Auto-Load", 6, function()
        if selectedConfig ~= "(none)" then
            self:SetAutoLoad(selectedConfig)
            self:_buildConfigManager(container, Window)
        end
    end)

    makeBtn("Clear Auto-Load", 7, function()
        self:ClearAutoLoad()
        self:_buildConfigManager(container, Window)
    end)

    local autoLoadLabel = Instance.new("TextLabel")
    autoLoadLabel.Text = "Auto-Load: " .. (self._autoLoadName or "None")
    autoLoadLabel.Font = Enum.Font.Gotham
    autoLoadLabel.TextSize = 12
    autoLoadLabel.TextColor3 = Color3.fromRGB(130, 130, 145)
    autoLoadLabel.BackgroundTransparency = 1
    autoLoadLabel.Size = UDim2.new(1, 0, 0, 20)
    autoLoadLabel.TextXAlignment = Enum.TextXAlignment.Left
    autoLoadLabel.LayoutOrder = 8
    autoLoadLabel.ZIndex = 21
    autoLoadLabel.Parent = container
end

function Config._register(MoonLib)
    Config._moonlib = MoonLib
    MoonLib:RegisterAddon("Config", Config)
end

return Config
