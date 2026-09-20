-- SKVGui part5a colors+misc
local P5a = {}
function P5a.Build(Ctx, W, Settings)
local C_MUTED = Ctx.C_MUTED
local C_ACCENT = Ctx.C_ACCENT
local Cols = Ctx.Cols
local c1c, c2c = Cols("Colors")
W.Header(c1c, "ESP colors", C_ACCENT)
local function colB(parent, y, label, key)
local b = W.Button(parent, y, label)
b.MouseButton1Click:Connect(function()
local list = {Color3.fromRGB(255,60,60), Color3.fromRGB(60,160,255), Color3.fromRGB(60,255,60), Color3.fromRGB(255,255,60), Color3.fromRGB(150,0,200), Color3.fromRGB(74,255,181), Color3.fromRGB(255,255,255)}
local idx = 1
for i, c in ipairs(list) do if c == Settings[key] then idx = i break end end
idx = idx % #list + 1
Settings[key] = list[idx]
end)
end
colB(c1c, 28, "Killer color", "KillerColor")
colB(c1c, 62, "Survivor color", "SurvivorColor")
colB(c1c, 96, "Generator color", "GeneratorColor")
colB(c1c, 130, "Pallet color", "PalletColor")
W.Header(c2c, "Info", C_ACCENT)
local c1m, c2m = Cols("Misc")
W.Header(c1m, "World", C_ACCENT)
W.Check(Ctx, c1m, 28, "Full bright", Settings.EnableFullBright, function(v) Settings.EnableFullBright = v end)
W.Check(Ctx, c1m, 52, "Remove fog", Settings.RemoveFog, function(v) Settings.RemoveFog = v end)
W.Check(Ctx, c1m, 76, "FPS boost", Settings.FPSBoostApplied, function(v) Ctx.BoostFPS.Apply(v, Ctx.Connections) end)
W.Check(Ctx, c1m, 100, "Custom camera FOV", Settings.EnableCameraFOV, function(v) Settings.EnableCameraFOV = v end)
W.Slider(Ctx, c1m, 128, "Camera FOV", 30, 120, Settings.CameraFOVValue, "", function(v) Settings.CameraFOVValue = math.clamp(math.floor(v), 30, 120) end)
W.Check(Ctx, c1m, 176, "Show next killer", Settings.ShowNextKiller, function(v) Ctx.RankLabel.Visible = v end)
W.Header(c2m, "Movement / Auto", C_ACCENT)
W.Check(Ctx, c2m, 28, "Moonwalk", Settings.MoonwalkEnabled, function(v) Settings.MoonwalkEnabled = v Ctx.moonwalkInst:Toggle(v) end)
local mwB = W.Button(c2m, 54, "Moonwalk bind")
local function refMw()
local k = Ctx.moonwalkInst.BindKey
mwB.Text = "   Moonwalk bind: " .. (k and k.Name or "None")
end
refMw()
Ctx.refMw = refMw
mwB.MouseButton1Click:Connect(function() Ctx.moonwalkInst.IsWaitingForBind = true mwB.Text = "   Moonwalk bind: [press...]" end)
Ctx.moonwalkInst.OnBindChanged = function() refMw() end
W.Button(c2m, 88, "Moonwalk unbind", function() Ctx.moonwalkInst:ClearBind() refMw() end)
W.Check(Ctx, c2m, 122, "Auto skillcheck", Settings.AutoSkillCheck, function(v) if Ctx.AutoSkillCheck then Ctx.AutoSkillCheck.Toggle(v, Settings) end end)
W.Check(Ctx, c2m, 146, "Auto dagger", Settings.AutoDagger, function(v) if Ctx.AutoDagger then Ctx.AutoDagger.Toggle(v, Settings) end end)
return true
end
return P5a
