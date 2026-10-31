
-- Modules/AutoDagger.lua
-- Auto Dagger (Auto Parry) для [CURE] Violence District
--
-- Механика игры (по вики VD):
--   * "Parrying Dagger" - предмет выжившего (7000 Screws, Purple).
--   * Активация = "Flick your dagger into a guarding stance": даёт окно парирования 0.8 сек.
--     Успешный парир станит киллера на 4 сек.
--     КД: 90 сек. при успехе, 60 сек. при промахе.
--   * Парировать можно windup обычной атаки киллера (M1/lunge).
--
-- Абилка предмета запускается через UI/инпут, поэтому модуль:
--   1) находит кнопку абилки в мобильных контролах (по аналогии с
--      <Team>-mob.Controls.action.check у skill check) либо в хотбаре/инвентаре;
--   2) если есть Tool "dagger/parry" - умеет активировать его напрямую;
--   3) определяет момент атаки киллера (новый attack-анимационный трек,
--      атрибуты Attacking/IsAttacking и т.п.) и держит окно парирования заранее.

local AutoDagger = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local TOUCH_ID = 8823
local TOUCH_BEGIN, TOUCH_CHANGE, TOUCH_END = 0, 1, 2

local DEFAULTS = {
    DaggerMode = "Reactive",              -- "Reactive" | "Preempt" | "Spam" | "Chase"
    DaggerRange = 16,                     -- дистанция реакции в студах
    DaggerReactionDelay = 0.05,           -- задержка перед нажатием (сек)
    DaggerDispatch = "Touch",             -- "Touch" | "Mouse" | "Key" | "Tool" | "Remote"
    DaggerKey = Enum.KeyCode.F,           -- клавиша для режима "Key"
    DaggerAllowRemote = false,            -- разрешить поиск/вызов ремоута (риск)
    DaggerCooldownMiss = 60,              -- КД при промахе
    DaggerCooldownSuccess = 90,           -- КД при успешном парировании
    DaggerIgnoreCooldown = false,         -- игнорировать собственный учёт КД
    DaggerRequireChase = false,           -- парировать только когда IsChased == true
    DaggerDebug = false,

    -- Шаблоны имён (можно править из Settings под патчи игры)
    DaggerAttackPatterns = {"attack", "slash", "m1", "swing", "stab", "lunge", "melee", "punch", "weapon", "heavy"},
    DaggerStunPatterns = {"stun", "parried", "parry", "dazed", "fatigue"},
    DaggerButtonPatterns = {"parry", "dagger", "item", "ability", "use", "equip"},
    DaggerToolPatterns = {"parry", "dagger", "knife", "shield"},
}

local KILLER_TEAM_HINTS = {"killer", "maniac", "murderer", "monster", "hunter", "slasher"}

local function get(Settings, key)
    local value = Settings and Settings[key]
    if value == nil then value = DEFAULTS[key] end
    return value
end

local state = {
    Active = false,
    Settings = nil,
    Conn = nil,

    ReadyAt = 0,
    PendingUntil = 0,
    PendingKiller = nil,
    LastWorkingMethod = nil,
    LastWorkingButton = nil,
    LastButtonScan = 0,
    LastRemoteScan = 0,
    RemoteCache = nil,
    LastWatchScan = 0,
    TrackCache = {},
    Stats = {
        Uses = 0,
        Success = 0,
        Skipped = 0,
        Detected = 0,
        LastReason = "-",
        LastMethod = "-",
    },
}
-- Служебные функции ---------------------------------------------------------

local function log(Settings, ...)
    if get(Settings, "DaggerDebug") then
        warn("[AutoDagger]", ...)
    end
end

local function matchesAny(text, patterns)
    if not text or text == "" or type(patterns) ~= "table" then return false end
    local lower = string.lower(tostring(text))
    for _, pattern in ipairs(patterns) do
        if string.find(lower, string.lower(tostring(pattern)), 1, true) then
            return true
        end
    end
    return false
end

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

local function getPlayerTeamName(player)
    return (player and player.Team and player.Team.Name) or ""
end

