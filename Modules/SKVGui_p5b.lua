-- SKVGui part5b settings credits shift
local P5b = {}
function P5b.Build(Ctx, W, Settings)
local C_MUTED = Ctx.C_MUTED
local C_ACCENT = Ctx.C_ACCENT
local Cols = Ctx.Cols
local c1s, c2s = Cols("Settings")
W.Header(c1s, "Nick changer", C_ACCENT)
W.Check(Ctx, c1s, 28, "Enable nick changer", Settings.EnableNickChanger, function(v) Settings.EnableNickChanger = v end)
local orig = Instance.new("TextBox", c1s)
orig.Size = UDim2.new(1, 0, 0, 28)
orig.Position = UDim2.new(0, 0, 0, 56)
orig.BackgroundColor3 = Color3.fromRGB(18,18,22)
orig.PlaceholderText = "Original nick"
orig.Text = ""
orig.Font = Enum.Font.Gotham
orig.TextSize = 13
orig.TextColor3 = C_ACCENT
local oc = Instance.new("UICorner", orig) oc.CornerRadius = UDim.new(0, 6)
local fake = Instance.new("TextBox", c1s)
fake.Size = UDim2.new(1, 0, 0, 28)
fake.Position = UDim2.new(0, 0, 0, 90)
fake.BackgroundColor3 = Color3.fromRGB(18,18,22)
fake.PlaceholderText = "Fake nick"
fake.Text = ""
fake.Font = Enum.Font.Gotham
fake.TextSize = 13
fake.TextColor3 = C_ACCENT
local fc = Instance.new("UICorner", fake) fc.CornerRadius = UDim.new(0, 6)
W.Button(c1s, 124, "+ Add nick", function()
if orig.Text ~= "" and fake.Text ~= "" then Settings.CustomNicks[orig.Text] = fake.Text orig.Text = "" fake.Text = "" Ctx.refNicks() end
end)
local nicks = Instance.new("Frame", c1s)
nicks.Size = UDim2.new(1, 0, 0, 150)
nicks.Position = UDim2.new(0, 0, 0, 210)
nicks.BackgroundTransparency = 1
local function refNicks()
for _, ch in ipairs(nicks:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
local y = 0
for o, f in pairs(Settings.CustomNicks) do
local b = W.Button(nicks, y, o .. " -> " .. f)
b.TextColor3 = Color3.fromRGB(255, 100, 100)
b.MouseButton1Click:Connect(function() Settings.CustomNicks[o] = nil refNicks() end)
y = y + 34
end
end
Ctx.refNicks = refNicks
refNicks()
W.Header(c2s, "Menu", C_ACCENT)
local menuB = W.Button(c2s, 28, "Menu key")
local function refMenu()
menuB.Text = Settings.IsBindingMenuKey and "   Menu key: [press...]" or ("   Menu key: " .. Settings.MenuKeyBind.Name)
end
Ctx.refMenu = refMenu
refMenu()
menuB.MouseButton1Click:Connect(function() Settings.IsBindingMenuKey = true refMenu() end)
W.Button(c2s, 62, "Unload script", function() Ctx.FullCleanup() end)
local c1r, c2r = Cols("Credits")
W.Header(c1r, "SKV", C_ACCENT)
local cr1 = Instance.new("TextLabel", c1r)
cr1.Size = UDim2.new(1, 0, 0, 30)
cr1.Position = UDim2.new(0, 0, 0, 28)
cr1.BackgroundTransparency = 1
cr1.Font = Enum.Font.GothamBold
cr1.Text = "Telegram: @whoisSKV"
cr1.TextColor3 = Color3.fromRGB(50, 160, 255)
cr1.TextSize = 14
cr1.TextXAlignment = Enum.TextXAlignment.Left
local cr2 = Instance.new("TextLabel", c1r)
cr2.Size = UDim2.new(1, 0, 0, 60)
cr2.Position = UDim2.new(0, 0, 0, 58)
cr2.BackgroundTransparency = 1
cr2.Font = Enum.Font.Gotham
cr2.Text = "пишите если возникли вопросы."
cr2.TextColor3 = C_MUTED
cr2.TextSize = 13
cr2.TextWrapped = true
cr2.TextXAlignment = Enum.TextXAlignment.Left
Ctx.SwitchTab("Visuals")
local UIS = Ctx.UIS
table.insert(Ctx.Connections, UIS.InputBegan:Connect(function(input, gp)
if Settings.IsBindingMenuKey then
if input.UserInputType == Enum.UserInputType.Keyboard then Settings.MenuKeyBind = input.KeyCode Settings.IsBindingMenuKey = false Ctx.refMenu() end
return
end
if Settings.IsBindingAimKey then
if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
Settings.AimKey = (input.UserInputType == Enum.UserInputType.Keyboard) and input.KeyCode or input.UserInputType
Settings.IsBindingAimKey = false
Ctx.refAim()
end
return
end
if Ctx.moonwalkInst.IsWaitingForBind and input.UserInputType == Enum.UserInputType.Keyboard then
Ctx.moonwalkInst.BindKey = input.KeyCode
Ctx.moonwalkInst.IsWaitingForBind = false
if Ctx.moonwalkInst.OnBindChanged then Ctx.moonwalkInst.OnBindChanged() end
return
end
if not gp and input.KeyCode == Settings.MenuKeyBind then Ctx.MainFrame.Visible = not Ctx.MainFrame.Visible end
end))
return true
end
return P5b
