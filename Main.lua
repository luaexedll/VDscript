-- Main.lua (Fluent UI Version - Fixed Logic)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Загрузка Fluent UI Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Загрузка оригинальных модулей
local Settings = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Settings.lua"))()
local Esp = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/Esp.lua"))()
local NextKiller = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/NextKiller.lua"))()
local NameChanger = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/NameChanger.lua"))()
local BoostFPS = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/BoostFPS.lua"))()
local FullBright = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/FullBright.lua"))()
local Fov = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/Fov.lua"))()
local MoonwalkModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/Moonwalk.lua"))()
local moonwalkInst = MoonwalkModule.new()

local Connections = {}
local ActiveTasks = {}
local ActiveGenerators = {}
local ActivePallets = {}
local LastUpdateTick = 0
local LastFullESPRefresh = 0

local IndicatorGui

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Filled = false
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(0, 242, 254)
FOVCircle.NumSides = 64
FOVCircle.Radius = Settings.FOVRadius or 120

local function ProtectGui(gui)
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
            gui.Parent = CoreGui
        elseif gethui then
            gui.Parent = gethui()
        else
            gui.Parent = CoreGui
        end
    end)
    if not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

IndicatorGui = Instance.new("ScreenGui")
IndicatorGui.Name = "ChasedIndsSKV"
IndicatorGui.IgnoreGuiInset = true
IndicatorGui.DisplayOrder = 999
ProtectGui(IndicatorGui)

-- Создание Fluent Окна с привязкой бинда из Settings (по умолчанию RightShift)
local Window = Fluent:CreateWindow({
    Title = "SKV by takeushi/neshluha2017",
    SubTitle = "Violence District",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Settings.MenuKeyBind or Enum.KeyCode.RightShift
})

Fluent:SetTheme({
    Background = Color3.fromRGB(13, 17, 23),
    ContainerFrame = Color3.fromRGB(11, 14, 20),
    Accent = Color3.fromRGB(0, 242, 254),
    Text = Color3.fromRGB(240, 240, 240),
    SubText = Color3.fromRGB(150, 160, 175)
})

local Tabs = {
    Aim = Window:AddTab({ Title = "Aim", Icon = "target" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "sliders" }),
    Config = Window:AddTab({ Title = "Config", Icon = "settings" }),
    Credits = Window:AddTab({ Title = "Credits", Icon = "user" })
}

-- ==================== ВКЛАДКА 1: AIM ====================
Tabs.Aim:AddSection("AIM CONFIGURATION")

local AimToggle = Tabs.Aim:AddToggle("AimToggle", { Title = "Aim", SubTitle = "Enable aim assist", Default = Settings.EnableAim or false })
AimToggle:OnChanged(function(Value)
    Settings.EnableAim = Value
end)

local AimTargetDropdown = Tabs.Aim:AddDropdown("AimTarget", {
    Title = "Aim Target",
    SubTitle = "Target bone selection",
    Values = {"Head", "Body"},
    Default = (Settings.TargetPart == "HumanoidRootPart" and "Body" or "Head"),
})
AimTargetDropdown:OnChanged(function(Value)
    Settings.TargetPart = (Value == "Head") and "Head" or "HumanoidRootPart"
end)

local AimKeybind = Tabs.Aim:AddKeybind("AimKey", {
    Title = "Aim Key",
    SubTitle = "Press to bind",
    Mode = "Hold",
    Default = "MouseButton2",
    ChangedCallback = function(NewKey)
        if typeof(NewKey) == "EnumItem" then
            Settings.AimKey = NewKey
        elseif typeof(NewKey) == "string" then
            if NewKey == "MB2" or NewKey == "RMB" or NewKey == "MouseButton2" then
                Settings.AimKey = Enum.UserInputType.MouseButton2
            elseif NewKey == "MB1" or NewKey == "LMB" or NewKey == "MouseButton1" then
                Settings.AimKey = Enum.UserInputType.MouseButton1
            elseif Enum.KeyCode[NewKey] then
                Settings.AimKey = Enum.KeyCode[NewKey]
            end
        end
    end
})

local SmoothSlider = Tabs.Aim:AddSlider("SmoothSlider", {
    Title = "Smooth",
    SubTitle = "Aim smoothness",
    Min = 0.1,
    Max = 1.0,
    Default = Settings.Smoothness or 0.5,
    Rounding = 1,
    Callback = function(Value)
        Settings.Smoothness = Value
    end
})