local function isKillerPlayer(player)
    if not player then return false end
    local teamName = string.lower(getPlayerTeamName(player))
    for _, hint in ipairs(KILLER_TEAM_HINTS) do
        if string.find(teamName, hint, 1, true) then return true end
    end
    -- Резерв: атрибут роли на игроке/персонаже
    local candidates = {player, player.Character}
    for _, instance in ipairs(candidates) do
        if instance then
            local ok, role = pcall(function() return instance:GetAttribute("Role") end)
            if ok and role and matchesAny(tostring(role), KILLER_TEAM_HINTS) then return true end
        end
    end
    return false
end

local function getLocalRoot()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function findNearestKiller(Range)
    local root = getLocalRoot()
    if not root then return nil, nil end
    local best, bestDistance = nil, Range or math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isKillerPlayer(player) then
            local character = player.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if hrp and humanoid and humanoid.Health > 0 then
                local distance = (hrp.Position - root.Position).Magnitude
                if distance <= bestDistance then
                    best, bestDistance = player, distance
                end
            end
        end
    end
    return best, bestDistance
end

local function isChased()
    local character = LocalPlayer.Character
    if not character then return nil end
    local ok, value = pcall(function() return character:GetAttribute("IsChased") end)
    if ok and value ~= nil then return value == true end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local ok2, value2 = pcall(function() return humanoid:GetAttribute("IsChased") end)
        if ok2 and value2 ~= nil then return value2 == true end
    end
    return nil -- атрибут отсутствует: не блокируем работу
end
-- Поиск кнопки абилки предмета -----------------------------------------------

local function findDaggerButton(Settings)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    local patterns = get(Settings, "DaggerButtonPatterns")

    -- 1) Мобильные контролы: <Team>-mob.Controls.action.* (кнопку "check" не трогаем)
    local fallbackButton = nil
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
                        if child:IsA("GuiButton") and not string.find(string.lower(child.Name), "check", 1, true) then
                            if matchesAny(child.Name, patterns) then
                                return child, "mob-action"
                            end
                            if not fallbackButton and isGuiVisible(child) then
                                fallbackButton = child
                            end
                        end
                    end
                end
            end
        end
    end
    if fallbackButton then return fallbackButton, "mob-action-fallback" end

    -- 2) Кнопки хотбара/инвентаря с dagger/parry в имени или тексте
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("GuiButton") and matchesAny(obj.Name, {"dagger", "parry"}) then
            return obj, "hotbar"
        end
        if obj:IsA("TextLabel") and matchesAny(obj.Text, {"dagger", "parry"}) then
            local parent = obj.Parent
            if parent and parent:IsA("GuiButton") then
                return parent, "hotbar-label"
            end
        end
    end
    return nil
end

-- Поиск Tool предмета --------------------------------------------------------

local function findDaggerTool(Settings)
    local patterns = get(Settings, "DaggerToolPatterns")
    local containers = {}
    local character = LocalPlayer.Character
    if character then table.insert(containers, character) end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then table.insert(containers, backpack) end

    for _, container in ipairs(containers) do
        for _, obj in ipairs(container:GetChildren()) do
            if obj:IsA("Tool") and matchesAny(obj.Name, patterns) then
                return obj
            end
        end
    end
    -- Иногда предмет это не Tool, а Model (например, со своим ремоутом внутри)
    for _, container in ipairs(containers) do
        for _, obj in ipairs(container:GetChildren()) do
            if not obj:IsA("Tool") and matchesAny(obj.Name, patterns) then
                return obj
            end
        end
    end
    return nil
end

-- Поиск возможного ремоута предмета (только если DaggerAllowRemote = true) ----

local function findDaggerRemote(Settings)
    if not get(Settings, "DaggerAllowRemote") then return nil end
    local now = os.clock()
    if state.RemoteCache and state.RemoteCache.Parent and (now - state.LastRemoteScan) < 5 then
        return state.RemoteCache
    end
    state.LastRemoteScan = now
    state.RemoteCache = nil
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return nil end
    for _, obj in ipairs(remotes:GetDescendants()) do
        if obj:IsA("RemoteEvent") and matchesAny(obj.Name, get(Settings, "DaggerButtonPatterns")) then
            state.RemoteCache = obj
            return obj
        end
    end
    return nil
end
-- Способы активации предмета -------------------------------------------------

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

local function useTouch(Settings)
    local button = state.LastWorkingButton
    if not button or not button.Parent or (os.clock() - state.LastButtonScan) > 3 then
        button = findDaggerButton(Settings)
        state.LastWorkingButton = button
        state.LastButtonScan = os.clock()
    end
    if not button then return false end
    return tapGuiObject(button)
