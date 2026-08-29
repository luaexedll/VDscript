-- Main.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Загрузка модулей
local Settings = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Settings.lua"))()
local Esp = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/Esp.lua"))()
local NextKiller = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/NextKiller.lua"))()
local NameChanger = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/NameChanger.lua"))()
local BoostFPS = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/BoostFPS.lua"))()
local FullBright = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/FullBright.lua"))()
local Fov = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/Fov.lua"))()

local Connections = {}
local ActiveTasks = {}
local ActiveGenerators = {}
local ActivePallets = {}
local LastUpdateTick = 0
local LastFullESPRefresh = 0

local ScreenGui, IconGui, IndicatorGui, IntroGui

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Filled = false
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(50, 120, 255)
FOVCircle.NumSides = 64
FOVCircle.Radius = Settings.FOVRadius

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

-- Анимация загрузки
local function ShowIntroAnimation()
    IntroGui = Instance.new("ScreenGui")
    IntroGui.Name = "SKV_IntroGui"
    IntroGui.ResetOnSpawn = false
    ProtectGui(IntroGui)

    local IntroFrame = Instance.new("Frame")
    IntroFrame.Size = UDim2.new(0, 300, 0, 70)
    IntroFrame.Position = UDim2.new(0.5, -150, 0.85, 0)
    IntroFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    IntroFrame.BackgroundTransparency = 1
    IntroFrame.BorderSizePixel = 0
    IntroFrame.Parent = IntroGui

    local IntroCorner = Instance.new("UICorner")
    IntroCorner.CornerRadius = UDim.new(0, 8)
    IntroCorner.Parent = IntroFrame

    local IntroLabel = Instance.new("TextLabel")
    IntroLabel.Size = UDim2.new(1, 0, 1, 0)
    IntroLabel.BackgroundTransparency = 1
    IntroLabel.Text = "SKV by takeushi"
    IntroLabel.TextColor3 = Color3.fromRGB(50, 120, 255)
    IntroLabel.TextTransparency = 1
    IntroLabel.TextSize = 16
    IntroLabel.Font = Enum.Font.GothamBold
    IntroLabel.Parent = IntroFrame

    TweenService:Create(IntroFrame, TweenInfo.new(0.6), {BackgroundTransparency = 0.15}):Play()
    TweenService:Create(IntroLabel, TweenInfo.new(0.6), {TextTransparency = 0}):Play()

    task.delay(2.2, function()
        pcall(function()
            TweenService:Create(IntroFrame, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
            TweenService:Create(IntroLabel, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
            task.wait(0.6)
            IntroGui:Destroy()
        end)
    end)
end

ShowIntroAnimation()

local function BuildUI()
    if ScreenGui then pcall(function() ScreenGui:Destroy() end) end
    if IconGui then pcall(function() IconGui:Destroy() end) end
    if IndicatorGui then pcall(function() IndicatorGui:Destroy() end) end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ESPSuiteSKVTakeushi"
    ScreenGui.ResetOnSpawn = false
    ProtectGui(ScreenGui)

    IconGui = Instance.new("ScreenGui")
    IconGui.Name = "ESPQuickIconSKV"
    IconGui.ResetOnSpawn = false
    ProtectGui(IconGui)

    IndicatorGui = Instance.new("ScreenGui")
    IndicatorGui.Name = "ChasedIndsSKV"
    IndicatorGui.IgnoreGuiInset = true
    IndicatorGui.DisplayOrder = 999
    ProtectGui(IndicatorGui)
end

BuildUI()

local QuickIcon = Instance.new("TextButton")
QuickIcon.Size = UDim2.new(0, 36, 0, 36)
QuickIcon.Position = UDim2.new(0, 20, 0.5, -18)
QuickIcon.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
QuickIcon.Text = "SKV"
QuickIcon.TextColor3 = Color3.fromRGB(50, 120, 255)
QuickIcon.TextSize = 12
QuickIcon.Font = Enum.Font.GothamBold
QuickIcon.Visible = false
QuickIcon.Active = true
QuickIcon.Draggable = true
QuickIcon.Parent = IconGui

local qic = Instance.new("UICorner")
qic.CornerRadius = UDim.new(0, 6)
qic.Parent = QuickIcon

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 420)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 8)
HeaderCorner.Parent = Header

