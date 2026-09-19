-- Modules/AutoSkillCheck.lua
-- Auto Skill Check (Perfect / Instant) для [CURE] Violence District
--
-- Механика игры (проверено по открытым исходникам VD-скриптов):
--   * PlayerGui.<SkillCheckPromptGui>.Check содержит два GuiObject:
--       Line - вращающаяся стрелка (свойство Rotation)
--       Goal - зона попадания (свойство Rotation)
--   * Идеальное окно = Goal.Rotation + 101 ... Goal.Rotation + 115 (градусы)
--   * Проверка активируется мобильной кнопкой PlayerGui["<Team>-mob"].Controls.action.check
--     через VirtualInputManager:SendTouchEvent(TouchID, 0/1/2, x, y)
--   * Instant-режим (необязательный) использует ремоуты:
--       ReplicatedStorage.Remotes.Generator.SkillCheckResultEvent:FireServer("success", 1, generator, point)
--       ReplicatedStorage.Remotes.Generator.RepairEvent:FireServer(point, true)

local AutoSkillCheck = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Идентификатор "пальца" для тач-эмуляции и значения UserInputState
local TOUCH_ID = 8822
local TOUCH_BEGIN, TOUCH_CHANGE, TOUCH_END = 0, 1, 2

-- Значения по умолчанию (если в Settings ключа нет)
local DEFAULTS = {
    SkillCheckMode = "Perfect",          -- "Perfect" | "Instant"
    SkillCheckDispatch = "Touch",        -- "Touch" | "Mouse" | "Key"
    SkillCheckKey = Enum.KeyCode.Space,  -- клавиша для режима "Key"
    SkillCheckWindowStart = 101,         -- смещение начала идеального окна от Goal.Rotation
    SkillCheckWindowEnd = 115,           -- смещение конца идеального окна от Goal.Rotation
    SkillCheckPrediction = true,         -- предсказывать момент входа стрелки в окно
    SkillCheckLead = 0.02,               -- компенсация задержки кадра/пинга (сек)
    SkillCheckTeam = "Survivors",        -- "Survivors" | "Any"
    SkillCheckInstantRepair = true,      -- в Instant-режиме дополнительно дёргать RepairEvent
    SkillCheckDebug = false,
}

local function get(Settings, key)
    local value = Settings and Settings[key]
    if value == nil then value = DEFAULTS[key] end
    return value
end

local state = {
    Active = false,
    Settings = nil,
    Conn = nil,

    Prompt = nil,
    Check = nil,
    Line = nil,
    Goal = nil,
    LastScan = 0,

    Button = nil,
    LastButtonScan = 0,

    SessionActive = false,
    Fired = false,
    PrevRel = nil,
    PrevRotation = nil,
    Dispatching = false,

    Stats = {
        Checks = 0,
        Perfect = 0,
        Instant = 0,
        Missed = 0,
        Failed = 0,
        LastResult = "-",
    },
}
-- Служебные функции ---------------------------------------------------------

local function getPlayerGui()
    return LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
end

-- Учитывает видимость всех родителей (GuiObject.Visible / ScreenGui.Enabled)
local function isGuiVisible(obj)
    if not obj or not obj.Parent then return false end
    local current = obj
    while current and current ~= game do
        if current:IsA("GuiObject") and current.Visible == false then return false end
        if current:IsA("LayerCollector") and current.Enabled == false then return false end
        current = current.Parent
    end
    return true
end

local function getGuiCenter(guiObject)
    if not guiObject or not guiObject.Parent then return nil end
    local position = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize
    if size.X <= 0 or size.Y <= 0 then return nil end
    local inset = GuiService:GetGuiInset()
    return position.X + (size.X / 2) + inset.X, position.Y + (size.Y / 2) + inset.Y
end

local function log(Settings, ...)
    if get(Settings, "SkillCheckDebug") then
        warn("[AutoSkillCheck]", ...)
    end
end

-- Поиск дерева проверки -----------------------------------------------------

local function findCheckTree()
    local playerGui = getPlayerGui()
    if not playerGui then return nil end

    -- 1) По имени GUI (SkillCheckPromptGui и любые похожие названия)
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            local lower = string.lower(gui.Name)
            if string.find(lower, "skillcheck", 1, true) or string.find(lower, "skill_check", 1, true) then
                local check = gui:FindFirstChild("Check", true)
                local line = check and check:FindFirstChild("Line", true)
                local goal = check and check:FindFirstChild("Goal", true)
                if line and goal and line:IsA("GuiObject") and goal:IsA("GuiObject") then
                    return gui, check, line, goal
                end
            end
        end
    end

    -- 2) Поиск по структуре (Goal + Line в одном родителе)
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            for _, obj in ipairs(gui:GetDescendants()) do
                if obj:IsA("GuiObject") and obj.Name == "Goal" then
                    local check = obj.Parent
                    local line = check and check:FindFirstChild("Line", true)
                    if line and line:IsA("GuiObject") then
                        return gui, check, line, obj
                    end
                end
            end
        end
    end
    return nil
