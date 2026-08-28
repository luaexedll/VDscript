-- Modules/BoostFPS.lua
local BoostFPS = {}
local Lighting = game:GetService("Lighting")

local function optimizePart(obj)
    if obj:IsA("BasePart") and not (obj.Parent and obj.Parent:FindFirstChild("Humanoid")) then
        obj.Material = Enum.Material.SmoothPlastic
        obj.CastShadow = false
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
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
        
        -- Оптимизируем существующие объекты
        for _, obj in ipairs(workspace:GetDescendants()) do
            optimizePart(obj)
        end
        
        -- Подписываемся на появление новых объектов (стриминг карты, новые зоны)
        local conn = workspace.DescendantAdded:Connect(function(obj)
            optimizePart(obj)
        end)
        
        if connectionHolder then
            table.insert(connectionHolder, conn)
        end
    end
end

return BoostFPS