local HeaderCover = Instance.new("Frame")
HeaderCover.Size = UDim2.new(1, 0, 0, 10)
HeaderCover.Position = UDim2.new(0, 0, 1, -10)
HeaderCover.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
HeaderCover.BorderSizePixel = 0
HeaderCover.Parent = Header

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 240, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "SKV by takeushi"
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Header

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 28, 0, 28)
CloseButton.Position = UDim2.new(1, -35, 0.5, -14)
CloseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseButton.TextSize = 12
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = Header

local cbc = Instance.new("UICorner")
cbc.CornerRadius = UDim.new(0, 6)
cbc.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    QuickIcon.Visible = true
end)

QuickIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    QuickIcon.Visible = false
end)

local TabButtonsContainer = Instance.new("Frame")
TabButtonsContainer.Size = UDim2.new(0, 360, 0, 30)
TabButtonsContainer.Position = UDim2.new(1, -400, 0.5, -15)
TabButtonsContainer.BackgroundTransparency = 1
TabButtonsContainer.Parent = Header

local UIListLayoutTabs = Instance.new("UIListLayout")
UIListLayoutTabs.FillDirection = Enum.FillDirection.Horizontal
UIListLayoutTabs.HorizontalAlignment = Enum.HorizontalAlignment.Right
UIListLayoutTabs.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayoutTabs.Padding = UDim.new(0, 3)
UIListLayoutTabs.Parent = TabButtonsContainer

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -20, 1, -65)
ContentFrame.Position = UDim2.new(0, 10, 0, 55)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local Tabs = {}
local ActiveTabName = "Visuals"

local function CreateTabContent(name)
    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Name = name .. "Tab"
    tabContainer.Size = UDim2.new(1, 0, 1, 0)
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.ScrollBarThickness = 4
    tabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabContainer.Visible = (name == ActiveTabName)
    tabContainer.Parent = ContentFrame
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = tabContainer
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabContainer.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
    
    Tabs[name] = tabContainer
    return tabContainer
end

local tabVisuals = CreateTabContent("Visuals")
local tabAim = CreateTabContent("Aim")
local tabColors = CreateTabContent("Colors")
local tabMisc = CreateTabContent("Misc")
local tabSettings = CreateTabContent("Settings")
local tabCredits = CreateTabContent("Credits")

local function CreateTabButton(name, text, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 52, 0, 28)
    btn.BackgroundColor3 = (name == ActiveTabName) and Color3.fromRGB(50, 120, 255) or Color3.fromRGB(35, 35, 45)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamMedium
    btn.LayoutOrder = order
    btn.Parent = TabButtonsContainer
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        ActiveTabName = name
        for tName, tFrame in pairs(Tabs) do
            tFrame.Visible = (tName == name)
        end
        for _, child in ipairs(TabButtonsContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = (child == btn) and Color3.fromRGB(50, 120, 255) or Color3.fromRGB(35, 35, 45)
            end
        end
    end)
end

CreateTabButton("Visuals", "Visuals", 1)
CreateTabButton("Aim", "Aim", 2)
CreateTabButton("Colors", "Colors", 3)
CreateTabButton("Misc", "Misc", 4)
CreateTabButton("Settings", "Config", 5)
CreateTabButton("Credits", "Credits", 6)

local function CreateToggle(parent, label, settingKey, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(40, 110, 70) or Color3.fromRGB(28, 28, 36)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.TextColor3 = Color3.fromRGB(240, 240, 240)
    btn.LayoutOrder = order
    btn.Parent = parent
    
    local function updateText()
        local stateStr = Settings[settingKey] and "ON" or "OFF"
        btn.Text = "    " .. label .. ": " .. stateStr
    end
    updateText()
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        btn.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(40, 110, 70) or Color3.fromRGB(28, 28, 36)
        updateText()
        if callback then callback(Settings[settingKey]) end
    end)
end