local WallCheckToggle = Tabs.Aim:AddToggle("WallCheck", { Title = "Wall Check", SubTitle = "Skip targets behind walls", Default = Settings.WallCheck or false })
WallCheckToggle:OnChanged(function(Value) Settings.WallCheck = Value end)

local TeamCheckToggle = Tabs.Aim:AddToggle("TeamCheck", { Title = "Team Check", SubTitle = "Skip teammates", Default = Settings.TeamCheck or false })
TeamCheckToggle:OnChanged(function(Value) Settings.TeamCheck = Value end)

local FOVSlider = Tabs.Aim:AddSlider("FOVSlider", {
    Title = "FOV Size",
    SubTitle = "Aim field of view",
    Min = 10,
    Max = 500,
    Default = Settings.FOVRadius or 120,
    Rounding = 0,
    Callback = function(Value)
        Settings.FOVRadius = Value
        FOVCircle.Radius = Value
    end
})

-- ==================== ВКЛАДКА 2: VISUALS ====================
Tabs.Visuals:AddSection("VISUAL CONFIGURATION")

local ModeDropdown = Tabs.Visuals:AddDropdown("ModeDropdown", {
    Title = "Mode",
    SubTitle = "Target selection",
    Values = {"Enemies only", "All players"},
    Default = (Settings.RoleLogic == "All" and "All players" or "Enemies only")
})
ModeDropdown:OnChanged(function(Value)
    Settings.RoleLogic = (Value == "Enemies only") and "EnemiesOnly" or "All"
end)

local ShowNamesToggle = Tabs.Visuals:AddToggle("ShowNames", { Title = "Show names", SubTitle = "Display player names", Default = Settings.ShowName or false })
ShowNamesToggle:OnChanged(function(Value) Settings.ShowName = Value end)

local ShowDistanceToggle = Tabs.Visuals:AddToggle("ShowDistance", { Title = "Show distance", SubTitle = "Display distance to target", Default = Settings.ShowDistance or false })
ShowDistanceToggle:OnChanged(function(Value) Settings.ShowDistance = Value end)

local ESPToggle = Tabs.Visuals:AddToggle("ESPToggle", { Title = "ESP", SubTitle = "Players ESP", Default = Settings.EnableESP or false })
ESPToggle:OnChanged(function(Value) Settings.EnableESP = Value end)

local GenESPToggle = Tabs.Visuals:AddToggle("GenESP", { Title = "Generator ESP", SubTitle = "ESP for generators", Default = Settings.EnableGeneratorsESP or false })
GenESPToggle:OnChanged(function(Value) Settings.EnableGeneratorsESP = Value end)

local PalletESPToggle = Tabs.Visuals:AddToggle("PalletESP", { Title = "Pallet ESP", SubTitle = "ESP for pallet", Default = Settings.EnablePalletsESP or false })
PalletESPToggle:OnChanged(function(Value) Settings.EnablePalletsESP = Value end)

local CameraFOVSlider = Tabs.Visuals:AddSlider("CameraFOV", {
    Title = "FOV",
    SubTitle = "Camera Field of View",
    Min = 60,
    Max = 120,
    Default = Settings.CameraFOVValue or 90,
    Rounding = 0,
    Callback = function(Value)
        Settings.CameraFOVValue = Value
        Settings.EnableCameraFOV = true
    end
})

local NextKillerParagraph = Tabs.Visuals:AddParagraph({
    Title = "NEXT KILLER",
    Content = "NEXT KILLER: KILLER | YOU"
})

-- ==================== ВКЛАДКА 3: MISC ====================
Tabs.Misc:AddSection("MISCELLANEOUS")

local NoFogToggle = Tabs.Misc:AddToggle("NoFog", { Title = "No Fog", SubTitle = "Disable game fog", Default = Settings.RemoveFog or false })
NoFogToggle:OnChanged(function(Value) Settings.RemoveFog = Value end)

local FPSBoostToggle = Tabs.Misc:AddToggle("FPSBoost", { Title = "FPS Boost", SubTitle = "Optimize graphics", Default = Settings.FPSBoostApplied or false })
FPSBoostToggle:OnChanged(function(Value)
    Settings.FPSBoostApplied = Value
    BoostFPS.Apply(Value, Connections)
end)

local FullBrightToggle = Tabs.Misc:AddToggle("FullBright", { Title = "Full Bright", SubTitle = "Disable darkness", Default = Settings.EnableFullBright or false })
FullBrightToggle:OnChanged(function(Value) Settings.EnableFullBright = Value end)