end

local function useMouse(Settings, button)
    local x, y
    if button and button:IsA("GuiObject") then
        x, y = getGuiCenter(button)
    end
    if not x then
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(0, 0)
        x, y = viewport.X / 2, viewport.Y / 2
    end
    return clickAt(x, y)
end

local function useKey(Settings)
    return pressKey(get(Settings, "DaggerKey"))
end

local function useTool(Settings)
    local tool = findDaggerTool(Settings)
    if not tool then return false end

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and tool:IsA("Tool") and tool.Parent ~= character then
        pcall(function() humanoid:EquipTool(tool) end)
    end

    -- 1) Прямой вызов подключений Activated (если executor умеет getconnections)
    if getconnections then
        local fired = false
        pcall(function()
            for _, connection in ipairs(getconnections(tool.Activated)) do
                if connection.Function then
                    connection.Function()
                    fired = true
                end
            end
        end)
        if fired then return true end
    end

    -- 2) Штатная активация инструмента
    local ok = pcall(function() tool:Activate() end)
    if ok then return true end

    -- 3) Резерв: клик мышью
    return useMouse(Settings, nil)
end

local function useRemote(Settings)
    local remote = findDaggerRemote(Settings)
    if not remote then return false end
    return pcall(function() remote:FireServer() end)
end

-- Перебирает методы в заданном порядке до первого успешного
local function tryDispatchMethods(Settings, reason)
    local primary = get(Settings, "DaggerDispatch")
    local order = {primary, "Touch", "Mouse", "Key", "Tool", "Remote"}
    local tried = {}

    for _, method in ipairs(order) do
        local alreadyTried = false
        for _, name in ipairs(tried) do
            if name == method then alreadyTried = true end
        end
        if not alreadyTried then
            table.insert(tried, method)

            local ok = false
            if method == "Touch" then
                ok = useTouch(Settings)
            elseif method == "Mouse" then
                ok = useMouse(Settings, state.LastWorkingButton)
            elseif method == "Key" then
                ok = useKey(Settings)
            elseif method == "Tool" then
                ok = useTool(Settings)
            elseif method == "Remote" then
                ok = useRemote(Settings)
            end

            if ok then
                state.LastWorkingMethod = method
                state.Stats.LastMethod = method
                log(Settings, "активация предмета через '" .. method .. "' (причина: " .. tostring(reason) .. ")")
                return true
            end
        end
    end

    log(Settings, "не удалось активировать предмет ни одним методом")
    return false
end
-- Определение атаки киллера --------------------------------------------------

-- Проверяет атрибуты/дочерние значения вида Attacking/IsAttacking/Swinging
local function hasAttackAttribute(instance, patterns)
    if not instance then return false end
    local ok, attributes = pcall(function() return instance:GetAttributes() end)
    if ok and type(attributes) == "table" then
        for name, value in pairs(attributes) do
            if matchesAny(name, patterns) then
                if value == true or (type(value) == "number" and value > 0) then
                    return true
                end
            end
        end
    end
    return false
end

-- Ищет новый проигрываемый attack-трек (сравнивая с предыдущим кадром)
local function hasNewAttackAnimation(player, patterns)
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if not animator then return false end

    local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
    if not ok or type(tracks) ~= "table" then return false end

    local cache = state.TrackCache[player]
    if not cache or cache.character ~= character then
        cache = {character = character, tracks = {}}
        state.TrackCache[player] = cache
    end

    local found = false
    local seen = {}
    for _, track in ipairs(tracks) do
        local animation = track.Animation
        local animationName = (animation and animation.Name) or track.Name or ""
        local animationId = (animation and animation.AnimationId) or ""
        seen[track] = true
        if not cache.tracks[track] then
            if matchesAny(animationName, patterns) or matchesAny(animationId, patterns) then
                found = true
            end
        end
    end
    cache.tracks = seen
    return found
end

local function isStunDetected(killer)
    if not killer or not killer.Character then return false end
    local character = killer.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local patterns = get(state.Settings, "DaggerStunPatterns")

    if hasAttackAttribute(character, patterns) then return true end
    if hasAttackAttribute(humanoid, patterns) then return true end
    if hasAttackAttribute(killer, patterns) then return true end

    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if animator then
        local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
        if ok and type(tracks) == "table" then
            for _, track in ipairs(tracks) do
                local animation = track.Animation
                local name = (animation and animation.Name) or track.Name or ""
                if matchesAny(name, patterns) then return true end
            end
        end
    end
    return false