-- Visuals Tab UI
local RoleBtn = Instance.new("TextButton")
RoleBtn.Size = UDim2.new(1, 0, 0, 36)
RoleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
RoleBtn.TextXAlignment = Enum.TextXAlignment.Left
RoleBtn.TextSize = 13
RoleBtn.Font = Enum.Font.Gotham
RoleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RoleBtn.LayoutOrder = 1
RoleBtn.Parent = tabVisuals

local function updateRoleBtnText()
    if Settings.RoleLogic == "EnemiesOnly" then
        RoleBtn.Text = "    Mode: Enemies Only"
    else
        RoleBtn.Text = "    Mode: All Players"
    end
end
updateRoleBtnText()
Instance.new("UICorner", RoleBtn).CornerRadius = UDim.new(0, 6)

RoleBtn.MouseButton1Click:Connect(function()
    if Settings.RoleLogic == "EnemiesOnly" then
        Settings.RoleLogic = "All"
    else
        Settings.RoleLogic = "EnemiesOnly"
    end
    updateRoleBtnText()
end)

local ESPMainContainer = Instance.new("Frame")
ESPMainContainer.Size = UDim2.new(1, 0, 0, 36)
ESPMainContainer.BackgroundTransparency = 1
ESPMainContainer.LayoutOrder = 2
ESPMainContainer.Parent = tabVisuals

local ESPLayout = Instance.new("UIListLayout")
ESPLayout.SortOrder = Enum.SortOrder.LayoutOrder
ESPLayout.Padding = UDim.new(0, 4)
ESPLayout.Parent = ESPMainContainer

local ESPToggleBtn = Instance.new("TextButton")
ESPToggleBtn.Size = UDim2.new(1, 0, 0, 36)
ESPToggleBtn.BackgroundColor3 = Settings.EnableESP and Color3.fromRGB(40, 110, 70) or Color3.fromRGB(28, 28, 36)
ESPToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
ESPToggleBtn.TextSize = 13
ESPToggleBtn.Font = Enum.Font.Gotham
ESPToggleBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
ESPToggleBtn.LayoutOrder = 1
ESPToggleBtn.Parent = ESPMainContainer

local ESPSubContainer = Instance.new("Frame")
ESPSubContainer.Size = UDim2.new(1, 0, 0, 185)
ESPSubContainer.BackgroundTransparency = 1
ESPSubContainer.Visible = false
ESPSubContainer.LayoutOrder = 2
ESPSubContainer.Parent = ESPMainContainer

local subLayout = Instance.new("UIListLayout")
subLayout.SortOrder = Enum.SortOrder.LayoutOrder
subLayout.Padding = UDim.new(0, 4)
subLayout.Parent = ESPSubContainer

CreateToggle(ESPSubContainer, "Skeleton ESP", "Skeleton", 1)
CreateToggle(ESPSubContainer, "Chams (Highlight)", "Chams", 2)
CreateToggle(ESPSubContainer, "Tracers", "Tracers", 3)
CreateToggle(ESPSubContainer, "Show Names", "ShowName", 4)
CreateToggle(ESPSubContainer, "Show Distance", "ShowDistance", 5)

local function updateESPToggleText()
    local stateStr = Settings.EnableESP and "ON" or "OFF"
    local arrowStr = ESPSubContainer.Visible and " [▲]" or " [▼]"
    ESPToggleBtn.Text = "    ESP Players Main: " .. stateStr .. arrowStr
end
updateESPToggleText()
Instance.new("UICorner", ESPToggleBtn).CornerRadius = UDim.new(0, 6)

ESPToggleBtn.MouseButton1Click:Connect(function()
    Settings.EnableESP = not Settings.EnableESP
    ESPToggleBtn.BackgroundColor3 = Settings.EnableESP and Color3.fromRGB(40, 110, 70) or Color3.fromRGB(28, 28, 36)
    
    local isOpen = not ESPSubContainer.Visible
    ESPSubContainer.Visible = isOpen
    if isOpen then
        ESPMainContainer.Size = UDim2.new(1, 0, 0, 36 + 185 + 4)
    else
        ESPMainContainer.Size = UDim2.new(1, 0, 0, 36)
    end
    updateESPToggleText()
end)