end

-- Кнопка активации проверки (мобильные контролы либо сама кнопка проверки)
local function findActionButton()
    local playerGui = getPlayerGui()
    if not playerGui then return nil end

    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            local lowerName = string.lower(gui.Name)
            local looksLikeMobile = string.find(lowerName, "mob", 1, true)
                or string.find(lowerName, "mobile", 1, true)
                or string.find(lowerName, "control", 1, true)
            if looksLikeMobile then
                local controls = gui:FindFirstChild("Controls", true)
                local action = controls and controls:FindFirstChild("action", true)
                if action then
                    for _, child in ipairs(action:GetChildren()) do
                        if child:IsA("GuiButton") and string.find(string.lower(child.Name), "check", 1, true) then
                            return child
                        end
                    end
                end
            end
        end
    end

    -- Резервный вариант: любая кнопка с "check" в имени
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("GuiButton") and string.find(string.lower(obj.Name), "check", 1, true) then
            return obj
        end
    end
    return nil
end
-- Способы ввода -------------------------------------------------------------

-- Тап по кнопке (основной и проверенный способ для VD)
local function tapGuiObject(guiObject)
    local x, y = getGuiCenter(guiObject)
    if not x then return false end
    local ok = pcall(function()
        VirtualInputManager:SendTouchEvent(TOUCH_ID, TOUCH_BEGIN, x, y)
        task.wait(0.01)
        VirtualInputManager:SendTouchEvent(TOUCH_ID, TOUCH_CHANGE, x, y)
        task.wait(0.01)
        VirtualInputManager:SendTouchEvent(TOUCH_ID, TOUCH_END, x, y)
    end)
    return ok
end

local function clickAt(x, y)
    local ok = pcall(function()
        VirtualInputManager:SendMouseMoveEvent(x, y, game)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)
    if not ok then
        ok = pcall(function() mouse1click() end)
    end
    return ok
end

local function pressKey(keyCode)
    if not keyCode then return false end
    return pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.02)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
end

local function refreshActionButton()
    local now = os.clock()
    if state.Button and state.Button.Parent and (now - state.LastButtonScan) < 3 then
        return state.Button
    end
    state.Button = findActionButton()
    state.LastButtonScan = now
    return state.Button
end

local function dispatch(Settings)
    if state.Dispatching then return end
    state.Dispatching = true

    local method = get(Settings, "SkillCheckDispatch")
    local ok = false

    if method == "Touch" then
        local button = refreshActionButton()
        if not button and state.Check and state.Check:IsA("GuiButton") then
            button = state.Check
        end
        if button then ok = tapGuiObject(button) end
        if not ok then ok = pressKey(get(Settings, "SkillCheckKey")) end
    elseif method == "Mouse" then
        local target = refreshActionButton() or state.Check
        local x, y
        if target and target:IsA("GuiObject") then
            x, y = getGuiCenter(target)
        end
        if not x then
            local mouse = UserInputService:GetMouseLocation()
            x, y = mouse.X, mouse.Y
        end
        ok = clickAt(x, y)
        if not ok then ok = pressKey(get(Settings, "SkillCheckKey")) end
    else -- "Key"
        ok = pressKey(get(Settings, "SkillCheckKey"))
    end

    if not ok then
        state.Stats.Failed = state.Stats.Failed + 1
        log(Settings, "не удалось отправить нажатие (метод " .. tostring(method) .. ")")
    end
    state.Dispatching = false
end

-- Instant-режим (через ремоуты) ---------------------------------------------

local function getGeneratorRemotes()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local generator = remotes and remotes:FindFirstChild("Generator")
    if not generator then return nil end
    return generator:FindFirstChild("RepairEvent"), generator:FindFirstChild("SkillCheckResultEvent")
end

