-- Modules/AutoSkillCheck.lua
-- Новый Auto Skill Check для [CURE] Violence District (по мотивам NewAutoSkillCheck)
--
-- Механика:
--   * PlayerGui.SkillCheckPromptGui.Check содержит два GuiObject:
--       Line - вращающаяся стрелка (свойство Rotation)
--       Goal - зона попадания (свойство Rotation)
--   * Идеальное окно = Goal.Rotation + 102 ... Goal.Rotation + 116 (градусы)
--   * Нажатие эмулируется тачем по мобильной кнопке
--     PlayerGui["Survivor-mob"].Controls.action.check, иначе — Space
--   * Между кадрами интерполируется траектория стрелки, чтобы не пропускать
--     ультра-быстрые скилл-чеки

local AutoSkillCheck = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Глобальная очистка (на случай повторной загрузки скрипта)
if _G.ASC_MainLoop then pcall(function() _G.ASC_MainLoop:Disconnect() end) end
_G.ASC_MainLoop = nil

local TouchID = 8822
local ActionPath = "Survivor-mob.Controls.action.check"

local state = {
    Active = false,
    Conn = nil,
    IsProcessingHit = false,
    LastRotation = nil,
}

-- Получить кнопку действия (мобильный тап-чек)
local function GetActionTarget()
    local current = PlayerGui
    for segment in string.gmatch(ActionPath, "[^%.]+") do
        current = current and current:FindFirstChild(segment)
    end
    return current
end

-- Триггер действия (мобильный тап или Space)
local function TriggerAction()
    local b = GetActionTarget()
    if b and b:IsA("GuiObject") then
        local p, s, i = b.AbsolutePosition, b.AbsoluteSize, GuiService:GetGuiInset()
        local cx, cy = p.X + (s.X / 2) + i.X, p.Y + (s.Y / 2) + i.Y
        pcall(function()
            VirtualInputManager:SendTouchEvent(TouchID, 0, cx, cy)
            task.wait(0.002)
            VirtualInputManager:SendTouchEvent(TouchID, 2, cx, cy)
        end)
    else
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.002)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end
end

-- Проверка команды (только выжившие)
local function EvaluateTeamState()
    local team = LocalPlayer.Team
    local teamName = team and team.Name:lower() or ""
    return teamName:find("survivor") ~= nil
end

-- Проверка угла с учётом "перелёта" через 0/360
local function IsAngleInRange(angle, startAngle, endAngle)
    if startAngle <= endAngle then
        return angle >= startAngle and angle <= endAngle
    else
        return angle >= startAngle or angle <= endAngle
    end
end

-- Основной цикл (один кадр)
local function Step()
    if not EvaluateTeamState() then
        state.LastRotation = nil
        return
    end

    local prompt = PlayerGui:FindFirstChild("SkillCheckPromptGui")
    if not prompt then
        state.IsProcessingHit = false
        state.LastRotation = nil
        return
    end

    local check = prompt:FindFirstChild("Check")
    if not check or not check.Visible or not check.Parent then
        state.IsProcessingHit = false
        state.LastRotation = nil
        return
    end

    local line = check:FindFirstChild("Line")
    local goal = check:FindFirstChild("Goal")
    if not line or not goal then
        state.LastRotation = nil
        return
    end

    local lr = line.Rotation % 360
    local gr = goal.Rotation % 360

    local startOffset = 102
    local endOffset = 116

    local ss = (gr + startOffset) % 360
    local se = (gr + endOffset) % 360

    -- Текущая позиция или интерполяция траектории для ультра-быстрых скилл-чеков
    local isInZone = IsAngleInRange(lr, ss, se)

    if not isInZone and state.LastRotation ~= nil then
        local diff = (lr - state.LastRotation) % 360
        if diff > 180 then diff = diff - 360 end

        local steps = math.max(1, math.floor(math.abs(diff)))
        for i = 1, steps do
            local interpolatedAngle = (state.LastRotation + (diff * (i / steps))) % 360
            if IsAngleInRange(interpolatedAngle, ss, se) then
                isInZone = true
                break
            end
        end
    end

    if not isInZone and state.IsProcessingHit then
        state.IsProcessingHit = false
    end

    if not state.IsProcessingHit and isInZone then
        state.IsProcessingHit = true
        TriggerAction()

        task.delay(0.02, function()
            state.IsProcessingHit = false
        end)
    end

    state.LastRotation = lr
end

-- Публичное API (совместимо со старым модулем) ------------------------------

function AutoSkillCheck.Start()
    AutoSkillCheck.Stop()
    state.Active = true
    state.IsProcessingHit = false
    state.LastRotation = nil
    state.Conn = RunService.Heartbeat:Connect(function()
        if not state.Active then return end
        local ok, err = pcall(Step)
        if not ok then
            warn("[AutoSkillCheck] ошибка: " .. tostring(err))
        end
    end)
    _G.ASC_MainLoop = state.Conn
end

function AutoSkillCheck.Stop()
    state.Active = false
    state.IsProcessingHit = false
    state.LastRotation = nil
    if state.Conn then
        pcall(function() state.Conn:Disconnect() end)
        state.Conn = nil
    end
    if _G.ASC_MainLoop then pcall(function() _G.ASC_MainLoop:Disconnect() end) end
    _G.ASC_MainLoop = nil
end

function AutoSkillCheck.Toggle(enabled, Settings)
    if enabled then
        AutoSkillCheck.Start()
    else
        AutoSkillCheck.Stop()
    end
end

-- Полная очистка (используется в FullCleanup)
function AutoSkillCheck.Cleanup()
    AutoSkillCheck.Stop()
end

function AutoSkillCheck.IsActive()
    return state.Active
end

return AutoSkillCheck
