-- Modules/Moonwalk.lua
local Moonwalk = {}
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

function Moonwalk.Apply(settingsTable, connectionHolder)
    -- Инициализация настроек по умолчанию, если их нет
    if settingsTable.MoonwalkEnabled == nil then settingsTable.MoonwalkEnabled = false end
    if settingsTable.MoonwalkKey == nil then settingsTable.MoonwalkKey = Enum.KeyCode.Q end
    if settingsTable.IsBindingMoonwalkKey == nil then settingsTable.IsBindingMoonwalkKey = false end

    -- Обработка нажатий клавиш для мунволка и бинда
    local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if settingsTable.IsBindingMoonwalkKey then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape then
                    -- Если нажали Escape, отменяем бинд (оставляем старый)
                    settingsTable.IsBindingMoonwalkKey = false
                else
                    settingsTable.MoonwalkKey = input.KeyCode
                    settingsTable.IsBindingMoonwalkKey = false
                end
            end
            return
        end

        if settingsTable.MoonwalkEnabled and not gameProcessed and input.KeyCode == settingsTable.MoonwalkKey then
            task.spawn(function()
                while UserInputService:IsKeyDown(settingsTable.MoonwalkKey) and settingsTable.MoonwalkEnabled do
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.A, false, game)
                    task.wait(0.06)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.A, false, game)
                    
                    task.wait(0.02)

                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.D, false, game)
                    task.wait(0.06)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.D, false, game)
                    
                    task.wait(0.02)
                end
            end)
        end
    end)

    if connectionHolder then
        table.insert(connectionHolder, inputConn)
    end
end

return Moonwalk
