-- Piggy Script by Вася2 (оптимизированная версия)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Piggy Script",
    Icon = 0,
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by Вася2",
    Theme = "Default",
    ToggleUIKeybind = "K",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "PiggyConfig",
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

-- Сервисы
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local RepStorage  = game:GetService("ReplicatedStorage")
local UIS         = game:GetService("UserInputService")
local LP          = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- Дефолтные значения
local defaults = {
    speed    = 16,
    jump     = 50,
    gravity  = workspace.Gravity,
    fov      = Camera.FieldOfView,
    flySpeed = 100
}
local lightingDefaults = {
    ambient  = game.Lighting.Ambient,
    fogStart = game.Lighting.FogStart,
    fogEnd   = game.Lighting.FogEnd
}

-- Состояние
local state = {
    -- movement
    speed        = defaults.speed,
    jump         = defaults.jump,
    gravity      = defaults.gravity,
    fov          = defaults.fov,
    flySpeed     = defaults.flySpeed,
    speedToggle  = false,
    jumpToggle   = false,
    gravityToggle= false,
    fovToggle    = false,
    fly          = false,
    noclip       = false,
    infJump      = false,
    -- voting
    mapToggle    = false,
    mapChoice    = "House",
    votedMap     = false,
    modeToggle   = false,
    modeChoice   = "Bot",
    votedMode    = false,
    -- utilities
    fullbright   = false,
    removeDoors  = false,
    removeSafes  = false
}

-- Применить основные настройки (speed, jump, gravity, fov)
local function applySettings()
    local char = LP.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = state.speedToggle and state.speed or defaults.speed
            humanoid.JumpPower  = state.jumpToggle  and state.jump  or defaults.jump
        end
    end
    workspace.Gravity          = state.gravityToggle and state.gravity or defaults.gravity
    Camera.FieldOfView        = state.fovToggle     and state.fov     or defaults.fov
end

-- Авто-обновление speed каждую секунду
do
    local acc = 0
    RunService.Heartbeat:Connect(function(dt)
        acc = acc + dt
        if acc >= 1 then
            if state.speedToggle and LP.Character then
                local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = state.speed end
            end
            acc = acc - 1
        end
    end)
end

