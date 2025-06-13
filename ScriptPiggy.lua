local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Piggy Script",
    Icon = 0,
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by Вася2",
    Theme = "Default",
    
    ToggleUIKeybind = "K",
    
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    
    ConfigurationSaving = {
      Enabled = true,
      FolderName = PiggyConfig,
      FileName = "Saves"
   },

   Discord = {
      Enabled = true,
      Invite = "R7YbX48GcE",
      RememberJoins = true
   },

    KeySystem = true,
    KeySettings = { 
        Title = "Ключ", 
        Subtitle = "Ключ система", 
        Note = "Купите скрипт", 
        FileName = "Key", 
        SaveKey = true, 
        GrabKeyFromSite = false, 
        Key = {"PiggyScriptByVasia2"} 
    }
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RepStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local defaults = { 
    speed = 16, 
    jump = 50, 
    gravity = workspace.Gravity, 
    fov = Camera.FieldOfView, 
    flySpeed = 100 
}
local state = {
    speed = defaults.speed,
    jump = defaults.jump,
    gravity = defaults.gravity,
    fov = defaults.fov,
    flySpeed = defaults.flySpeed,
    speedToggle = false,
    jumpToggle = false,
    gravityToggle = false,
    fovToggle = false,
    fly = false,
    noclip = false,
    infJump = false,
    mapToggle = false,
    mapChoice = "House",
    votedMap = false,
    modeToggle = false,
    modeChoice = "Bot",
    votedMode = false
}

local lightingDefaults = {
    ambient = Color3.fromRGB(0.3921568627, 0.3921568627, 0.3921568627),
    fogStart = 0,
    fogEnd = 1000
}

local lastState = {
    speedToggle = state.speedToggle,
    jumpToggle = state.jumpToggle,
    gravityToggle = state.gravityToggle,
    fovToggle = state.fovToggle
}

local fullbrightState = false

local function applySettings()
    local char = LP.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = state.speedToggle and state.speed or defaults.speed
        humanoid.JumpPower = state.jumpToggle and state.jump or defaults.jump
    end
    workspace.Gravity = state.gravityToggle and state.gravity or defaults.gravity
    Camera.FieldOfView = state.fovToggle and state.fov or defaults.fov
end

local speedAccumulator = 0
RunService.Heartbeat:Connect(function(dt)
    speedAccumulator = speedAccumulator + dt
    if speedAccumulator >= 1 then
        if state.speedToggle and LP.Character then
            local humanoid = LP.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = state.speed
            end
        end
        speedAccumulator = speedAccumulator - 1
    end
end)

local function updateNoclip()
    if state.noclip and LP.Character then
        for _, part in ipairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end

LP.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    char.Humanoid.Died:Connect(function()
        lastState = {
            speedToggle = state.speedToggle,
            jumpToggle = state.jumpToggle,
            gravityToggle = state.gravityToggle,
            fovToggle = state.fovToggle
        }
    end)
    state.speedToggle = lastState.speedToggle
    state.jumpToggle = lastState.jumpToggle
    state.gravityToggle = lastState.gravityToggle
    state.fovToggle = lastState.fovToggle
    applySettings()
    char.Humanoid.Changed:Connect(function(prop)
        if prop == "WalkSpeed" or prop == "JumpPower" then
            applySettings()
        end
    end)
end)

if LP.Character then applySettings() end
RunService.Heartbeat:Connect(updateNoclip)

UIS.JumpRequest:Connect(function()
    if state.infJump and LP.Character then
        LP.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

local bodyVelocity
RunService.Heartbeat:Connect(function()
    if state.fly then
        if not bodyVelocity and LP.Character then
            local root = LP.Character:FindFirstChild("HumanoidRootPart")
            if root then
                bodyVelocity = Instance.new("BodyVelocity", root)
                bodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)
            end
        end
        if bodyVelocity then
            local dir = Vector3.new()
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            bodyVelocity.Velocity = dir.Unit * state.flySpeed
        end
    else
        if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    end
end)

RunService.Heartbeat:Connect(function()
    local phase = workspace.GameFolder.Phase.Value
    if phase == "Map Voting" and state.mapToggle and not state.votedMap then
        RepStorage.Remotes.NewVote:FireServer("Map", state.mapChoice)
        state.votedMap = true
    end
    if phase == "Piggy Voting" and state.modeToggle and not state.votedMode then
        RepStorage.Remotes.NewVote:FireServer("Piggy", state.modeChoice)
        state.votedMode = true
    end
    if phase ~= "Map Voting" then state.votedMap = false end
    if phase ~= "Piggy Voting" then state.votedMode = false end
end)