local MoonwalkToggle = Tabs.Misc:AddToggle("Moonwalk", { Title = "Moonwalk", SubTitle = "Enable moonwalk feature", Default = false })
MoonwalkToggle:OnChanged(function(Value)
    moonwalkInst:Toggle(Value)
end)

-- ==================== ВКЛАДКА 4: CONFIG ====================
Tabs.Config:AddSection("CONFIGURATIONS")

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

SaveManager:BuildConfigFolder(Fluent, "SKV_Script_Configs")
InterfaceManager:BuildInterfaceSection(Tabs.Config)
SaveManager:BuildConfigSection(Tabs.Config)

local UnloadButton = Tabs.Config:AddButton({
    Title = "Unload UI",
    Description = "Completely remove script from memory",
    Callback = function()
        FullCleanup()
        Fluent:Destroy()
    end
})

-- ==================== ВКЛАДКА 5: CREDITS ====================
Tabs.Credits:AddSection("CREDITS & CONTACTS")

Tabs.Credits:AddParagraph({
    Title = "По всем вопросам:",
    Content = "Telegram: @whoisSKV"
})

Tabs.Credits:AddButton({
    Title = "Copy Telegram Handle",
    Description = "Click to copy @whoisSKV",
    Callback = function()
        if setclipboard then
            setclipboard("@whoisSKV")
            Fluent:Notify({ Title = "Copied", Content = "Telegram contact copied to clipboard!", Duration = 3 })
        end
    end
})

-- ==================== ИСХОДНАЯ ЛОГИКА ====================

function FullCleanup()
    for _, conn in ipairs(Connections) do pcall(function() conn:Disconnect() end) end
    Connections = {}
    for _, taskThread in ipairs(ActiveTasks) do pcall(function() task.cancel(taskThread) end) end
    ActiveTasks = {}

    Esp.ClearAll()

    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local h = p.Character:FindFirstChild("ESP_Chams_Clean")
            if h then pcall(function() h:Destroy() end) end
        end
    end

    local Map = workspace:FindFirstChild("Map")
    if Map then
        for _, obj in ipairs(Map:GetDescendants()) do
            local tag = obj:FindFirstChild("GenSKV_Tag")
            if tag then pcall(function() tag:Destroy() end) end
            local objH = obj:FindFirstChild("SKV_ObjH")
            if objH then pcall(function() objH:Destroy() end) end
        end
    end

    pcall(function() Camera.FieldOfView = 70 end)
    pcall(function() FOVCircle:Remove() end)
    pcall(function() if IndicatorGui then IndicatorGui:Destroy() end end)
end

-- Исходное подключение ввода Aim к Fov модулю
local fovConns = Fov.SetupInputs(Settings, nil)
for _, c in ipairs(fovConns) do table.insert(Connections, c) end

local function GetGameValue(obj, name)
    if not obj then return nil end
    local attr = obj:GetAttribute(name)
    if attr ~= nil then return attr end
    local child = obj:FindFirstChild(name)
    if child then
        local success, val = pcall(function() return child.Value end)
        if success then return val end
    end
    return nil
end

local function ApplyObjectHighlight(object, color, enabled)
    if not enabled then
        local h = object:FindFirstChild("SKV_ObjH")
        if h then h:Destroy() end
        return
    end
    local h = object:FindFirstChild("SKV_ObjH")
    if not h then
        h = Instance.new("Highlight")
        h.Name = "SKV_ObjH"
        h.Adornee = object
        h.FillTransparency = 0.7
        h.OutlineTransparency = 0.2
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = object
    end
    h.FillColor = color or Color3.fromRGB(0, 242, 254)
    h.OutlineColor = color or Color3.fromRGB(0, 242, 254)
end

local function CreateBillboardTag(text, color, size, textSize)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SKV_Tag"
    billboard.AlwaysOnTop = true
    billboard.Size = size or UDim2.new(0, 120, 0, 30)
    
    local label = Instance.new("TextLabel")
    label.Name = "SKV_Label"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = textSize or 10
    label.TextWrapped = true
    label.RichText = true 
    label.Parent = billboard
    return billboard
end

