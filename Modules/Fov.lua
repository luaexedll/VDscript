-- Modules/Fov.lua
-- Aim Assist + FOV circle для [CURE] Violence District
-- Интегрировано с настройками GUI: EnableAim, AimKey, AimPartMode, Smoothness, FOVRadius, TeamCheck, WallCheck

local Fov = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local isAiming = false
local CurrentTarget = nil

-- Части тела для каждого режима прицела
local PART_MODES = {
    Head   = { "Head" },
    Arms   = { "LeftHand", "RightHand", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "Left Arm", "Right Arm" },
    Legs   = { "LeftFoot", "RightFoot", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "Left Leg", "Right Leg" },
    Body   = { "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso" },
}

-- Найти часть тела у персонажа по режиму (ищет по всей иерархии, т.к. в R15/R6 части вложены)
local function FindTargetPart(character, mode)
    local list = PART_MODES[mode] or PART_MODES.Head
    for _, partName in ipairs(list) do
        local part = character:FindFirstDescendant(partName)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return nil
end

-- Проверка видимости сквозь стены (Raycast)
local function IsVisible(targetPart)
    if not LocalPlayer.Character then return false end
    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local direction = targetPos - origin

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { LocalPlayer.Character, targetPart.Parent }
    raycastParams.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, raycastParams)
    if result then
        local hit = result.Instance
        if hit and hit:IsDescendantOf(targetPart.Parent) then
            return true
        end
        return false
    end
    return true
end

-- Найти ближайшую к мыши цель внутри FOV
local function GetClosestTarget(Settings)
    local mousePos = UserInputService:GetMouseLocation()
    local bestPart = nil
    local bestDist = Settings.FOVRadius

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if Settings.TeamCheck and player.Team and player.Team == LocalPlayer.Team then
                    -- skip teammate
                else
                    local part = FindTargetPart(player.Character, Settings.AimPartMode)
                    if part then
                        local screenPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen and screenPoint.Z > 0 then
                            local dist = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
                            if dist < bestDist then
                                if not Settings.WallCheck or IsVisible(part) then
                                    bestDist = dist
                                    bestPart = part
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return bestPart
end

-- Подключение клавиши прицела (поддерживает KeyCode и UserInputType)
function Fov.SetupInputs(Settings, AimKeyBtn)
    local connections = {}

    table.insert(connections, UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if Settings.IsBindingAimKey then return end

        local match = false
        if typeof(Settings.AimKey) == "EnumItem" then
            local enumType = tostring(Settings.AimKey.EnumType)
            if enumType == "Enum.KeyCode" and input.KeyCode == Settings.AimKey then
                match = true
            elseif enumType == "Enum.UserInputType" and input.UserInputType == Settings.AimKey then
                match = true
            end
        end
        if match then
            isAiming = true
        end
    end))

    table.insert(connections, UserInputService.InputEnded:Connect(function(input, gp)
        if gp then return end
        local match = false
        if typeof(Settings.AimKey) == "EnumItem" then
            local enumType = tostring(Settings.AimKey.EnumType)
            if enumType == "Enum.KeyCode" and input.KeyCode == Settings.AimKey then
                match = true
            elseif enumType == "Enum.UserInputType" and input.UserInputType == Settings.AimKey then
                match = true
            end
        end
        if match then
            isAiming = false
        end
    end))

    return connections
end

-- Основной цикл (вызывается из RenderStepped в Main.lua)
function Fov.Update(Settings, FOVCircle, MainFrame)
    local mousePos = UserInputService:GetMouseLocation()

    -- Camera FOV
    if Settings.EnableCameraFOV then
        Camera.FieldOfView = Settings.CameraFOVValue
    end

    -- FOV circle
    FOVCircle.Position = mousePos
    FOVCircle.Visible = Settings.EnableAim and Settings.EnableFOV and MainFrame.Visible == false
    FOVCircle.Radius = Settings.FOVRadius

    -- Aim Assist
    if Settings.EnableAim and isAiming then
        local targetPart = GetClosestTarget(Settings)
        if targetPart then
            CurrentTarget = targetPart
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, Settings.Smoothness)
        else
            CurrentTarget = nil
        end
    else
        CurrentTarget = nil
    end
end

function Fov.GetCurrentTarget()
    return CurrentTarget
end

function Fov.IsAiming()
    return isAiming
end

return Fov
