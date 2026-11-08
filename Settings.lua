-- Settings.lua
local Settings = {
    MenuKeyBind = Enum.KeyCode.RightShift,
    EnableESP = false,
    Skeleton = false,
    Chams = true,
    Tracers = false,
    ShowName = false,
    ShowDistance = false,
    EnableGeneratorsESP = true,
    EnablePalletsESP = true,
    EnableBearTrapsESP = true,
    EnablePumpkinsESP = true,
    RoleLogic = "All",
    KillerColor = Color3.fromRGB(255, 60, 60),
    SurvivorColor = Color3.fromRGB(60, 160, 255),
    GeneratorColor = Color3.fromRGB(150, 0, 200),
    PalletColor = Color3.fromRGB(74, 255, 181),
    BearTrapColor = Color3.fromRGB(255, 170, 0),
    PumpkinColor = Color3.fromRGB(255, 130, 0),
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
    -- Moonwalk / Auto tools (для нового GUI)
    MoonwalkEnabled = false,
    AutoSkillCheck = false,
    AutoDagger = false,
    ShowNextKiller = true,
}

return Settings
