-- Modules/BoostFPS.lua
local BoostFPS = {}
local Lighting = game:GetService("Lighting")

function BoostFPS.Apply(state)
    if state then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not (obj.Parent and obj.Parent:FindFirstChild("Humanoid")) then
                obj.Material = Enum.Material.SmoothPlastic
                obj.CastShadow = false
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            end
        end
        
        Lighting.GlobalShadows = false
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") or effect:IsA("Atmosphere") or effect:IsA("Sky") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") then
                effect.Enabled = false
            end
        end
    end
end

return BoostFPS
