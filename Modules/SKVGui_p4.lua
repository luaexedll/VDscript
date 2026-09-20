-- SKVGui part4 pages Visuals+Aim
local P4 = {}
function P4.Build(Ctx, W, Settings)
local Pages = {}
local TabButtons = {}
local Tween = Ctx.Tween
local C_ACCENT = Ctx.C_ACCENT
local C_MUTED = Ctx.C_MUTED
local function Cols(name)
local page = Instance.new("Frame", Ctx.ContentHost)
page.Name = name .. "_Page"
page.Size = UDim2.new(1, 0, 1, 0)
page.BackgroundTransparency = 1
page.Visible = false
local c1 = Instance.new("Frame", page)
c1.Size = UDim2.new(0, 245, 1, 0)
c1.Position = UDim2.new(0, 10, 0, 0)
c1.BackgroundTransparency = 1
local c2 = Instance.new("Frame", page)
c2.Size = UDim2.new(0, 245, 1, 0)
c2.Position = UDim2.new(0, 270, 0, 0)
c2.BackgroundTransparency = 1
Pages[name] = {Page = page}
return c1, c2
end
local function Switch(t)
for n, b in pairs(TabButtons) do
local cur = (n == t)
Tween:Create(b, TweenInfo.new(0.18), {TextColor3 = cur and C_ACCENT or C_MUTED}):Play()
b.Font = cur and Enum.Font.GothamBold or Enum.Font.GothamMedium
end
for n, d in pairs(Pages) do d.Page.Visible = (n == t) end
end
Ctx.Pages = Pages
Ctx.TabButtons = TabButtons
Ctx.SwitchTab = Switch
Ctx.Cols = Cols
local names = {"Visuals", "Aim", "Colors", "Misc", "Settings", "Credits"}
for _, n in ipairs(names) do
local b = Instance.new("TextButton", Ctx.TabContainer)
b.Size = UDim2.new(1, 0, 0, 24)
b.BackgroundTransparency = 1
b.Font = (n == "Visuals") and Enum.Font.GothamBold or Enum.Font.GothamMedium
b.Text = n
b.TextColor3 = (n == "Visuals") and C_ACCENT or C_MUTED
b.TextSize = 14
b.TextXAlignment = Enum.TextXAlignment.Left
TabButtons[n] = b
b.MouseButton1Click:Connect(function() Switch(n) end)
end
local c1v, c2v = Cols("Visuals")
W.Header(c1v, "Player ESP", C_ACCENT)
W.Check(Ctx, c1v, 28, "Enable ESP", Settings.EnableESP, function(v) Settings.EnableESP = v end)
W.Check(Ctx, c1v, 52, "Skeleton", Settings.Skeleton, function(v) Settings.Skeleton = v end)
W.Check(Ctx, c1v, 76, "Chams", Settings.Chams, function(v) Settings.Chams = v end)
W.Check(Ctx, c1v, 100, "Tracers", Settings.Tracers, function(v) Settings.Tracers = v end)
W.Check(Ctx, c1v, 124, "Show names", Settings.ShowName, function(v) Settings.ShowName = v end)
W.Check(Ctx, c1v, 148, "Show distance", Settings.ShowDistance, function(v) Settings.ShowDistance = v end)
W.Header(c2v, "Map ESP", C_ACCENT)
W.Check(Ctx, c2v, 28, "Generator ESP", Settings.EnableGeneratorsESP, function(v) Settings.EnableGeneratorsESP = v end)
W.Check(Ctx, c2v, 52, "Pallet ESP", Settings.EnablePalletsESP, function(v) Settings.EnablePalletsESP = v end)
W.Header(c2v, "Mode", C_ACCENT)
local roleB = W.Button(c2v, 110, "Mode: " .. (Settings.RoleLogic == "EnemiesOnly" and "Enemies Only" or "All Players"))
roleB.MouseButton1Click:Connect(function()
Settings.RoleLogic = (Settings.RoleLogic == "EnemiesOnly") and "All" or "EnemiesOnly"
roleB.Text = "   Mode: " .. (Settings.RoleLogic == "EnemiesOnly" and "Enemies Only" or "All Players")
end)
local c1a, c2a = Cols("Aim")
W.Header(c1a, "Aim Assist", C_ACCENT)
W.Check(Ctx, c1a, 28, "Enable aim", Settings.EnableAim, function(v) Settings.EnableAim = v end)
W.Check(Ctx, c1a, 52, "Team check", Settings.TeamCheck, function(v) Settings.TeamCheck = v end)
W.Check(Ctx, c1a, 76, "Wall check", Settings.WallCheck, function(v) Settings.WallCheck = v end)
W.Check(Ctx, c1a, 100, "Show FOV circle", Settings.EnableFOV, function(v) Settings.EnableFOV = v end)
W.Header(c2a, "Tuning", C_ACCENT)
local partB = W.Button(c2a, 28, "Part: " .. Settings.TargetPart)
partB.MouseButton1Click:Connect(function()
Settings.TargetPart = (Settings.TargetPart == "Head") and "HumanoidRootPart" or "Head"
partB.Text = "   Part: " .. Settings.TargetPart
end)
W.Slider(Ctx, c2a, 62, "Smoothness", 0.05, 1, Settings.Smoothness, "", function(v) Settings.Smoothness = v end)
W.Slider(Ctx, c2a, 110, "FOV radius", 20, 400, Settings.FOVRadius, "px", function(v) Settings.FOVRadius = math.floor(v) Ctx.FOVCircle.Radius = Settings.FOVRadius end)
local aimB = W.Button(c2a, 158, "Aim key: ...")
local function refAim() aimB.Text = "   Aim key: " .. tostring(Settings.AimKey.Name ~= "" and Settings.AimKey.Name or Settings.AimKey) end
refAim()
Ctx.refAim = refAim
aimB.MouseButton1Click:Connect(function() Settings.IsBindingAimKey = true aimB.Text = "   Aim key: [press...]" end)
return true
end
return P4