CreateToggle(tabVisuals, "Generator ESP", "EnableGeneratorsESP", 3)
CreateToggle(tabVisuals, "Pallet ESP", "EnablePalletsESP", 4)

-- Aim Tab UI
CreateToggle(tabAim, "Включить Aim Assist", "EnableAim", 1)

local PartBtn = Instance.new("TextButton")
PartBtn.Size = UDim2.new(1, 0, 0, 36)
PartBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
PartBtn.TextXAlignment = Enum.TextXAlignment.Left
PartBtn.TextSize = 13
PartBtn.Font = Enum.Font.Gotham
PartBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
PartBtn.Text = "    Часть тела: Голова (Head)"
PartBtn.LayoutOrder = 2
PartBtn.Parent = tabAim
Instance.new("UICorner", PartBtn).CornerRadius = UDim.new(0, 6)

PartBtn.MouseButton1Click:Connect(function()
    if Settings.TargetPart == "Head" then
        Settings.TargetPart = "HumanoidRootPart"
        PartBtn.Text = "    Часть тела: Торс (Body)"
    else
        Settings.TargetPart = "Head"
        PartBtn.Text = "    Часть тела: Голова (Head)"
    end
end)

local AimKeyBtn = Instance.new("TextButton")
AimKeyBtn.Size = UDim2.new(1, 0, 0, 36)
AimKeyBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
AimKeyBtn.TextXAlignment = Enum.TextXAlignment.Left
AimKeyBtn.TextSize = 13
AimKeyBtn.Font = Enum.Font.Gotham
AimKeyBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
AimKeyBtn.Text = "    Клавиша Аима (Aim Key): MouseButton2 (ПКМ)"
AimKeyBtn.LayoutOrder = 3
AimKeyBtn.Parent = tabAim
Instance.new("UICorner", AimKeyBtn).CornerRadius = UDim.new(0, 6)

AimKeyBtn.MouseButton1Click:Connect(function()
    Settings.IsBindingAimKey = true
    AimKeyBtn.Text = "    Клавиша Аима: [Нажмите кнопку...]"
end)

local SmoothLevels = {0.1, 0.25, 0.5, 1.0}
local SmoothNames = {"Очень плавно (0.1)", "Стандарт (0.25)", "Быстро (0.5)", "Мгновенно (1.0)"}
local currentSmoothIdx = 2

local SmoothBtn = Instance.new("TextButton")
SmoothBtn.Size = UDim2.new(1, 0, 0, 36)
SmoothBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
SmoothBtn.TextXAlignment = Enum.TextXAlignment.Left
SmoothBtn.TextSize = 13
SmoothBtn.Font = Enum.Font.Gotham
SmoothBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
SmoothBtn.Text = "    Плавность: " .. SmoothNames[currentSmoothIdx]
SmoothBtn.LayoutOrder = 4
SmoothBtn.Parent = tabAim
Instance.new("UICorner", SmoothBtn).CornerRadius = UDim.new(0, 6)

SmoothBtn.MouseButton1Click:Connect(function()
    currentSmoothIdx = currentSmoothIdx + 1
    if currentSmoothIdx > #SmoothLevels then currentSmoothIdx = 1 end
    Settings.Smoothness = SmoothLevels[currentSmoothIdx]
    SmoothBtn.Text = "    Плавность: " .. SmoothNames[currentSmoothIdx]
end)

CreateToggle(tabAim, "Проверка стен (WallCheck)", "WallCheck", 5)
CreateToggle(tabAim, "Проверка команды (TeamCheck)", "TeamCheck", 6)
CreateToggle(tabAim, "Отображать круг FOV", "EnableFOV", 7)

local FOVBox = Instance.new("TextBox")
FOVBox.Size = UDim2.new(1, 0, 0, 36)
FOVBox.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
FOVBox.PlaceholderText = "Радиус FOV (например: 120)"
FOVBox.Text = tostring(Settings.FOVRadius)
FOVBox.TextXAlignment = Enum.TextXAlignment.Left
FOVBox.TextSize = 13
FOVBox.Font = Enum.Font.Gotham
FOVBox.TextColor3 = Color3.fromRGB(240, 240, 240)
FOVBox.LayoutOrder = 8
FOVBox.Parent = tabAim
Instance.new("UICorner", FOVBox).CornerRadius = UDim.new(0, 6)

