-- Modules/Fov.lua
local Fov = {}
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local isAiming = false

function Fov.SetupInputs(Settings, AimKeyBtn)
    local connections = {}
    
    table.insert(connections, UserInputService.InputBegan:Connect(function(input, gp)
        if Settings.IsBindingAimKey then return end
        if input.UserInputType == Settings.AimKey or (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Settings.AimKey) then
            isAiming = true
        end
    end))

    table.insert(connections, UserInputService.InputEnded:Connect(function(input, gp)
        if input.UserInputType == Settings.AimKey or (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Settings.AimKey) then
            isAiming = false
        end
    end))
    
    return connections
end

local function IsVisible(targetPart, Settings)
    if not Settings.WallCheck then return true end
    if not LocalPlayer.Character then return false end
    
    local localChar = LocalPlayer.Character
    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local direction = targetPos - origin
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = RaycastParams.RaycastFilterType.Exclude
    
    local filterList = {localChar}
    if targetPart.Parent then
        table.insert(filterList, targetPart.Parent)
        if targetPart.Parent.Parent and targetPart.Parent.Parent:FindFirstChild("Humanoid") then
            table.insert(filterList, targetPart.Parent.Parent)
        end
    end
    raycastParams.FilterDescendantsInstances = filterList
    raycastParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    if result then
        return false
    end
    return true
end

local function GetClosestTarget(Settings)
    local target = nil
    local shortestDist = Settings.FOVRadius
    local mousePos = UserInputService:GetMouseLocation()

    -- Список частей тела в зависимости от выбранного режима
    local partList = {}
    if Settings.AimPartMode == "Arms" then
        partList = { "LeftHand", "RightHand", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "Left Arm", "Right Arm" }
    elseif Settings.AimPartMode == "Legs" then
        partList = { "LeftFoot", "RightFoot", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "Left Leg", "Right Leg" }
    elseif Settings.AimPartMode == "Body" then
        partList = { "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso" }
    else -- "Head"
        partList = { "Head" }
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local targetPart = nil

            if humanoid and humanoid.Health > 0 then
                -- Ищем любую подходящую часть тела (FindFirstDescendant, т.к. в R15/R6 руки/ноги вложены в иерархию)
                for _, partName in ipairs(partList) do
                    local p = player.Character:FindFirstDescendant(partName)
                    if p and p:IsA("BasePart") then
                        targetPart = p
                        break
                    end
                end
            end

            if humanoid and humanoid.Health > 0 and targetPart then
                if Settings.TeamCheck and player.Team and player.Team == LocalPlayer.Team then
                    continue
                end

                local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen and screenPoint.Z > 0 then
                    local dist = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
                    if dist < shortestDist then
                        if IsVisible(targetPart, Settings) then
                            shortestDist = dist
                            target = targetPart
                        end
                    end
                end
            end
        end
    end
    return target
end

local PreviousFOVState = false

function Fov.Update(Settings, FOVCircle, MainFrame)
    local mousePos = UserInputService:GetMouseLocation()
    
    if Settings.EnableCameraFOV then
        Camera.FieldOfView = Settings.CameraFOVValue
        PreviousFOVState = true
    elseif PreviousFOVState then
        Camera.FieldOfView = 70
        PreviousFOVState = false
    end

    FOVCircle.Position = mousePos
    FOVCircle.Visible = Settings.EnableAim and Settings.EnableFOV and MainFrame.Visible == false
    
    if Settings.EnableAim and isAiming then
        local targetPart = GetClosestTarget(Settings)
        if targetPart then
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, Settings.Smoothness)
        end
    end
end

return Fov