local PlayerTab = Window:CreateTab("LocalPlayer", 4483362458)
PlayerTab:CreateSection("Скорость")
PlayerTab:CreateSlider({
    Name = "Скорость",
    Range = {16, 100},
    Increment = 1,
    Suffix = "ед.",
    CurrentValue = state.speed,
    Callback = function(v)
        state.speed = v
        applySettings()
    end
})
PlayerTab:CreateToggle({
    Name = "Поменять скорость",
    CurrentValue = state.speedToggle,
    Callback = function(v)
        state.speedToggle = v
        applySettings()
    end
})

PlayerTab:CreateSection("Прыжок")
PlayerTab:CreateSlider({
    Name = "Прыжок",
    Range = {50, 200},
    Increment = 1,
    Suffix = "ед.",
    CurrentValue = state.jump,
    Callback = function(v)
        state.jump = v
        applySettings()
    end
})
PlayerTab:CreateToggle({
    Name = "Поменять прыжок",
    CurrentValue = state.jumpToggle,
    Callback = function(v)
        state.jumpToggle = v
        applySettings()
    end
})

PlayerTab:CreateSection("Гравитация")
PlayerTab:CreateSlider({
    Name = "Гравитация",
    Range = {0, 192},
    Increment = 1,
    Suffix = "ед.",
    CurrentValue = state.gravity,
    Callback = function(v)
        state.gravity = v
        applySettings()
    end
})
PlayerTab:CreateToggle({
    Name = "Поменять гравитацию",
    CurrentValue = state.gravityToggle,
    Callback = function(v)
        state.gravityToggle = v
        applySettings()
    end
})

PlayerTab:CreateSection("Поле зрения")
PlayerTab:CreateSlider({
    Name = "Поле зрения",
    Range = {50, 120},
    Increment = 1,
    Suffix = "ед.",
    CurrentValue = state.fov,
    Callback = function(v)
        state.fov = v
        if state.fovToggle then applySettings() end
    end
})
PlayerTab:CreateToggle({
    Name = "Поменять поле зрения",
    CurrentValue = state.fovToggle,
    Callback = function(v)
        state.fovToggle = v
        applySettings()
    end
})

PlayerTab:CreateSection("Ноуклип")
PlayerTab:CreateToggle({
    Name = "Ноуклип",
    CurrentValue = state.noclip,
    Callback = function(v)
        state.noclip = v
    end
})

task.spawn(function()
    while true do
        if state.noclip and LP.Character then
            for _, part in ipairs(LP.Character:GetDescendants()) do
                if part:IsA("BasePart") and not part.Anchored then
                    part.CanCollide = false
                end
            end
        elseif not state.noclip and LP.Character then
            for _, part in ipairs(LP.Character:GetDescendants()) do
                if part:IsA("BasePart") and not part.Anchored then
                    part.CanCollide = true
                end
            end
        end
        task.wait(0.1)
    end
end)

PlayerTab:CreateSection("Бесконечные прыжки")
PlayerTab:CreateToggle({
    Name = "Бесконечные прыжки",
    CurrentValue = state.infJump,
    Callback = function(v)
        state.infJump = v
    end
})

PlayerTab:CreateSection("Fly")
PlayerTab:CreateSlider({
    Name = "Скорость флая",
    Range = {15, 100},
    Increment = 1,
    Suffix = "ед.",
    CurrentValue = state.flySpeed,
    Callback = function(v)
        state.flySpeed = v
    end
})
PlayerTab:CreateToggle({
    Name = "Fly",
    CurrentValue = state.fly,
    Callback = function(v)
        state.fly = v
    end
})

PlayerTab:CreateSection("Автоматическое голосование")
PlayerTab:CreateDropdown({
    Name = "Карты",
    Options = {"House","Station","Gallery","Forest","School","Hospital","Metro","Carnival","City","Mall","Outpost","DistortedMemory","Plant"},
    CurrentOption = {state.mapChoice},
    MultipleOptions = false,
    Callback = function(opt)
        state.mapChoice = opt[1]
        state.votedMap = false
    end
})
PlayerTab:CreateToggle({
    Name = "Автоматическое голосование карты",
    CurrentValue = state.mapToggle,
    Callback = function(v)
        state.mapToggle = v
        if v then state.votedMap = false end
    end
})
PlayerTab:CreateDropdown({
    Name = "Моды",
    Options = {"Bot","Player","PlayerBot","Infection","Traitor","Swarm","Tag"},
    CurrentOption = {state.modeChoice},
    MultipleOptions = false,
    Callback = function(opt)
        state.modeChoice = opt[1]
        state.votedMode = false
    end
})
PlayerTab:CreateToggle({
    Name = "Автоматическое голосование мода",
    CurrentValue = state.modeToggle,
    Callback = function(v)
        state.modeToggle = v
        if v then state.votedMode = false end
    end
})