FOVBox:GetPropertyChangedSignal("Text"):Connect(function()
    local num = tonumber(FOVBox.Text)
    if num then
        Settings.FOVRadius = num
        FOVCircle.Radius = num
    end
end)

-- Colors Tab UI
local function CreateColorPickerButton(parent, label, colorKey, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.TextColor3 = Color3.fromRGB(240, 240, 240)
    btn.LayoutOrder = order
    btn.Parent = parent
    
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 24, 0, 20)
    indicator.Position = UDim2.new(1, -34, 0.5, -10)
    indicator.BackgroundColor3 = Settings[colorKey]
    indicator.Parent = btn
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 4)
    
    btn.Text = "    " .. label
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local colorsList = {
        Color3.fromRGB(255, 60, 60),
        Color3.fromRGB(60, 160, 255),
        Color3.fromRGB(60, 255, 60),
        Color3.fromRGB(255, 255, 60),
        Color3.fromRGB(150, 0, 200),
        Color3.fromRGB(74, 255, 181),
        Color3.fromRGB(255, 255, 255)
    }
    local idx = 1
    
    btn.MouseButton1Click:Connect(function()
        idx = idx % #colorsList + 1
        Settings[colorKey] = colorsList[idx]
        indicator.BackgroundColor3 = Settings[colorKey]
    end)
end

CreateColorPickerButton(tabColors, "Killer / Enemy Color", "KillerColor", 1)
CreateColorPickerButton(tabColors, "Survivor / Ally Color", "SurvivorColor", 2)
CreateColorPickerButton(tabColors, "Generator Color", "GeneratorColor", 3)
CreateColorPickerButton(tabColors, "Pallet Color", "PalletColor", 4)

-- Misc Tab UI
CreateToggle(tabMisc, "Next Killer Display", "EnableNextKiller", 1)
CreateToggle(tabMisc, "Custom Camera FOV", "EnableCameraFOV", 2)

local CamFOVBox = Instance.new("TextBox")
CamFOVBox.Size = UDim2.new(1, 0, 0, 36)
CamFOVBox.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
CamFOVBox.PlaceholderText = "Поле зрения Камеры (например: 90)"
CamFOVBox.Text = tostring(Settings.CameraFOVValue)
CamFOVBox.TextXAlignment = Enum.TextXAlignment.Left
CamFOVBox.TextSize = 13
CamFOVBox.Font = Enum.Font.Gotham
CamFOVBox.TextColor3 = Color3.fromRGB(240, 240, 240)
CamFOVBox.LayoutOrder = 3
CamFOVBox.Parent = tabMisc
Instance.new("UICorner", CamFOVBox).CornerRadius = UDim.new(0, 6)

CamFOVBox:GetPropertyChangedSignal("Text"):Connect(function()
    local val = tonumber(CamFOVBox.Text)
    if val then
        Settings.CameraFOVValue = math.clamp(val, 30, 120)
    end
end)

CreateToggle(tabMisc, "Full Bright (Ночное зрение)", "EnableFullBright", 4)
CreateToggle(tabMisc, "FPS Boost (Оптимизация)", "FPSBoostApplied", 5, function(state)
    BoostFPS.Apply(state, Connections)
end)
CreateToggle(tabMisc, "Убрать туман (Remove Fog)", "RemoveFog", 6)

-- Добавленная функция Moonwalk в Misc вкладку
if Settings.EnableMoonwalk == nil then Settings.EnableMoonwalk = false end
CreateToggle(tabMisc, "Moonwalk", "EnableMoonwalk", 7)

table.insert(ActiveTasks, task.spawn(function()
    while true do
        task.wait()
        if Settings.EnableMoonwalk then
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoid and rootPart then
                    if humanoid.MoveDirection.Magnitude > 0 then
                        rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.pi, 0)
                    end
                end
            end
        end
    end
end))

