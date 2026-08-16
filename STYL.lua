local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local idleConnection
local function setupAntiAFK()
    if idleConnection then return end
    idleConnection = LocalPlayer.Idled:Connect(function()
        task.wait(0.1)
        game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
    StarterGui:SetCore("SendNotification", { 
        Title = "反挂机已开启。", 
        Text = " ", 
        Duration = 3,
        Icon = "rbxassetid://128981664025072"
    })
end
setupAntiAFK()

local Window = Rayfield:CreateWindow({
    Name = "银狼脚本",
    LoadingTitle = "银狼脚本",
    LoadingSubtitle = "ST封锁战线",
    ShowText = "银狼脚本",
    Icon = 128981664025072, 
    Style = 3,
    DisableRayfieldPrompts = true, 
    ConfigurationSaving = { Enabled = false },
})

local Tab1 = Window:CreateTab("主要功能")
local Tab2 = Window:CreateTab("其它")
local Tab3 = Window:CreateTab("自动化")
local Tab4 = Window:CreateTab("选择特殊泰坦")
local Tab5 = Window:CreateTab("选择角色")
local Tab6 = Window:CreateTab("加入私服房")
local Tab7 = Window:CreateTab("ESP")
local Tab8 = Window:CreateTab("商店")
local Tab9 = Window:CreateTab("付费功能")

Tab1:CreateButton({
    Name = "复制休闲码",
    Ext = true,
    Callback = function()
        pcall(function()
            local codeToCopy = ReplicatedStorage:WaitForChild("DiffModeCode").Value
            setclipboard(codeToCopy)
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "休闲码已复制到剪贴板！", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end)
    end,
})

Tab1:CreateButton({
    Name = "随机服务器",
    Ext = true,
    Callback = function()
        local HttpService = game:GetService("HttpService")
        local TeleportService = game:GetService("TeleportService")
        local function getServers(placeId)
            local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=100"
            local success, response = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(url))
            end)
            if success and response and response.data then
                return response.data
            end
            return {}
        end
        local function teleportToRandomServer()
            local servers = getServers(game.PlaceId)
            if #servers == 0 then
                StarterGui:SetCore("SendNotification", { Title = "提示", Text = "没有找到可用的服务器", Duration = 2, Icon = "rbxassetid://128981664025072" })
                return
            end
            local randomServer = servers[math.random(1, #servers)]
            local targetServerId = randomServer.id
            TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServerId, LocalPlayer)
        end
        teleportToRandomServer()
    end,
})

Tab1:CreateToggle({
    Name = "背包界面",
    CurrentValue = false,
    Flag = "InventoryToggle",
    Ext = true,
    Callback = function(Value)
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local inv = playerGui:FindFirstChild("Inventory")
            if inv then
                inv.Enabled = Value
                StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = Value and "已开启背包界面" or "已关闭背包界面", Duration = 2, Icon = "rbxassetid://128981664025072" })
            else
                StarterGui:SetCore("SendNotification", { Title = "错误提示", Text = "找不到 Inventory 界面", Duration = 2, Icon = "rbxassetid://128981664025072" })
            end
        end
    end,
})

local spinLoopConnection = nil
Tab3:CreateToggle({
    Name = "自动百抽",
    CurrentValue = false,
    Flag = "AutoGachaToggle",
    Ext = true,
    Callback = function(Value)
        if Value then
            if not spinLoopConnection then
                spinLoopConnection = RunService.RenderStepped:Connect(function()
                    local Event = ReplicatedStorage.GachaSkins
                    Event:FireServer("100Spins")
                    task.wait(15)
                end)
                StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已开启自动百抽", Duration = 2, Icon = "rbxassetid://128981664025072" })
            end
        else
            if spinLoopConnection then
                spinLoopConnection:Disconnect()
                spinLoopConnection = nil
                StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已关闭自动百抽", Duration = 2, Icon = "rbxassetid://128981664025072" })
            end
        end
    end,
})

local function isShopOnMap()
    local shopBase = Workspace:FindFirstChild("HelicopterShop")
    if shopBase then
        local shopXDD = shopBase:FindFirstChild("ShopXDD")
        if shopXDD then
            local part = shopXDD:FindFirstChild("PartForShop")
            if part and part:IsA("BasePart") then
                local pos = part.Position
                local distance = math.sqrt((pos.X - 10.23)^2 + (pos.Y - 8.55)^2 + (pos.Z + 81.34)^2)
                return distance < 100
            end
        end
    end
    return false
end

local zombieJob = nil
local zombieRunning = false

local function stopZombie()
    zombieRunning = false
    if zombieJob then task.cancel(zombieJob); zombieJob = nil end
    local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if r then for _, c in ipairs(r:GetChildren()) do if c:IsA("BodyGyro") then c:Destroy() end end end
    StarterGui:SetCore("SendNotification", { Title = "自动化", Text = "丧尸刷级已停止", Duration = 2, Icon = "rbxassetid://128981664025072" })
end

Tab3:CreateToggle({
    Name = "自动刷级(丧尸)",
    CurrentValue = false,
    Flag = "ZombieFarmToggle",
    Ext = true,
    Callback = function(Value)
        if Value then
            if not zombieRunning then
                zombieRunning = true
                zombieJob = task.spawn(function()
                    while zombieRunning do
                        local attackEvent = ReplicatedStorage:WaitForChild("LMB")
                        local shopEvent = ReplicatedStorage:WaitForChild("ShopSystem")
                        local returnEvent = ReplicatedStorage:WaitForChild("ReturnToLobby")
                        local root, bg
                        local lockTarget = nil
                        local gyroConn = nil
                        local followConnection = nil

                        local function resetGyro()
                            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                            root = character:WaitForChild("HumanoidRootPart")
                            if root:FindFirstChild("BodyGyro") then root.BodyGyro:Destroy() end
                            bg = Instance.new("BodyGyro")
                            bg.MaxTorque = Vector3.new(1e8, 1e8, 1e8)
                            bg.P = 25000
                            bg.Parent = root
                        end

                        local function findTarget()
                            local livingFolder = Workspace:FindFirstChild("Living")
                            if not livingFolder then return nil end
                            for _, obj in pairs(livingFolder:GetChildren()) do
                                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                                    local humanoid = obj.Humanoid
                                    if humanoid.Health > 0 then
                                        local name = string.lower(obj.Name)
                                        if string.sub(name, 1, 6) == "zombie" then return obj end
                                    end
                                end
                            end
                            return nil
                        end

                        local function startAutoAttack()
                            if followConnection then return end
                            gyroConn = RunService.RenderStepped:Connect(function()
                                if lockTarget and lockTarget:FindFirstChild("HumanoidRootPart") then
                                    local targetRoot = lockTarget.HumanoidRootPart
                                    bg.CFrame = CFrame.lookAt(root.Position, targetRoot.Position - Vector3.new(0, 28, 0))
                                end
                            end)
                            followConnection = RunService.Heartbeat:Connect(function()
                                local targetModel = findTarget()
                                if not targetModel then lockTarget = nil return end
                                lockTarget = targetModel
                                local targetHrp = targetModel:FindFirstChild("HumanoidRootPart")
                                local char = LocalPlayer.Character
                                if not (char and root and targetHrp) then return end
                                local targetPos = targetHrp.Position
                                root.CFrame = CFrame.new(targetPos + Vector3.new(0, 11, 0), targetPos - Vector3.new(0, 28, 0))
                                if targetModel.Humanoid.Health > 0 then attackEvent:FireServer() end
                            end)
                        end

                        local function stopAutoAttack()
                            if followConnection then followConnection:Disconnect(); followConnection = nil end
                            if gyroConn then gyroConn:Disconnect(); gyroConn = nil end
                            lockTarget = nil
                        end

                        ReplicatedStorage:WaitForChild("Vote"):FireServer("Zombie")
                        if not zombieRunning then break end

                        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                        local humanoid = character:WaitForChild("Humanoid")
                        humanoid:Move(Vector3.new(0, 0, -1), true)
                        local startWait = tick()
                        while tick() - startWait < 10 and zombieRunning do task.wait() end
                        humanoid:Move(Vector3.new(0, 0, 0), true)
                        if not zombieRunning then break end

                        ReplicatedStorage:WaitForChild("GetReadyRemote"):FireServer("1", true)

                        resetGyro()
                        LocalPlayer.CharacterAdded:Connect(resetGyro)
                        startAutoAttack()

                        local helicopterCount = 0
                        local shopWasOnMap = false
                        while helicopterCount < 5 and zombieRunning do
                            task.wait(0.5)
                            local shopOnMap = isShopOnMap()
                            if shopOnMap and not shopWasOnMap then
                                helicopterCount = helicopterCount + 1
                                shopEvent:FireServer("Buy", "FillHP")
                            end
                            shopWasOnMap = shopOnMap
                        end
                        if not zombieRunning then break end

                        task.wait(1)
                        shopEvent:FireServer("Buy", "FillHP")
                        task.wait(2)
                        returnEvent:FireServer()

                        stopAutoAttack()
                        if not zombieRunning then break end
                        task.wait(10)
                    end
                end)
                StarterGui:SetCore("SendNotification", { Title = "自动化", Text = "丧尸模式已启动", Duration = 2, Icon = "rbxassetid://128981664025072" })
            end
        else
            stopZombie()
        end
    end,
})

