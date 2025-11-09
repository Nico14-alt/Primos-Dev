local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Config
local Config = {
    AutoTeleportPrivateServer = true,
    MeleeAuraRange = 10,
    VehicleModifiers = {
        SpeedMultiplier = 2,
        JumpPowerMultiplier = 1.5,
    },
    ESPColors = {
        SafeZone = Color3.fromRGB(0, 255, 0),
        SpawnProtection = Color3.fromRGB(255, 255, 0),
        Enemy = Color3.fromRGB(255, 0, 0),
        Friendly = Color3.fromRGB(0, 0, 255),
    },
    ItemRarityColors = {
        Common = Color3.fromRGB(255, 255, 255),
        Uncommon = Color3.fromRGB(30, 255, 0),
        Rare = Color3.fromRGB(0, 112, 221),
        Epic = Color3.fromRGB(163, 53, 238),
        Legendary = Color3.fromRGB(255, 128, 0),
    },
    MagicBulletSpeed = 300,
    InfiniteStamina = true,
    SilentAimFOV = 30,
    ImprovedSilentAimAccuracy = 0.95,
    AntiAimEnabled = true,
    HideName = true,
    Invisible = true,
    InstantSellDrop = true,
    UnlimitedEquip = true,
}

-- Utility functions
local function IsInSafeZone(player)
    -- Placeholder: Detect if player is in safe zone or spawn protection
    -- This should be replaced with actual game logic
    local character = player.Character
    if not character then return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    -- Example: safe zone is within 50 studs of origin
    return (hrp.Position - Vector3.new(0, 0, 0)).Magnitude < 50
end

local function GetRarityColor(rarity)
    return Config.ItemRarityColors[rarity] or Color3.new(1,1,1)
end

-- ESP
local function CreateESP(player)
    if player == LocalPlayer then return end
    local espBox = Instance.new("BoxHandleAdornment")
    espBox.Adornee = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    espBox.AlwaysOnTop = true
    espBox.ZIndex = 10
    espBox.Size = Vector3.new(4, 6, 4)
    espBox.Transparency = 0.5
    espBox.Parent = player.Character or Workspace

    RunService.RenderStepped:Connect(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            espBox.Adornee = player.Character.HumanoidRootPart
            if IsInSafeZone(player) then
                espBox.Color3 = Config.ESPColors.SafeZone
            else
                espBox.Color3 = Config.ESPColors.Enemy
            end
        else
            espBox:Destroy()
        end
    end)
end

for _, player in pairs(Players:GetPlayers()) do
    CreateESP(player)
end

Players.PlayerAdded:Connect(CreateESP)

-- Silent Aim + Improved Silent Aim
local function GetClosestTarget()
    local closestPlayer = nil
    local closestDistance = Config.SilentAimFOV
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local headPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(player.Character.Head.Position)
            if onScreen then
                local screenPos = Vector2.new(headPos.X, headPos.Y)
                local distance = (screenPos - mousePos).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

local function AimAtTarget(target)
    if not target or not target.Character or not target.Character:FindFirstChild("Head") then return end
    local headPos = target.Character.Head.Position
    local camera = workspace.CurrentCamera
    local direction = (headPos - camera.CFrame.Position).Unit
    local newCFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + direction)
    camera.CFrame = newCFrame
end

RunService.RenderStepped:Connect(function()
    if math.random() < Config.ImprovedSilentAimAccuracy then
        local target = GetClosestTarget()
        if target then
            AimAtTarget(target)
        end
    end
end)

-- Anti Aim (simple jitter)
if Config.AntiAimEnabled then
    spawn(function()
        while true do
            local camera = workspace.CurrentCamera
            local cf = camera.CFrame
            local jitterAngle = math.rad(math.random(-10,10))
            camera.CFrame = cf * CFrame.Angles(0, jitterAngle, 0)
            wait(0.1)
        end
    end)
end

-- Hide Name
if Config.HideName then
    local function HidePlayerName(player)
        if player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.DisplayName = ""
                humanoid.NameDisplayDistance = 0
            end
        end
    end
    for _, player in pairs(Players:GetPlayers()) do
        HidePlayerName(player)
    end
    Players.PlayerAdded:Connect(HidePlayerName)
end

-- Invisible
if Config.Invisible then
    local function MakeInvisible(character)
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
                part.CanCollide = false
            elseif part:IsA("Decal") then
                part.Transparency = 1
            elseif part:IsA("ParticleEmitter") or part:IsA("Trail") then
                part.Enabled = false
            end
        end
    end
    if LocalPlayer.Character then
        MakeInvisible(LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(MakeInvisible)
end

-- Auto Teleport to Private Server (placeholder)
if Config.AutoTeleportPrivateServer then
    -- This requires game-specific private server join logic
    -- Placeholder: Teleport to a private server place ID (replace with actual)
    local privateServerPlaceId = game.PlaceId -- Replace with actual private server place ID
    local TeleportService = game:GetService("TeleportService")
    TeleportService:Teleport(privateServerPlaceId, LocalPlayer)
end

-- Infinite Stamina (placeholder)
if Config.InfiniteStamina then
    spawn(function()
        while true do
            if LocalPlayer.Character then
                local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid:FindFirstChild("Stamina") then
                    humanoid.Stamina.Value = humanoid.Stamina.MaxValue
                end
            end
            wait(0.1)
        end
    end)
end

-- Melee Aura
spawn(function()
    while true do
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if humanoid and hrp then
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local targetHRP = player.Character.HumanoidRootPart
                        local distance = (hrp.Position - targetHRP.Position).Magnitude
                        if distance <= Config.MeleeAuraRange then
                            -- Attack logic placeholder: fire melee attack event
                            local meleeEvent = ReplicatedStorage:FindFirstChild("MeleeAttack")
                            if meleeEvent then
                                meleeEvent:FireServer(player.Character)
                            end
                        end
                    end
                end
            end
        end
        wait(0.2)
    end
end)

-- Vehicle Modifier
local function ModifyVehicle(vehicle)
    if vehicle and vehicle:IsA("VehicleSeat") then
        vehicle.MaxSpeed = (vehicle.MaxSpeed or 50) * Config.VehicleModifiers.SpeedMultiplier
        vehicle.MaxTorque = (vehicle.MaxTorque or Vector3.new(400000,400000,400000)) * Config.VehicleModifiers.JumpPowerMultiplier
    end
end

-- Auto lock vehicle (placeholder)
local function AutoLockVehicle()
    if LocalPlayer.Character then
        for _, v in pairs(Workspace:GetChildren()) do
            if v:IsA("VehicleSeat") and (v.Occupant == nil or v.Occupant.Parent ~= LocalPlayer.Character) then
                -- Lock vehicle logic placeholder
                if v:FindFirstChild("Lock") then
                    v.Lock.Value = true
                end
            end
        end
    end
end