-- Settings Tab UI
CreateToggle(tabSettings, "Nick Changer (FPS Saver)", "EnableNickChanger", 1)

local TargetNickBox = Instance.new("TextBox")
TargetNickBox.Size = UDim2.new(1, 0, 0, 34)
TargetNickBox.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
TargetNickBox.Text = ""
TargetNickBox.PlaceholderText = "Оригинальный ник"
TargetNickBox.TextXAlignment = Enum.TextXAlignment.Left
TargetNickBox.TextSize = 13
TargetNickBox.Font = Enum.Font.Gotham
TargetNickBox.TextColor3 = Color3.fromRGB(240, 240, 240)
TargetNickBox.LayoutOrder = 2
TargetNickBox.Parent = tabSettings
Instance.new("UICorner", TargetNickBox).CornerRadius = UDim.new(0, 6)

local NewNickBox = Instance.new("TextBox")
NewNickBox.Size = UDim2.new(1, 0, 0, 34)
NewNickBox.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
NewNickBox.Text = ""
NewNickBox.PlaceholderText = "Новый фейк-ник"
NewNickBox.TextXAlignment = Enum.TextXAlignment.Left
NewNickBox.TextSize = 13
NewNickBox.Font = Enum.Font.Gotham
NewNickBox.TextColor3 = Color3.fromRGB(240, 240, 240)
NewNickBox.LayoutOrder = 3
NewNickBox.Parent = tabSettings
Instance.new("UICorner", NewNickBox).CornerRadius = UDim.new(0, 6)

local ApplyNickBtn = Instance.new("TextButton")
ApplyNickBtn.Size = UDim2.new(1, 0, 0, 34)
ApplyNickBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 255)
ApplyNickBtn.TextXAlignment = Enum.TextXAlignment.Left
ApplyNickBtn.TextSize = 13
ApplyNickBtn.Font = Enum.Font.GothamBold
ApplyNickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyNickBtn.Text = "    + Добавить подмену ника"
ApplyNickBtn.LayoutOrder = 4
ApplyNickBtn.Parent = tabSettings
Instance.new("UICorner", ApplyNickBtn).CornerRadius = UDim.new(0, 6)

local NicksListHeader = Instance.new("TextLabel")
NicksListHeader.Size = UDim2.new(1, 0, 0, 24)
NicksListHeader.BackgroundTransparency = 1
NicksListHeader.Text = "    Активные подмены (нажми чтобы удалить):"
NicksListHeader.TextColor3 = Color3.fromRGB(180, 180, 200)
NicksListHeader.TextSize = 12
NicksListHeader.Font = Enum.Font.GothamBold
NicksListHeader.TextXAlignment = Enum.TextXAlignment.Left
NicksListHeader.LayoutOrder = 5
NicksListHeader.Parent = tabSettings

local NicksListContainer = Instance.new("Frame")
NicksListContainer.Size = UDim2.new(1, 0, 0, 90)
NicksListContainer.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
NicksListContainer.BorderSizePixel = 0
NicksListContainer.LayoutOrder = 6
NicksListContainer.Parent = tabSettings
Instance.new("UICorner", NicksListContainer).CornerRadius = UDim.new(0, 6)

local NicksScrolling = Instance.new("ScrollingFrame")
NicksScrolling.Size = UDim2.new(1, -6, 1, -6)
NicksScrolling.Position = UDim2.new(0, 3, 0, 3)
NicksScrolling.BackgroundTransparency = 1
NicksScrolling.BorderSizePixel = 0
NicksScrolling.ScrollBarThickness = 3
NicksScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
NicksScrolling.Parent = NicksListContainer

local NicksListLayout = Instance.new("UIListLayout")
NicksListLayout.SortOrder = Enum.SortOrder.LayoutOrder
NicksListLayout.Padding = UDim.new(0, 4)
NicksListLayout.Parent = NicksScrolling

NicksListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    NicksScrolling.CanvasSize = UDim2.new(0, 0, 0, NicksListLayout.AbsoluteContentSize.Y + 5)
end)

