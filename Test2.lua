local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local DEBUG = {Enabled = true, Logs = {}}

local function DebugLog(category, message, level)
    level = level or "INFO"
    local timestamp = os.date("%H:%M:%S")
    local logMessage = string.format("[%s][%s][%s] %s", timestamp, level, category, message)
    table.insert(DEBUG.Logs, logMessage)
    if DEBUG.Enabled then
        if level == "ERROR" then warn(logMessage) else print(logMessage) end
    end
end

DebugLog("INIT", "Starting Script Hub initialization", "INFO")

local AntiSpam = {
    LastAction = {},
    Cooldowns = {Toggle = 0.3, Resize = 0.05, Drag = 0.05, Execute = 1.0, Category = 0.2}
}

local function CanPerformAction(actionName)
    local now = tick()
    local lastTime = AntiSpam.LastAction[actionName] or 0
    local cooldown = AntiSpam.Cooldowns[actionName] or 0.5
    if now - lastTime >= cooldown then
        AntiSpam.LastAction[actionName] = now
        return true
    end
    return false
end

local CONFIG = {
    Colors = {
        Primary = Color3.fromRGB(88, 101, 242),
        Secondary = Color3.fromRGB(114, 137, 218),
        Background = Color3.fromRGB(32, 34, 37),
        Surface = Color3.fromRGB(47, 49, 54),
        SurfaceHover = Color3.fromRGB(54, 57, 63),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(185, 187, 190),
        Success = Color3.fromRGB(67, 181, 129),
        Danger = Color3.fromRGB(237, 66, 69),
        Warning = Color3.fromRGB(250, 166, 26),
    },
    MinSize = {Width = 450, Height = 250},
    MaxSize = {Width = 1000, Height = 700},
    DefaultSize = {Width = 650, Height = 400},
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScriptHubGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local startupLoading = Instance.new("Frame")
startupLoading.Name = "StartupLoading"
startupLoading.Size = UDim2.new(1, 0, 1, 0)
startupLoading.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
startupLoading.BorderSizePixel = 0
startupLoading.ZIndex = 2000
startupLoading.Parent = screenGui

local startupTitle = Instance.new("TextLabel")
startupTitle.Size = UDim2.new(0, 500, 0, 70)
startupTitle.Position = UDim2.new(0.5, -250, 0.5, -100)
startupTitle.BackgroundTransparency = 1
startupTitle.Text = "SCRIPT HUB"
startupTitle.TextColor3 = CONFIG.Colors.Primary
startupTitle.Font = Enum.Font.GothamBold
startupTitle.TextSize = 48
startupTitle.Parent = startupLoading

local startupSubtitle = Instance.new("TextLabel")
startupSubtitle.Size = UDim2.new(0, 400, 0, 30)
startupSubtitle.Position = UDim2.new(0.5, -200, 0.5, -20)
startupSubtitle.BackgroundTransparency = 1
startupSubtitle.Text = "Loading, please wait..."
startupSubtitle.TextColor3 = CONFIG.Colors.TextSecondary
startupSubtitle.Font = Enum.Font.Gotham
startupSubtitle.TextSize = 16
startupSubtitle.Parent = startupLoading

local startupSpinner = Instance.new("Frame")
startupSpinner.Size = UDim2.new(0, 80, 0, 80)
startupSpinner.Position = UDim2.new(0.5, -40, 0.5, 50)
startupSpinner.BackgroundTransparency = 1
startupSpinner.Parent = startupLoading

for i = 1, 8 do
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.BackgroundColor3 = CONFIG.Colors.Primary
    dot.BorderSizePixel = 0
    local angle = math.rad((i - 1) * 45)
    local radius = 28
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    dot.Position = UDim2.new(0.5, x - 6, 0.5, y - 6)
    dot.BackgroundTransparency = 0.2 + (i - 1) * 0.1
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot
    dot.Parent = startupSpinner
end

local startupSpinConnection = RunService.RenderStepped:Connect(function()
    if not startupLoading.Parent then 
        return 
    end
    startupSpinner.Rotation = (startupSpinner.Rotation + 3) % 360
end)

task.delay(2, function()
    TweenService:Create(startupLoading, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    TweenService:Create(startupTitle, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    TweenService:Create(startupSubtitle, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    for _, dot in pairs(startupSpinner:GetChildren()) do
        if dot:IsA("Frame") then
            TweenService:Create(dot, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        end
    end
    task.wait(0.5)
    if startupSpinConnection then startupSpinConnection:Disconnect() end
    startupLoading:Destroy()
    DebugLog("STARTUP", "Startup loading completed", "INFO")
end)

local loadingScreen = Instance.new("Frame")
loadingScreen.Name = "LoadingScreen"
loadingScreen.Size = UDim2.new(1, 0, 1, 0)
loadingScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
loadingScreen.BackgroundTransparency = 1
loadingScreen.BorderSizePixel = 0
loadingScreen.Visible = false
loadingScreen.ZIndex = 1000
loadingScreen.Parent = screenGui

local loadingTitle = Instance.new("TextLabel")
loadingTitle.Size = UDim2.new(0, 400, 0, 60)
loadingTitle.Position = UDim2.new(0.5, -200, 0.5, -80)
loadingTitle.BackgroundTransparency = 1
loadingTitle.Text = "LOADING"
loadingTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
loadingTitle.Font = Enum.Font.GothamBold
loadingTitle.TextSize = 32
loadingTitle.TextTransparency = 1
loadingTitle.Parent = loadingScreen

local loadingDesc = Instance.new("TextLabel")
loadingDesc.Size = UDim2.new(0, 500, 0, 40)
loadingDesc.Position = UDim2.new(0.5, -250, 0.5, -10)
loadingDesc.BackgroundTransparency = 1
loadingDesc.Text = "Please wait while we are loading this program"
loadingDesc.TextColor3 = CONFIG.Colors.TextSecondary
loadingDesc.Font = Enum.Font.Gotham
loadingDesc.TextSize = 14
loadingDesc.TextWrapped = true
loadingDesc.TextTransparency = 1
loadingDesc.Parent = loadingScreen

local spinnerFrame = Instance.new("Frame")
spinnerFrame.Size = UDim2.new(0, 80, 0, 80)
spinnerFrame.Position = UDim2.new(0.5, -40, 0.5, 40)
spinnerFrame.BackgroundTransparency = 1
spinnerFrame.Parent = loadingScreen

for i = 1, 8 do
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.BackgroundColor3 = CONFIG.Colors.Primary
    dot.BorderSizePixel = 0
    dot.BackgroundTransparency = 1
    local angle = math.rad((i - 1) * 45)
    local radius = 28
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    dot.Position = UDim2.new(0.5, x - 6, 0.5, y - 6)
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot
    dot.Parent = spinnerFrame
end

local loadingSpinConnection = nil

local function showLoadingScreen()
    if not CanPerformAction("Loading") then return end
    loadingScreen.Visible = true
    TweenService:Create(loadingScreen, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
    TweenService:Create(loadingTitle, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    TweenService:Create(loadingDesc, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    
    for i, dot in pairs(spinnerFrame:GetChildren()) do
        if dot:IsA("Frame") then
            dot.BackgroundTransparency = 0.2 + (i - 1) * 0.1
        end
    end
    
    loadingSpinConnection = RunService.RenderStepped:Connect(function()
        if not loadingScreen.Visible then 
            if loadingSpinConnection then 
                loadingSpinConnection:Disconnect()
                loadingSpinConnection = nil
            end
            return 
        end
        spinnerFrame.Rotation = (spinnerFrame.Rotation + 3) % 360
    end)
    
    task.delay(3, function()
        hideLoadingScreen()
    end)
end

function hideLoadingScreen()
    TweenService:Create(loadingScreen, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    TweenService:Create(loadingTitle, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
    TweenService:Create(loadingDesc, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
    for _, dot in pairs(spinnerFrame:GetChildren()) do
        if dot:IsA("Frame") then
            TweenService:Create(dot, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        end
    end
    task.wait(0.2)
    loadingScreen.Visible = false
    if loadingSpinConnection then 
        loadingSpinConnection:Disconnect() 
        loadingSpinConnection = nil
    end
end

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 50, 0, 50)
toggleButton.Position = UDim2.new(0, 15, 0.5, -25)
toggleButton.BackgroundColor3 = CONFIG.Colors.Primary
toggleButton.BorderSizePixel = 0
toggleButton.Text = ""
toggleButton.AutoButtonColor = false
toggleButton.ZIndex = 100
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0.5, 0)
toggleCorner.Parent = toggleButton

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(255, 255, 255)
toggleStroke.Thickness = 2
toggleStroke.Transparency = 0.8
toggleStroke.Parent = toggleButton

local iconFrame = Instance.new("Frame")
iconFrame.Size = UDim2.new(1, 0, 1, 0)
iconFrame.BackgroundTransparency = 1
iconFrame.Parent = toggleButton

for i = 1, 3 do
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, 26, 0, 3)
    line.Position = UDim2.new(0.5, -13, 0, 15 + (i - 1) * 9)
    line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    line.BorderSizePixel = 0
    line.Parent = iconFrame
    local lineCorner = Instance.new("UICorner")
    lineCorner.CornerRadius = UDim.new(1, 0)
    lineCorner.Parent = line
end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, CONFIG.DefaultSize.Width, 0, CONFIG.DefaultSize.Height)
mainFrame.Position = UDim2.new(0.5, -CONFIG.DefaultSize.Width/2, 0.5, -CONFIG.DefaultSize.Height/2)
mainFrame.BackgroundColor3 = CONFIG.Colors.Background
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = CONFIG.Colors.Primary
mainStroke.Thickness = 2
mainStroke.Transparency = 1
mainStroke.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = CONFIG.Colors.Surface
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleBottom = Instance.new("Frame")
titleBottom.Size = UDim2.new(1, 0, 0, 12)
titleBottom.Position = UDim2.new(0, 0, 1, -12)
titleBottom.BackgroundColor3 = CONFIG.Colors.Surface
titleBottom.BorderSizePixel = 0
titleBottom.Parent = titleBar

local titleIcon = Instance.new("TextLabel")
titleIcon.Size = UDim2.new(0, 28, 0, 28)
titleIcon.Position = UDim2.new(0, 8, 0.5, -14)
titleIcon.BackgroundColor3 = CONFIG.Colors.Primary
titleIcon.Text = "📜"
titleIcon.TextSize = 14
titleIcon.Font = Enum.Font.GothamBold
titleIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
titleIcon.BorderSizePixel = 0
titleIcon.Parent = titleBar

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 6)
iconCorner.Parent = titleIcon

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -140, 1, 0)
titleLabel.Position = UDim2.new(0, 42, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "ROBLOX SCRIPT HUB"
titleLabel.TextColor3 = CONFIG.Colors.Text
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 28, 0, 28)
minimizeButton.Position = UDim2.new(1, -64, 0.5, -14)
minimizeButton.BackgroundColor3 = CONFIG.Colors.Warning
minimizeButton.Text = "−"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.TextSize = 16
minimizeButton.AutoButtonColor = false
minimizeButton.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minimizeButton

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 28, 0, 28)
closeButton.Position = UDim2.new(1, -32, 0.5, -14)
closeButton.BackgroundColor3 = CONFIG.Colors.Danger
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.AutoButtonColor = false
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -16, 1, -52)
contentContainer.Position = UDim2.new(0, 8, 0, 44)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

local categoryFrame = Instance.new("ScrollingFrame")
categoryFrame.Size = UDim2.new(0, 180, 1, 0)
categoryFrame.BackgroundColor3 = CONFIG.Colors.Surface
categoryFrame.BorderSizePixel = 0
categoryFrame.ScrollBarThickness = 4
categoryFrame.ScrollBarImageColor3 = CONFIG.Colors.Primary
categoryFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
categoryFrame.Parent = contentContainer

local catCorner = Instance.new("UICorner")
catCorner.CornerRadius = UDim.new(0, 8)
catCorner.Parent = categoryFrame

local categoryList = Instance.new("UIListLayout")
categoryList.Padding = UDim.new(0, 6)
categoryList.SortOrder = Enum.SortOrder.LayoutOrder
categoryList.Parent = categoryFrame

local catPadding = Instance.new("UIPadding")
catPadding.PaddingTop = UDim.new(0, 6)
catPadding.PaddingBottom = UDim.new(0, 6)
catPadding.PaddingLeft = UDim.new(0, 6)
catPadding.PaddingRight = UDim.new(0, 6)
catPadding.Parent = categoryFrame

local scriptContainer = Instance.new("Frame")
scriptContainer.Size = UDim2.new(1, -188, 1, 0)
scriptContainer.Position = UDim2.new(0, 188, 0, 0)
scriptContainer.BackgroundColor3 = CONFIG.Colors.Surface
scriptContainer.BorderSizePixel = 0
scriptContainer.Parent = contentContainer

local scriptCorner = Instance.new("UICorner")
scriptCorner.CornerRadius = UDim.new(0, 8)
scriptCorner.Parent = scriptContainer

local placeholderFrame = Instance.new("Frame")
placeholderFrame.Size = UDim2.new(1, 0, 1, 0)
placeholderFrame.BackgroundTransparency = 1
placeholderFrame.Parent = scriptContainer

local placeholderText = Instance.new("TextLabel")
placeholderText.Size = UDim2.new(1, -32, 0, 60)
placeholderText.Position = UDim2.new(0, 16, 0.5, -30)
placeholderText.BackgroundTransparency = 1
placeholderText.Text = "🎯\n\nSelect a category to view scripts"
placeholderText.TextColor3 = CONFIG.Colors.TextSecondary
placeholderText.Font = Enum.Font.Gotham
placeholderText.TextSize = 13
placeholderText.TextWrapped = true
placeholderText.Parent = placeholderFrame

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size = UDim2.new(1, -12, 1, -12)
contentFrame.Position = UDim2.new(0, 6, 0, 6)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 4
contentFrame.ScrollBarImageColor3 = CONFIG.Colors.Primary
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.Visible = false
contentFrame.Parent = scriptContainer

local contentList = Instance.new("UIListLayout")
contentList.Padding = UDim.new(0, 6)
contentList.SortOrder = Enum.SortOrder.LayoutOrder
contentList.Parent = contentFrame

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 4)
contentPadding.PaddingBottom = UDim.new(0, 4)
contentPadding.Parent = contentFrame

local function createHoverEffect(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = hoverColor}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = normalColor}):Play()
    end)
