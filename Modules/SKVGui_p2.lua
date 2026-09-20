-- SKVGui part2 sidebar+content+helpers
local P2 = {}
function P2.Build(Ctx)
local UIS = Ctx.UIS
local C_ACCENT = Color3.fromRGB(255,255,255)
local C_MUTED = Color3.fromRGB(125,125,136)
local C_SIDEBAR = Color3.fromRGB(14,14,17)
local MainFrame = Ctx.MainFrame
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 155, 1, 0)
Sidebar.BackgroundColor3 = C_SIDEBAR
Sidebar.BorderSizePixel = 0
local sc = Instance.new("UICorner", Sidebar) sc.CornerRadius = UDim.new(0, 14)
local cover = Instance.new("Frame", Sidebar)
cover.Size = UDim2.new(0, 16, 1, 0)
cover.Position = UDim2.new(1, -16, 0, 0)
cover.BackgroundColor3 = C_SIDEBAR
cover.BorderSizePixel = 0
local brand = Instance.new("TextLabel", Sidebar)
brand.Size = UDim2.new(0, 110, 0, 24)
brand.Position = UDim2.new(0, 18, 0, 15)
brand.BackgroundTransparency = 1
brand.Font = Enum.Font.GothamBold
brand.Text = "SKV"
brand.TextColor3 = C_ACCENT
brand.TextSize = 16
brand.TextXAlignment = Enum.TextXAlignment.Left
local sub = Instance.new("TextLabel", Sidebar)
sub.Size = UDim2.new(0, 110, 0, 14)
sub.Position = UDim2.new(0, 18, 0, 36)
sub.BackgroundTransparency = 1
sub.Font = Enum.Font.Gotham
sub.Text = "by takeushi"
sub.TextColor3 = C_MUTED
sub.TextSize = 11
sub.TextXAlignment = Enum.TextXAlignment.Left
local TabContainer = Instance.new("Frame", Sidebar)
TabContainer.Size = UDim2.new(1, -16, 0, 370)
TabContainer.Position = UDim2.new(0, 18, 0, 62)
TabContainer.BackgroundTransparency = 1
local ll = Instance.new("UIListLayout", TabContainer)
ll.SortOrder = Enum.SortOrder.LayoutOrder
ll.Padding = UDim.new(0, 6)
local ProfileFrame = Instance.new("Frame", Sidebar)
ProfileFrame.Size = UDim2.new(1, -24, 0, 40)
ProfileFrame.Position = UDim2.new(0, 14, 1, -50)
ProfileFrame.BackgroundTransparency = 1
local NameLabel = Instance.new("TextLabel", ProfileFrame)
NameLabel.Size = UDim2.new(1, 0, 0, 16)
NameLabel.BackgroundTransparency = 1
NameLabel.Font = Enum.Font.GothamBold
NameLabel.Text = Ctx.LocalPlayer.DisplayName
NameLabel.TextColor3 = C_ACCENT
NameLabel.TextSize = 13
NameLabel.TextXAlignment = Enum.TextXAlignment.Left
local RankLabel = Instance.new("TextLabel", ProfileFrame)
RankLabel.Size = UDim2.new(1, 0, 0, 14)
RankLabel.Position = UDim2.new(0, 0, 0, 17)
RankLabel.BackgroundTransparency = 1
RankLabel.Font = Enum.Font.Gotham
RankLabel.Text = "Next: ..."
RankLabel.TextColor3 = C_MUTED
RankLabel.TextSize = 11
RankLabel.TextXAlignment = Enum.TextXAlignment.Left
local ContentHost = Instance.new("Frame", MainFrame)
ContentHost.Size = UDim2.new(1, -165, 1, -24)
ContentHost.Position = UDim2.new(0, 160, 0, 14)
ContentHost.BackgroundTransparency = 1
local Drag = Instance.new("Frame", MainFrame)
Drag.Size = UDim2.new(1, 0, 0, 36)
Drag.BackgroundTransparency = 1
Drag.ZIndex = 3
local dragging, dragStart, startPos
Drag.InputBegan:Connect(function(i)
if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true dragStart = i.Position startPos = MainFrame.Position end
end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false Ctx.isInteracting = false end end)
UIS.InputChanged:Connect(function(i)
if dragging and i.UserInputType == Enum.UserInputType.MouseMovement and not Ctx.isInteracting then
local d = i.Position - dragStart
MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
end
end)
Ctx.TabContainer = TabContainer
Ctx.ContentHost = ContentHost
Ctx.RankLabel = RankLabel
Ctx.C_ACCENT = C_ACCENT
Ctx.C_MUTED = C_MUTED
return true
end
return P2