-- Ближайшая точка генератора (та, у которой стоит игрок)
local function findNearestGeneratorPoint()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local map = workspace:FindFirstChild("Map")
    if not map then return nil end

    local bestPoint, bestGenerator, bestDistance = nil, nil, math.huge
    for _, obj in ipairs(map:GetDescendants()) do
        if obj.Name == "Generator" then
            for _, point in ipairs(obj:GetChildren()) do
                if point:IsA("BasePart") and string.find(point.Name, "GeneratorPoint", 1, true) then
                    local distance = (point.Position - root.Position).Magnitude
                    if distance < bestDistance then
                        bestDistance, bestPoint, bestGenerator = distance, point, obj
                    end
                end
            end
        end
    end
    return bestPoint, bestGenerator, bestDistance
end

local function fireInstantSuccess(Settings)
    local repairEvent, skillCheckEvent = getGeneratorRemotes()
    if not skillCheckEvent then
        log(Settings, "Instant: ремоуты Remotes.Generator не найдены")
        return false
    end
    -- Ремоуты могут быть защищены: точка, у которой стоит игрок, и генератор-владелец
    local point, generator = findNearestGeneratorPoint()
    if not point then
        log(Settings, "Instant: точки GeneratorPoint не найдены")
        return false
    end
    local ok = pcall(function()
        if repairEvent and get(Settings, "SkillCheckInstantRepair") then
            repairEvent:FireServer(point, true)
        end
        skillCheckEvent:FireServer("success", 1, generator or point.Parent, point)
    end)
    if not ok then
        log(Settings, "Instant: FireServer отклонён (возможно ремоут закрыт патчем)")
    end
    return ok
end
-- Главная логика -----------------------------------------------------------

local function scanCheckTree(Settings)
    local prompt, check, line, goal = findCheckTree()
    state.Prompt, state.Check, state.Line, state.Goal = prompt, check, line, goal
    state.LastScan = os.clock()
    if Settings and get(Settings, "SkillCheckDebug") and not check then
        log(Settings, "SkillCheck GUI не найден (ожидается SkillCheckPromptGui.Check)")
    end
end

local function endSession()
    if state.SessionActive and not state.Fired then
        state.Stats.Missed = state.Stats.Missed + 1
        state.Stats.LastResult = "missed"
    end
    state.SessionActive = false
    state.Fired = false
    state.PrevRel = nil
    state.PrevRotation = nil
end

-- Возвращает true, если стрелка в идеальном окне прямо сейчас,
-- либо попадёт в него/прошла через него с учётом скорости вращения.
local function isPerfectMoment(Settings, dt)
    local line, goal = state.Line, state.Goal
    if not line or not goal then return false end

    local rotation = line.Rotation % 360
    local goalRotation = goal.Rotation % 360
    local relative = (rotation - goalRotation) % 360

    local windowStart = get(Settings, "SkillCheckWindowStart")
    local windowEnd = get(Settings, "SkillCheckWindowEnd")
    local inWindow = relative >= windowStart and relative <= windowEnd

    local predicted = false
    local crossed = false
    local previous = state.PrevRel

    if previous then
        local step = relative - previous
        -- Разворот через 0/360 учитываем приведением к [-180; 180]
        if step > 180 then step = step - 360 elseif step < -180 then step = step + 360 end

        -- предсказание: где стрелка окажется через Lead секунд
        if get(Settings, "SkillCheckPrediction") then
            local velocity = step / math.max(dt, 1e-4)
            local predictedRelative = (relative + velocity * get(Settings, "SkillCheckLead")) % 360
            predicted = predictedRelative >= windowStart and predictedRelative <= windowEnd
        end

        -- пролёт: между кадрами стрелка перескочила окно с любой стороны
        if step > 0 and previous < windowStart and relative > windowEnd then
            crossed = true
        elseif step < 0 and previous > windowEnd and relative < windowStart then
            crossed = true
        end
    end

    state.PrevRel = relative
    state.PrevRotation = rotation

    return inWindow or predicted or crossed
end