local xJob = nil
local xRun = false

local function stopX()
    xRun = false
    if xJob then task.cancel(xJob); xJob = nil end
    local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if r then for _, c in ipairs(r:GetChildren()) do if c:IsA("BodyGyro") then c:Destroy() end end end
    StarterGui:SetCore("SendNotification", { Title = "自动化", Text = "圣诞模式已停止", Duration = 2, Icon = "rbxassetid://128981664025072" })
end

Tab3:CreateToggle({
    Name = "自动刷等级(圣诞)",
    CurrentValue = false,
    Flag = "XmasLoopToggle",
    Ext = true,
    Callback = function(Value)
        if Value then
            if not xRun then
                xRun = true
                xJob = task.spawn(function()
                    while xRun do
                        local attackEvent = ReplicatedStorage:WaitForChild("LMB")
                        local shopEvent = ReplicatedStorage:WaitForChild("ShopSystem")
                        local returnEvent = ReplicatedStorage:WaitForChild("ReturnToLobby")
                        local root, bg
                        local lockTarget = nil
                        local gyroConn = nil
                        local followConnection = nil

                        local function resetGyro()
                            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                            root = character:WaitForChild("HumanoidRootPart")
                            if root:FindFirstChild("BodyGyro") then root.BodyGyro:Destroy() end
                            bg = Instance.new("BodyGyro")
                            bg.MaxTorque = Vector3.new(1e8, 1e8, 1e8)
                            bg.P = 25000
                            bg.Parent = root
                        end

                        local function findTarget(targetType)
                            local livingFolder = Workspace:FindFirstChild("Living")
                            if not livingFolder then return nil end
                            for _, obj in pairs(livingFolder:GetChildren()) do
                                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                                    local humanoid = obj.Humanoid
                                    if humanoid.Health > 0 then
                                        local name = string.lower(obj.Name)
                                        if targetType == "speaker" and string.sub(name,1,7)=="speaker" then
                                            return obj
                                        elseif targetType == "rocket" and string.sub(name,1,6)=="rocket" then
                                            return obj
                                        elseif targetType == "snowsoldierrocket" and name == "snow soldier rocket toilet" then
                                            return obj
                                        elseif targetType == "snow" and string.sub(name,1,4)=="snow" and name ~= "snow soldier rocket toilet" then
                                            return obj
                                        end
                                    end
                                end
                            end
                            return nil
                        end

                        local function startAutoAttack()
                            if followConnection then return end
                            gyroConn = RunService.RenderStepped:Connect(function()
                                if lockTarget and lockTarget:FindFirstChild("HumanoidRootPart") then
                                    local targetRoot = lockTarget.HumanoidRootPart
                                    bg.CFrame = CFrame.lookAt(root.Position, targetRoot.Position - Vector3.new(0, 28, 0))
                                end
                            end)
                            followConnection = RunService.Heartbeat:Connect(function()
                                local targetModel = findTarget("speaker") or findTarget("rocket") or findTarget("snowsoldierrocket") or findTarget("snow")
                                if not targetModel then lockTarget = nil return end
                                lockTarget = targetModel
                                local targetHrp = targetModel:FindFirstChild("HumanoidRootPart")
                                local char = LocalPlayer.Character
                                if not (char and root and targetHrp) then return end
                                local targetPos = targetHrp.Position
                                root.CFrame = CFrame.new(targetPos + Vector3.new(0, 11, 0), targetPos - Vector3.new(0, 28, 0))
                                if targetModel.Humanoid.Health > 0 then attackEvent:FireServer() end
                            end)
                        end

                        local function stopAutoAttack()
                            if followConnection then followConnection:Disconnect(); followConnection = nil end
                            if gyroConn then gyroConn:Disconnect(); gyroConn = nil end
                            lockTarget = nil
                        end

                        ReplicatedStorage:WaitForChild("Vote"):FireServer("Christmas")
                        if not xRun then break end

                        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                        local humanoid = character:WaitForChild("Humanoid")
                        humanoid:Move(Vector3.new(0, 0, -1), true)
                        local startWait = tick()
                        while tick() - startWait < 10 and xRun do task.wait() end
                        humanoid:Move(Vector3.new(0, 0, 0), true)
                        if not xRun then break end

                        ReplicatedStorage:WaitForChild("GetReadyRemote"):FireServer("1", true)

                        resetGyro()
                        LocalPlayer.CharacterAdded:Connect(resetGyro)
                        startAutoAttack()

                        local helicopterCount = 0
                        local shopWasOnMap = false
                        while helicopterCount < 5 and xRun do
                            task.wait(0.5)
                            local shopOnMap = isShopOnMap()
                            if shopOnMap and not shopWasOnMap then
                                helicopterCount = helicopterCount + 1
                                shopEvent:FireServer("Buy", "FillHP")
                            end
                            shopWasOnMap = shopOnMap
                        end
                        if not xRun then break end

                        task.wait(1)
                        shopEvent:FireServer("Buy", "FillHP")
                        task.wait(2)
                        returnEvent:FireServer()

                        stopAutoAttack()
                        if not xRun then break end
                        task.wait(10)
                    end
                end)
                StarterGui:SetCore("SendNotification", { Title = "自动化", Text = "圣诞模式已启动", Duration = 2, Icon = "rbxassetid://128981664025072" })
            end
        else
            stopX()
        end
    end,
})

local aJob = nil
local aRun = false

local function stopA()
    aRun = false
    if aJob then task.cancel(aJob); aJob = nil end
    local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if r then for _, c in ipairs(r:GetChildren()) do if c:IsA("BodyVelocity") or c:IsA("BodyGyro") then c:Destroy() end end end
    StarterGui:SetCore("SendNotification", { Title = "自动化", Text = "天文模式已停止", Duration = 2, Icon = "rbxassetid://128981664025072" })
end

