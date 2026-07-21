--[[
    MoonLib Config Addon
]]

local HttpService = game:GetService("HttpService")

local ConfigAddon = {}
ConfigAddon._name = "Config"

function ConfigAddon._register(MoonLib)
    local Config = {}
    Config._data = {}
    Config._defaults = {}
    Config._fileName = "MoonLibConfig.json"
    Config._suppressSave = false
    Config._version = 1
    Config._callbacks = {}
    Config._bindings = {} -- {path -> {element, type}}
    Config._autoLoadCallbacks = {} -- вызываются после загрузки

    function Config:SetFile(name)
        self._fileName = name
    end

    function Config:SetDefaults(defaults)
        self._defaults = defaults
        self._data = Config:_deepClone(defaults)
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

    function Config:Load()
        local ok, data = pcall(function()
            if not isfile then return nil end
            if not isfile(self._fileName) then return nil end
            return HttpService:JSONDecode(readfile(self._fileName))
        end)
        if ok and data then
            if data._version and data._version < self._version then
                data = self:_migrate(data)
            end
            self._data = self:_merge(self._defaults, data)
            return true
        end
        return false
    end

    function Config:Save()
        if self._suppressSave then return end
        pcall(function()
            if not writefile then return end
            local saveData = self:_deepClone(self._data)
            saveData._version = self._version
            writefile(self._fileName, HttpService:JSONEncode(saveData))
        end)
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

    function Config:OnChanged(cb)
        table.insert(self._callbacks, cb)
    end

    function Config:GetAll()
        return self:_deepClone(self._data)
    end

    function Config:Reset()
        self._data = self:_deepClone(self._defaults)
        self:Save()
        self:ApplyAll()
    end

    -- привязка элемента UI к пути в конфиге
    -- element должен иметь :Set(value) и :OnChanged(cb) и .Value
    function Config:Bind(path, element)
        self._bindings[path] = element

        -- сразу применяем значение из конфига
        local savedValue = self:Get(path)
        if savedValue ~= nil and element.Set then
            self._suppressSave = true
            pcall(function() element:Set(savedValue) end)
            self._suppressSave = false
        end

        -- подписываемся на изменения элемента → пишем в конфиг
        if element.OnChanged then
            element:OnChanged(function(newValue)
                if not self._suppressSave then
                    self:Set(path, newValue)
                end
            end)
        end
    end

    -- применить все значения из конфига к привязанным элементам
    function Config:ApplyAll()
        self._suppressSave = true
        for path, element in pairs(self._bindings) do
            local value = self:Get(path)
            if value ~= nil and element.Set then
                pcall(function() element:Set(value) end)
            end
        end
        self._suppressSave = false

        -- вызываем автолоад-коллбеки (для фич, которые нужно активировать)
        for _, cb in ipairs(self._autoLoadCallbacks) do
            pcall(cb, self._data)
        end
    end

    -- регистрация функции, которая вызовется после загрузки конфига
    -- сюда пиши код который должен включать фичи (fly, noclip и тд)
    function Config:OnAutoLoad(cb)
        table.insert(self._autoLoadCallbacks, cb)
    end

    -- удобная функция: загрузить + применить всё сразу
    function Config:LoadAndApply()
        self:Load()
        self:ApplyAll()
    end

    function Config:SetupSettingsUI(Window)
        Window:AddSettingsSection("Config", 100)
        Window:AddSettingsToggle("Auto-Save", true, 101, function(v)
            self._suppressSave = not v
        end)
    end

    MoonLib:RegisterAddon("Config", Config)
end

return ConfigAddon