local function step(Settings, dt)
    local now = os.clock()
    local check, line, goal = state.Check, state.Line, state.Goal

    local valid = check and check.Parent and line and line.Parent and goal and goal.Parent
    if not valid or (now - state.LastScan) > 1 then
        scanCheckTree(Settings)
        check, line, goal = state.Check, state.Line, state.Goal
    end

    local active = check and isGuiVisible(check)
    if not active then
        if state.SessionActive then endSession() end
        return
    end

    if not state.SessionActive then
        state.SessionActive = true
        state.Fired = false
        state.PrevRel = nil
        state.PrevRotation = nil
        state.Stats.Checks = state.Stats.Checks + 1
        state.Stats.LastResult = "started"
    end

    if state.Fired then return end

    -- Проверка команды (по умолчанию только за выживших)
    local requiredTeam = get(Settings, "SkillCheckTeam")
    if requiredTeam and requiredTeam ~= "" and requiredTeam ~= "Any" then
        local teamName = (LocalPlayer.Team and LocalPlayer.Team.Name) or ""
        if teamName ~= requiredTeam then return end
    end

    if get(Settings, "SkillCheckMode") == "Instant" then
        state.Fired = true
        state.Stats.Instant = state.Stats.Instant + 1
        state.Stats.LastResult = "instant"
        task.spawn(function()
            local ok = fireInstantSuccess(Settings)
            log(Settings, "Instant результат: " .. tostring(ok))
        end)
        return
    end

    if isPerfectMoment(Settings, dt) then
        state.Fired = true
        state.Stats.Perfect = state.Stats.Perfect + 1
        state.Stats.LastResult = "perfect"
        task.spawn(function() dispatch(Settings) end)
        log(Settings, "Perfect! Стрелка в окне, отправлено нажатие")
    end
end
-- Публичное API ------------------------------------------------------------

function AutoSkillCheck.Start(Settings)
    AutoSkillCheck.Stop()
    state.Settings = Settings
    state.Active = true
    scanCheckTree(Settings)
    state.Conn = RunService.Heartbeat:Connect(function(dt)
        if not state.Active then return end
        local ok, err = pcall(step, Settings, dt)
        if not ok then
            warn("[AutoSkillCheck] ошибка: " .. tostring(err))
        end
    end)
end

function AutoSkillCheck.Stop()
    state.Active = false
    if state.Conn then
        pcall(function() state.Conn:Disconnect() end)
        state.Conn = nil
    end
end

function AutoSkillCheck.Toggle(enabled, Settings)
    if enabled then
        AutoSkillCheck.Start(Settings)
    else
        AutoSkillCheck.Stop()
    end
end

-- Полная очистка (используется в Clear Script) 
function AutoSkillCheck.Cleanup()
    AutoSkillCheck.Stop()
    state.Settings = nil
    state.Prompt, state.Check, state.Line, state.Goal = nil, nil, nil, nil
    state.Button = nil
    state.LastScan = 0
    state.LastButtonScan = 0
    endSession()
    state.Dispatching = false
end

function AutoSkillCheck.GetStats()
    return state.Stats
end

function AutoSkillCheck.IsActive()
    return state.Active
end

function AutoSkillCheck.ResetStats()
    state.Stats.Checks = 0
    state.Stats.Perfect = 0
    state.Stats.Instant = 0
    state.Stats.Missed = 0
    state.Stats.Failed = 0
    state.Stats.LastResult = "-"
end

-- Диагностика: выводит в консоль найденные пути (для настройки под игру)
function AutoSkillCheck.Probe(Settings)
    Settings = Settings or state.Settings or {}
    print("===== AutoSkillCheck Probe =====")

    local playerGui = getPlayerGui()
    print("  PlayerGui: " .. tostring(playerGui))

    local gui, check, line, goal = findCheckTree()
    print("  SkillCheck GUI: " .. tostring(gui and gui:GetFullName()))
    print("  Check: " .. tostring(check and check:GetFullName()))
    print("  Line: " .. tostring(line and line:GetFullName()))
    print("  Goal: " .. tostring(goal and goal:GetFullName()))

    local button = findActionButton()
    print("  Action button: " .. tostring(button and button:GetFullName()))

    local repairEvent, skillCheckEvent = getGeneratorRemotes()
    print("  Remotes.Generator.RepairEvent: " .. tostring(repairEvent and repairEvent:GetFullName()))
    print("  Remotes.Generator.SkillCheckResultEvent: " .. tostring(skillCheckEvent and skillCheckEvent:GetFullName()))

    local point, generator, distance = findNearestGeneratorPoint()
    print(string.format("  Nearest GeneratorPoint: %s (generator: %s, distance: %s)",
        tostring(point and point:GetFullName()),
        tostring(generator and generator.Name),
        distance and string.format("%.1f", distance) or "n/a"))

    print(string.format("  Mode: %s | Dispatch: %s | Window: %s..%s",
        tostring(get(Settings, "SkillCheckMode")),
        tostring(get(Settings, "SkillCheckDispatch")),
        tostring(get(Settings, "SkillCheckWindowStart")),
        tostring(get(Settings, "SkillCheckWindowEnd"))))
    print("=================================")
end

return AutoSkillCheck