-- Ноуклип
local function updateNoclip()
    if state.noclip and LP.Character then
        for _, p in ipairs(LP.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end
RunService.Heartbeat:Connect(updateNoclip)

-- Бесконечный прыжок
UIS.JumpRequest:Connect(function()
    if state.infJump and LP.Character then
        LP.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

-- Флай (ПК и мобильный)
local bodyVelocity
local mobileFlyDir, mobileFlyActive = Vector3.new(), false
local function createMobileFlyButtons()
    if not UIS.TouchEnabled then return end
    if game.CoreGui:FindFirstChild("PiggyFlyControls") then return end
    local gui = Instance.new("ScreenGui", game.CoreGui)
    gui.Name = "PiggyFlyControls"
    gui.ResetOnSpawn = false
    local dirs = {
        {Name="Up",   Pos=UDim2.new(0.85,0,0.6,0),  Vec=Vector3.new(0,1,0), Text="↑"},
        {Name="Down", Pos=UDim2.new(0.85,0,0.8,0),  Vec=Vector3.new(0,-1,0),Text="↓"},
        {Name="Left", Pos=UDim2.new(0.8,0,0.7,0),   Vec=Vector3.new(-1,0,0),Text="←"},
        {Name="Right",Pos=UDim2.new(0.9,0,0.7,0),   Vec=Vector3.new(1,0,0), Text="→"},
        {Name="Fwd",  Pos=UDim2.new(0.85,0,0.7,0),  Vec=Vector3.new(0,0,-1),Text="⯅"},
        {Name="Back", Pos=UDim2.new(0.85,0,0.9,0),  Vec=Vector3.new(0,0,1), Text="⯆"},
    }
    for _, d in ipairs(dirs) do
        local btn = Instance.new("TextButton", gui)
        btn.Name = d.Name
        btn.Size = UDim2.new(0,40,0,40)
        btn.Position = d.Pos
        btn.BackgroundTransparency = 0.3
        btn.Text = d.Text
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 28
        btn.MouseButton1Down:Connect(function()
            mobileFlyActive = true
            mobileFlyDir = mobileFlyDir + d.Vec
        end)
        btn.MouseButton1Up:Connect(function()
            mobileFlyDir = mobileFlyDir - d.Vec
            if mobileFlyDir.Magnitude == 0 then mobileFlyActive = false end
        end)
    end
end
local function removeMobileFlyButtons()
    local gui = game.CoreGui:FindFirstChild("PiggyFlyControls")
    if gui then gui:Destroy() end
    mobileFlyDir, mobileFlyActive = Vector3.new(), false
end
RunService.Heartbeat:Connect(function()
    if state.fly and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        local root = LP.Character.HumanoidRootPart
        if not bodyVelocity or bodyVelocity.Parent ~= root then
            if bodyVelocity then bodyVelocity:Destroy() end
            bodyVelocity = Instance.new("BodyVelocity", root)
            bodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)
            bodyVelocity.P = 1e4
        end
        local dir = Vector3.new()
        -- ПК
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        -- Моб
        if UIS.TouchEnabled then
            createMobileFlyButtons()
            if mobileFlyActive and mobileFlyDir.Magnitude > 0 then
                local cf = Camera.CFrame
                local rel = cf.RightVector * mobileFlyDir.X + cf.LookVector * mobileFlyDir.Z
                dir = dir + Vector3.new(rel.X, mobileFlyDir.Y, rel.Z)
            end
        else
            removeMobileFlyButtons()
        end
        bodyVelocity.Velocity = (dir.Magnitude > 0 and dir.Unit * state.flySpeed) or Vector3.new()
    else
        if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
        removeMobileFlyButtons()
    end
end)

-- Авто-голосование
RunService.Heartbeat:Connect(function()
    local phase = workspace.GameFolder.Phase.Value
    if phase == "Map Voting" and state.mapToggle and not state.votedMap then
        RepStorage.Remotes.NewVote:FireServer("Map", state.mapChoice)
        state.votedMap = true
    elseif phase == "Piggy Voting" and state.modeToggle and not state.votedMode then
        RepStorage.Remotes.NewVote:FireServer("Piggy", state.modeChoice)
        state.votedMode = true
    end
    if phase ~= "Map Voting" then state.votedMap = false end
    if phase ~= "Piggy Voting" then state.votedMode = false end
end)

-- ====================================================================
-- Утилиты: автоматическое определение карты, fullbright/fog, remove folders & doors, чертёж
-- ====================================================================

-- 1) Поиск карты (модель с наибольшим кол-вом BasePart)
local function findMapModel()
    local best, maxCount = nil, 0
    for _, m in ipairs(workspace:GetChildren()) do
        if m:IsA("Model") then
            local cnt = 0
            for _, d in ipairs(m:GetDescendants()) do
                if d:IsA("BasePart") then cnt = cnt + 1 end
            end
            if cnt > maxCount then best, maxCount = m, cnt end
        end
    end
    return best
end

-- 2) Удаление ТОЛЬКО папок Doors и ExtraDoors в карте
local function removeMapFolders()
    local mdl = findMapModel()
    if mdl then
        for _, name in ipairs({"Doors", "ExtraDoors"}) do
            local folder = mdl:FindFirstChild(name)
            if folder and folder:IsA("Folder") then
                folder:Destroy()
            end
        end
    end
end

