-- Settings.lua
local Settings = {
    MenuKeyBind = Enum.KeyCode.RightShift,
    EnableESP = false,
    Skeleton = false,
    Chams = true,
    Tracers = false,
    ShowName = false,
    ShowDistance = false,
    EnableGeneratorsESP = false,
    EnablePalletsESP = true,
    EnableNextKiller = true,
    RoleLogic = "All",
    KillerColor = Color3.fromRGB(255, 60, 60),
    SurvivorColor = Color3.fromRGB(60, 160, 255),
    GeneratorColor = Color3.fromRGB(150, 0, 200),
    PalletColor = Color3.fromRGB(74, 255, 181),
    IsBindingMenuKey = false,
    EnableNickChanger = false,
    CustomNicks = {},
    
    -- Настройки Aim Assist
    EnableAim = false,
    AimKey = Enum.UserInputType.MouseButton2,
    IsBindingAimKey = false,
    Smoothness = 0.25,
    TargetPart = "Head",
    EnableFOV = true,
    FOVRadius = 120,
    TeamCheck = false,
    WallCheck = false,

    -- Настройки Camera FOV и Misc
    EnableCameraFOV = false,
    CameraFOVValue = 70,
    EnableFullBright = false,
    FPSBoostApplied = false,
    RemoveFog = false,
}

return Settings