local function doA()
    local p = LocalPlayer
    local rs = ReplicatedStorage

    local buff = rs:WaitForChild("Buff")
    local vote = rs:WaitForChild("Vote")
    local ready = rs:WaitForChild("GetReadyRemote")

    local c = p.Character
    if not c then c = p.CharacterAdded:Wait() end
    local h = c:WaitForChild("HumanoidRootPart")
    local hum = c:WaitForChild("Humanoid")

    local keep = true
    local lastB = 0

    spawn(function()
        while keep and aRun do
            pcall(function()
                if c and hum and hum.Health > 0 then
                    if hum.Health <= hum.MaxHealth / 2 and tick() - lastB > 5 then
                        buff:FireServer()
                        lastB = tick()
                    end
                end
            end)
            task.wait(0.1)
            if not aRun then break end
        end
    end)

    local endV = tick() + 10
    while tick() < endV and aRun do
        vote:FireServer("AstroV2")
        task.wait()
    end
    if not aRun then return end

    ready:FireServer("1", true)
    local ws = tick()
    while tick() - ws < 71 and aRun do task.wait(1) end
    if not aRun then return end

    c = p.Character
    if not c then keep = false return end
    h = c:WaitForChild("HumanoidRootPart")

    local pts = {
        Vector3.new(-666.88, 296.16, -541.21),
        Vector3.new(490.00, 295.81, -541.63),
        Vector3.new(490.42, 296.16, 487.95),
        Vector3.new(-667.22, 296.21, 488.04)
    }
    local endP = Vector3.new(-22.88, 2.71, -1.34)
    local limit = 900
    local spd = 530
    local d = 5

    local bv = Instance.new("BodyVelocity", h)
    bv.MaxForce = Vector3.new(1e8, 1e8, 1e8)
    bv.Velocity = Vector3.zero
    bv.P = 20000

    local bg = Instance.new("BodyGyro", h)
    bg.MaxTorque = Vector3.new(1e8, 1e8, 1e8)
    bg.P = 20000
    bg.CFrame = h.CFrame

    local function go(t)
        local dis = (t - h.Position).Magnitude
        local stuck = 0
        while dis > d and aRun do
            local cur = h.Position
            local dir = (t - cur).Unit
            bv.Velocity = dir * spd
            local look = Vector3.new(dir.X, 0, dir.Z)
            if look.Magnitude > 0 then bg.CFrame = CFrame.lookAt(cur, cur + look) end
            task.wait()
            if not aRun then break end
            local nd = (t - h.Position).Magnitude
            if math.abs(nd - dis) < 0.5 then stuck = stuck + 1 else stuck = 0 end
            if stuck > 30 then break end
            dis = nd
        end
        bv.Velocity = Vector3.zero
    end

    local st = tick()
    while tick() - st < limit and aRun do
        for _, p in ipairs(pts) do
            go(p)
            if tick() - st >= limit or not aRun then break end
            task.wait(0.02)
        end
    end

    pcall(function() if bv then bv:Destroy() end end)
    pcall(function() if bg then bg:Destroy() end end)

    c = p.Character
    if c and c:FindFirstChild("HumanoidRootPart") then c.HumanoidRootPart.CFrame = CFrame.new(endP) end
    keep = false
end

Tab3:CreateToggle({
    Name = "自动通关天文模式",
    CurrentValue = false,
    Flag = "AutoLoopToggle",
    Ext = true,
    Callback = function(v)
        if v then
            if not aRun then
                aRun = true
                aJob = task.spawn(function() while aRun do doA(); if not aRun then break end; task.wait(5) end end)
                StarterGui:SetCore("SendNotification", { Title = "自动化", Text = "开跑了", Duration = 2, Icon = "rbxassetid://128981664025072" })
            end
        else
            stopA()
        end
    end,
})

local hEnabled = false
local hList = {}
local dLabels = {}
local hDistConn = nil
local hAddConn = nil

local function updateNames()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        t[p.Name] = true
        t[p.DisplayName] = true
    end
    return t
end

local pNames = updateNames()
Players.PlayerAdded:Connect(function() pNames = updateNames() end)
Players.PlayerRemoving:Connect(function() pNames = updateNames() end)

local function isPly(m)
    if not m or not m:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(m) then return true end
    if pNames[m.Name] then return true end
    if m == LocalPlayer.Character then return true end
    local h = m:FindFirstChild("Humanoid")
    if h and h:FindFirstChild("DisplayName") then return true end
    return false
end

local function addLbl(m)
    if dLabels[m] then return end
    local r = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart")
    if not r then return end
    local bb = Instance.new("BillboardGui")
    bb.Adornee = r
    bb.Size = UDim2.new(0, 120, 0, 40)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = m
    local n = Instance.new("TextLabel", bb)
    n.Size = UDim2.new(1, 0, 0.6, 0)
    n.Position = UDim2.new(0, 0, 0, 0)
    n.BackgroundTransparency = 1
    n.Text = m.Name
    n.TextColor3 = Color3.fromRGB(255, 255, 0)
    n.TextSize = 11
    n.Font = Enum.Font.GothamBold
    n.TextStrokeTransparency = 0.3
    n.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    local d = Instance.new("TextLabel", bb)
    d.Size = UDim2.new(1, 0, 0.4, 0)
    d.Position = UDim2.new(0, 0, 0.6, 0)
    d.BackgroundTransparency = 1
    d.Text = "0m"
    d.TextColor3 = Color3.fromRGB(200, 200, 200)
    d.TextSize = 9
    d.Font = Enum.Font.Gotham
    d.TextStrokeTransparency = 0.3
    d.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    dLabels[m] = {name = n, dist = d}
end

local function rmLbl(m)
    if dLabels[m] then
        local bb = dLabels[m].name.Parent
        if bb then bb:Destroy() end
        dLabels[m] = nil
    end
end

local function addHL(m)
    if hList[m] then return end
    if not m or not m:IsA("Model") then return end
    if isPly(m) then return end
    local h = m:FindFirstChildWhichIsA("Humanoid")
    if not h then return end
    if h.Health <= 0 then return end
    local hl = Instance.new("Highlight")
    hl.Adornee = m
    hl.FillColor = Color3.fromRGB(255, 255, 255)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.7
    hl.OutlineTransparency = 0.5
    hl.Parent = m
    hList[m] = hl
    addLbl(m)
end

local function rmHL(m)
    if hList[m] then
        hList[m]:Destroy()
        hList[m] = nil
    end
    rmLbl(m)
end

local function clearAll()
    for m, _ in pairs(hList) do rmHL(m) end
    for m, _ in pairs(dLabels) do rmLbl(m) end
end

local function scan()
    clearAll()
    if not hEnabled then return end
    pNames = updateNames()
    local living = Workspace:FindFirstChild("Living")
    if not living then return end
    for _, m in pairs(living:GetChildren()) do
        if m:IsA("Model") and not isPly(m) then addHL(m) end
    end
end

local function updDist()
    if not hEnabled then return end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for m, lbl in pairs(dLabels) do
        if lbl and lbl.dist and lbl.dist.Parent then
            local t = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart")
            if t then
                local d = (hrp.Position - t.Position).Magnitude
                lbl.dist.Text = string.format("%.1fm", d)
            end
        end
    end
end

local living = Workspace:FindFirstChild("Living")
if living then
    hAddConn = living.ChildAdded:Connect(function(c)
        task.wait(0.3)
        if hEnabled and c:IsA("Model") and not isPly(c) then addHL(c) end
    end)
end

local speedVal = 0
Tab1:CreateInput({
    Name = "CFrame移速",
    PlaceholderText = "", 
    RemoveTextAfterFocusLost = false,
    Callback = function(t)
        local n = tonumber(t)
        if n then speedVal = n else speedVal = 0 end
    end,
})
RunService.Stepped:Connect(function()
    if speedVal > 0 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local h = LocalPlayer.Character.HumanoidRootPart
        local d = LocalPlayer.Character.Humanoid.MoveDirection
        h.CFrame = h.CFrame + (d * speedVal)
    end
end)

