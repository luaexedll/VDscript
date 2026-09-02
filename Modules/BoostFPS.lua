-- Modules/BoostFPS.lua
local BoostFPS = {}
local Lighting = game:GetService("Lighting")
local originalLighting = nil
local optimizedObjects = {}
local active = false
local activeConnection = nil
local activeLoop = nil

local function saveLighting()
    if originalLighting then return end
    originalLighting = {
        GlobalShadows = Lighting.GlobalShadows,
        Effects = {}
    }
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") or effect:IsA("Atmosphere") or effect:IsA("Sky") then
            originalLighting.Effects[effect] = effect.Enabled
        end
    end
end

local function restoreLighting()
    if not originalLighting then return end
    Lighting.GlobalShadows = originalLighting.GlobalShadows
    for effect, enabled in pairs(originalLighting.Effects) do
        if effect and effect.Parent then effect.Enabled = enabled end
    end
    originalLighting = nil
end

local function optimizePart(obj)
    if obj:IsA("BasePart") and not (obj.Parent and obj.Parent:FindFirstChild("Humanoid")) then
        if obj.Material ~= Enum.Material.SmoothPlastic or obj.CastShadow == true then
            if not optimizedObjects[obj] then
                optimizedObjects[obj] = {
                    Material = obj.Material,
                    CastShadow = obj.CastShadow
                }
            end
            obj.Material = Enum.Material.SmoothPlastic
            obj.CastShadow = false
        end
    elseif (obj:IsA("Decal") or obj:IsA("Texture")) and obj.Transparency ~= 1 then
        if not optimizedObjects[obj] then
            optimizedObjects[obj] = {Transparency = obj.Transparency}
        end
        obj.Transparency = 1
    end
end

local function restoreObjects()
    for obj, state in pairs(optimizedObjects) do
        if obj and obj.Parent then
            if obj:IsA("BasePart") then
                obj.Material = state.Material
                obj.CastShadow = state.CastShadow
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = state.Transparency
            end
        end
    end
    optimizedObjects = {}
end

function BoostFPS.Apply(state, connectionHolder)
    if state then
        if active then return end
        active = true
        saveLighting()
        -- Отключаем глобальные тени и эффекты освещения
        Lighting.GlobalShadows = false
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") or effect:IsA("Atmosphere") or effect:IsA("Sky") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") then
                effect.Enabled = false
            end
        end
        
        -- Первичная оптимизация всего, что есть
        for _, obj in ipairs(workspace:GetDescendants()) do
            optimizePart(obj)
        end
        
        -- Слушатель новых объектов в реальном времени
        activeConnection = workspace.DescendantAdded:Connect(function(obj)
            optimizePart(obj)
        end)
        
        if connectionHolder then
            table.insert(connectionHolder, {
                Disconnect = function()
                    if activeConnection then
                        activeConnection:Disconnect()
                        activeConnection = nil
                    end
                end
            })
        end
        
        -- Фоновый цикл: каждые 3 секунды проверяет пропущенные новые зоны и стриминг-районы
        activeLoop = task.spawn(function()
            while active do
                task.wait(3)
                if active then
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        optimizePart(obj)
                    end
                end
            end
        end)
        
        if connectionHolder then
            table.insert(connectionHolder, {
                Disconnect = function()
                    active = false
                    if activeLoop then
                        pcall(function() task.cancel(activeLoop) end)
                        activeLoop = nil
                    end
                end
            })
        end
    else
        active = false
        if activeConnection then
            activeConnection:Disconnect()
            activeConnection = nil
        end
        if activeLoop then
            pcall(function() task.cancel(activeLoop) end)
            activeLoop = nil
        end
        restoreObjects()
        restoreLighting()
    end
end

return BoostFPS
