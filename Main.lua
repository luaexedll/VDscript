
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- лоад модулей
local Settings = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Settings.lua"))()
local Esp = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/Esp.lua"))()
local NameChanger = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/NameChanger.lua"))()
local BoostFPS = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/BoostFPS.lua"))()
local FullBright = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/FullBright.lua"))()
local Fov = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/Fov.lua"))()
local MoonwalkModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/Moonwalk.lua"))()
local moonwalkInst = MoonwalkModule.new()

local function SafeLoadModule(url, name)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not ok or type(result) ~= "table" then
        return nil
    end
    return result
end

local AutoSkillCheck = SafeLoadModule("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/AutoSkillCheck.lua", "AutoSkillCheck")
local AutoDagger = SafeLoadModule("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/AutoDagger.lua", "AutoDagger")

Settings.SkillCheckKey = Enum.KeyCode.Space
Settings.DaggerKey = Enum.UserInputType.MouseButton2

local Connections = {}
local ActiveTasks = {}
local ActiveGenerators = {}
local ActivePallets = {}
local GeneratorProgressCache = {}
local LastUpdateTick = 0
local LastFullESPRefresh = 0

local ScreenGui, IconGui, IntroGui
local NextKillerLabel

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

-- лоад гуи
local SKVGuiP1 = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/SKVGui_p1.lua"))()
local SKVGuiP2 = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/SKVGui_p2.lua"))()
local SKVGuiP3 = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/SKVGui_p3.lua"))()
local SKVGuiP4 = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/SKVGui_p4.lua"))()
local SKVGuiP5a = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/SKVGui_p5a.lua"))()
local SKVGuiP5b = loadstring(game:HttpGet("https://raw.githubusercontent.com/luaexedll/VDscript/refs/heads/main/Modules/SKVGui_p5b.lua"))()

local GuiCtx = {
    Connections = Connections,
    FOVCircle = FOVCircle,
    moonwalkInst = moonwalkInst,
    AutoSkillCheck = AutoSkillCheck,
    AutoDagger = AutoDagger,
    BoostFPS = BoostFPS,
    isInteracting = false,
}

local function FullCleanup()
    moonwalkInst:Toggle(false)
    BoostFPS.Apply(false)
    if AutoSkillCheck then pcall(AutoSkillCheck.Cleanup) end
    if AutoDagger then pcall(AutoDagger.Cleanup) end
    Settings.AutoSkillCheck = false
    Settings.AutoDagger = false
    for _, conn in ipairs(Connections) do pcall(function() conn:Disconnect() end) end
    Connections = {}
    GuiCtx.Connections = Connections
    for _, taskThread in ipairs(ActiveTasks) do pcall(function() task.cancel(taskThread) end) end
    ActiveTasks = {}
    Esp.ClearAll()
    Esp.ClearMapESP()
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
    pcall(function() if GuiCtx.ScreenGui then GuiCtx.ScreenGui:Destroy() end end)
    pcall(function() if ScreenGui then ScreenGui:Destroy() end end)
    pcall(function() if IntroGui then IntroGui:Destroy() end end)
end
GuiCtx.FullCleanup = FullCleanup

SKVGuiP1.BuildFrame(Settings, GuiCtx)
SKVGuiP2.Build(GuiCtx)
SKVGuiP4.Build(GuiCtx, SKVGuiP3, Settings)
SKVGuiP5a.Build(GuiCtx, SKVGuiP3, Settings)
SKVGuiP5b.Build(GuiCtx, SKVGuiP3, Settings)

local ScreenGui = GuiCtx.ScreenGui
local MainFrame = GuiCtx.MainFrame
local NextKillerLabel = GuiCtx.RankLabel
local function RefreshNicksListUI() if GuiCtx.refNicks then GuiCtx.refNicks() end end
local function safeUpdateMenuBindText() if GuiCtx.refMenu then GuiCtx.refMenu() end end

do
local fovConns = Fov.SetupInputs(Settings, nil)
for _, c in ipairs(fovConns) do table.insert(Connections, c) end

table.insert(Connections, Players.PlayerRemoving:Connect(function(player)
    Esp.CleanupPlayerCache(player)
end))

end

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

local function UpdateNextKillerLabel()
    if not NextKillerLabel or not NextKillerLabel.Parent then return end

    local players = Players:GetPlayers()
    table.sort(players, function(a, b)
        local aAllowed = GetGameValue(a, "AllowKiller") or GetGameValue(a, "CanBeKiller") or false
        local bAllowed = GetGameValue(b, "AllowKiller") or GetGameValue(b, "CanBeKiller") or false
        if aAllowed ~= bAllowed then return aAllowed == true end
        return (GetGameValue(a, "KillerChance") or GetGameValue(a, "Chance") or 0) >
            (GetGameValue(b, "KillerChance") or GetGameValue(b, "Chance") or 0)
    end)

    local nextKiller = players[1]
    if not nextKiller then
        NextKillerLabel.Text = "    Next Killer: Calculating..."
        return
    end

    local killerName = tostring(
        GetGameValue(nextKiller, "SelectedKiller") or
        GetGameValue(nextKiller, "Killer") or
        GetGameValue(nextKiller, "Role") or
        "Killer"
    )
    local playerName = nextKiller == LocalPlayer and "YOU" or NameChanger.GetDisplayName(nextKiller, Settings)
    NextKillerLabel.Text = "Next: " .. killerName .. " | " .. playerName
end

-- ESP карты через модуль (1 шт, без дублей)
table.insert(Connections, workspace.ChildAdded:Connect(function(c)
    if c.Name == "Map" then
        task.wait(1)
        Esp.RefreshESPMapObjects(Settings)
    end
end))
table.insert(Connections, workspace.Map.ChildAdded:Connect(function(child)
    task.wait(0.2)
    Esp.RefreshESPMapObjects(Settings)
end))
table.insert(Connections, RunService.RenderStepped:Connect(function()
    local now = tick()
    Fov.Update(Settings, FOVCircle, MainFrame)
    if now - LastUpdateTick < 0.03 then return end
    LastUpdateTick = now
    UpdateNextKillerLabel()
    Esp.UpdateMapESP(Settings)
    Esp.Update(Settings, function(p)
        return NameChanger.GetDisplayName(p, Settings)
    end)
end))
Esp.RefreshESPMapObjects(Settings)
