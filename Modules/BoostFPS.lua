-- Modules/BoostFPS.lua
local BoostFPS = {}
local Lighting = game:GetService("Lighting")

local function optimizePart(obj)
    if obj:IsA("BasePart") and not (obj.Parent and obj.Parent:FindFirstChild("Humanoid")) then
        if obj.Material ~= Enum.Material.SmoothPlastic or obj.CastShadow == true then
            obj.Material = Enum.Material.SmoothPlastic
            obj.CastShadow = false
        end
    elseif (obj:IsA("Decal") or obj:IsA("Texture")) and obj.Transparency ~= 1 then
        obj.Transparency = 1
    end
end

function BoostFPS.Apply(state, connectionHolder)
    if state then
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
        local conn = workspace.DescendantAdded:Connect(function(obj)
            optimizePart(obj)
        end)
        
        if connectionHolder then
            table.insert(connectionHolder, conn)
        end
        
        -- Фоновый цикл: каждые 3 секунды проверяет пропущенные новые зоны и стриминг-районы
        local loopTask = task.spawn(function()
            while true do
                task.wait(3)
                for _, obj in ipairs(workspace:GetDescendants()) do
                    optimizePart(obj)
                end
            end
        end)
        
        if connectionHolder then
            table.insert(connectionHolder, {
                Disconnect = function()
                    pcall(function() task.cancel(loopTask) end)
                end
            })
        end
    end
end

return BoostFPS
