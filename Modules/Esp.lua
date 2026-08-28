-- Modules/Esp.lua
local Esp = {}
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local DrawingsCache = {}
local HighlightsCache = {}

local function createDrawing(objType, properties)
    local obj = Drawing.new(objType)
    for k, v in pairs(properties) do obj[k] = v end
    return obj
end

local function hideDrawings(d)
    if d.Tracer then d.Tracer.Visible = false end
    if d.Name then d.Name.Visible = false end
    if d.Skeleton then
        for _, line in pairs(d.Skeleton) do line.Visible = false end
    end
end

function Esp.CleanupPlayerCache(player)
    if DrawingsCache[player] then
        local dList = DrawingsCache[player]
        if typeof(dList) == "table" then
            if dList.Tracer then pcall(function() dList.Tracer:Remove() end) end
            if dList.Name then pcall(function() dList.Name:Remove() end) end
            if dList.Skeleton then
                for _, line in pairs(dList.Skeleton) do pcall(function() line:Remove() end) end
            end
        end
        DrawingsCache[player] = nil
    end

    if HighlightsCache[player] then
        pcall(function() HighlightsCache[player]:Destroy() end)
        HighlightsCache[player] = nil
    end
end

function Esp.ClearAll()
    for _, p in ipairs(Players:GetPlayers()) do
        Esp.CleanupPlayerCache(p)
    end
    DrawingsCache = {}
    HighlightsCache = {}
end

local function getPlayerRole(player)
    if player.Team then
        local tName = string.lower(player.Team.Name)
        if string.find(tName, "killer") or string.find(tName, "murderer") or string.find(tName, "monster") or string.find(tName, "hunter") then
            return "Killer"
        end
    end
    return "Survivor"
end

local function determineColor(player, Settings)
    if getPlayerRole(player) == "Killer" then
        return Settings.KillerColor
    else
        return Settings.SurvivorColor
    end
end

local function shouldRenderPlayer(player, Settings)
    if player == LocalPlayer then return false end
    if not Settings.EnableESP then return false end
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    local localRole = getPlayerRole(LocalPlayer)
    local targetRole = getPlayerRole(player)
    if Settings.RoleLogic ~= "All" and localRole == targetRole then
        return false
    end
    return true
end

local function updateHighlight(player, color, Settings)
    if not player.Character or not Settings.Chams or not Settings.EnableESP then 
        if HighlightsCache[player] then HighlightsCache[player]:Destroy(); HighlightsCache[player] = nil end
        return 
    end
    
    local hl = HighlightsCache[player]
    if not hl or hl.Parent ~= player.Character then
        if hl then hl:Destroy() end
        hl = Instance.new("Highlight")
        hl.Name = "ESP_Chams_Clean"
        hl.Adornee = player.Character
        hl.FillTransparency = 0.4
        hl.OutlineTransparency = 0
        hl.Parent = player.Character
        HighlightsCache[player] = hl
    end
    hl.FillColor = color
    hl.OutlineColor = color
    hl.Enabled = true
end

function Esp.Update(Settings, GetDisplayNameFunc)
    for _, player in ipairs(Players:GetPlayers()) do
        local shouldRender = shouldRenderPlayer(player, Settings)
        
        if not shouldRender then
            if DrawingsCache[player] then hideDrawings(DrawingsCache[player]) end
            if HighlightsCache[player] then HighlightsCache[player]:Destroy(); HighlightsCache[player] = nil end
            continue
        end
        
        local char = player.Character
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        
        if not hrp or not head then
            if DrawingsCache[player] then hideDrawings(DrawingsCache[player]) end
            continue
        end
        
        local color = determineColor(player, Settings)
        updateHighlight(player, color, Settings)
        
        if not DrawingsCache[player] then
            DrawingsCache[player] = {
                Tracer = createDrawing("Line", {Thickness = 1}),
                Name = createDrawing("Text", {Size = 12, Center = true, Outline = true, Font = 2}),
                Skeleton = {}
            }
        end
        
        local d = DrawingsCache[player]
        local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        local headVector = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local legVector = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        
        if onScreen and headVector.Z > 0 then
            if Settings.Tracers then
                d.Tracer.Visible = true
                d.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                d.Tracer.To = Vector2.new(vector.X, legVector.Y)
                d.Tracer.Color = color
            else
                d.Tracer.Visible = false
            end
            
            if Settings.ShowName or Settings.ShowDistance then
                d.Name.Visible = true
                local textStr = GetDisplayNameFunc(player)
                if Settings.ShowDistance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
                    textStr = textStr .. " [" .. dist .. "m]"
                end
                d.Name.Text = textStr
                d.Name.Position = Vector2.new(vector.X, headVector.Y - 22)
                d.Name.Color = color
            else
                d.Name.Visible = false
            end
            
            if Settings.Skeleton then
                local bonePairs = {}
                if char:FindFirstChild("UpperTorso") then
                    bonePairs = {
                        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
                        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
                        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightUpperArm", "RightHand"},
                        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
                        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
                    }
                elseif char:FindFirstChild("Torso") then
                    bonePairs = {
                        {"Head", "Torso"},
                        {"Torso", "Left Arm"}, {"Left Arm", "LeftHand"},
                        {"Torso", "Right Arm"}, {"Right Arm", "RightHand"},
                        {"Torso", "Left Leg"}, {"Left Leg", "LeftFoot"},
                        {"Torso", "Right Leg"}, {"Right Leg", "RightFoot"}
                    }
                end
                
                for i, bone in ipairs(bonePairs) do
                    local p1 = char:FindFirstChild(bone[1])
                    local p2 = char:FindFirstChild(bone[2])
                    
                    if p1 and p2 then
                        if not d.Skeleton[i] then d.Skeleton[i] = createDrawing("Line", {Thickness = 1}) end
                        local line = d.Skeleton[i]
                        local v1, vis1 = Camera:WorldToViewportPoint(p1.Position)
                        local v2, vis2 = Camera:WorldToViewportPoint(p2.Position)
                        
                        if vis1 and vis2 and v1.Z > 0 and v2.Z > 0 then
                            line.Visible = true
                            line.From = Vector2.new(v1.X, v1.Y)
                            line.To = Vector2.new(v2.X, v2.Y)
                            line.Color = color
                        else
                            line.Visible = false
                        end
                    else
                        if d.Skeleton[i] then d.Skeleton[i].Visible = false end
                    end
                end
            else
                if d.Skeleton then
                    for _, line in pairs(d.Skeleton) do line.Visible = false end
                end
            end
        else
            hideDrawings(d)
        end
    end
end

return Esp
