--1 Modules/Esp.lua
local Esp = {}
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local DrawingsCache = {}
local HighlightsCache = {}
-- === ESP предметов карты (генераторы / палеты), перенесено из Main.lua без изменений логики ===
local ActiveGenerators = {}
local ActivePallets = {}
local GeneratorProgressCache = {}
local LastFullESPRefresh = 0

local function GetMapValue(obj, name)
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

local function ApplyObjectHighlight(object, color, enabled)
    if not enabled then
        local h = object:FindFirstChild("SKV_ObjH")
        if h then h:Destroy() end
        return
    end
    local h = object:FindFirstChild("SKV_ObjH")
    if not h then
        h = Instance.new("Highlight")
        h.Name = "SKV_ObjH"
        h.Adornee = object
        h.FillTransparency = 0.7
        h.OutlineTransparency = 0.2
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = object
    end
    h.FillColor = color
    h.OutlineColor = color
end

local function CreateBillboardTag(text, color, size, textSize)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SKV_Tag"
    billboard.AlwaysOnTop = true
    billboard.Size = size or UDim2.new(0, 120, 0, 30)
    local label = Instance.new("TextLabel")
    label.Name = "SKV_Label"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = textSize or 10
    label.TextWrapped = true
    label.RichText = true
    label.Parent = billboard
    return billboard
end

local function updateGeneratorProgress(generator, Settings)
    if not generator or not generator.Parent then
        GeneratorProgressCache[generator] = nil
        return true
    end
    if not Settings.EnableGeneratorsESP then
        local billboard = generator:FindFirstChild("GenSKV_Tag")
        if billboard then billboard:Destroy() end
        ApplyObjectHighlight(generator, Settings.GeneratorColor, false)
        GeneratorProgressCache[generator] = nil
        return false
    end
    local percent = GetMapValue(generator, "RepairProgress") or GetMapValue(generator, "Progress") or 0
    local billboard = generator:FindFirstChild("GenSKV_Tag")
    if percent >= 100 then
        if billboard then billboard:Destroy() end
        ApplyObjectHighlight(generator, Settings.GeneratorColor, false)
        GeneratorProgressCache[generator] = nil
        return true
    end
    ApplyObjectHighlight(generator, Settings.GeneratorColor, true)
    local cp = math.clamp(percent, 0, 100)
    local finalColor = cp < 50 and Settings.GeneratorColor:Lerp(Color3.fromRGB(180, 180, 0), cp / 50) or Color3.fromRGB(180, 180, 0):Lerp(Color3.fromRGB(0, 150, 0), (cp - 50) / 50)
    local now = tick()
    local progressState = GeneratorProgressCache[generator]
    local speed = 0
    if progressState then
        local elapsed = now - progressState.Time
        if elapsed > 0 then speed = (percent - progressState.Percent) / elapsed end
    end
    GeneratorProgressCache[generator] = { Percent = percent, Time = now }
    local remaining = math.max(0, 100 - percent)
    local eta = speed > 0 and remaining / speed or nil
    local etaText = eta and string.format("%ds", math.max(0, math.floor(eta + 0.5))) or "--"
    local speedText = speed > 0 and string.format("%.1f%%/s", speed) or "--"
    local percentStr = string.format("%.0f%% | %s | %s", percent, speedText, etaText)
    if not billboard then
        billboard = CreateBillboardTag(percentStr, finalColor, UDim2.new(0, 180, 0, 24), 10)
        billboard.Name, billboard.StudsOffset = "GenSKV_Tag", Vector3.new(0, 2, 0)
        billboard.Adornee = generator:FindFirstChild("defaultMaterial", true) or generator
        billboard.Parent = generator
        billboard:SetAttribute("LastTextUpdate", now)
    else
        local lbl = billboard:FindFirstChild("SKV_Label")
        local lastTextUpdate = billboard:GetAttribute("LastTextUpdate") or 0
        if lbl and now - lastTextUpdate >= 0.2 then
            lbl.Text = percentStr
            lbl.TextColor3 = finalColor
            billboard:SetAttribute("LastTextUpdate", now)
        end
    end
    return false
end

function Esp.RefreshESPMapObjects(Settings)
    ActiveGenerators = {}
    ActivePallets = {}
    local Map = workspace:FindFirstChild("Map")
    if not Map then return end
    for _, obj in ipairs(Map:GetDescendants()) do
        if obj.Name == "Generator" then
            table.insert(ActiveGenerators, obj)
            updateGeneratorProgress(obj, Settings)
        elseif obj.Name == "Palletwrong" or obj.Name == "Pallet" then
            table.insert(ActivePallets, obj)
            ApplyObjectHighlight(obj, Settings.PalletColor, Settings.EnablePalletsESP)
        end
    end
end

function Esp.UpdateMapESP(Settings)
    local now = tick()
    if now - LastFullESPRefresh > 5 then
        LastFullESPRefresh = now
        Esp.RefreshESPMapObjects(Settings)
    end
    for i = #ActivePallets, 1, -1 do
        local p = ActivePallets[i]
        if p and p.Parent then ApplyObjectHighlight(p, Settings.PalletColor, Settings.EnablePalletsESP)
        else table.remove(ActivePallets, i) end
    end
    for i = #ActiveGenerators, 1, -1 do
        local g = ActiveGenerators[i]
        if g and g.Parent then
            if updateGeneratorProgress(g, Settings) then table.remove(ActiveGenerators, i) end
        else table.remove(ActiveGenerators, i) end
    end
end

function Esp.ClearMapESP()
    for _, g in ipairs(ActiveGenerators) do
        if g and g.Parent then
            local b = g:FindFirstChild("GenSKV_Tag")
            if b then pcall(function() b:Destroy() end) end
            ApplyObjectHighlight(g, nil, false)
        end
    end
    for _, p in ipairs(ActivePallets) do
        if p and p.Parent then ApplyObjectHighlight(p, nil, false) end
    end
    ActiveGenerators = {}
    ActivePallets = {}
    GeneratorProgressCache = {}
end


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