end

local selectedCategory = nil

local function createCategoryButton(name, icon, scripts)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 38)
    button.BackgroundColor3 = CONFIG.Colors.Background
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = categoryFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = button
    
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0.7, 0)
    indicator.Position = UDim2.new(0, 2, 0.15, 0)
    indicator.BackgroundColor3 = CONFIG.Colors.Primary
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.Parent = button
    
    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(1, 0)
    indCorner.Parent = indicator
    
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 26, 0, 26)
    iconLabel.Position = UDim2.new(0, 8, 0.5, -13)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextSize = 16
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextColor3 = CONFIG.Colors.TextSecondary
    iconLabel.Parent = button
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -65, 1, 0)
    textLabel.Position = UDim2.new(0, 38, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = name
    textLabel.TextColor3 = CONFIG.Colors.TextSecondary
    textLabel.Font = Enum.Font.GothamSemibold
    textLabel.TextSize = 12
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = button
    
    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 22, 0, 16)
    badge.Position = UDim2.new(1, -26, 0.5, -8)
    badge.BackgroundColor3 = CONFIG.Colors.Primary
    badge.Text = tostring(#scripts)
    badge.TextColor3 = Color3.fromRGB(255, 255, 255)
    badge.Font = Enum.Font.GothamBold
    badge.TextSize = 10
    badge.Parent = button
    
    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0.5, 0)
    badgeCorner.Parent = badge
    
    createHoverEffect(button, CONFIG.Colors.Background, CONFIG.Colors.SurfaceHover)
    
    button.MouseButton1Click:Connect(function()
        if not CanPerformAction("Category") then return end
        
        if selectedCategory then
            selectedCategory.Indicator.Visible = false
            selectedCategory.IconLabel.TextColor3 = CONFIG.Colors.TextSecondary
            selectedCategory.TextLabel.TextColor3 = CONFIG.Colors.TextSecondary
        end
        
        selectedCategory = {Indicator = indicator, IconLabel = iconLabel, TextLabel = textLabel}
        indicator.Visible = true
        iconLabel.TextColor3 = CONFIG.Colors.Primary
        textLabel.TextColor3 = CONFIG.Colors.Text
        
        for _, child in pairs(contentFrame:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        
        placeholderFrame.Visible = false
        contentFrame.Visible = true
        
        for i, scriptData in ipairs(scripts) do
            local scriptCard = Instance.new("Frame")
            scriptCard.Size = UDim2.new(1, 0, 0, 65)
            scriptCard.BackgroundColor3 = CONFIG.Colors.Background
            scriptCard.BorderSizePixel = 0
            scriptCard.Parent = contentFrame
            
            local cardCorner = Instance.new("UICorner")
            cardCorner.CornerRadius = UDim.new(0, 6)
            cardCorner.Parent = scriptCard
            
            local scriptName = Instance.new("TextLabel")
            scriptName.Size = UDim2.new(1, -100, 0, 20)
            scriptName.Position = UDim2.new(0, 10, 0, 8)
            scriptName.BackgroundTransparency = 1
            scriptName.Text = scriptData.name
            scriptName.TextColor3 = CONFIG.Colors.Text
            scriptName.Font = Enum.Font.GothamBold
            scriptName.TextSize = 12
            scriptName.TextXAlignment = Enum.TextXAlignment.Left
            scriptName.Parent = scriptCard
            
            local scriptDesc = Instance.new("TextLabel")
            scriptDesc.Size = UDim2.new(1, -100, 0, 30)
            scriptDesc.Position = UDim2.new(0, 10, 0, 28)
            scriptDesc.BackgroundTransparency = 1
            scriptDesc.Text = scriptData.description or "Click to run script"
            scriptDesc.TextColor3 = CONFIG.Colors.TextSecondary
            scriptDesc.Font = Enum.Font.Gotham
            scriptDesc.TextSize = 10
            scriptDesc.TextXAlignment = Enum.TextXAlignment.Left
            scriptDesc.TextWrapped = true
            scriptDesc.Parent = scriptCard
            
            local executeBtn = Instance.new("TextButton")
            executeBtn.Size = UDim2.new(0, 85, 0, 28)
            executeBtn.Position = UDim2.new(1, -90, 0.5, -14)
            executeBtn.BackgroundColor3 = CONFIG.Colors.Success
            executeBtn.Text = "▶ RUN"
            executeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            executeBtn.Font = Enum.Font.GothamBold
            executeBtn.TextSize = 10
            executeBtn.AutoButtonColor = false
            executeBtn.Parent = scriptCard
            
            local execCorner = Instance.new("UICorner")
            execCorner.CornerRadius = UDim.new(0, 5)
            execCorner.Parent = executeBtn
            
            createHoverEffect(executeBtn, CONFIG.Colors.Success, Color3.fromRGB(77, 191, 139))
            
            executeBtn.MouseButton1Click:Connect(function()
                if not CanPerformAction("Execute") then return end
                executeBtn.Text = "⏳..."
                executeBtn.BackgroundColor3 = CONFIG.Colors.Warning
                showLoadingScreen()
                task.spawn(function()
                    local success, err = pcall(function()
                        loadstring(game:HttpGet(scriptData.url, true))()
                    end)
                    task.wait(0.5)
                    if success then
                        executeBtn.Text = "✓ OK"
                        executeBtn.BackgroundColor3 = CONFIG.Colors.Success
                    else
                        executeBtn.Text = "✕ ERROR"
                        executeBtn.BackgroundColor3 = CONFIG.Colors.Danger
                    end
                    task.wait(1.5)
                    executeBtn.Text = "▶ RUN"
                    executeBtn.BackgroundColor3 = CONFIG.Colors.Success
                end)
            end)
        end
        
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentList.AbsoluteContentSize.Y + 8)
    end)
