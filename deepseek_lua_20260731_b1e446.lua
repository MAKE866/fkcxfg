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

local Tab1 = Window:CreateTab("ST封锁战线功能")
local Tab2 = Window:CreateTab("其它")
local Tab3 = Window:CreateTab("自动化")
local Tab4 = Window:CreateTab("选择特殊泰坦")
local Tab5 = Window:CreateTab("选择角色")
local Tab6 = Window:CreateTab("加入私服房")

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

Tab1:CreateToggle({
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

Tab1:CreateParagraph({ Title = "提 示", Content = "以下是丧尸2功能" })

local bState = false
local sGui = nil
local sBtn = nil

Tab1:CreateButton({
    Name = "一刀修罗",
    Ext = true,
    Callback = function()
        bState = not bState
        if bState then
            local Players = game:GetService("Players")
            local RS = game:GetService("ReplicatedStorage")
            local UIS = game:GetService("UserInputService")
            local SG = game:GetService("StarterGui")
            local LP = Players.LocalPlayer
            local PG = LP:WaitForChild("PlayerGui", 10)

            local sw = false
            local dStart, sPos
            local isDrag = false

            sGui = Instance.new("ScreenGui")
            sGui.Name = "SkillSwitchUI"
            sGui.ResetOnSpawn = false
            sGui.IgnoreGuiInset = true
            sGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            sGui.Parent = PG

            sBtn = Instance.new("TextButton")
            sBtn.Size = UDim2.new(0, 160, 0, 50)
            sBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
            sBtn.BackgroundColor3 = Color3.fromRGB(20, 120, 220)
            sBtn.TextColor3 = Color3.new(1, 1, 1)
            sBtn.Font = Enum.Font.SourceSansBold
            sBtn.TextSize = 18
            sBtn.Text = "开启一刀修罗"
            sBtn.Draggable = true
            sBtn.Visible = true
            sBtn.Parent = sGui

            sBtn.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Touch then
                    isDrag = true
                    dStart = i.Position
                    sPos = sBtn.AbsolutePosition
                end
            end)

            UIS.InputChanged:Connect(function(i)
                if isDrag and i.UserInputType == Enum.UserInputType.TouchMovement then
                    local d = i.Position - dStart
                    sBtn.Position = UDim2.new(0, sPos.X + d.X, 0, sPos.Y + d.Y)
                end
            end)

            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.TouchEnd then
                    isDrag = false
                end
            end)

            local function runSkill()
                task.spawn(function()
                    while task.wait(0.3) do
                        if not sw then break end
                        local args = { { Skill = "Kaijin" } }
                        pcall(function()
                            RS:WaitForChild("HeadCaptainOfCCTVSet"):FireServer(unpack(args))
                        end)
                    end
                end)
            end

            sBtn.MouseButton1Click:Connect(function()
                sw = not sw
                if sw then
                    sBtn.BackgroundColor3 = Color3.fromRGB(30, 180, 60)
                    sBtn.Text = "关闭一刀修罗"
                    runSkill()
                    SG:SetCore("SendNotification", {
                        Title = "功能提示",
                        Text = "已开启一刀修罗",
                        Duration = 2,
                        Icon = "rbxassetid://128981664025072"
                    })
                else
                    sBtn.BackgroundColor3 = Color3.fromRGB(20, 120, 220)
                    sBtn.Text = "开启一刀修罗"
                    SG:SetCore("SendNotification", {
                        Title = "功能提示",
                        Text = "已关闭一刀修罗",
                        Duration = 2,
                        Icon = "rbxassetid://128981664025072"
                    })
                end
            end)
            
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已生成一刀修罗悬浮开关", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            if sGui then
                sGui:Destroy()
                sGui = nil
                sBtn = nil
                StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已移除一刀修罗悬浮开关", Duration = 2, Icon = "rbxassetid://128981664025072" })
            end
        end
    end,
})

local zNames = {
    ["Mutated Zombie Scientist Toilet"] = true,
    ["Zombie Upgraded Titan Speaker V2"] = true,
    ["Z UTTV Tentacle"] = true
}
local zEsp = false
local zHandled = {}
local zAddConn = nil
local zDescConn = nil

local function clearZ()
    for _, o in ipairs(LocalPlayer:FindFirstChild("PlayerGui"):GetDescendants()) do
        if o:IsA("Highlight") and o.Name == "MonsterESP_HL" then o:Destroy() end
    end
    table.clear(zHandled)
end

local function addZ(m)
    if zHandled[m] then return end
    zHandled[m] = true
    local h = Instance.new("Highlight")
    h.Name = "MonsterESP_HL"
    h.Adornee = m
    h.FillTransparency = 1
    h.OutlineTransparency = 0
    h.OutlineColor = Color3.new(1, 1, 1)
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = LocalPlayer:FindFirstChild("PlayerGui")
    m.AncestryChanged:Connect(function(_, p)
        if not p then
            zHandled[m] = nil
            h:Destroy()
        end
    end)
end

local function scanZ()
    clearZ()
    if not zEsp then return end
    local living = Workspace:FindFirstChild("Living")
    if living then
        for _, m in ipairs(living:GetChildren()) do
            if m:IsA("Model") and zNames[m.Name] then task.spawn(addZ, m) end
        end
    end
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("Model") and o.Parent ~= living and zNames[o.Name] then task.spawn(addZ, o) end
    end
end

local livingF = Workspace:FindFirstChild("Living")
if livingF then
    zAddConn = livingF.ChildAdded:Connect(function(n)
        if not zEsp then return end
        if n:IsA("Model") and zNames[n.Name] then task.spawn(addZ, n) end
    end)
end

zDescConn = Workspace.DescendantAdded:Connect(function(n)
    if not zEsp then return end
    if n:IsA("Model") and n.Parent ~= livingF and zNames[n.Name] then task.spawn(addZ, n) end
end)

Tab1:CreateToggle({
    Name = "丧尸泰坦透视",
    CurrentValue = false,
    Flag = "ZombieEspToggle",
    Ext = true,
    Callback = function(v)
        zEsp = v
        if v then scanZ() else clearZ() end
        StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = v and "已开启丧尸泰坦透视" or "已关闭丧尸泰坦透视", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

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

Tab1:CreateButton({
    Name = "自动重生",
    Ext = true,
    Callback = function()
        local c = LocalPlayer.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            task.spawn(function()
                c.HumanoidRootPart.CFrame = CFrame.new(fPos)
                task.wait(0.3) 
                if cRemote then pcall(function() cRemote:FireServer(unpack(cArgs)) end) end
            end)
            StarterGui:SetCore("SendNotification", { Title = "功能提示", Text = "已执行自动重生", Duration = 2, Icon = "rbxassetid://128981664025072" })
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
        ReplicatedStorage.ForChangeCharacter:FireServer("Dark Speakerman", 3)
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

task.spawn(function()
    StarterGui:SetCore("SendNotification", { Title = "银狼脚本已加载", Text = " ", Duration = 3, Icon = "rbxassetid://128981664025072" })
    task.wait(3)
    StarterGui:SetCore("SendNotification", { Title = "每天周日更新", Text = " ", Duration = 3, Icon = "rbxassetid://128981664025072" })
    task.wait(3)
    StarterGui:SetCore("SendNotification", { Title = "感谢你的支持", Text = " ", Duration = 3, Icon = "rbxassetid://128981664025072" })
end)