end

-- Оценка времени до контакта (для режима Preempt)
local function timeToContact(player, distance)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local walkSpeed = humanoid and humanoid.WalkSpeed or 0
    if walkSpeed <= 0 then return nil end
    -- Ланж киллера покрывает часть дистанции
    local effective = math.max(0, (distance or 0) - 5)
    return effective / walkSpeed
end

-- Попытка парирования ---------------------------------------------------------

local function canUseDagger(Settings)
    if get(Settings, "DaggerIgnoreCooldown") then return true end
    return os.clock() >= state.ReadyAt
end

local function triggerParry(Settings, reason, killer)
    if not canUseDagger(Settings) then
        state.Stats.Skipped = state.Stats.Skipped + 1
        log(Settings, "пропуск: предмет на КД (осталось " ..
            string.format("%.1f", math.max(0, state.ReadyAt - os.clock())) .. " сек)")
        return false
    end

    state.Stats.Uses = state.Stats.Uses + 1
    state.Stats.LastReason = reason
    state.PendingKiller = killer
    state.PendingUntil = os.clock() + 1.5
    -- Ставим короткую блокировку, чтобы не стрелять несколько раз в одном окне
    state.ReadyAt = os.clock() + 0.9

    local delay = get(Settings, "DaggerReactionDelay")
    if delay and delay > 0 then
        task.delay(delay, function()
            if state.Active then
                tryDispatchMethods(Settings, reason)
            end
        end)
    else
        tryDispatchMethods(Settings, reason)
    end
    return true
end
-- Главный цикл ---------------------------------------------------------------

local function updatePending(Settings, now)
    if state.PendingUntil <= 0 then return end

    if state.PendingKiller and isStunDetected(state.PendingKiller) then
        state.Stats.Success = state.Stats.Success + 1
        state.ReadyAt = now + get(Settings, "DaggerCooldownSuccess")
        log(Settings, "парирование успешно! Киллер застанен, КД " ..
            tostring(get(Settings, "DaggerCooldownSuccess")) .. " сек")
        state.PendingUntil = 0
        state.PendingKiller = nil
        return
    end

    if now >= state.PendingUntil then
        -- стан не подтверждён => считаем промахом
        state.ReadyAt = state.PendingUntil - 1.5 + get(Settings, "DaggerCooldownMiss")
        log(Settings, "стан не подтверждён, КД " .. tostring(get(Settings, "DaggerCooldownMiss")) .. " сек")
        state.PendingUntil = 0
        state.PendingKiller = nil
    end
end

local function pruneCache(now)
    if now - state.LastWatchScan < 5 then return end
    state.LastWatchScan = now
    for player in pairs(state.TrackCache) do
        if not player.Parent then
            state.TrackCache[player] = nil
        end
    end
end

local function step(Settings, dt)
    local now = os.clock()
    pruneCache(now)
    updatePending(Settings, now)

    local range = get(Settings, "DaggerRange")
    local killer, distance = findNearestKiller(range)
    if not killer then return end

    if get(Settings, "DaggerRequireChase") then
        local chased = isChased()
        if chased == false then return end
    end

    local patterns = get(Settings, "DaggerAttackPatterns")
    local attackDetected = false
    if hasNewAttackAnimation(killer, patterns) then attackDetected = true end
    if hasAttackAttribute(killer.Character, patterns) or hasAttackAttribute(killer, patterns) then
        attackDetected = true
    end
    local killerHumanoid = killer.Character and killer.Character:FindFirstChildOfClass("Humanoid")
    if hasAttackAttribute(killerHumanoid, patterns) then attackDetected = true end

    if attackDetected then
        state.Stats.Detected = state.Stats.Detected + 1
    end

    local mode = get(Settings, "DaggerMode")

    if mode == "Spam" then
        triggerParry(Settings, "spam", killer)
    elseif mode == "Preempt" then
        if attackDetected then
            triggerParry(Settings, "attack", killer)
        else
            local contact = timeToContact(killer, distance)
            if contact and contact <= 0.75 then
                triggerParry(Settings, string.format("preempt %.2fs", contact), killer)
            end
        end
    elseif mode == "Chase" then
        local chased = isChased()
        if chased ~= false and attackDetected then
            triggerParry(Settings, "attack-chase", killer)
        end
    else -- "Reactive"
        if attackDetected then
            triggerParry(Settings, "attack", killer)
        end
    end
