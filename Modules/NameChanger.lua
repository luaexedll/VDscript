-- Modules/NameChanger.lua
local NameChanger = {}
local Players = game:GetService("Players")

function NameChanger.GetDisplayName(player, Settings)
    local name = player.Name
    local displayName = player.DisplayName
    for orig, fake in pairs(Settings.CustomNicks) do
        local lowerOrig = string.lower(orig)
        if string.lower(name) == lowerOrig or string.lower(displayName) == lowerOrig or string.find(string.lower(name), lowerOrig) or string.find(string.lower(displayName), lowerOrig) then
            return fake
        end
    end
    return displayName ~= "" and displayName or name
end

function NameChanger.Run(Settings)
    if Settings.EnableNickChanger then
        for _, player in ipairs(Players:GetPlayers()) do
            local pGui = player:FindFirstChild("PlayerGui")
            if pGui then
                for _, desc in ipairs(pGui:GetDescendants()) do
                    if desc:IsA("TextLabel") or desc:IsA("TextBox") or desc:IsA("TextButton") then
                        for orig, fake in pairs(Settings.CustomNicks) do
                            if orig ~= "" and fake ~= "" and string.find(string.lower(desc.Text), string.lower(orig)) then
                                desc.Text = string.gsub(desc.Text, orig, fake)
                            end
                        end
                    end
                end
            end
        end
    end
end

return NameChanger
