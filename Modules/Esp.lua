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
    -- 1. Оптимизация обычных деталей (сохраняем видимость и размеры)
    if obj:IsA("BasePart") and not (obj.Parent and obj.Parent:FindFirstChild("Humanoid")) then
        if obj.Material ~= Enum.Material.SmoothPlastic or obj.CastShadow == true then
            if not optimizedObjects[obj] then
                optimizedObjects[obj] = {
                    Material = obj.Material,
                    CastShadow = obj.CastShadow,
                    Reflectance = obj.Reflectance
                }
            end
            obj.Material = Enum.Material.SmoothPlastic
            obj.CastShadow = false
            obj.Reflectance = 0
        end
        
        -- Упрощаем сетки MeshPart без уменьшения дальности прорисовки
        if obj:IsA("MeshPart") and obj.RenderFidelity ~= Enum.RenderFidelity.Performance then
            if not optimizedObjects[obj] then
                optimizedObjects[obj] = optimizedObjects[obj] or {}
                optimizedObjects[obj].RenderFidelity = obj.RenderFidelity
            end
            obj.RenderFidelity = Enum.RenderFidelity.Performance
        end

    -- 2. Скрытие текстур и декалей
    elseif (obj:IsA("Decal") or obj:IsA("Texture")) and obj.Transparency ~= 1 then
        if not optimizedObjects[obj] then
            optimizedObjects[obj] = {Transparency = obj.Transparency}
        end
        obj.Transparency = 1

    -- 3. Полное отключение тяжелых частиц (дым, огонь, искры)
    elseif obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
        if obj.Enabled then
            if not optimizedObjects[obj] then
                optimizedObjects[obj] = {Enabled = obj.Enabled}
            end
            obj.Enabled = false
        end

    -- 4. Отключение следов (Trail) и лучей (Beam)
    elseif (obj:IsA("Trail") or obj:IsA("Beam")) and obj.Enabled then
        if not optimizedObjects[obj] then
            optimizedObjects[obj] = {Enabled = obj.Enabled}
        end
        obj.Enabled = false

    -- 5. Удаление подсветки (Highlight)
    elseif obj:IsA("Highlight") and obj.Enabled then
        if not optimizedObjects[obj] then
            optimizedObjects[obj] = {Enabled = obj.Enabled}
        end
        obj.Enabled = false
    end
end

local function restoreObjects()
    for obj, state in pairs(optimizedObjects) do
        if obj and obj.Parent then
            if obj:IsA("BasePart") then
                obj.Material = state.Material
                obj.CastShadow = state.CastShadow
                if state.Reflectance then obj.Reflectance = state.Reflectance end
                if obj:IsA("MeshPart") and state.RenderFidelity then
                    obj.RenderFidelity = state.RenderFidelity
                end
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = state.Transparency
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Highlight") then
                if state.Enabled ~= nil then
                    obj.Enabled = state.Enabled
                end
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
        
        Lighting.GlobalShadows = false
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") or effect:IsA("Atmosphere") or effect:IsA("Sky") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") then
                effect.Enabled = false
            end
        end
        
        for _, obj in ipairs(workspace:GetDescendants()) do
            optimizePart(obj)
        end
        
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
        
        activeLoop = task.spawn(function()
            while active do
                task.wait(3)
                if active     then
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