local function RefreshNicksListUI()
    for _, child in ipairs(NicksScrolling:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    local index = 1
    for orig, fake in pairs(Settings.CustomNicks) do
        local itemBtn = Instance.new("TextButton")
        itemBtn.Size = UDim2.new(1, 0, 0, 26)
        itemBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
        itemBtn.TextXAlignment = Enum.TextXAlignment.Left
        itemBtn.TextSize = 11
        itemBtn.Font = Enum.Font.Gotham
        itemBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        itemBtn.Text = "    [-] " .. orig .. " -> " .. fake
        itemBtn.LayoutOrder = index
        itemBtn.Parent = NicksScrolling
        Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 4)
        
        itemBtn.MouseButton1Click:Connect(function()
            Settings.CustomNicks[orig] = nil
            RefreshNicksListUI()
        end)
        index = index + 1
    end
end

ApplyNickBtn.MouseButton1Click:Connect(function()
    local target = TargetNickBox.Text
    local fake = NewNickBox.Text
    if target ~= "" and fake ~= "" then
        Settings.CustomNicks[target] = fake
        TargetNickBox.Text = ""
        NewNickBox.Text = ""
        RefreshNicksListUI()
    end
end)

local MenuBindButton = Instance.new("TextButton")
MenuBindButton.Size = UDim2.new(1, 0, 0, 34)
MenuBindButton.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
MenuBindButton.TextXAlignment = Enum.TextXAlignment.Left
MenuBindButton.TextSize = 13
MenuBindButton.Font = Enum.Font.Gotham
MenuBindButton.TextColor3 = Color3.fromRGB(240, 240, 240)
MenuBindButton.LayoutOrder = 7
MenuBindButton.Parent = tabSettings
Instance.new("UICorner", MenuBindButton).CornerRadius = UDim.new(0, 6)

local function safeUpdateMenuBindText()
    if Settings.IsBindingMenuKey then
        MenuBindButton.Text = "    Menu Toggle Key: [Press any key...]"
    else
        MenuBindButton.Text = "    Menu Toggle Key: " .. tostring(Settings.MenuKeyBind.Name)
    end
end
safeUpdateMenuBindText()

MenuBindButton.MouseButton1Click:Connect(function()
    Settings.IsBindingMenuKey = true
    safeUpdateMenuBindText()
end)

-- Отдельная кнопка для сброса/очистки бинда меню (теперь не ломает открытие гуи)
local ResetMenuBindBtn = Instance.new("TextButton")
ResetMenuBindBtn.Size = UDim2.new(1, 0, 0, 34)
ResetMenuBindBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
ResetMenuBindBtn.TextXAlignment = Enum.TextXAlignment.Left
ResetMenuBindBtn.TextSize = 13
ResetMenuBindBtn.Font = Enum.Font.Gotham
ResetMenuBindBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
ResetMenuBindBtn.Text = "    Сбросить бинд меню на Insert"
ResetMenuBindBtn.LayoutOrder = 8
ResetMenuBindBtn.Parent = tabSettings
Instance.new("UICorner", ResetMenuBindBtn).CornerRadius = UDim.new(0, 6)

ResetMenuBindBtn.MouseButton1Click:Connect(function()
    Settings.MenuKeyBind = Enum.KeyCode.Insert
    Settings.IsBindingMenuKey = false
    safeUpdateMenuBindText()
end)

local ClearScriptBtn = Instance.new("TextButton")
ClearScriptBtn.Size = UDim2.new(1, 0, 0, 34)
ClearScriptBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
ClearScriptBtn.TextXAlignment = Enum.TextXAlignment.Left
ClearScriptBtn.TextSize = 13
ClearScriptBtn.Font = Enum.Font.GothamBold
ClearScriptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearScriptBtn.Text = "    Clear Script (Unload)"
ClearScriptBtn.LayoutOrder = 9
ClearScriptBtn.Parent = tabSettings
Instance.new("UICorner", ClearScriptBtn).CornerRadius = UDim.new(0, 6)

