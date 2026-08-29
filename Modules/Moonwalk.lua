--[[
    VD_Script - Moonwalk Module
    Integrated into Misc Tab with customizable Keybind and Unbind support.
]]

local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local MoonwalkModule = {}
MoonwalkModule.__index = MoonwalkModule

function MoonwalkModule.new()
    local self = setmetatable({}, MoonwalkModule)
    
    self.Enabled = false
    self.Keybind = Enum.KeyCode.Q -- Бинд по умолчанию (можно изменить)
    self.IsWaitingForBind = false
    self.Connection = nil
    
    return self
end

-- Метод для запуска логики удержания клавиши мунволка
function MoonwalkModule:StartLoop()
    if self.Connection then
        self.Connection:Disconnect()
    end

    self.Connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if self.IsWaitingForBind then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                self.Keybind = input.KeyCode
                self.IsWaitingForBind = false
                if self.OnBindChanged then
                    self.OnBindChanged(input.KeyCode.Name)
                end
            end
            return
        end

        -- Если включено, не в чате/интерфейсе игры и нажата забинженая клавиша
        if self.Enabled and not gameProcessed and self.Keybind and input.KeyCode == self.Keybind then
            task.spawn(function()
                while UserInputService:IsKeyDown(self.Keybind) and self.Enabled do
                    -- Нажимаем и удерживаем A
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.A, false, game)
                    task.wait(0.06)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.A, false, game)
                    
                    task.wait(0.02)

                    -- Нажимаем и удерживаем D
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.D, false, game)
                    task.wait(0.06)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.D, false, game)
                    
                    task.wait(0.02)
                end
            end)
        end
    end)
end

function MoonwalkModule:Toggle(state)
    self.Enabled = state
    if state then
        self:StartLoop()
    else
        if self.Connection then
            self.Connection:Disconnect()
            self.Connection = nil
        end
    end
end

function MoonwalkModule:SetBind(keyCode)
    self.Keybind = keyCode
end

function MoonwalkModule:ClearBind()
    self.Keybind = nil
    self.IsWaitingForBind = false
end

return MoonwalkModule