end

local scriptDatabase = {
    {category = "Pressure", icon = "🔥", scripts = {{name = "Nullfire Hub", description = "Official script hub", url = "https://rawscripts.net/raw/Pressure-WORKING-fire-hub-18064"}}},
    {category = "The Forge", icon = "⚒️", scripts = {{name = "Speed Hub X", description = "High-speed hub", url = "https://raw.githubusercontent.com/AhmadV99/Speed-Hub-X/main/Speed%20Hub%20X.lua"}}},
    {category = "Grow A Garden", icon = "🌱", scripts = {{name = "Speed Hub X", description = "High-speed hub", url = "https://raw.githubusercontent.com/AhmadV99/Speed-Hub-X/main/Speed%20Hub%20X.lua"}}}
}

for _, data in ipairs(scriptDatabase) do
    createCategoryButton(data.category, data.icon, data.scripts)
end

categoryFrame.CanvasSize = UDim2.new(0, 0, 0, categoryList.AbsoluteContentSize.Y + 12)

local toggleDragging = false
local toggleDragStart = nil
local toggleStartPos = nil
local toggleMoveThreshold = 10
local isTogglePressed = false

local function getInputPosition(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        return input.Position
    else
        return UserInputService:GetMouseLocation()
    end
end

toggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isTogglePressed = true
        toggleDragging = false
        toggleDragStart = getInputPosition(input)
        toggleStartPos = toggleButton.Position
        TweenService:Create(toggleButton, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 55, 0, 55)}):Play()
    end