local UtilitiesTab = Window:CreateTab("Утилиты", 4483362458)

UtilitiesTab:CreateSection("Fullbright/Fog")
UtilitiesTab:CreateToggle({
    Name = "Вкл освещение+Выкл туман",
    CurrentValue = fullbrightState,
    Flag = "FULLBRIGHT",
    Callback = function(Value)
        fullbrightState = Value
        if Value then
            game.Lighting.Ambient = Color3.fromRGB(1, 1, 1)
            game.Lighting.FogStart = 0
            game.Lighting.FogEnd = 99999
        else
            game.Lighting.Ambient = lightingDefaults.ambient
            game.Lighting.FogStart = lightingDefaults.fogStart
            game.Lighting.FogEnd = lightingDefaults.fogEnd
        end
    end,
})

UtilitiesTab:CreateSection("Page")
UtilitiesTab:CreateButton({
    Name = "Собрать страницы",
    Callback = function()
        Rayfield:Notify({
            Title = "Страницы",
            Content = "Функция пока не реализована",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

UtilitiesTab:CreateSection("Blueprints")
UtilitiesTab:CreateButton({
    Name = "Собрать чертёж",
    Callback = function()
        local char = LP.Character
        if not char then 
            Rayfield:Notify({
                Title = "Чертёж",
                Content = "Персонаж не найден",
                Duration = 3,
                Image = 4483362458,
            })
            return 
        end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then 
            Rayfield:Notify({
                Title = "Чертёж",
                Content = "Гуманоид не найден",
                Duration = 3,
                Image = 4483362458,
            })
            return 
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then 
            Rayfield:Notify({
                Title = "Чертёж",
                Content = "RootPart не найден",
                Duration = 3,
                Image = 4483362458,
            })
            return 
        end
        local blueprints = {}
        for _, item in ipairs(workspace:GetDescendants()) do
            if item.Name == "BlueprintItem" and (item:IsA("BasePart") or item:IsA("Model")) then
                table.insert(blueprints, item)
            end
        end
        if #blueprints == 0 then
            Rayfield:Notify({
                Title = "Чертёж",
                Content = "Чертёж не найден!",
                Duration = 3,
                Image = 4483362458,
            })
            return
        end
        local originalPosition = root.CFrame
        local originalCollisions = {}
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                originalCollisions[part] = part.CanCollide
                part.CanCollide = false
            end
        end
        local collected = 0
        for _, bp in ipairs(blueprints) do
            if bp and bp.Parent then
                local targetPos = nil
                if bp:IsA("Model") and bp.PrimaryPart then
                    targetPos = bp.PrimaryPart.Position
                elseif bp:IsA("BasePart") then
                    targetPos = bp.Position
                end
                if targetPos then
                    root.CFrame = CFrame.new(targetPos) + Vector3.new(0, 3, 0)
                    task.wait(0.3)
                    root.CFrame = CFrame.new(targetPos)
                    task.wait(0.2)
                    collected = collected + 1
                end
            end
        end
        root.CFrame = originalPosition
        task.wait(0.2)
        for part, collide in pairs(originalCollisions) do
            if part:IsA("BasePart") and part.Parent then
                part.CanCollide = collide
            end
        end
        Rayfield:Notify({
            Title = "Чертёж",
            Content = string.format("Собран %d чертёж!", collected),
            Duration = 5,
            Image = 4483362458,
        })
    end,
})

local doorState = {
    removeAll = false,
    removeSafes = false
}

local function removeMapFolders()
    local mapName = state.mapChoice
    local mapModel = workspace:FindFirstChild(mapName)
    if mapModel and mapModel:IsA("Model") then
        for _, child in ipairs(mapModel:GetChildren()) do
            if child:IsA("Folder") then
                child:Destroy()
            end
        end
    end
end

local function removeDoors()
    for _, item in ipairs(workspace:GetDescendants()) do
        if item:IsA("Model") then
            if doorState.removeAll and (
                item.Name == "Door" or 
                item.Name == "SideDoor" or 
                item.Name == "ExtraDoors" or 
                item.Name == "Doors" or 
                item.Name == "CrawlSpaces"
            ) then
                item:Destroy()
            end
            if doorState.removeSafes and string.find(item.Name:lower(), "safe") then
                item:Destroy()
            end
        end
    end
end

local doorRemovalConnection
local mapFolderLoop = nil

local function manageDoorRemoval()
    if mapFolderLoop then
        mapFolderLoop:Disconnect()
        mapFolderLoop = nil
    end

    if doorRemovalConnection then
        doorRemovalConnection:Disconnect()
        doorRemovalConnection = nil
    end

    if doorState.removeAll or doorState.removeSafes then
        removeDoors()
        doorRemovalConnection = workspace.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("Model") then
                if doorState.removeAll and (
                    descendant.Name == "Door" or 
                    descendant.Name == "SideDoor" or 
                    descendant.Name == "ExtraDoors" or 
                    descendant.Name == "Doors" or 
                    descendant.Name == "CrawlSpaces"
                ) then
                    descendant:Destroy()
                end
                if doorState.removeSafes and string.find(descendant.Name:lower(), "safe") then
                    descendant:Destroy()
                end
            end
        end)
        mapFolderLoop = RunService.Heartbeat:Connect(function()
            removeMapFolders()
        end)
    else
        if doorRemovalConnection then
            doorRemovalConnection:Disconnect()
            doorRemovalConnection = nil
        end
        if mapFolderLoop then
            mapFolderLoop:Disconnect()
            mapFolderLoop = nil
        end
    end
end

UtilitiesTab:CreateSection("Двери/Папки карты")
UtilitiesTab:CreateToggle({
    Name = "Убрать двери и папки карты",
    CurrentValue = doorState.removeAll,
    Flag = "REMOVE_DOORS",
    Callback = function(Value)
        doorState.removeAll = Value
        manageDoorRemoval()
    end,
})
UtilitiesTab:CreateToggle({
    Name = "Убрать двери сейфов",
    CurrentValue = doorState.removeSafes,
    Flag = "REMOVE_SAFES",
    Callback = function(Value)
        doorState.removeSafes = Value
        manageDoorRemoval()
    end,
})

task.spawn(function()
    while true do
        if doorState.removeAll then
            removeMapFolders()
        end
        task.wait(3)
    end
end)

if not fullbrightState then
    game.Lighting.Ambient = lightingDefaults.ambient
    game.Lighting.FogStart = lightingDefaults.fogStart
    game.Lighting.FogEnd = lightingDefaults.fogEnd
end

applySettings()

local TeleportTab = Window:CreateTab("Телепортация", 4483362458)
TeleportTab:CreateSection("Список")

local function getPlayerNames()
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            table.insert(names, plr.Name)
        end
    end
    return names
end

local Dropdown = TeleportTab:CreateDropdown({
    Name = "Игроки",
    Options = getPlayerNames(),
    CurrentOption = {getPlayerNames()[1] or ""},
    MultipleOptions = false,
    Flag = "Игроки1",
    Callback = function(Options)
    end
})

local function refreshPlayerDropdown()
    local names = getPlayerNames()
    Dropdown:Refresh(names, true)
    local current = Dropdown:GetCurrentOption()
    local found = false
    for _, name in ipairs(names) do
        if name == current then
            found = true
            break
        end
    end
    if not found then
        Dropdown:SetOption(names[1] or "")
    end
end

if not task then
    local task = {}
    function task.spawn(f) return coroutine.wrap(f)() end
    function task.wait(t) wait(t) end
end

task.spawn(function()
    while true do
        refreshPlayerDropdown()
        task.wait(3)
    end
end)

TeleportTab:CreateButton({
    Name = "Телепортироваться к игроку",
    Callback = function()
        local selectedPlayer = Dropdown:GetCurrentOption()
        if selectedPlayer and selectedPlayer ~= "" then
            local targetPlayer = Players:FindFirstChild(selectedPlayer)
            if targetPlayer and targetPlayer.Character then
                LP.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
            else
                Rayfield:Notify({
                    Title = "Ошибка",
                    Content = "Игрок не найден или не в игре.",
                    Duration = 3,
                    Image = 4483362458,
                })
            end
        else
            Rayfield:Notify({
                Title = "Ошибка",
                Content = "Выберите игрока для телепортации.",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})