end
-- Публичное API --------------------------------------------------------------

function AutoDagger.Start(Settings)
    AutoDagger.Stop()
    state.Settings = Settings
    state.Active = true
    state.ReadyAt = 0
    state.PendingUntil = 0
    state.PendingKiller = nil
    state.TrackCache = {}
    state.LastWorkingButton = findDaggerButton(Settings)
    state.LastButtonScan = os.clock()
    state.Conn = RunService.Heartbeat:Connect(function(dt)
        if not state.Active then return end
        local ok, err = pcall(step, Settings, dt)
        if not ok then
            warn("[AutoDagger] ошибка: " .. tostring(err))
        end
    end)
    log(Settings, "запущен, режим " .. tostring(get(Settings, "DaggerMode")) ..
        ", радиус " .. tostring(get(Settings, "DaggerRange")) .. " studs")
end

function AutoDagger.Stop()
    state.Active = false
    if state.Conn then
        pcall(function() state.Conn:Disconnect() end)
        state.Conn = nil
    end
    state.PendingUntil = 0
    state.PendingKiller = nil
end

function AutoDagger.Toggle(enabled, Settings)
    if enabled then
        AutoDagger.Start(Settings)
    else
        AutoDagger.Stop()
    end
end

function AutoDagger.Cleanup()
    AutoDagger.Stop()
    state.Settings = nil
    state.TrackCache = {}
    state.LastWorkingButton = nil
    state.RemoteCache = nil
    state.ReadyAt = 0
end

function AutoDagger.GetStats()
    return state.Stats
end

function AutoDagger.IsActive()
    return state.Active
end

function AutoDagger.ResetStats()
    state.Stats.Uses = 0
    state.Stats.Success = 0
    state.Stats.Skipped = 0
    state.Stats.Detected = 0
    state.Stats.LastReason = "-"
    state.Stats.LastMethod = "-"
end
-- Диагностика: показывает, что найдено в игре (для настройки шаблонов)
function AutoDagger.Probe(Settings)
    Settings = Settings or state.Settings or {}
    print("===== AutoDagger Probe =====")

    print(string.format("  Режим: %s | Метод: %s | Радиус: %s",
        tostring(get(Settings, "DaggerMode")),
        tostring(get(Settings, "DaggerDispatch")),
        tostring(get(Settings, "DaggerRange"))))

    local button, source = findDaggerButton(Settings)
    print("  Кнопка абилки: " .. tostring(button and button:GetFullName()) .. " (" .. tostring(source) .. ")")

    local tool = findDaggerTool(Settings)
    print("  Tool предмета: " .. tostring(tool and tool:GetFullName()))

    local remote = findDaggerRemote(Settings)
    print("  Ремоут предмета: " .. tostring(remote and remote:GetFullName()) ..
        (get(Settings, "DaggerAllowRemote") and "" or " (DaggerAllowRemote = false)"))

    local killer, distance = findNearestKiller(get(Settings, "DaggerRange"))
    if killer then
        print(string.format("  Ближайший киллер: %s [team: %s] - %.1f studs",
            killer.Name, getPlayerTeamName(killer), distance or 0))
    else
        print("  Ближайший киллер: не найден в радиусе " .. tostring(get(Settings, "DaggerRange")))
    end

    print("  IsChased (локальный персонаж): " .. tostring(isChased()))

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isKillerPlayer(player) then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
            local names = {}
            if animator then
                local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
                if ok and type(tracks) == "table" then
                    for _, track in ipairs(tracks) do
                        local animation = track.Animation
                        table.insert(names, (animation and animation.Name) or track.Name or "?")
                    end
                end
            end
            print(string.format("    killer '%s' активные анимации: %s", player.Name, table.concat(names, ", ")))
        end
    end

    print(string.format("  Статистика: использований %d, успешных париров %d, детекций атаки %d",
        state.Stats.Uses, state.Stats.Success, state.Stats.Detected))
    print("===========================")
end

return AutoDagger