end)

toggleButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(toggleButton, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 50, 0, 50)}):Play()
        if not toggleDragging then
            toggleGUI()
        end
        toggleDragging = false
        isTogglePressed = false
        toggleDragStart = nil
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isTogglePressed and toggleDragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local currentPos = getInputPosition(input)
        local delta = currentPos - toggleDragStart
        local distance = math.sqrt(delta.X * delta.X + delta.Y * delta.Y)
        
        if distance > toggleMoveThreshold then
            toggleDragging = true
            toggleButton.Position = UDim2.new(toggleStartPos.X.Scale, toggleStartPos.X.Offset + delta.X, toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + delta.Y)
        end
    end
end)

local isVisible = false

function toggleGUI()
    if not CanPerformAction("Toggle") then return end
    isVisible = not isVisible
    
    if isVisible then
        mainFrame.Visible = true
        mainFrame.BackgroundTransparency = 1
        mainStroke.Transparency = 1
        mainFrame.Size = UDim2.new(0, CONFIG.DefaultSize.Width * 0.8, 0, CONFIG.DefaultSize.Height * 0.8)
        mainFrame.Position = UDim2.new(0.5, -CONFIG.DefaultSize.Width * 0.4, 0.5, -CONFIG.DefaultSize.Height * 0.4)
        
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, CONFIG.DefaultSize.Width, 0, CONFIG.DefaultSize.Height),
            Position = UDim2.new(0.5, -CONFIG.DefaultSize.Width/2, 0.5, -CONFIG.DefaultSize.Height/2),
            BackgroundTransparency = 0
        }):Play()
        
        TweenService:Create(mainStroke, TweenInfo.new(0.3), {Transparency = 0.5}):Play()
    else
        TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, CONFIG.DefaultSize.Width * 0.8, 0, CONFIG.DefaultSize.Height * 0.8),
            BackgroundTransparency = 1
        }):Play()
        
        TweenService:Create(mainStroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
        
        task.wait(0.2)
        mainFrame.Visible = false
    end
end

local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil
local dragThreshold = 10
local hasMoved = false

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
        dragStart = getInputPosition(input)
        startPos = mainFrame.Position
        dragging = false
        hasMoved = false
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        dragInput = nil
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragInput and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local currentPos = getInputPosition(input)
        local delta = currentPos - dragStart
        local distance = math.sqrt(delta.X * delta.X + delta.Y * delta.Y)
        
        if distance > dragThreshold or hasMoved then
            dragging = true
            hasMoved = true
            if CanPerformAction("Drag") then
                mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end
end)

