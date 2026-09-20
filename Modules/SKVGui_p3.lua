-- SKVGui part3 widgets
local P3 = {}
function P3.Header(parent, text, C_ACCENT)
local l = Instance.new("TextLabel", parent)
l.Size = UDim2.new(1, 0, 0, 22)
l.BackgroundTransparency = 1
l.Font = Enum.Font.GothamBold
l.Text = text
l.TextColor3 = C_ACCENT
l.TextSize = 16
l.TextXAlignment = Enum.TextXAlignment.Left
return l
end
function P3.Check(Ctx, parent, yPos, text, def, cb)
local Tween = Ctx.Tween
local C_ACCENT = Ctx.C_ACCENT
local C_MUTED = Ctx.C_MUTED
local C_BORDER = Color3.fromRGB(34,34,40)
local wrap = Instance.new("TextButton", parent)
wrap.Size = UDim2.new(1, 0, 0, 22)
wrap.Position = UDim2.new(0, 0, 0, yPos)
wrap.BackgroundTransparency = 1
wrap.Text = ""
local radio = Instance.new("Frame", wrap)
radio.Size = UDim2.new(0, 14, 0, 14)
radio.Position = UDim2.new(0, 0, 0.5, -7)
radio.BackgroundColor3 = def and C_ACCENT or Color3.fromRGB(20,20,24)
radio.BorderSizePixel = 0
local rc = Instance.new("UICorner", radio) rc.CornerRadius = UDim.new(1, 0)
local rs = Instance.new("UIStroke", radio)
rs.Color = def and C_ACCENT or C_BORDER
rs.Thickness = 1.2
local label = Instance.new("TextLabel", wrap)
label.Size = UDim2.new(1, -24, 1, 0)
label.Position = UDim2.new(0, 22, 0, 0)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamMedium
label.Text = text
label.TextColor3 = def and C_ACCENT or C_MUTED
label.TextSize = 13
label.TextXAlignment = Enum.TextXAlignment.Left
local state = def
wrap.MouseButton1Click:Connect(function()
state = not state
Tween:Create(radio, TweenInfo.new(0.15), {BackgroundColor3 = state and C_ACCENT or Color3.fromRGB(20,20,24)}):Play()
Tween:Create(rs, TweenInfo.new(0.15), {Color = state and C_ACCENT or C_BORDER}):Play()
Tween:Create(label, TweenInfo.new(0.15), {TextColor3 = state and C_ACCENT or C_MUTED}):Play()
if cb then cb(state) end
end)
return true
end
function P3.Button(parent, yPos, text, cb)
local b = Instance.new("TextButton", parent)
b.Size = UDim2.new(1, 0, 0, 28)
b.Position = UDim2.new(0, 0, 0, yPos)
b.BackgroundColor3 = Color3.fromRGB(18,18,22)
b.Text = "   " .. text
b.TextColor3 = Color3.fromRGB(255,255,255)
b.Font = Enum.Font.GothamMedium
b.TextSize = 13
b.TextXAlignment = Enum.TextXAlignment.Left
local cr = Instance.new("UICorner", b) cr.CornerRadius = UDim.new(0, 6)
local st = Instance.new("UIStroke", b) st.Color = Color3.fromRGB(34,34,40)
if cb then b.MouseButton1Click:Connect(function() cb(b) end) end
return b
end
function P3.Slider(Ctx, parent, yPos, labelText, minV, maxV, defV, suffix, cb)
local UIS = Ctx.UIS
local C_MUTED = Ctx.C_MUTED
local wrap = Instance.new("Frame", parent)
wrap.Size = UDim2.new(1, 0, 0, 42)
wrap.Position = UDim2.new(0, 0, 0, yPos)
wrap.BackgroundTransparency = 1
local title = Instance.new("TextLabel", wrap)
title.Size = UDim2.new(0.7, 0, 0, 16)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamMedium
title.Text = labelText
title.TextColor3 = C_MUTED
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
local valueLabel = Instance.new("TextLabel", wrap)
valueLabel.Size = UDim2.new(0.3, 0, 0, 16)
valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
valueLabel.BackgroundTransparency = 1
valueLabel.Font = Enum.Font.GothamMedium
valueLabel.Text = string.format("%.2f", defV) .. suffix
valueLabel.TextColor3 = C_MUTED
valueLabel.TextSize = 13
valueLabel.TextXAlignment = Enum.TextXAlignment.Right
local bar = Instance.new("TextButton", wrap)
bar.Size = UDim2.new(1, 0, 0, 13)
bar.Position = UDim2.new(0, 0, 0, 22)
bar.BackgroundColor3 = Color3.fromRGB(24,24,28)
bar.Text = ""
bar.AutoButtonColor = false
local bc = Instance.new("UICorner", bar) bc.CornerRadius = UDim.new(0, 7)
local rel = math.clamp((defV - minV) / (maxV - minV), 0.05, 1)
local fill = Instance.new("Frame", bar)
fill.Size = UDim2.new(rel, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(200,200,210)
local fc = Instance.new("UICorner", fill) fc.CornerRadius = UDim.new(0, 7)
local sliding = false
local function upd(x)
local p = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
local v = minV + (maxV - minV) * p
valueLabel.Text = string.format("%.2f", v) .. suffix
fill.Size = UDim2.new(math.max(p, 0.04), 0, 1, 0)
if cb then cb(v) end
end
bar.InputBegan:Connect(function(i)
if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true Ctx.isInteracting = true upd(i.Position.X) end
end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false Ctx.isInteracting = false end end)
UIS.InputChanged:Connect(function(i) if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then upd(i.Position.X) end end)
end
return P3
