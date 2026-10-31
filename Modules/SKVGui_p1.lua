-- SKVGui part1
local SKVGui = {}
function SKVGui.BuildFrame(S, Ctx)
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = game:GetService("Players").LocalPlayer
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SKV_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
if syn and syn.protect_gui then syn.protect_gui(ScreenGui) ScreenGui.Parent = CoreGui
elseif gethui then ScreenGui.Parent = gethui()
else ScreenGui.Parent = CoreGui end
end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 690, 0, 520)
MainFrame.Position = UDim2.new(0.5, -345, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(11, 11, 13)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
local c1 = Instance.new("UICorner", MainFrame) c1.CornerRadius = UDim.new(0, 14)
local st = Instance.new("UIStroke", MainFrame) st.Thickness = 1.2 st.Color = Color3.fromRGB(34, 34, 40)
local Shadow = Instance.new("ImageLabel", MainFrame)
Shadow.BackgroundTransparency = 1
Shadow.Position = UDim2.new(0, -25, 0, -25)
Shadow.Size = UDim2.new(1, 50, 1, 50)
Shadow.ZIndex = 0
Shadow.Image = "rbxassetid://1316045217"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.4
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
Ctx.ScreenGui = ScreenGui
Ctx.MainFrame = MainFrame
Ctx.UIS = UIS
Ctx.Tween = TweenService
Ctx.LocalPlayer = LocalPlayer
return ScreenGui, MainFrame
end
return SKVGui
