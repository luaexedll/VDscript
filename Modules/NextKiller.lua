-- Modules/NextKiller.lua
local NextKiller = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function GetGameValue(obj, name)
    if not obj then return nil end
    local attr = obj:GetAttribute(name)
    if attr ~= nil then return attr end
    
    local child = obj:FindFirstChild(name)
    if child then
        local success, val = pcall(function() return child.Value end)
        if success then return val end
    end
    return nil
end

function NextKiller.Update(Settings, IndicatorGui, GetDisplayNameFunc)
    if not IndicatorGui or not IndicatorGui.Parent then return end
    local label = IndicatorGui:FindFirstChild("NextKillerDisplaySKV")
    
    if Settings.EnableNextKiller then
        if not label then
            label = Instance.new("TextLabel", IndicatorGui)
            label.Name = "NextKillerDisplaySKV"
            label.Size = UDim2.new(0, 320, 0, 30)
            label.Position = UDim2.new(0.5, 0, 0, 45)
            label.AnchorPoint = Vector2.new(0.5, 0)
            label.BackgroundTransparency = 0.5
            label.BackgroundColor3 = Color3.new(0, 0, 0)
            label.TextColor3 = Color3.new(1, 1, 1)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.RichText = true
            label.Text = "Next Killer: Calculating..."
        end
        
        pcall(function()
            local players = Players:GetPlayers()
            table.sort(players, function(a, b)
                local aA = GetGameValue(a, "AllowKiller") or GetGameValue(a, "CanBeKiller") or false
                local bA = GetGameValue(b, "AllowKiller") or GetGameValue(b, "CanBeKiller") or false
                if aA ~= bA then return aA == true end
                return (GetGameValue(a, "KillerChance") or GetGameValue(a, "Chance") or 0) > (GetGameValue(b, "KillerChance") or GetGameValue(b, "Chance") or 0)
            end)
            
            local nk = players[1]
            if nk then
                local killerName = tostring(GetGameValue(nk, "SelectedKiller") or GetGameValue(nk, "Killer") or GetGameValue(nk, "Role") or "Killer")
                local playerName = (nk == LocalPlayer and "YOU" or GetDisplayNameFunc(nk))
                label.Text = "Next Killer: <font color=\"rgb(255,80,80)\">" .. killerName .. "</font> | " .. playerName
            end
        end)
        label.Visible = true
    else
        if label then label.Visible = false end
    end
end

return NextKiller