local resizing = false
local resizeCorner = nil
local resizeStart = nil
local resizeStartSize = nil
local resizeStartPos = nil
local resizeThreshold = 25

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local mousePos = getInputPosition(input)
        local framePos = mainFrame.AbsolutePosition
        local frameSize = mainFrame.AbsoluteSize
        local relX = mousePos.X - framePos.X
        local relY = mousePos.Y - framePos.Y
        
        if relX <= resizeThreshold and relY <= resizeThreshold then
            resizeCorner = "TopLeft"
        elseif relX >= frameSize.X - resizeThreshold and relY <= resizeThreshold then
            resizeCorner = "TopRight"
        elseif relX <= resizeThreshold and relY >= frameSize.Y - resizeThreshold then
            resizeCorner = "BottomLeft"
        elseif relX >= frameSize.X - resizeThreshold and relY >= frameSize.Y - resizeThreshold then
            resizeCorner = "BottomRight"
        else
            return
        end
        
        resizing = true
        resizeStart = mousePos
        resizeStartSize = mainFrame.Size
        resizeStartPos = mainFrame.Position
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
        resizeCorner = nil
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        if not CanPerformAction("Resize") then return end
        local currentPos = getInputPosition(input)
        local delta = currentPos - resizeStart
        local newWidth = resizeStartSize.X.Offset
        local newHeight = resizeStartSize.Y.Offset
        local newPosX = resizeStartPos.X.Offset
        local newPosY = resizeStartPos.Y.Offset
        
        if resizeCorner == "TopLeft" then
            newWidth = resizeStartSize.X.Offset - delta.X
            newHeight = resizeStartSize.Y.Offset - delta.Y
            newPosX = resizeStartPos.X.Offset + delta.X
            newPosY = resizeStartPos.Y.Offset + delta.Y
        elseif resizeCorner == "TopRight" then
            newWidth = resizeStartSize.X.Offset + delta.X
            newHeight = resizeStartSize.Y.Offset - delta.Y
            newPosY = resizeStartPos.Y.Offset + delta.Y
        elseif resizeCorner == "BottomLeft" then
            newWidth = resizeStartSize.X.Offset - delta.X
            newHeight = resizeStartSize.Y.Offset + delta.Y
            newPosX = resizeStartPos.X.Offset + delta.X
        elseif resizeCorner == "BottomRight" then
            newWidth = resizeStartSize.X.Offset + delta.X
            newHeight = resizeStartSize.Y.Offset + delta.Y
        end
        
        newWidth = math.clamp(newWidth, CONFIG.MinSize.Width, CONFIG.MaxSize.Width)
        newHeight = math.clamp(newHeight, CONFIG.MinSize.Height, CONFIG.MaxSize.Height)
        
        mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
        mainFrame.Position = UDim2.new(0.5, newPosX, 0.5, newPosY)
    end
end)

minimizeButton.MouseButton1Click:Connect(function() toggleGUI() end)

closeButton.MouseButton1Click:Connect(function()
    TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    }):Play()
    TweenService:Create(toggleButton, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    for _, line in pairs(iconFrame:GetChildren()) do
        if line:IsA("Frame") then
            TweenService:Create(line, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        end
    end
    task.wait(0.2)
    screenGui:Destroy()
end)

createHoverEffect(minimizeButton, CONFIG.Colors.Warning, Color3.fromRGB(255, 180, 50))
createHoverEffect(closeButton, CONFIG.Colors.Danger, Color3.fromRGB(255, 80, 80))

task.wait(2.5)
toggleGUI()

print("===========================================")
print("🎮 ROBLOX SCRIPT HUB")
print("✅ Loaded successfully!")
print("📱 Mobile & PC supported")
print("===========================================")
