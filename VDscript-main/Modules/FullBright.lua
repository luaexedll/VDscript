-- Modules/FullBright.lua
local FullBright = {}
local Lighting = game:GetService("Lighting")

function FullBright.Update(Settings)
    if Settings.EnableFullBright then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
        Lighting.ColorShift_Top = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    end
    
    if Settings.RemoveFog then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 100000
        
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then
            atmosphere.Density = 0
        end
    end
end

return FullBright