-- 3) Удаление дверей и сейфов
local function removeDoorsIn(item)
    item = item or workspace
    for _, d in ipairs(item:GetDescendants()) do
        if d:IsA("Model") then
            local n = d.Name
            if state.removeDoors and (n=="Door" or n=="SideDoor" or n=="CrawlSpaces") then
                d:Destroy()
            end
            if state.removeSafes and n:lower():find("safe") then
                d:Destroy()
            end
        end
    end
end

-- 4) Подписки для утилит
local utilConnections = {}
local function manageUtilities()
    -- отписка
    for _, c in pairs(utilConnections) do c:Disconnect() end
    utilConnections = {}

    if state.removeDoors or state.removeSafes then
        removeMapFolders()
        removeDoorsIn()
        
        -- Постоянное удаление папок
        utilConnections.heartbeat = RunService.Heartbeat:Connect(function()
            removeMapFolders()
        end)
        
        -- Удаление новых объектов
        utilConnections.descAdded = workspace.DescendantAdded:Connect(function(d)
            local mdl = findMapModel()
            if mdl and d:IsDescendantOf(mdl) then
                -- Удаление ТОЛЬКО папок Doors и ExtraDoors
                if d:IsA("Folder") and (d.Name == "Doors" or d.Name == "ExtraDoors") then
                    d:Destroy()
                -- Удаление дверей и сейфов
                elseif d:IsA("Model") then
                    local n = d.Name
                    if state.removeDoors and (n=="Door" or n=="SideDoor" or n=="CrawlSpaces") then
                        d:Destroy()
                    end
                    if state.removeSafes and n:lower():find("safe") then
                        d:Destroy()
                    end
                end
            end
        end)
    end
end

-- 5) Оптимизированный Fullbright / Fog (обновление только при изменении состояния)
local fullbrightConnection
if fullbrightConnection then fullbrightConnection:Disconnect() end
fullbrightConnection = game:GetService("RunService").Heartbeat:Connect(function()
    if state.fullbright then
        game.Lighting.Ambient = Color3.new(1, 1, 1)
        game.Lighting.FogStart = 0
        game.Lighting.FogEnd = 999999
    end
end)