local function updateGeneratorProgress(generator)
    if not generator or not generator.Parent then return true end
    if not Settings.EnableGeneratorsESP then
        local billboard = generator:FindFirstChild("GenSKV_Tag")
        if billboard then billboard:Destroy() end
        ApplyObjectHighlight(generator, Settings.GeneratorColor, false)
        return false
    end
    
    local percent = GetGameValue(generator, "RepairProgress") or GetGameValue(generator, "Progress") or 0
    local billboard = generator:FindFirstChild("GenSKV_Tag")
    
    if percent >= 100 then
        if billboard then billboard:Destroy() end
        ApplyObjectHighlight(generator, Settings.GeneratorColor, false)
        return true
    end
    
    ApplyObjectHighlight(generator, Settings.GeneratorColor, true)
    local cp = math.clamp(percent, 0, 100)
    local genColor = Settings.GeneratorColor or Color3.fromRGB(0, 242, 254)
    local finalColor = cp < 50 and genColor:Lerp(Color3.fromRGB(180, 180, 0), cp / 50) or Color3.fromRGB(180, 180, 0):Lerp(Color3.fromRGB(0, 150, 0), (cp - 50) / 50)
    
    local percentStr = string.format("[%.2f%%]", percent)
    if not billboard then
        billboard = CreateBillboardTag(percentStr, finalColor)
        billboard.Name, billboard.StudsOffset = "GenSKV_Tag", Vector3.new(0, 2, 0)
        billboard.Adornee = generator:FindFirstChild("defaultMaterial", true) or generator
        billboard.Parent = generator
    else
        local lbl = billboard:FindFirstChild("SKV_Label")
        if lbl then
            lbl.Text = percentStr
            lbl.TextColor3 = finalColor
        end
    end
    return false
end

local function RefreshESPMapObjects()
    ActiveGenerators = {}
    ActivePallets = {}
    local Map = workspace:FindFirstChild("Map")
    if not Map then return end
    
    for _, obj in ipairs(Map:GetDescendants()) do
        if obj.Name == "Generator" then 
            table.insert(ActiveGenerators, obj)
            updateGeneratorProgress(obj)
        elseif obj.Name == "Palletwrong" or obj.Name == "Pallet" then 
            table.insert(ActivePallets, obj)
            ApplyObjectHighlight(obj, Settings.PalletColor, Settings.EnablePalletsESP)
        end
    end
end

table.insert(Connections, workspace.ChildAdded:Connect(function(c) 
    if c.Name == "Map" then 
        task.wait(1) 
        RefreshESPMapObjects() 
    end 
end))

table.insert(Connections, Players.PlayerRemoving:Connect(function(player)
    Esp.CleanupPlayerCache(player)
end))

-- Фоновые задачи
table.insert(ActiveTasks, task.spawn(function()
    while task.wait(0.5) do
        NameChanger.Run(Settings)
    end
end))

table.insert(ActiveTasks, task.spawn(function()
    while task.wait(0.1) do
        FullBright.Update(Settings)
    end
end))

-- Исходный цикл обновления
table.insert(Connections, RunService.RenderStepped:Connect(function()
    local now = tick()
    
    -- Обновление AIM / FOV
    Fov.Update(Settings, FOVCircle, nil)
    
    if now - LastUpdateTick < 0.03 then return end
    LastUpdateTick = now
    
    if now - LastFullESPRefresh > 5 then 
        LastFullESPRefresh = now 
        RefreshESPMapObjects() 
    end
    
    -- Обновление NextKiller
    NextKiller.Update(Settings, IndicatorGui, function(p)
        return NameChanger.GetDisplayName(p, Settings)
    end)
    
    if NextKillerParagraph then
        local killerText = "NEXT KILLER: " .. (Settings.NextKillerName or "UNKNOWN")
        NextKillerParagraph:SetTitle("NEXT KILLER STATUS")
        NextKillerParagraph:SetDesc(killerText)
    end
    
    for i = #ActivePallets, 1, -1 do
        local p = ActivePallets[i]
        if p and p.Parent then ApplyObjectHighlight(p, Settings.PalletColor, Settings.EnablePalletsESP)
        else table.remove(ActivePallets, i) end
    end
    
    for i = #ActiveGenerators, 1, -1 do
        local g = ActiveGenerators[i]
        if g and g.Parent then 
            if updateGeneratorProgress(g) then table.remove(ActiveGenerators, i) end 
        else table.remove(ActiveGenerators, i) end
    end

    -- Обновление ESP Игроков
    Esp.Update(Settings, function(p)
        return NameChanger.GetDisplayName(p, Settings)
    end)
end))

RefreshESPMapObjects()
SaveManager:LoadAutoloadConfig()
