-- Modules/NameChanger.lua
local NameChanger = {}
local Players = game:GetService("Players")

local function replaceFirstInsensitive(text, original, replacement)
    local lowerText = string.lower(text)
    local lowerOriginal = string.lower(original)
    local startPos, endPos = string.find(lowerText, lowerOriginal, 1, true)
    if not startPos then return text end
    return string.sub(text, 1, startPos - 1) .. replacement .. string.sub(text, endPos + 1)
end

function NameChanger.GetDisplayName(player, Settings)
    local name = player.Name
    local displayName = player.DisplayName
    for orig, fake in pairs(Settings.CustomNicks) do
        local lowerOrig = string.lower(orig)
        if string.lower(name) == lowerOrig or string.lower(displayName) == lowerOrig or string.find(string.lower(name), lowerOrig, 1, true) or string.find(string.lower(displayName), lowerOrig, 1, true) then
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
                            if orig ~= "" and fake ~= "" and string.find(string.lower(desc.Text), string.lower(orig), 1, true) then
                                desc.Text = replaceFirstInsensitive(desc.Text, orig, fake)
                            end
                        end
                    end
                end
            end
        end
    end
end

return NameChanger