local teleS = false
local fPos = Vector3.new(429.45, -620.79, 335.26)
local rPos = Vector3.new(1490.10, 5.45, 1315.10)
local cArgs = { "Head Captain Of The CCTV", 0 }
local cRemote
task.spawn(function() pcall(function() cRemote = ReplicatedStorage:WaitForChild("ForChangeCharacter", 5) end) end)
LocalPlayer.CharacterAdded:Connect(function(n)
    task.wait(0.3)
    if teleS and n:FindFirstChild("HumanoidRootPart") then
        n.HumanoidRootPart.CFrame = CFrame.new(rPos)
    end
end)

Tab1:CreateToggle({
    Name = "zuts远距离跟随",
    CurrentValue = false,
    Flag = "MonsterFollowToggle",
    Ext = true,
    Callback = function(v)
        if v then
            if not fConn then
                fConn = RunService.Heartbeat:Connect(function()
                    pcall(function()
                        local c = LocalPlayer.Character
                        if not c then return end
                        local h = c:FindFirstChild("HumanoidRootPart")
                        if not h then return end
                        local l = Workspace:FindFirstChild("Living")
                        if not l then return end
                        local t = l:FindFirstChild("Zombie Upgraded Titan Speaker V2")
                        if not t then return end
                        local th = t:FindFirstChild("HumanoidRootPart")
                        if not th then return end
                        h.CFrame = CFrame.new(th.Position + Vector3.new(90, 15, -130), th.Position)
                    end)
                end)
            end
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已开启zuts远距离跟随", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            if fConn then fConn:Disconnect(); fConn = nil end
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已关闭zuts远距离跟随", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

local fConn = nil

local missileLoopRunning = false
local missileJob = nil

Tab1:CreateToggle({
    Name = "删除导弹特效",
    CurrentValue = false,
    Flag = "DeleteMissileToggle",
    Ext = true,
    Callback = function(Value)
        if Value then
            if not missileLoopRunning then
                missileLoopRunning = true
                missileJob = task.spawn(function()
                    while missileLoopRunning do
                        local effectsFolder = Workspace:FindFirstChild("Effects")
                        if effectsFolder then
                            for _, v in ipairs(effectsFolder:GetChildren()) do
                                if v.Name == "MissileBOOM" then
                                    pcall(function() v:Destroy() end)
                                end
                            end
                        end
                        task.wait(0.1)
                    end
                end)
                StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已开启删除导弹特效", Duration = 2, Icon = "rbxassetid://128981664025072" })
            end
        else
            missileLoopRunning = false
            if missileJob then
                task.cancel(missileJob)
                missileJob = nil
            end
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已关闭删除导弹特效", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

Tab1:CreateToggle({
    Name = "自动重生",
    CurrentValue = false,
    Flag = "AutoRebirthToggle",
    Ext = true,
    Callback = function(Value)
        if Value then
            task.spawn(function()
                while Value do
                    local character = LocalPlayer.Character
                    if character then
                        local humanoid = character:FindFirstChild("Humanoid")
                        if humanoid and humanoid.Health < 10 and character:IsDescendantOf(Workspace:FindFirstChild("Living")) then
                            humanoid.Health = 0
                        end
                    end
                    task.wait(1)
                end
            end)
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已开启自动重生", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已关闭自动重生", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

local gSim = false
Tab2:CreateToggle({
    Name = "画质简化",
    CurrentValue = false,
    Flag = "GraphicsSimplifiedToggle",
    Ext = true,
    Callback = function(v)
        gSim = v
        if v then
            Lighting.GlobalShadows = false
            Lighting.ShadowSoftness = 0
            Lighting.Brightness = 2
            pcall(function()
                Lighting.Bloom.Enabled = false
                Lighting.Blur.Enabled = false
                Lighting.SunRays.Enabled = false
                Lighting.ColorCorrection.Enabled = false
                Lighting.DepthOfField.Enabled = false
            end)
            settings().Rendering.QualityLevel = 1
            pcall(function()
                Workspace.Terrain.WaterWaveSize = 0
                Workspace.Terrain.WaterWaveSpeed = 0
                Workspace.Terrain.WaterReflectance = 0
                Workspace.Terrain.WaterTransparency = 0.5
            end)
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已开启画质简化 (流畅模式)", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            Lighting.GlobalShadows = true
            Lighting.ShadowSoftness = 1
            Lighting.Brightness = 1
            pcall(function()
                Lighting.Bloom.Enabled = true
                Lighting.Blur.Enabled = true
                Lighting.SunRays.Enabled = true
                Lighting.ColorCorrection.Enabled = true
                Lighting.DepthOfField.Enabled = true
            end)
            settings().Rendering.QualityLevel = 10
            pcall(function()
                Workspace.Terrain.WaterWaveSize = 5
                Workspace.Terrain.WaterWaveSpeed = 10
                Workspace.Terrain.WaterReflectance = 0.5
                Workspace.Terrain.WaterTransparency = 0.5
            end)
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已关闭画质简化 (恢复原画质)", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

Tab2:CreateToggle({
    Name = "快速互动",
    CurrentValue = false,
    Flag = "QuickInteractToggle",
    Ext = true,
    Callback = function(v)
        if v then
            for _, p in ipairs(Workspace:GetDescendants()) do
                if p:IsA("ProximityPrompt") then p.HoldDuration = 0 end
            end
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已开启快速互动", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            for _, p in ipairs(Workspace:GetDescendants()) do
                if p:IsA("ProximityPrompt") then p.HoldDuration = 1 end
            end
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已关闭快速互动", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

local nvConn = nil
Tab2:CreateToggle({
    Name = "夜视",
    CurrentValue = false,
    Flag = "NightVisionToggle",
    Ext = true,
    Callback = function(v)
        if v then
            if not nvConn then nvConn = RunService.RenderStepped:Connect(function() Lighting.Ambient = Color3.new(1, 1, 1) end) end
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已开启夜视", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            if nvConn then nvConn:Disconnect(); nvConn = nil end
            Lighting.Ambient = Color3.new(0, 0, 0)
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已关闭夜视", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

local hNameEnabled = false
local hNameConn = nil

local function hideNameOnly()
    if not hNameEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if hum then hum.NameDisplayDistance = 0 end
    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("BillboardGui") then
            for _, child in pairs(obj:GetChildren()) do
                if child:IsA("TextLabel") and (child.Text == LocalPlayer.Name or child.Text == LocalPlayer.DisplayName) then
                    obj:Destroy()
                end
            end
        end
    end
end

local function restoreName()
    if not hNameEnabled then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if hum then hum.NameDisplayDistance = 10 end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if hNameEnabled then hideNameOnly() else restoreName() end
end)

Tab2:CreateToggle({
    Name = "隐藏名字(客户端)",
    CurrentValue = false,
    Flag = "HideNameToggle",
    Ext = true,
    Callback = function(v)
        hNameEnabled = v
        if v then
            hideNameOnly()
            if not hNameConn then
                hNameConn = task.spawn(function()
                    while hNameEnabled do
                        task.wait(0.5)
                        hideNameOnly()
                    end
                end)
            end
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已开启隐藏名字", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            hNameEnabled = false
            if hNameConn then task.cancel(hNameConn); hNameConn = nil end
            restoreName()
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已关闭隐藏名字", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

Tab2:CreateButton({
    Name = "重置人物（自杀）",
    Ext = true,
    Callback = function()
        local player = LocalPlayer
        if player and player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.Health = 0
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已执行重置人物", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            StarterGui:SetCore("SendNotification", { Title = "错误提示", Text = "未找到角色", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

Tab4:CreateSection("特殊泰坦")

Tab4:CreateButton({
    Name = "泰坦电视2.0",
    Ext = true,
    Callback = function()
        ReplicatedStorage.ForChangeCharacter:FireServer("Upgraded Titan TV", 1)
        StarterGui:SetCore("SendNotification", { Title = "角色切换", Text = "已切换至 泰坦电视2.0", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab4:CreateButton({
    Name = "泰坦音响2.0",
    Ext = true,
    Callback = function()
        ReplicatedStorage.ForChangeCharacter:FireServer("Upgraded Titan Speaker", 1)
        StarterGui:SetCore("SendNotification", { Title = "角色切换", Text = "已切换至 泰坦音响2.0", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab4:CreateButton({
    Name = "泰坦监控2.0",
    Ext = true,
    Callback = function()
        ReplicatedStorage.ForChangeCharacter:FireServer("Upgraded Titan Cameraman", 1)
        StarterGui:SetCore("SendNotification", { Title = "角色切换", Text = "已切换至 泰坦监控2.0", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab4:CreateButton({
    Name = "泰坦时钟",
    Ext = true,
    Callback = function()
        ReplicatedStorage.ForChangeCharacter:FireServer("Clock Titan", 0)
        StarterGui:SetCore("SendNotification", { Title = "角色切换", Text = "已切换至 泰坦时钟", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab4:CreateButton({
    Name = "x18",
    Ext = true,
    Callback = function()
        ReplicatedStorage.ForChangeCharacter:FireServer("G-Toilet Z", 0)
        StarterGui:SetCore("SendNotification", { Title = "角色切换", Text = "已切换至 x18", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab4:CreateButton({
    Name = "塞壬",
    Ext = true,
    Callback = function()
        ReplicatedStorage.ForChangeCharacter:FireServer("Siren Titan", 0)
        StarterGui:SetCore("SendNotification", { Title = "角色切换", Text = "已切换至 塞壬", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab5:CreateSection("角色")

Tab5:CreateButton({
    Name = "天文大电视",
    Ext = true,
    Callback = function()
        ReplicatedStorage.ForChangeCharacter:FireServer("Astro Large TV man", 0)
        StarterGui:SetCore("SendNotification", { Title = "角色切换", Text = "已切换至 天文大电视", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab5:CreateButton({
    Name = "故障",
    Ext = true,
    Callback = function()
        ReplicatedStorage.ForChangeCharacter:FireServer("Glitch Double plunger", 0)
        StarterGui:SetCore("SendNotification", { Title = "角色切换", Text = "已切换至 故障", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab5:CreateButton({
    Name = "反派",
    Ext = true,
    Callback = function()
        ReplicatedStorage.ForChangeCharacter:FireServer("Brown Camera man", 1)
        StarterGui:SetCore("SendNotification", { Title = "角色切换", Text = "已切换至 反派", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab5:CreateButton({
    Name = "音队",
    Ext = true,
    Callback = function()
        ReplicatedStorage.ForChangeCharacter:FireServer("Dark Speakerman", 2)
        StarterGui:SetCore("SendNotification", { Title = "角色切换", Text = "已切换至 音队", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab5:CreateButton({
    Name = "首席时钟",
    Ext = true,
    Callback = function()
        ReplicatedStorage.ForChangeCharacter:FireServer("Clock Man", 0)
        StarterGui:SetCore("SendNotification", { Title = "角色切换", Text = "已切换至 首席时钟", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab5:CreateButton({
    Name = "女三体",
    Ext = true,
    Callback = function()
        ReplicatedStorage.ForChangeCharacter:FireServer("Tri Soldier Athena (Girl)", 0)
        StarterGui:SetCore("SendNotification", { Title = "角色切换", Text = "已切换至 女三体", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab5:CreateButton({
    Name = "山本",
    Ext = true,
    Callback = function()
        ReplicatedStorage.ForChangeCharacter:FireServer("Head Captain Of The CCTV", 0)
        StarterGui:SetCore("SendNotification", { Title = "角色切换", Text = "已切换至 山本", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab5:CreateButton({
    Name = "普罗米修斯",
    Ext = true,
    Callback = function()
        ReplicatedStorage.ForChangeCharacter:FireServer("Prometheus", 0)
        StarterGui:SetCore("SendNotification", { Title = "角色切换", Text = "已切换至 普罗米修斯", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab5:CreateButton({
    Name = "女监控2.0",
    Ext = true,
    Callback = function()
        ReplicatedStorage.ForChangeCharacter:FireServer("Camera woman 2.0", 0)
        StarterGui:SetCore("SendNotification", { Title = "角色切换", Text = "已切换至 女监控2.0", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab5:CreateButton({
    Name = "DJ2.0",
    Ext = true,
    Callback = function()
        ReplicatedStorage.ForChangeCharacter:FireServer("DJ Toilet 2.0", 0)
        StarterGui:SetCore("SendNotification", { Title = "角色切换", Text = "已切换至 DJ2.0", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab6:CreateButton({
    Name = "点击进入私服",
    Ext = true,
    Callback = function()
        pcall(function()
            ReplicatedStorage.VIPServer:FireServer("Join", "TLSophvrRP")
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已尝试加入私服代码: TLSophvrRP", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end)
    end,
})

Tab7:CreateToggle({
    Name = "透视ST角色",
    CurrentValue = false,
    Flag = "NpcHighlightToggle",
    Ext = true,
    Callback = function(v)
        hEnabled = v
        if v then
            if not hDistConn then hDistConn = RunService.Heartbeat:Connect(updDist) end
            scan()
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已开启透视ST角色", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            clearAll()
            if hDistConn then hDistConn:Disconnect(); hDistConn = nil end
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已关闭透视ST角色", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

local playerEspEnabled = false
local playerEspConnections = {}
local playerEspScanLoop = nil

local function getPlayerFromCharacter(character)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character == character then
            return player
        end
    end
    return nil
end

local function createBillboard(character, player)
    local head = character:FindFirstChild("Head")
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerInfo"
    billboard.Size = UDim2.new(0, 120, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 10000
    billboard.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0.4, 0)
    distLabel.Position = UDim2.new(0, 0, 0.6, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0m"
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distLabel.TextSize = 9
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextStrokeTransparency = 0.3
    distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distLabel.Parent = billboard

    return {billboard = billboard, name = nameLabel, dist = distLabel}
end

local function createHighlight(character, player)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "PlayerESP"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    return highlight
end

local function removeESP(character)
    local highlight = character:FindFirstChild("PlayerESP")
    if highlight then highlight:Destroy() end

    local head = character:FindFirstChild("Head")
    if head then
        local billboard = head:FindFirstChild("PlayerInfo")
        if billboard then billboard:Destroy() end
    end
end

local function handleLivingCharacter(character)
    local player = getPlayerFromCharacter(character)
    if not player then return end

    if character:FindFirstChild("PlayerESP") then return end

    task.wait(0.2)
    createHighlight(character, player)
    createBillboard(character, player)
end

local function scanLiving()
    local livingFolder = Workspace:FindFirstChild("Living")
    if not livingFolder then return end

    for _, character in ipairs(livingFolder:GetChildren()) do
        if character:IsA("Model") and character:FindFirstChild("Humanoid") then
            handleLivingCharacter(character)
        end
    end
end

local function updatePlayerDistances()
    if not playerEspEnabled then return end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local livingFolder = Workspace:FindFirstChild("Living")
    if not livingFolder then return end

    for _, character in ipairs(livingFolder:GetChildren()) do
        if character:IsA("Model") then
            local head = character:FindFirstChild("Head")
            if head then
                local billboard = head:FindFirstChild("PlayerInfo")
                if billboard then
                    local distLabel = billboard:FindFirstChild("TextLabel")
                    if distLabel and distLabel.Position == UDim2.new(0, 0, 0.6, 0) then
                        local targetPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("BasePart")
                        if targetPart then
                            local dist = (hrp.Position - targetPart.Position).Magnitude
                            distLabel.Text = string.format("%.1fm", dist)
                        end
                    end
                end
            end
        end
    end
end

local function setupLivingWatcher()
    if not playerEspEnabled then return end
    local livingFolder = Workspace:FindFirstChild("Living")
    if not livingFolder then
        local conn = Workspace.ChildAdded:Connect(function(child)
            if child.Name == "Living" then
                setupLivingWatcher()
            end
        end)
        table.insert(playerEspConnections, conn)
        return
    end

    scanLiving()

    local addConn = livingFolder.ChildAdded:Connect(function(character)
        if character:IsA("Model") and character:FindFirstChild("Humanoid") then
            handleLivingCharacter(character)
        end
    end)
    table.insert(playerEspConnections, addConn)

    local remConn = livingFolder.ChildRemoved:Connect(function(character)
        removeESP(character)
    end)
    table.insert(playerEspConnections, remConn)
end

local function clearPlayerESP()
    if playerEspScanLoop then
        task.cancel(playerEspScanLoop)
        playerEspScanLoop = nil
    end
    for _, conn in ipairs(playerEspConnections) do
        pcall(function() conn:Disconnect() end)
    end
    playerEspConnections = {}
    local livingFolder = Workspace:FindFirstChild("Living")
    if livingFolder then
        for _, character in ipairs(livingFolder:GetChildren()) do
            removeESP(character)
        end
    end
end

Tab7:CreateToggle({
    Name = "玩家透视",
    CurrentValue = false,
    Flag = "PlayerEspToggle",
    Ext = true,
    Callback = function(Value)
        playerEspEnabled = Value
        if Value then
            clearPlayerESP()
            setupLivingWatcher()
            playerEspScanLoop = task.spawn(function()
                while playerEspEnabled do
                    task.wait(0.5)
                    updatePlayerDistances()
                end
            end)
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已开启玩家透视", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            clearPlayerESP()
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已关闭玩家透视", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

local playerDisplayEnabled = false
local displayKeepAliveLoop = nil
local displayUpdateLoop = nil

local function destroyDisplayUI()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local screenGui = playerGui:FindFirstChild("PlayerCountUI")
        if screenGui then
            screenGui:Destroy()
        end
    end
end

local function createDisplayUI()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PlayerCountUI"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local aliveLabel = Instance.new("TextLabel")
    aliveLabel.Name = "AliveLabel"
    aliveLabel.Size = UDim2.new(0, 100, 0, 22)
    aliveLabel.Position = UDim2.new(1, -105, 0, 5)
    aliveLabel.BackgroundTransparency = 1
    aliveLabel.Text = "存活: 0"
    aliveLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    aliveLabel.Font = Enum.Font.SourceSansBold
    aliveLabel.TextSize = 14
    aliveLabel.TextStrokeTransparency = 0
    aliveLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    aliveLabel.TextXAlignment = Enum.TextXAlignment.Right
    aliveLabel.Parent = screenGui

    local downedLabel = Instance.new("TextLabel")
    downedLabel.Name = "DownedLabel"
    downedLabel.Size = UDim2.new(0, 100, 0, 22)
    downedLabel.Position = UDim2.new(1, -105, 0, 27)
    downedLabel.BackgroundTransparency = 1
    downedLabel.Text = "倒地: 0"
    downedLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    downedLabel.Font = Enum.Font.SourceSansBold
    downedLabel.TextSize = 14
    downedLabel.TextStrokeTransparency = 0
    downedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    downedLabel.TextXAlignment = Enum.TextXAlignment.Right
    downedLabel.Parent = screenGui
    
    return screenGui
end

local function updateCounts()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end
    local screenGui = playerGui:FindFirstChild("PlayerCountUI")
    if not screenGui then return end
    
    local aliveLabel = screenGui:FindFirstChild("AliveLabel")
    local downedLabel = screenGui:FindFirstChild("DownedLabel")
    if not aliveLabel or not downedLabel then return end
    
    pcall(function()
        local livingFolder = Workspace:FindFirstChild("Living")
        if not livingFolder then
            aliveLabel.Text = "存活: 0"
            downedLabel.Text = "倒地: 0"
            return
        end

        local aliveCount = 0
        local downedCount = 0

        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            local char = otherPlayer.Character
            if char and char:IsDescendantOf(livingFolder) then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local isDowned = false
                if hrp then
                    local reviveUI = hrp:FindFirstChild("ReviveUI")
                    if reviveUI then
                        isDowned = true
                    end
                end

                if isDowned then
                    downedCount = downedCount + 1
                else
                    aliveCount = aliveCount + 1
                end
            end
        end

        aliveLabel.Text = "存活: " .. aliveCount
        downedLabel.Text = "倒地: " .. downedCount
    end)
end

local function startDisplayUpdate()
    if displayUpdateLoop then return end
    displayUpdateLoop = task.spawn(function()
        while playerDisplayEnabled do
            updateCounts()
            task.wait(1)
        end
    end)
end

local function stopDisplayUpdate()
    if displayUpdateLoop then
        task.cancel(displayUpdateLoop)
        displayUpdateLoop = nil
    end
end

local function startDisplayKeepAlive()
    if displayKeepAliveLoop then return end
    displayKeepAliveLoop = task.spawn(function()
        while playerDisplayEnabled do
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                local screenGui = playerGui:FindFirstChild("PlayerCountUI")
                if not screenGui then
                    createDisplayUI()
                end
            end
            task.wait(0.5)
        end
    end)
end

local function stopDisplayKeepAlive()
    if displayKeepAliveLoop then
        task.cancel(displayKeepAliveLoop)
        displayKeepAliveLoop = nil
    end
end

Tab7:CreateToggle({
    Name = "玩家显示",
    CurrentValue = false,
    Flag = "PlayerDisplayToggle",
    Ext = true,
    Callback = function(Value)
        playerDisplayEnabled = Value
        if Value then
            destroyDisplayUI()
            createDisplayUI()
            startDisplayKeepAlive()
            startDisplayUpdate()
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已开启玩家显示", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            stopDisplayKeepAlive()
            stopDisplayUpdate()
            destroyDisplayUI()
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已关闭玩家显示", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

local gachaStatEnabled = false
local gachaStatScreenGui = nil
local gachaStatMainLabel = nil
local gachaStatTotal = {Common = 0, Epic = 0, Legendary = 0, Mythic = 0}
local gachaStatTotal100Spins = 0

local function createGachaStatUI()
    if gachaStatScreenGui then return end
    gachaStatScreenGui = Instance.new("ScreenGui")
    gachaStatScreenGui.Name = "GachaStatUI"
    gachaStatScreenGui.Parent = game:GetService("CoreGui")
    gachaStatScreenGui.DisplayOrder = 999
    gachaStatScreenGui.Enabled = true

    gachaStatMainLabel = Instance.new("TextLabel")
    gachaStatMainLabel.Size = UDim2.new(0.5, 0, 0.07, 0)
    gachaStatMainLabel.Position = UDim2.new(0.25, 0, 0.02, 0)
    gachaStatMainLabel.BackgroundTransparency = 1
    gachaStatMainLabel.TextColor3 = Color3.new(1, 1, 1)
    gachaStatMainLabel.TextScaled = true
    gachaStatMainLabel.Font = Enum.Font.Gotham
    gachaStatMainLabel.ZIndex = 10
    gachaStatMainLabel.Text = "普通:" .. gachaStatTotal.Common .. " 史诗:" .. gachaStatTotal.Epic .. " 传说:" .. gachaStatTotal.Legendary .. " 神话:" .. gachaStatTotal.Mythic
    gachaStatMainLabel.Parent = gachaStatScreenGui
end

local function destroyGachaStatUI()
    if gachaStatScreenGui then
        gachaStatScreenGui:Destroy()
        gachaStatScreenGui = nil
        gachaStatMainLabel = nil
    end
end

local function updateGachaStatLabel()
    if gachaStatMainLabel then
        gachaStatMainLabel.Text = "普通:" .. gachaStatTotal.Common .. " 史诗:" .. gachaStatTotal.Epic .. " 传说:" .. gachaStatTotal.Legendary .. " 神话:" .. gachaStatTotal.Mythic
    end
end

local gachaStatConnection = nil
local function setupGachaStatListener()
    if gachaStatConnection then return end
    local GachaCharacter = ReplicatedStorage:FindFirstChild("GachaCharacter")
    if not GachaCharacter then return end
    gachaStatConnection = GachaCharacter.OnClientEvent:Connect(function(data, ...)
        if type(data) ~= "table" then return end
        if not gachaStatEnabled then return end
        local counts = {}
        for _, item in ipairs(data) do
            local rarity = item[2]
            counts[rarity] = (counts[rarity] or 0) + 1
        end
        gachaStatTotal.Common = gachaStatTotal.Common + (counts["Common"] or 0)
        gachaStatTotal.Epic = gachaStatTotal.Epic + (counts["Epic"] or 0)
        gachaStatTotal.Legendary = gachaStatTotal.Legendary + (counts["Legendary"] or 0)
        gachaStatTotal.Mythic = gachaStatTotal.Mythic + (counts["Mythic"] or 0)
        updateGachaStatLabel()
    end)

    local oldFire = GachaCharacter.FireServer
    GachaCharacter.FireServer = function(self, ...)
        local args = {...}
        for _, arg in pairs(args) do
            if type(arg) == "string" and arg:lower():find("100") then
                gachaStatTotal100Spins = gachaStatTotal100Spins + 1
                if gachaStatEnabled then
                    StarterGui:SetCore("SendNotification", {
                        Title = "100抽统计",
                        Text = "已进行 " .. gachaStatTotal100Spins .. " 次100抽",
                        Duration = 4
                    })
                end
                break
            end
        end
        return oldFire(self, ...)
    end
end

Tab7:CreateToggle({
    Name = "抽奖统计显示",
    CurrentValue = false,
    Flag = "GachaStatToggle",
    Ext = true,
    Callback = function(Value)
        gachaStatEnabled = Value
        if Value then
            setupGachaStatListener()
            createGachaStatUI()
            updateGachaStatLabel()
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已开启抽奖统计显示", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            destroyGachaStatUI()
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已关闭抽奖统计显示", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

local matEnabled = false
local matHList = {}
local matDLabels = {}
local matDistConn = nil
local matScanConn = nil

local function isInteractable(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    if obj:FindFirstChildWhichIsA("ClickDetector") then return true end
    if obj:FindFirstChildWhichIsA("ProximityPrompt") then return true end
    return false
end

local function matAddLabel(obj)
    if matDLabels[obj] then return end
    if not obj or not obj:IsA("BasePart") then return end

    local bill = Instance.new("BillboardGui")
    bill.Adornee = obj
    bill.Size = UDim2.new(0, 150, 0, 45)
    bill.StudsOffset = Vector3.new(0, 2.5, 0)
    bill.AlwaysOnTop = true
    bill.MaxDistance = math.huge
    bill.Parent = obj

    local nameLabel = Instance.new("TextLabel", bill)
    nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = obj.Name
    nameLabel.TextColor3 = Color3.fromRGB(0, 162, 255)
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

    local distLabel = Instance.new("TextLabel", bill)
    distLabel.Size = UDim2.new(1, 0, 0.4, 0)
    distLabel.Position = UDim2.new(0, 0, 0.6, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0m"
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distLabel.TextSize = 9
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextStrokeTransparency = 0.3
    distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

    matDLabels[obj] = {name = nameLabel, dist = distLabel}
end

local function matRemoveLabel(obj)
    if matDLabels[obj] then
        local bill = matDLabels[obj].name.Parent
        if bill then bill:Destroy() end
        matDLabels[obj] = nil
    end
end

local function matAddHighlight(obj)
    if matHList[obj] then return end
    if not obj or not obj:IsA("BasePart") then return end
    if obj:FindFirstChild("Highlight_ESP") then return end

    local hl = Instance.new("Highlight")
    hl.Name = "Highlight_ESP"
    hl.Adornee = obj
    hl.FillColor = Color3.fromRGB(255, 255, 255)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.7
    hl.OutlineTransparency = 0.5
    hl.Parent = obj
    matHList[obj] = hl

    matAddLabel(obj)
end

local function matRemoveHighlight(obj)
    if matHList[obj] then
        matHList[obj]:Destroy()
        matHList[obj] = nil
    end
    matRemoveLabel(obj)
end

local function matClearAll()
    for obj, _ in pairs(matHList) do matRemoveHighlight(obj) end
    for obj, _ in pairs(matDLabels) do matRemoveLabel(obj) end
end

local function matScanInteractables()
    if not matEnabled then return end
    matClearAll()

    local count = 0
    for _, obj in pairs(Workspace:GetDescendants()) do
        if isInteractable(obj) then
            matAddHighlight(obj)
            count = count + 1
        end
    end
end

local function matUpdateDistances()
    if not matEnabled then return end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for obj, labels in pairs(matDLabels) do
        if labels and labels.dist and labels.dist.Parent and obj and obj.Parent then
            local pos = obj.Position
            if pos then
                local dist = (hrp.Position - pos).Magnitude
                labels.dist.Text = string.format("%.1fm", dist)
            end
        end
    end
end

local matAddConn = nil

Tab7:CreateToggle({
    Name = "材料透视",
    CurrentValue = false,
    Flag = "MaterialEspToggle",
    Ext = true,
    Callback = function(Value)
        matEnabled = Value
        if Value then
            matClearAll()
            if not matAddConn then
                matAddConn = Workspace.DescendantAdded:Connect(function(obj)
                    task.wait(0.1)
                    if matEnabled and isInteractable(obj) then
                        matAddHighlight(obj)
                    end
                end)
            end
            if not matDistConn then matDistConn = RunService.Heartbeat:Connect(matUpdateDistances) end
            if not matScanConn then matScanConn = RunService.Heartbeat:Connect(matScanInteractables) end
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已开启材料透视", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            if matAddConn then matAddConn:Disconnect(); matAddConn = nil end
            if matDistConn then matDistConn:Disconnect(); matDistConn = nil end
            if matScanConn then matScanConn:Disconnect(); matScanConn = nil end
            matClearAll()
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已关闭材料透视", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

local playerGui = LocalPlayer:WaitForChild("PlayerGui")

Tab8:CreateToggle({
    Name = "直升机商店",
    CurrentValue = false,
    Flag = "HeliShopToggle",
    Ext = true,
    Callback = function(Value)
        local target = playerGui:FindFirstChild("003-A")
        if target then
            target.Enabled = Value
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = Value and "已开启直升机商店" or "已关闭直升机商店", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            StarterGui:SetCore("SendNotification", { Title = "错误提示", Text = "未找到商店", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

Tab8:CreateToggle({
    Name = "泰坦电视2.0装备商店",
    CurrentValue = false,
    Flag = "TVShopToggle",
    Ext = true,
    Callback = function(Value)
        local target = playerGui:FindFirstChild("UpgradeTVShop")
        if target then
            target.Enabled = Value
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = Value and "已开启泰坦电视2.0装备商店" or "已关闭泰坦电视2.0装备商店", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            StarterGui:SetCore("SendNotification", { Title = "错误提示", Text = "未找到泰坦电视2.0装备商店", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

Tab8:CreateToggle({
    Name = "泰坦音响2.0装备商店",
    CurrentValue = false,
    Flag = "UTSMShopToggle",
    Ext = true,
    Callback = function(Value)
        local target = playerGui:FindFirstChild("ConfirmUTSM")
        if target then
            target.Enabled = Value
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = Value and "已开启泰坦音响2.0装备商店" or "已关闭泰坦音响2.0装备商店", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            StarterGui:SetCore("SendNotification", { Title = "错误提示", Text = "未找到泰坦音响2.0装备商店", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

Tab8:CreateToggle({
    Name = "泰坦监控2.0装备商店",
    CurrentValue = false,
    Flag = "CameraShopToggle",
    Ext = true,
    Callback = function(Value)
        local target = playerGui:FindFirstChild("UpgradeCameraShop")
        if target then
            target.Enabled = Value
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = Value and "已开启泰坦监控2.0装备商店" or "已关闭泰坦监控2.0装备商店", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            StarterGui:SetCore("SendNotification", { Title = "错误提示", Text = "未找到泰坦监控2.0装备商店", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

local isBuyingC4 = false
Tab8:CreateButton({
    Name = "导弹人装备升级",
    Ext = true,
    Callback = function()
        if isBuyingC4 then return end
        isBuyingC4 = true
        local nukeTitanSet = ReplicatedStorage:FindFirstChild("NukeTitanSet")
        if nukeTitanSet then
            pcall(function()
                nukeTitanSet:FireServer("BuyC4s")
            end)
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已购买 C4 装备", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            StarterGui:SetCore("SendNotification", { Title = "错误提示", Text = "未找到装备", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
        task.wait(1)
        isBuyingC4 = false
    end,
})

local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
UserInputService.MouseIconEnabled = false

local autoClickRunning = false
local autoClickJob = nil

local function tapGachaButton()
    local gacha = LocalPlayer:FindFirstChild("GachaMomment")
    if not gacha then return false end
    local absPos = gacha.AbsolutePosition
    local absSize = gacha.AbsoluteSize
    if absPos.X == 0 and absPos.Y == 0 then return false end
    local centerX = absPos.X + absSize.X / 2
    local centerY = absPos.Y + absSize.Y / 2
    local touchId = math.random(1000, 9999)
    VirtualInputManager:SendTouchEvent(touchId, 0, centerX, centerY)
    task.wait(0.02)
    VirtualInputManager:SendTouchEvent(touchId, 1, centerX, centerY)
    task.wait(0.02)
    VirtualInputManager:SendTouchEvent(touchId, 2, centerX, centerY)
    return true
end

Tab3:CreateToggle({
    Name = "自动点击抽奖",
    CurrentValue = false,
    Flag = "AutoClickGachaToggle",
    Ext = true,
    Callback = function(Value)
        if Value then
            if not autoClickRunning then
                autoClickRunning = true
                autoClickJob = task.spawn(function()
                    while autoClickRunning do
                        if not tapGachaButton() then
                            task.wait(0.5)
                        else
                            task.wait(0.05)
                        end
                    end
                end)
                StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已开启自动点击抽奖", Duration = 2, Icon = "rbxassetid://128981664025072" })
            end
        else
            autoClickRunning = false
            if autoClickJob then
                task.cancel(autoClickJob)
                autoClickJob = nil
            end
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已关闭自动点击抽奖", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

local whitelist = {"SA_BERROXY"}
local function checkIsWhitelisted()
    local name = LocalPlayer.Name
    local display = LocalPlayer.DisplayName
    for _, w in ipairs(whitelist) do
        if name == w or display == w then
            return true
        end
    end
    return false
end

Tab9:CreateButton({
    Name = "一刀修罗",
    Ext = true,
    Callback = function()
        if not checkIsWhitelisted() then
            StarterGui:SetCore("SendNotification", {
                Title = "付费功能",
                Text = "您无权使用此功能，仅限白名单用户",
                Duration = 3,
                Icon = "rbxassetid://128981664025072"
            })
            return
        end

        local existingUI = LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("SkillSwitchUI")
        if existingUI then
            existingUI:Destroy()
            StarterGui:SetCore("SendNotification", {
                Title = "付费功能",
                Text = "已关闭一刀修罗界面",
                Duration = 2,
                Icon = "rbxassetid://128981664025072"
            })
            return
        end

        local ScreenUI = Instance.new("ScreenGui")
        ScreenUI.Name = "SkillSwitchUI"
        ScreenUI.ResetOnSpawn = false
        ScreenUI.IgnoreGuiInset = true
        ScreenUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenUI.Parent = LocalPlayer:WaitForChild("PlayerGui")

        local SkillBtn = Instance.new("TextButton")
        SkillBtn.Size = UDim2.new(0, 160, 0, 50)
        SkillBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
        SkillBtn.BackgroundColor3 = Color3.fromRGB(20, 120, 220)
        SkillBtn.TextColor3 = Color3.new(1, 1, 1)
        SkillBtn.Font = Enum.Font.SourceSansBold
        SkillBtn.TextSize = 18
        SkillBtn.Text = "开启一刀修罗"
        SkillBtn.Draggable = true
        SkillBtn.Parent = ScreenUI

        local isDragging = false
        local dragStart, startPos
        SkillBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                isDragging = true
                dragStart = input.Position
                startPos = SkillBtn.AbsolutePosition
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if isDragging and input.UserInputType == Enum.UserInputType.TouchMovement then
                local delta = input.Position - dragStart
                SkillBtn.Position = UDim2.new(0, startPos.X + delta.X, 0, startPos.Y + delta.Y)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.TouchEnd then
                isDragging = false
            end
        end)

        local SkillSwitch = false
        local function RunSkill()
            task.spawn(function()
                while task.wait(0.3) do
                    if not SkillSwitch then break end
                    local args = {{Skill = "Kaijin"}}
                    pcall(function()
                        ReplicatedStorage:WaitForChild("HeadCaptainOfCCTVSet"):FireServer(unpack(args))
                    end)
                end
            end)
        end

        SkillBtn.MouseButton1Click:Connect(function()
            SkillSwitch = not SkillSwitch
            if SkillSwitch then
                SkillBtn.BackgroundColor3 = Color3.fromRGB(30, 180, 60)
                SkillBtn.Text = "关闭一刀修罗"
                RunSkill()
                StarterGui:SetCore("SendNotification", {
                    Title = "功能提示",
                    Text = "已开启一刀修罗",
                    Duration = 2
                })
            else
                SkillBtn.BackgroundColor3 = Color3.fromRGB(20, 120, 220)
                SkillBtn.Text = "开启一刀修罗"
                StarterGui:SetCore("SendNotification", {
                    Title = "功能提示",
                    Text = "已关闭一刀修罗",
                    Duration = 2
                })
            end
        end)

        StarterGui:SetCore("SendNotification", {
            Title = "付费功能",
            Text = "已开启一刀修罗界面",
            Duration = 2,
            Icon = "rbxassetid://128981664025072"
        })
    end,
})

task.spawn(function()
    StarterGui:SetCore("SendNotification", { Title = "已加载银狼脚本", Text = " ", Duration = 3, Icon = "rbxassetid://128981664025072" })
    task.wait(3)
    StarterGui:SetCore("SendNotification", { Title = "每天周日更新", Text = " ", Duration = 3, Icon = "rbxassetid://128981664025072" })
    task.wait(3)
    StarterGui:SetCore("SendNotification", { Title = "感谢你的支持", Text = " ", Duration = 3, Icon = "rbxassetid://128981664025072" })
end)