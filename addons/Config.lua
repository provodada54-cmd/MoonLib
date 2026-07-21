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
Config._moonlib = nil

local HttpService = game:GetService("HttpService")

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = deepCopy(v) end
    return c
end

local function deepMerge(base, over)
    local r = deepCopy(base)
    for k, v in pairs(over) do
        if type(v) == "table" and type(r[k]) == "table" then
            r[k] = deepMerge(r[k], v)
        else
            r[k] = deepCopy(v)
        end
    end
    return r
end

local function ensureFolder(name)
    if isfolder and not isfolder(name) then makefolder(name) end
end

local function fp(folder, name)
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
    return fp(self._folder, self._metaFile)
end

function Config:_defaultPath()
    return fp(self._folder, self._defaultFile)
end

function Config:_loadMeta()
    local meta = readJson(self:_metaPath())
    if meta then
        if meta.autoSave ~= nil then self._autoSave = meta.autoSave end
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
        local saved = readJson(fp(self._folder, loadName))
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
    local cur = self._data
    for _, key in ipairs(parts) do
        if type(cur) ~= "table" then return default end
        cur = cur[key]
        if cur == nil then return default end
    end
    return cur
end

function Config:Set(path, value)
    local parts = string.split(path, ".")
    local cur = self._data
    for i = 1, #parts - 1 do
        if type(cur[parts[i]]) ~= "table" then cur[parts[i]] = {} end
        cur = cur[parts[i]]
    end
    cur[parts[#parts]] = value
    if self._autoSave then self:Save() end
end

function Config:Bind(path, element)
    table.insert(self._binds, { path = path, element = element })
    local v = self:Get(path)
    if v ~= nil then element:Set(v) end
    element:OnChanged(function(newVal)
        self:Set(path, newVal)
    end)
end

function Config:OnAutoLoad(callback)
    table.insert(self._autoLoadCallbacks, callback)
end

function Config:ApplyAll()
    for _, bind in ipairs(self._binds) do
        local v = self:Get(bind.path)
        if v ~= nil then bind.element:Set(v) end
    end
    for _, cb in ipairs(self._autoLoadCallbacks) do cb(self._data) end
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
    writeJson(fp(self._folder, name .. ".json"), self._data)
end

function Config:LoadConfig(name)
    local saved = readJson(fp(self._folder, name .. ".json"))
    if saved then
        self._data = deepMerge(self._defaults, saved)
        self:ApplyAll()
    end
end

function Config:SaveConfig(name)
    ensureFolder(self._folder)
    writeJson(fp(self._folder, name .. ".json"), self._data)
end

function Config:DeleteConfig(name)
    local path = fp(self._folder, name .. ".json")
    if isfile and isfile(path) and delfile then delfile(path) end
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
    local configTab = Window:AddTab({ Name = "Config" })

    local mainSection = configTab:AddSection({ Name = "Config Settings", Side = "Left" })

    local autoSaveToggle = mainSection:AddToggle({
        Name = "Auto-Save",
        Default = self._autoSave,
        Callback = function(v)
            self._autoSave = v
            self:_saveMeta()
            if v then self:Save() end
        end
    })

    mainSection:AddButton({
        Name = "Force Save",
        Callback = function()
            local wasSave = self._autoSave
            self._autoSave = true
            self:Save()
            self._autoSave = wasSave
            if self._moonlib then
                self._moonlib:Notify("Config saved!", 2)
            end
        end
    })

    local managerSection = configTab:AddSection({ Name = "Config Manager", Side = "Right" })

    local configs = self:ListConfigs()
    if #configs == 0 then configs = { "(none)" } end

    local selectedConfig = configs[1]

    local configDropdown = managerSection:AddDropdown({
        Name = "Select Config",
        Items = configs,
        Default = selectedConfig,
        Callback = function(v)
            selectedConfig = v
        end
    })

    managerSection:AddButton({
        Name = "Load Config",
        Callback = function()
            if selectedConfig and selectedConfig ~= "(none)" then
                self:LoadConfig(selectedConfig)
                if self._moonlib then
                    self._moonlib:Notify("Loaded: " .. selectedConfig, 2)
                end
            end
        end
    })

    managerSection:AddButton({
        Name = "Save Config",
        Callback = function()
            if selectedConfig and selectedConfig ~= "(none)" then
                self:SaveConfig(selectedConfig)
                if self._moonlib then
                    self._moonlib:Notify("Saved: " .. selectedConfig, 2)
                end
            end
        end
    })

    managerSection:AddButton({
        Name = "New Config",
        Callback = function()
            if self._moonlib then
                self._moonlib:Prompt({
                    Title = "New Config",
                    Message = "Enter config name:",
                    Input = true,
                    Placeholder = "my_config",
                    OnConfirm = function(name)
                        if name and name ~= "" then
                            self:CreateConfig(name)
                            self._moonlib:Notify("Created: " .. name, 2)
                        end
                    end
                })
            end
        end
    })

    managerSection:AddButton({
        Name = "Delete Config",
        Callback = function()
            if selectedConfig and selectedConfig ~= "(none)" then
                self:DeleteConfig(selectedConfig)
                if self._moonlib then
                    self._moonlib:Notify("Deleted: " .. selectedConfig, 2)
                end
            end
        end
    })

    managerSection:AddButton({
        Name = "Set Auto-Load",
        Callback = function()
            if selectedConfig and selectedConfig ~= "(none)" then
                self:SetAutoLoad(selectedConfig)
                if self._moonlib then
                    self._moonlib:Notify("Auto-Load set: " .. selectedConfig, 2)
                end
            end
        end
    })

    managerSection:AddButton({
        Name = "Clear Auto-Load",
        Callback = function()
            self:ClearAutoLoad()
            if self._moonlib then
                self._moonlib:Notify("Auto-Load cleared", 2)
            end
        end
    })

    managerSection:AddLabel({
        Text = "Auto-Load: " .. (self._autoLoadName or "None")
    })
end

function Config._register(MoonLib)
    Config._moonlib = MoonLib
    MoonLib:RegisterAddon("Config", Config)
end

return Config