local function FullCleanup()
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
    pcall(function() if ScreenGui then ScreenGui:Destroy() end end)
    pcall(function() if IconGui then IconGui:Destroy() end end)
    pcall(function() if IndicatorGui then IndicatorGui:Destroy() end end)
    pcall(function() if IntroGui then IntroGui:Destroy() end end)
end

ClearScriptBtn.MouseButton1Click:Connect(function() FullCleanup() end)

-- Credits UI
local CreditLabel1 = Instance.new("TextLabel")
CreditLabel1.Size = UDim2.new(1, 0, 0, 30)
CreditLabel1.BackgroundTransparency = 1
CreditLabel1.Text = "Telegram: @whoisSKV"
CreditLabel1.TextColor3 = Color3.fromRGB(50, 160, 255)
CreditLabel1.TextSize = 16
CreditLabel1.Font = Enum.Font.GothamBold
CreditLabel1.TextXAlignment = Enum.TextXAlignment.Left
CreditLabel1.LayoutOrder = 1
CreditLabel1.Parent = tabCredits

local CreditLabel2 = Instance.new("TextLabel")
CreditLabel2.Size = UDim2.new(1, 0, 0, 50)
CreditLabel2.BackgroundTransparency = 1
CreditLabel2.Text = "пишите если возникли вопросы."
CreditLabel2.TextColor3 = Color3.fromRGB(200, 200, 200)
CreditLabel2.TextSize = 13
CreditLabel2.Font = Enum.Font.Gotham
CreditLabel2.TextXAlignment = Enum.TextXAlignment.Left
CreditLabel2.TextWrapped = true
CreditLabel2.LayoutOrder = 2
CreditLabel2.Parent = tabCredits

-- Подключаем модуль Aim
local fovConns = Fov.SetupInputs(Settings, AimKeyBtn)
for _, c in ipairs(fovConns) do table.insert(Connections, c) end

-- Обработка выходов игроков
table.insert(Connections, Players.PlayerRemoving:Connect(function(player)
    Esp.CleanupPlayerCache(player)
end))

-- Управление биндами меню и аима (Исправлено, чтобы не ломать переключение)
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gp)
    if Settings.IsBindingMenuKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Settings.MenuKeyBind = input.KeyCode
            Settings.IsBindingMenuKey = false
            safeUpdateMenuBindText()
        end
        return
    end

    if Settings.IsBindingAimKey then
        if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
            Settings.AimKey = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType
            Settings.IsBindingAimKey = false
            AimKeyBtn.Text = "    Клавиша Аима (Aim Key): " .. tostring(input.KeyCode.Name ~= "" and input.KeyCode.Name or input.UserInputType.Name)
        end
        return
    end
    
    if not gp and input.KeyCode == Settings.MenuKeyBind then
        MainFrame.Visible = not MainFrame.Visible
        QuickIcon.Visible = not MainFrame.Visible
    end
end))

-- Фоновые задачи (Nick Changer, FullBright)
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

-- Вспомогательные функции для генераторов и паллет
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
    h.FillColor = color
    h.OutlineColor = color
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
    local finalColor = cp < 50 and Settings.GeneratorColor:Lerp(Color3.fromRGB(180, 180, 0), cp / 50) or Color3.fromRGB(180, 180, 0):Lerp(Color3.fromRGB(0, 150, 0), (cp - 50) / 50)
    
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

-- Главный рендер-цикл
table.insert(Connections, RunService.RenderStepped:Connect(function()
    local now = tick()
    
    -- Обновление AIM и FOV камеры через модуль
    Fov.Update(Settings, FOVCircle, MainFrame)
    
    if now - LastUpdateTick < 0.03 then return end
    LastUpdateTick = now
    
    if now - LastFullESPRefresh > 5 then 
        LastFullESPRefresh = now 
        RefreshESPMapObjects() 
    end
    
    -- Обновление NextKiller через модуль
    NextKiller.Update(Settings, IndicatorGui, function(p)
        return NameChanger.GetDisplayName(p, Settings)
    end)
    
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

    -- Обновление ESP игроков через модуль
    Esp.Update(Settings, function(p)
        return NameChanger.GetDisplayName(p, Settings)
    end)
end))

RefreshESPMapObjects()