-- 6) Исправленный сбор чертежей (телепорт к ближайшему)
local function collectBlueprints()
    local char = LP.Character
    if not char then 
        Rayfield:Notify({Title="Чертёж",Content="Персонаж не найден",Duration=3,Image=4483362458})
        return 
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then 
        Rayfield:Notify({Title="Чертёж",Content="RootPart не найден",Duration=3,Image=4483362458})
        return 
    end
    
    -- Ищем ближайший чертеж
    local closestBlueprint = nil
    local minDistance = math.huge
    
    for _, item in ipairs(workspace:GetDescendants()) do
        if item.Name == "BlueprintItem" then
            local position = nil
            if item:IsA("BasePart") then
                position = item.Position
            elseif item:IsA("Model") and item.PrimaryPart then
                position = item.PrimaryPart.Position
            end
            
            if position then
                local distance = (root.Position - position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    closestBlueprint = item
                end
            end
        end
    end
    
    if not closestBlueprint then
        Rayfield:Notify({Title="Чертёж",Content="Чертёж не найден!",Duration=3,Image=4483362458})
        return
    end
    
    -- Определяем позицию чертежа
    local targetPos = nil
    if closestBlueprint:IsA("BasePart") then
        targetPos = closestBlueprint.Position
    elseif closestBlueprint:IsA("Model") and closestBlueprint.PrimaryPart then
        targetPos = closestBlueprint.PrimaryPart.Position
    end
    
    if not targetPos then return end
    
    -- Отключаем коллизии
    local originalCollisions = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            originalCollisions[part] = part.CanCollide
            part.CanCollide = false
        end
    end
    
    -- Телепортируемся к чертежу
    local originalPosition = root.CFrame
    root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
    task.wait(0.2)
    root.CFrame = CFrame.new(targetPos)
    task.wait(0.2)
    
    -- Возвращаем коллизии и позицию
    root.CFrame = originalPosition
    for part, collide in pairs(originalCollisions) do
        if part:IsA("BasePart") and part.Parent then
            part.CanCollide = collide
        end
    end
    
    Rayfield:Notify({
        Title="Чертёж",
        Content="Чертёж собран!",
        Duration=3,
        Image=4483362458
    })
end

-- ====================================================================
-- UI: вкладка LocalPlayer (первая вкладка)
-- ====================================================================
local PlayerTab = Window:CreateTab("LocalPlayer", 4483362458)
PlayerTab:CreateSection("Скорость")
PlayerTab:CreateSlider({
    Name = "Скорость",
    Range = {16,100}, Increment=1, Suffix="ед.",
    CurrentValue = state.speed,
    Callback = function(v) state.speed = v applySettings() end
})
PlayerTab:CreateToggle({
    Name = "Поменять скорость",
    CurrentValue = state.speedToggle,
    Callback = function(v) state.speedToggle = v applySettings() end
})

PlayerTab:CreateSection("Прыжок")
PlayerTab:CreateSlider({
    Name = "Прыжок",
    Range = {50,200}, Increment=1, Suffix="ед.",
    CurrentValue = state.jump,
    Callback = function(v) state.jump = v applySettings() end
})
PlayerTab:CreateToggle({
    Name = "Поменять прыжок",
    CurrentValue = state.jumpToggle,
    Callback = function(v) state.jumpToggle = v applySettings() end
})

PlayerTab:CreateSection("Гравитация")
PlayerTab:CreateSlider({
    Name = "Гравитация",
    Range = {0,192}, Increment=1, Suffix="ед.",
    CurrentValue = state.gravity,
    Callback = function(v) state.gravity = v applySettings() end
})
PlayerTab:CreateToggle({
    Name = "Поменять гравитацию",
    CurrentValue = state.gravityToggle,
    Callback = function(v) state.gravityToggle = v applySettings() end
})

PlayerTab:CreateSection("Поле зрения")
PlayerTab:CreateSlider({
    Name = "Поле зрения",
    Range = {50,120}, Increment=1, Suffix="ед.",
    CurrentValue = state.fov,
    Callback = function(v) state.fov = v if state.fovToggle then applySettings() end end
})
PlayerTab:CreateToggle({
    Name = "Поменять поле зрения",
    CurrentValue = state.fovToggle,
    Callback = function(v) state.fovToggle = v applySettings() end
})

PlayerTab:CreateSection("Ноуклип")
PlayerTab:CreateToggle({
    Name = "Ноуклип",
    CurrentValue = state.noclip,
    Callback = function(v) state.noclip = v end
})

PlayerTab:CreateSection("Бесконечные прыжки")
PlayerTab:CreateToggle({
    Name = "Inf Jump",
    CurrentValue = state.infJump,
    Callback = function(v) state.infJump = v end
})

PlayerTab:CreateSection("Fly")
PlayerTab:CreateSlider({
    Name = "Скорость флая",
    Range = {15,100}, Increment=1, Suffix="ед.",
    CurrentValue = state.flySpeed,
    Callback = function(v) state.flySpeed = v end
})
PlayerTab:CreateToggle({
    Name = "Fly",
    CurrentValue = state.fly,
    Callback = function(v) state.fly = v end
})

PlayerTab:CreateSection("Авто-голосование")
PlayerTab:CreateDropdown({
    Name = "Карты",
    Options = {"House","Station","Gallery","Forest","School","Hospital","Metro","Carnival","City","Mall","Outpost","DistortedMemory","Plant"},
    CurrentOption = {state.mapChoice},
    MultipleOptions = false,
    Callback = function(opt) state.mapChoice = opt[1]; state.votedMap = false end
})
PlayerTab:CreateToggle({
    Name = "Авто-голосование карты",
    CurrentValue = state.mapToggle,
    Callback = function(v) state.mapToggle = v; if v then state.votedMap = false end end
})
PlayerTab:CreateDropdown({
    Name = "Моды",
    Options = {"Bot","Player","PlayerBot","Infection","Traitor","Swarm","Tag"},
    CurrentOption = {state.modeChoice},
    MultipleOptions = false,
    Callback = function(opt) state.modeChoice = opt[1]; state.votedMode = false end
})
PlayerTab:CreateToggle({
    Name = "Авто-голосование мода",
    CurrentValue = state.modeToggle,
    Callback = function(v) state.modeToggle = v; if v then state.votedMode = false end end
})

-- ====================================================================
-- UI: вкладка Утилиты (вторая вкладка)
-- ====================================================================
local UtilitiesTab = Window:CreateTab("Утилиты", 4483362458)
UtilitiesTab:CreateSection("Fullbright / Fog")
UtilitiesTab:CreateToggle({
    Name = "Вкл освещение + Выкл туман",
    CurrentValue = state.fullbright,
    Callback = function(v) 
        state.fullbright = v 
        if not v then
            game.Lighting.Ambient = lightingDefaults.ambient
            game.Lighting.FogStart = lightingDefaults.fogStart
            game.Lighting.FogEnd = lightingDefaults.fogEnd
        end
    end
})

UtilitiesTab:CreateSection("Blueprints")
UtilitiesTab:CreateButton({
    Name = "Собрать чертёж",
    Callback = collectBlueprints
})

UtilitiesTab:CreateSection("Doors & Folders")
UtilitiesTab:CreateToggle({
    Name = "Убрать двери и папки",
    CurrentValue = state.removeDoors,
    Callback = function(v)
        state.removeDoors = v
        manageUtilities()
    end
})
UtilitiesTab:CreateToggle({
    Name = "Убрать сейф двери",
    CurrentValue = state.removeSafes,
    Callback = function(v)
        state.removeSafes = v
        manageUtilities()
    end
})

-- ====================================================================
-- UI: вкладка Телепортация (третья вкладка)
-- ====================================================================
local TeleportTab = Window:CreateTab("Телепортация", 4483362458)
TeleportTab:CreateSection("Список игроков")
local function getPlayerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(t, p.Name) end
    end
    return t
end
local Dropdown = TeleportTab:CreateDropdown({
    Name = "Игроки",
    Options = getPlayerNames(),
    CurrentOption = getPlayerNames()[1] or "",
    MultipleOptions = false,
    Callback = function() end
})
local function refreshPlayerDropdown()
    local opts = getPlayerNames()
    Dropdown:Refresh(opts, true)
    local cur = Dropdown:GetCurrentOption()
    if not table.find(opts, cur) then
        Dropdown:SetOption(opts[1] or "")
    end
end
task.spawn(function()
    while true do
        refreshPlayerDropdown()
        task.wait(2)
    end
end)
TeleportTab:CreateButton({
    Name = "Телепорт к игроку",
    Callback = function()
        local sel = Dropdown:GetCurrentOption()
        if sel and sel ~= "" then
            local pl = Players:FindFirstChild(sel)
            if pl and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
               and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                LP.Character.HumanoidRootPart.CFrame = pl.Character.HumanoidRootPart.CFrame
            else
                Rayfield:Notify({Title="Ошибка",Content="Игрок не доступен",Duration=3,Image=4483362458})
            end
        else
            Rayfield:Notify({Title="Ошибка",Content="Выберите игрока",Duration=3,Image=4483362458})
        end
    end
})

-- ====================================================================
-- Hook CharacterAdded для сохранения состояний
-- ====================================================================
LP.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid").Died:Connect(function()
        -- сохраняем toggles
        state.speedToggle   = state.speedToggle
        state.jumpToggle    = state.jumpToggle
        state.gravityToggle = state.gravityToggle
        state.fovToggle     = state.fovToggle
    end)
    applySettings()
end)

-- Начальная инициализация
if LP.Character then applySettings() end
