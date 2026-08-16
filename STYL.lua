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
    Name = "st封锁战线", 
    LoadingTitle = "st封锁战线", 
    LoadingSubtitle = "ST封锁战线",
    ShowText = "st封锁战线", 
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
    Name = "与监控2.0",
    Ext = true,
    Callback = function()
        ReplicatedStorage.ForChangeCharacter:FireServer("Camera woman 2.0", 0)
        StarterGui:SetCore("SendNotification", { Title = "角色切换", Text = "已切换至 与监控2.0", Duration = 2, Icon = "rbxassetid://128981664025072" })
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
    billboard.Size = UDim2.new(5, 0, 1, 0)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 10000
    billboard.Parent = head
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 12
    nameLabel.Parent = billboard
end

local function createHighlight(character, player)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "PlayerESP"
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    
    local function updateHighlightColor()
        if not humanoid or not humanoid.Parent then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local isDowned = false
        if humanoidRootPart then
            local reviveUI = humanoidRootPart:FindFirstChild("ReviveUI")
            if reviveUI then
                isDowned = true
            end
        end
        
        if player == Players.LocalPlayer then
            if isDowned then
                highlight.FillColor = Color3.fromRGB(100, 100, 100)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
            else
                highlight.FillColor = Color3.fromRGB(0, 255, 100)
                highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
            end
        else
            if isDowned then
                highlight.FillColor = Color3.fromRGB(100, 0, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 50, 50)
            else
                highlight.FillColor = Color3.fromRGB(255, 50, 50)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            end
        end
    end
    
    humanoid.HealthChanged:Connect(updateHighlightColor)
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        humanoidRootPart.ChildAdded:Connect(function(child)
            if child.Name == "ReviveUI" then
                updateHighlightColor()
            end
        end)
        humanoidRootPart.ChildRemoved:Connect(function(child)
            if child.Name == "ReviveUI" then
                updateHighlightColor()
            end
        end)
    end
    
    updateHighlightColor()
    
    createBillboard(character, player)
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
                    task.wait(3)
                    scanLiving()
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
            StarterGui:SetCore("SendNotification", { Title = "错误提示", Text = "找不到 003-A 界面", Duration = 2, Icon = "rbxassetid://128981664025072" })
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
            StarterGui:SetCore("SendNotification", { Title = "错误提示", Text = "找不到 UpgradeTVShop 界面", Duration = 2, Icon = "rbxassetid://128981664025072" })
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
            StarterGui:SetCore("SendNotification", { Title = "错误提示", Text = "请在局内使用", Duration = 2, Icon = "rbxassetid://128981664025072" })
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
            StarterGui:SetCore("SendNotification", { Title = "错误提示", Text = "请在局内使用", Duration = 2, Icon = "rbxassetid://128981664025072" })
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
            StarterGui:SetCore("SendNotification", { Title = "错误提示", Text = "找不到 NukeTitanSet 远程事件", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
        task.wait(1)
        isBuyingC4 = false
    end,
})

local GachaCharacter = ReplicatedStorage:FindFirstChild("GachaCharacter")
if GachaCharacter then
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = game:GetService("CoreGui")
    screenGui.DisplayOrder = 999

    local mainLabel = Instance.new("TextLabel")
    mainLabel.Size = UDim2.new(0.5, 0, 0.07, 0)
    mainLabel.Position = UDim2.new(0.25, 0, 0.02, 0)
    mainLabel.BackgroundTransparency = 1
    mainLabel.TextColor3 = Color3.new(1, 1, 1)
    mainLabel.TextScaled = true
    mainLabel.Font = Enum.Font.Gotham
    mainLabel.ZIndex = 10
    mainLabel.Text = "普通:0 史诗:0 传说:0 神话:0"
    mainLabel.Parent = screenGui

    local total = {Common = 0, Epic = 0, Legendary = 0, Mythic = 0}
    local total100Spins = 0

    GachaCharacter.OnClientEvent:Connect(function(data, ...)
        if type(data) ~= "table" then return end
        local counts = {}
        for _, item in ipairs(data) do
            local rarity = item[2]
            counts[rarity] = (counts[rarity] or 0) + 1
        end
        total.Common = total.Common + (counts["Common"] or 0)
        total.Epic = total.Epic + (counts["Epic"] or 0)
        total.Legendary = total.Legendary + (counts["Legendary"] or 0)
        total.Mythic = total.Mythic + (counts["Mythic"] or 0)
        mainLabel.Text = string.format("普通:%d 史诗:%d 传说:%d 神话:%d",
            total.Common, total.Epic, total.Legendary, total.Mythic)
    end)

    local oldFire = GachaCharacter.FireServer
    GachaCharacter.FireServer = function(self, ...)
        local args = {...}
        for _, arg in pairs(args) do
            if type(arg) == "string" and arg:lower():find("100") then
                total100Spins = total100Spins + 1
                StarterGui:SetCore("SendNotification", {
                    Title = "100抽统计",
                    Text = "已进行 " .. total100Spins .. " 次100抽",
                    Duration = 4
                })
                break
            end
        end
        return oldFire(self, ...)
    end
end

local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
UserInputService.MouseIconEnabled = false

local function tapScreen()
    local screenSize = Workspace.CurrentCamera.ViewportSize
    local centerX = screenSize.X / 2
    local centerY = screenSize.Y / 2
    local touchId = math.random(1000, 9999)
    VirtualInputManager:SendTouchEvent(touchId, 0, centerX, centerY)
    task.wait(0.02)
    VirtualInputManager:SendTouchEvent(touchId, 1, centerX, centerY)
    task.wait(0.02)
    VirtualInputManager:SendTouchEvent(touchId, 2, centerX, centerY)
end

Tab3:CreateToggle({
    Name = "自动点击抽奖",
    CurrentValue = false,
    Flag = "AutoClickGachaToggle",
    Ext = true,
    Callback = function(Value)
        local enabled = Value
        if enabled then
            task.spawn(function()
                while enabled do
                    local gachaMomment = LocalPlayer:FindFirstChild("GachaMomment")
                    if gachaMomment then
                        tapScreen()
                        task.wait(0.05)
                    else
                        task.wait(0.5)
                    end
                end
            end)
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已开启自动点击抽奖", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已关闭自动点击抽奖", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

task.spawn(function()
    StarterGui:SetCore("SendNotification", { Title = "st封锁战线已加载", Text = " ", Duration = 3, Icon = "rbxassetid://128981664025072" })
    task.wait(3)
    StarterGui:SetCore("SendNotification", { Title = "每天周日更新", Text = " ", Duration = 3, Icon = "rbxassetid://128981664025072" })
    task.wait(3)
    StarterGui:SetCore("SendNotification", { Title = "感谢你的支持", Text = " ", Duration = 3, Icon = "rbxassetid://128981664025072" })
end)