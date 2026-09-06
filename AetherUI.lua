-- ============================================================
--  AetherUI v1.0.0 — Roblox UI Library
--  GitHub: loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/AetherUI/main/AetherUI.lua"))()
--  Usage: local Aether = loadstring(...)() 
-- ============================================================

local AetherUI = {}
AetherUI.__index = AetherUI

-- ─── SERVICES ────────────────────────────────────────────────
local Players         = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local RunService      = game:GetService("RunService")
local HttpService     = game:GetService("HttpService")
local CoreGui         = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ─── INTERNAL STATE ──────────────────────────────────────────
local _windows      = {}
local _theme        = {}
local _aiKey        = nil
local _aiHistory    = {}
local _dragging     = false
local _dragTarget   = nil
local _dragOffset   = Vector2.new(0, 0)

-- ─── DEFAULT THEME ───────────────────────────────────────────
local DefaultTheme = {
    -- Backgrounds
    Background        = Color3.fromRGB(12, 12, 18),
    SecondaryBg       = Color3.fromRGB(18, 18, 28),
    TertiaryBg        = Color3.fromRGB(24, 24, 36),
    
    -- Accents
    Accent            = Color3.fromRGB(110, 80, 220),
    AccentHover       = Color3.fromRGB(130, 100, 240),
    AccentDim         = Color3.fromRGB(60, 40, 140),
    
    -- Text
    TextPrimary       = Color3.fromRGB(235, 235, 245),
    TextSecondary     = Color3.fromRGB(140, 140, 165),
    TextDisabled      = Color3.fromRGB(70, 70, 90),
    
    -- Elements
    Border            = Color3.fromRGB(40, 40, 60),
    Toggle_ON         = Color3.fromRGB(110, 80, 220),
    Toggle_OFF        = Color3.fromRGB(35, 35, 50),
    Slider_Fill       = Color3.fromRGB(110, 80, 220),
    Slider_BG         = Color3.fromRGB(35, 35, 50),
    Dropdown_BG       = Color3.fromRGB(20, 20, 32),
    Input_BG          = Color3.fromRGB(16, 16, 26),
    
    -- Notification
    Notify_Success    = Color3.fromRGB(60, 200, 120),
    Notify_Warning    = Color3.fromRGB(240, 180, 50),
    Notify_Error      = Color3.fromRGB(220, 60, 80),
    Notify_Info       = Color3.fromRGB(70, 140, 255),
    
    -- Sizing
    CornerRadius      = UDim.new(0, 6),
    Font              = Enum.Font.GothamMedium,
    FontBold          = Enum.Font.GothamBold,
    FontSize          = 13,
}

-- ─── UTILITY ─────────────────────────────────────────────────
local function tween(obj, props, duration, style, dir)
    style    = style or Enum.EasingStyle.Quart
    dir      = dir   or Enum.EasingDirection.Out
    duration = duration or 0.18
    local ti = TweenInfo.new(duration, style, dir)
    TweenService:Create(obj, ti, props):Play()
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or _theme.CornerRadius
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color     = color or _theme.Border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function pad(parent, top, right, bottom, left)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 6)
    p.PaddingRight  = UDim.new(0, right  or 8)
    p.PaddingBottom = UDim.new(0, bottom or 6)
    p.PaddingLeft   = UDim.new(0, left   or 8)
    p.Parent = parent
    return p
end

local function makeLabel(parent, text, size, color, font)
    local l = Instance.new("TextLabel")
    l.Text              = text
    l.TextSize          = size  or _theme.FontSize
    l.TextColor3        = color or _theme.TextPrimary
    l.Font              = font  or _theme.Font
    l.BackgroundTransparency = 1
    l.TextXAlignment    = Enum.TextXAlignment.Left
    l.TextWrapped       = true
    l.AutomaticSize     = Enum.AutomaticSize.Y
    l.Size              = UDim2.new(1, 0, 0, 0)
    l.Parent            = parent
    return l
end

local function makeFrame(parent, size, pos, color, transparency)
    local f = Instance.new("Frame")
    f.Size                = size          or UDim2.new(1, 0, 0, 30)
    f.Position            = pos           or UDim2.new(0, 0, 0, 0)
    f.BackgroundColor3    = color         or _theme.TertiaryBg
    f.BackgroundTransparency = transparency or 0
    f.BorderSizePixel     = 0
    f.Parent              = parent
    return f
end

local function makeButton(parent, text, size, pos)
    local b = Instance.new("TextButton")
    b.Text                    = text   or "Button"
    b.Size                    = size   or UDim2.new(1, 0, 0, 32)
    b.Position                = pos    or UDim2.new(0, 0, 0, 0)
    b.BackgroundColor3        = _theme.AccentDim
    b.TextColor3              = _theme.TextPrimary
    b.Font                    = _theme.Font
    b.TextSize                = _theme.FontSize
    b.BorderSizePixel         = 0
    b.AutoButtonColor         = false
    b.Parent                  = parent
    corner(b)
    
    b.MouseEnter:Connect(function()
        tween(b, {BackgroundColor3 = _theme.Accent}, 0.12)
    end)
    b.MouseLeave:Connect(function()
        tween(b, {BackgroundColor3 = _theme.AccentDim}, 0.12)
    end)
    b.MouseButton1Down:Connect(function()
        tween(b, {BackgroundColor3 = _theme.AccentHover}, 0.08)
    end)
    b.MouseButton1Up:Connect(function()
        tween(b, {BackgroundColor3 = _theme.Accent}, 0.08)
    end)
    
    return b
end

-- ─── DRAG SYSTEM ─────────────────────────────────────────────
local function makeDraggable(frame, dragHandle)
    local dragging, dragInput, mousePos, framePos
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            mousePos  = input.Position
            framePos  = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ─── NOTIFICATION SYSTEM ─────────────────────────────────────
local _notifyContainer = nil

local function ensureNotifyContainer()
    if _notifyContainer and _notifyContainer.Parent then return end
    local sg = Instance.new("ScreenGui")
    sg.Name              = "AetherNotify"
    sg.ResetOnSpawn      = false
    sg.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset    = true
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    
    local container = Instance.new("Frame")
    container.Name                = "Container"
    container.Size                = UDim2.new(0, 300, 1, 0)
    container.Position            = UDim2.new(1, -310, 0, 0)
    container.BackgroundTransparency = 1
    container.BorderSizePixel     = 0
    container.Parent              = sg
    
    local layout = Instance.new("UIListLayout")
    layout.Padding          = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment   = Enum.VerticalAlignment.Bottom
    layout.SortOrder        = Enum.SortOrder.LayoutOrder
    layout.Parent           = container
    
    pad(container, 10, 10, 10, 10)
    _notifyContainer = container
end

function AetherUI:Notify(options)
    ensureNotifyContainer()
    options = options or {}
    local title    = options.Title   or "AetherUI"
    local message  = options.Message or ""
    local ntype    = options.Type    or "Info"
    local duration = options.Duration or 4
    
    local typeColors = {
        Success = _theme.Notify_Success,
        Warning = _theme.Notify_Warning,
        Error   = _theme.Notify_Error,
        Info    = _theme.Notify_Info,
    }
    local accentColor = typeColors[ntype] or _theme.Notify_Info
    
    local card = makeFrame(_notifyContainer, UDim2.new(1, 0, 0, 0), nil, _theme.SecondaryBg)
    card.AutomaticSize    = Enum.AutomaticSize.Y
    card.BackgroundTransparency = 1
    corner(card)
    stroke(card, accentColor, 1)
    
    local accentBar = makeFrame(card, UDim2.new(0, 3, 1, 0), UDim2.new(0, 0, 0, 0), accentColor)
    corner(accentBar, UDim.new(0, 3))
    
    local content = makeFrame(card, UDim2.new(1, -11, 0, 0), UDim2.new(0, 11, 0, 0), Color3.new(0,0,0), 1)
    content.AutomaticSize = Enum.AutomaticSize.Y
    
    local layout = Instance.new("UIListLayout")
    layout.Padding    = UDim.new(0, 2)
    layout.SortOrder  = Enum.SortOrder.LayoutOrder
    layout.Parent     = content
    pad(content, 8, 8, 8, 8)
    
    local titleLabel = makeLabel(content, title, 13, accentColor, _theme.FontBold)
    titleLabel.LayoutOrder = 1
    
    local msgLabel = makeLabel(content, message, 12, _theme.TextSecondary)
    msgLabel.LayoutOrder = 2
    
    -- Animate in
    tween(card, {BackgroundTransparency = 0}, 0.2)
    
    -- Progress bar
    local pbar = makeFrame(card, UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 1, -2), accentColor)
    tween(pbar, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
    
    task.delay(duration, function()
        tween(card, {BackgroundTransparency = 1}, 0.2)
        task.wait(0.2)
        card:Destroy()
    end)
end

-- ─── WINDOW ──────────────────────────────────────────────────
local Window = {}
Window.__index = Window

function AetherUI:CreateWindow(options)
    options = options or {}
    local title    = options.Title  or "AetherUI"
    local size     = options.Size   or UDim2.new(0, 560, 0, 400)
    local pos      = options.Position or UDim2.new(0.5, -280, 0.5, -200)
    local tabs     = {}
    local activeTab = nil
    
    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name           = "AetherUI_" .. title
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset = true
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    
    -- Main Window Frame
    local win = makeFrame(sg, size, pos, _theme.Background)
    win.Name = "AetherWindow"
    corner(win, UDim.new(0, 10))
    stroke(win, _theme.Border, 1)
    
    -- Drop shadow (fake with a darker frame behind)
    local shadow = makeFrame(sg, UDim2.new(1, 10, 1, 10), UDim2.new(0, -5, 0, -5), Color3.fromRGB(0,0,0), 0.6)
    shadow.ZIndex = win.ZIndex - 1
    corner(shadow, UDim.new(0, 12))
    shadow.Parent = sg
    
    -- Topbar
    local topbar = makeFrame(win, UDim2.new(1, 0, 0, 46), UDim2.new(0,0,0,0), _theme.SecondaryBg)
    corner(topbar, UDim.new(0, 10))
    -- Cover bottom corners of topbar
    local topbarCover = makeFrame(win, UDim2.new(1, 0, 0, 8), UDim2.new(0, 0, 0, 38), _theme.SecondaryBg)
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text           = title
    titleLabel.Font           = _theme.FontBold
    titleLabel.TextSize       = 15
    titleLabel.TextColor3     = _theme.TextPrimary
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size           = UDim2.new(1, -100, 1, 0)
    titleLabel.Position       = UDim2.new(0, 14, 0, 0)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent         = topbar
    
    -- Close button
    local closeBtn = makeButton(topbar, "✕", UDim2.new(0, 28, 0, 28), UDim2.new(1, -36, 0.5, -14))
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 60)
    closeBtn.TextSize = 12
    closeBtn.MouseButton1Click:Connect(function()
        tween(win, {Size = UDim2.new(0, size.X.Offset, 0, 0)}, 0.18)
        task.wait(0.2)
        sg:Destroy()
    end)
    
    -- Minimize button
    local minimized = false
    local minBtn = makeButton(topbar, "─", UDim2.new(0, 28, 0, 28), UDim2.new(1, -70, 0.5, -14))
    minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    minBtn.TextSize = 12
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            tween(win, {Size = UDim2.new(0, size.X.Offset, 0, 46)}, 0.18)
        else
            tween(win, {Size = size}, 0.18)
        end
    end)
    
    makeDraggable(win, topbar)
    
    -- Tab bar
    local tabBar = makeFrame(win, UDim2.new(0, 130, 1, -46), UDim2.new(0, 0, 0, 46), _theme.SecondaryBg)
    -- Cover right edge of tabBar
    local tabBarCover = makeFrame(win, UDim2.new(0, 6, 1, -46), UDim2.new(0, 124, 0, 46), _theme.SecondaryBg)
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding        = UDim.new(0, 2)
    tabLayout.SortOrder      = Enum.SortOrder.LayoutOrder
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.Parent         = tabBar
    pad(tabBar, 8, 4, 8, 4)
    
    -- Content area
    local contentArea = makeFrame(win, UDim2.new(1, -136, 1, -54), UDim2.new(0, 134, 0, 50), _theme.Background, 1)
    
    -- Divider
    local divider = makeFrame(win, UDim2.new(0, 1, 1, -54), UDim2.new(0, 130, 0, 50), _theme.Border)
    
    -- Window object returned to user
    local winObj = setmetatable({}, Window)
    winObj._sg         = sg
    winObj._win        = win
    winObj._tabs       = tabs
    winObj._activeTab  = nil
    winObj._tabBar     = tabBar
    winObj._content    = contentArea
    winObj._tabOrder   = 0
    
    -- ─── AI CHAT TAB (auto-added) ──────────────────────────────
    -- Built-in AI chat; user sets API key in the Settings tab
    local function buildChatTab()
        local chatScroll = Instance.new("ScrollingFrame")
        chatScroll.Name                   = "ChatScroll"
        chatScroll.Size                   = UDim2.new(1, -8, 1, -46)
        chatScroll.Position               = UDim2.new(0, 4, 0, 0)
        chatScroll.BackgroundTransparency = 1
        chatScroll.BorderSizePixel        = 0
        chatScroll.ScrollBarThickness     = 3
        chatScroll.ScrollBarImageColor3   = _theme.Accent
        chatScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
        chatScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
        
        local msgLayout = Instance.new("UIListLayout")
        msgLayout.Padding   = UDim.new(0, 6)
        msgLayout.SortOrder = Enum.SortOrder.LayoutOrder
        msgLayout.Parent    = chatScroll
        pad(chatScroll, 6, 4, 6, 4)
        
        -- Input bar
        local inputBar = makeFrame(nil, UDim2.new(1, -8, 0, 36), UDim2.new(0, 4, 1, -40), _theme.Input_BG)
        corner(inputBar)
        stroke(inputBar, _theme.Border)
        
        local textInput = Instance.new("TextBox")
        textInput.PlaceholderText     = "Ask AI anything... (set API key in Settings)"
        textInput.PlaceholderColor3   = _theme.TextDisabled
        textInput.Text                = ""
        textInput.Font                = _theme.Font
        textInput.TextSize            = 12
        textInput.TextColor3          = _theme.TextPrimary
        textInput.BackgroundTransparency = 1
        textInput.Size                = UDim2.new(1, -44, 1, 0)
        textInput.Position            = UDim2.new(0, 8, 0, 0)
        textInput.TextXAlignment      = Enum.TextXAlignment.Left
        textInput.ClearTextOnFocus    = false
        textInput.TextWrapped         = false
        textInput.MultiLine           = false
        textInput.Parent              = inputBar
        
        local sendBtn = makeButton(inputBar, "➤", UDim2.new(0, 32, 0, 28), UDim2.new(1, -36, 0.5, -14))
        sendBtn.TextSize = 14
        
        local msgOrder = 0
        
        local function addMessage(text, isUser)
            msgOrder = msgOrder + 1
            local bubble = makeFrame(chatScroll, UDim2.new(0.85, 0, 0, 0), nil,
                isUser and _theme.AccentDim or _theme.TertiaryBg)
            bubble.AutomaticSize  = Enum.AutomaticSize.Y
            bubble.LayoutOrder    = msgOrder
            if isUser then
                bubble.Position = UDim2.new(0.15, 0, 0, 0)
            end
            corner(bubble)
            pad(bubble, 7, 10, 7, 10)
            
            local lbl = makeLabel(bubble, text, 12, isUser and _theme.TextPrimary or _theme.TextSecondary)
            lbl.TextWrapped = true
            lbl.AutomaticSize = Enum.AutomaticSize.Y
            lbl.Size = UDim2.new(1, 0, 0, 0)
            
            -- Auto scroll
            task.wait()
            chatScroll.CanvasPosition = Vector2.new(0, chatScroll.AbsoluteCanvasSize.Y)
            return bubble
        end
        
        local function callAI(userMsg)
            if not _aiKey or _aiKey == "" then
                addMessage("⚠ No API key set. Go to Settings tab → enter your Claude API key.", false)
                return
            end
            
            -- Add to history
            table.insert(_aiHistory, {role = "user", content = userMsg})
            
            local thinkingBubble = addMessage("...", false)
            
            local ok, result = pcall(function()
                local body = HttpService:JSONEncode({
                    model      = "claude-sonnet-4-6",
                    max_tokens = 1024,
                    messages   = _aiHistory,
                })
                
                -- Roblox HttpService: needs executor with http capability
                -- Use syn.request or http.request depending on executor
                local response
                if syn and syn.request then
                    response = syn.request({
                        Url     = "https://api.anthropic.com/v1/messages",
                        Method  = "POST",
                        Headers = {
                            ["Content-Type"]      = "application/json",
                            ["x-api-key"]         = _aiKey,
                            ["anthropic-version"] = "2023-06-01",
                        },
                        Body = body,
                    })
                elseif http and http.request then
                    response = http.request({
                        url     = "https://api.anthropic.com/v1/messages",
                        method  = "POST",
                        headers = {
                            ["Content-Type"]      = "application/json",
                            ["x-api-key"]         = _aiKey,
                            ["anthropic-version"] = "2023-06-01",
                        },
                        body = body,
                    })
                elseif request then
                    response = request({
                        Url     = "https://api.anthropic.com/v1/messages",
                        Method  = "POST",
                        Headers = {
                            ["Content-Type"]      = "application/json",
                            ["x-api-key"]         = _aiKey,
                            ["anthropic-version"] = "2023-06-01",
                        },
                        Body = body,
                    })
                else
                    error("No HTTP request function found. Use an executor with HTTP capability (Synapse, KRNL, etc.)")
                end
                
                local data = HttpService:JSONDecode(response.Body)
                if data.error then
                    error(data.error.message or "API Error")
                end
                return data.content[1].text
            end)
            
            -- Remove thinking bubble, add real reply
            thinkingBubble:Destroy()
            
            if ok then
                table.insert(_aiHistory, {role = "assistant", content = result})
                addMessage(result, false)
            else
                addMessage("✗ Error: " .. tostring(result), false)
            end
        end
        
        local function handleSend()
            local msg = textInput.Text
            if msg == "" or msg:match("^%s*$") then return end
            textInput.Text = ""
            addMessage(msg, true)
            task.spawn(callAI, msg)
        end
        
        sendBtn.MouseButton1Click:Connect(handleSend)
        textInput.FocusLost:Connect(function(enter)
            if enter then handleSend() end
        end)
        
        addMessage("Hello! I'm your AetherUI AI assistant powered by Claude. Set your API key in the Settings tab to get started.", false)
        
        return chatScroll, inputBar
    end
    
    -- ─── TAB CREATION ─────────────────────────────────────────
    function winObj:AddTab(tabOptions)
        tabOptions = tabOptions or {}
        local tabName = tabOptions.Name or "Tab"
        local tabIcon = tabOptions.Icon or ""
        
        self._tabOrder = self._tabOrder + 1
        local order = self._tabOrder
        
        -- Tab button
        local tabBtn = Instance.new("TextButton")
        tabBtn.Text               = (tabIcon ~= "" and tabIcon .. "  " or "") .. tabName
        tabBtn.Font               = _theme.Font
        tabBtn.TextSize           = 12
        tabBtn.TextColor3         = _theme.TextSecondary
        tabBtn.BackgroundColor3   = _theme.TertiaryBg
        tabBtn.BackgroundTransparency = 1
        tabBtn.BorderSizePixel    = 0
        tabBtn.Size               = UDim2.new(1, 0, 0, 30)
        tabBtn.AutoButtonColor    = false
        tabBtn.LayoutOrder        = order
        tabBtn.TextXAlignment     = Enum.TextXAlignment.Left
        tabBtn.Parent             = self._tabBar
        corner(tabBtn)
        pad(tabBtn, 0, 8, 0, 10)
        
        -- Tab content container
        local container = makeFrame(self._content, UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0), Color3.new(0,0,0), 1)
        container.Visible = false
        container.ClipsDescendants = true
        
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size                   = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel        = 0
        scroll.ScrollBarThickness     = 3
        scroll.ScrollBarImageColor3   = _theme.Accent
        scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
        scroll.Parent                 = container
        
        local contentLayout = Instance.new("UIListLayout")
        contentLayout.Padding   = UDim.new(0, 6)
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Parent    = scroll
        pad(scroll, 8, 10, 8, 10)
        
        local tabObj = {
            _btn       = tabBtn,
            _container = container,
            _scroll    = scroll,
            _layout    = contentLayout,
            _order     = 0,
            _win       = self,
        }
        
        local function activate()
            -- Deactivate all tabs
            for _, t in ipairs(self._tabs) do
                tween(t._btn, {TextColor3 = _theme.TextSecondary, BackgroundTransparency = 1}, 0.12)
                t._container.Visible = false
            end
            -- Activate this tab
            tween(tabBtn, {TextColor3 = _theme.TextPrimary, BackgroundTransparency = 0}, 0.12)
            container.Visible = true
            self._activeTab = tabObj
        end
        
        tabBtn.MouseButton1Click:Connect(activate)
        tabBtn.MouseEnter:Connect(function()
            if self._activeTab ~= tabObj then
                tween(tabBtn, {BackgroundTransparency = 0.7}, 0.1)
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if self._activeTab ~= tabObj then
                tween(tabBtn, {BackgroundTransparency = 1}, 0.1)
            end
        end)
        
        table.insert(self._tabs, tabObj)
        
        -- Auto-activate first tab
        if #self._tabs == 1 then
            activate()
        end
        
        -- ─── SECTION ────────────────────────────────────────
        function tabObj:AddSection(sectionName)
            self._order = self._order + 1
            local sectionOrder = self._order
            
            local sectionFrame = makeFrame(self._scroll, UDim2.new(1, 0, 0, 0), nil, _theme.TertiaryBg)
            sectionFrame.AutomaticSize = Enum.AutomaticSize.Y
            sectionFrame.LayoutOrder  = sectionOrder
            corner(sectionFrame)
            stroke(sectionFrame, _theme.Border)
            
            local sLayout = Instance.new("UIListLayout")
            sLayout.Padding   = UDim.new(0, 4)
            sLayout.SortOrder = Enum.SortOrder.LayoutOrder
            sLayout.Parent    = sectionFrame
            pad(sectionFrame, 8, 10, 10, 10)
            
            -- Section header
            if sectionName then
                local header = makeLabel(sectionFrame, sectionName, 11, _theme.TextDisabled, _theme.FontBold)
                header.LayoutOrder = 0
                header.Size        = UDim2.new(1, 0, 0, 16)
                header.AutomaticSize = Enum.AutomaticSize.None
            end
            
            local sectionObj = {
                _frame  = sectionFrame,
                _layout = sLayout,
                _order  = 0,
            }
            
            -- ─── TOGGLE ─────────────────────────────────────
            function sectionObj:AddToggle(opts)
                opts = opts or {}
                local label    = opts.Name    or "Toggle"
                local default  = opts.Default or false
                local callback = opts.Callback or function() end
                
                self._order = self._order + 1
                local state = default
                
                local row = makeFrame(self._frame, UDim2.new(1, 0, 0, 30), nil, Color3.new(0,0,0), 1)
                row.LayoutOrder = self._order
                
                local lbl = makeLabel(row, label, 13, _theme.TextPrimary)
                lbl.Size     = UDim2.new(1, -50, 1, 0)
                lbl.Position = UDim2.new(0, 0, 0, 0)
                lbl.AutomaticSize = Enum.AutomaticSize.None
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                
                local toggleBg = makeFrame(row, UDim2.new(0, 40, 0, 20), UDim2.new(1, -42, 0.5, -10),
                    state and _theme.Toggle_ON or _theme.Toggle_OFF)
                corner(toggleBg, UDim.new(1, 0))
                
                local knob = makeFrame(toggleBg, UDim2.new(0, 16, 0, 16), 
                    state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8), Color3.fromRGB(255,255,255))
                corner(knob, UDim.new(1, 0))
                
                local btn = Instance.new("TextButton")
                btn.Text                  = ""
                btn.BackgroundTransparency = 1
                btn.Size                  = UDim2.new(1, 0, 1, 0)
                btn.Parent                = row
                
                btn.MouseButton1Click:Connect(function()
                    state = not state
                    tween(toggleBg, {BackgroundColor3 = state and _theme.Toggle_ON or _theme.Toggle_OFF}, 0.15)
                    tween(knob, {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.15)
                    pcall(callback, state)
                end)
                
                local toggleAPI = {}
                function toggleAPI:Set(v)
                    state = v
                    tween(toggleBg, {BackgroundColor3 = state and _theme.Toggle_ON or _theme.Toggle_OFF}, 0.15)
                    tween(knob, {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.15)
                end
                function toggleAPI:Get() return state end
                return toggleAPI
            end
            
            -- ─── SLIDER ─────────────────────────────────────
            function sectionObj:AddSlider(opts)
                opts = opts or {}
                local label    = opts.Name    or "Slider"
                local min      = opts.Min     or 0
                local max      = opts.Max     or 100
                local default  = opts.Default or min
                local suffix   = opts.Suffix  or ""
                local callback = opts.Callback or function() end
                
                self._order = self._order + 1
                local value = math.clamp(default, min, max)
                
                local wrapper = makeFrame(self._frame, UDim2.new(1, 0, 0, 44), nil, Color3.new(0,0,0), 1)
                wrapper.LayoutOrder = self._order
                
                local topRow = makeFrame(wrapper, UDim2.new(1, 0, 0, 20), UDim2.new(0,0,0,0), Color3.new(0,0,0), 1)
                
                local lbl = makeLabel(topRow, label, 13, _theme.TextPrimary)
                lbl.Size = UDim2.new(1, -60, 1, 0)
                lbl.AutomaticSize = Enum.AutomaticSize.None
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                
                local valLabel = makeLabel(topRow, tostring(value) .. suffix, 12, _theme.Accent, _theme.FontBold)
                valLabel.Size              = UDim2.new(0, 55, 1, 0)
                valLabel.Position          = UDim2.new(1, -55, 0, 0)
                valLabel.TextXAlignment    = Enum.TextXAlignment.Right
                valLabel.AutomaticSize     = Enum.AutomaticSize.None
                valLabel.TextYAlignment    = Enum.TextYAlignment.Center
                
                local track = makeFrame(wrapper, UDim2.new(1, 0, 0, 6), UDim2.new(0, 0, 0, 30), _theme.Slider_BG)
                corner(track, UDim.new(1, 0))
                
                local fill = makeFrame(track, UDim2.new((value - min) / (max - min), 0, 1, 0), UDim2.new(0,0,0,0), _theme.Slider_Fill)
                corner(fill, UDim.new(1, 0))
                
                local knob = makeFrame(track, UDim2.new(0, 12, 0, 12), 
                    UDim2.new((value - min)/(max - min), -6, 0.5, -6), Color3.fromRGB(255,255,255))
                corner(knob, UDim.new(1, 0))
                
                local draggingSlider = false
                
                local function updateSlider(input)
                    local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
                    rel = math.clamp(rel, 0, 1)
                    value = math.floor(min + (max - min) * rel)
                    valLabel.Text = tostring(value) .. suffix
                    fill.Size     = UDim2.new(rel, 0, 1, 0)
                    knob.Position = UDim2.new(rel, -6, 0.5, -6)
                    pcall(callback, value)
                end
                
                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = true
                        updateSlider(input)
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateSlider(input)
                    end
                end)
                
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = false
                    end
                end)
                
                local sliderAPI = {}
                function sliderAPI:Set(v)
                    value = math.clamp(v, min, max)
                    local rel = (value - min) / (max - min)
                    valLabel.Text = tostring(value) .. suffix
                    fill.Size     = UDim2.new(rel, 0, 1, 0)
                    knob.Position = UDim2.new(rel, -6, 0.5, -6)
                end
                function sliderAPI:Get() return value end
                return sliderAPI
            end
            
            -- ─── BUTTON ─────────────────────────────────────
            function sectionObj:AddButton(opts)
                opts = opts or {}
                local label    = opts.Name     or "Button"
                local callback = opts.Callback or function() end
                
                self._order = self._order + 1
                
                local btn = makeButton(self._frame, label, UDim2.new(1, 0, 0, 32))
                btn.LayoutOrder = self._order
                btn.MouseButton1Click:Connect(function()
                    pcall(callback)
                end)
                return btn
            end
            
            -- ─── TEXTBOX ────────────────────────────────────
            function sectionObj:AddTextBox(opts)
                opts = opts or {}
                local label       = opts.Name        or "Input"
                local placeholder = opts.Placeholder  or "Enter text..."
                local default     = opts.Default      or ""
                local callback    = opts.Callback     or function() end
                
                self._order = self._order + 1
                
                local wrapper = makeFrame(self._frame, UDim2.new(1, 0, 0, 52), nil, Color3.new(0,0,0), 1)
                wrapper.LayoutOrder = self._order
                
                makeLabel(wrapper, label, 12, _theme.TextSecondary)
                
                local inputFrame = makeFrame(wrapper, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 20), _theme.Input_BG)
                corner(inputFrame)
                stroke(inputFrame, _theme.Border)
                
                local box = Instance.new("TextBox")
                box.PlaceholderText   = placeholder
                box.PlaceholderColor3 = _theme.TextDisabled
                box.Text              = default
                box.Font              = _theme.Font
                box.TextSize          = 12
                box.TextColor3        = _theme.TextPrimary
                box.BackgroundTransparency = 1
                box.Size              = UDim2.new(1, -16, 1, 0)
                box.Position          = UDim2.new(0, 8, 0, 0)
                box.TextXAlignment    = Enum.TextXAlignment.Left
                box.ClearTextOnFocus  = false
                box.Parent            = inputFrame
                
                box.FocusLost:Connect(function(enter)
                    pcall(callback, box.Text, enter)
                end)
                
                local tbAPI = {}
                function tbAPI:Get() return box.Text end
                function tbAPI:Set(v) box.Text = v end
                return tbAPI
            end
            
            -- ─── DROPDOWN ───────────────────────────────────
            function sectionObj:AddDropdown(opts)
                opts = opts or {}
                local label    = opts.Name     or "Dropdown"
                local items    = opts.Items    or {}
                local default  = opts.Default  or (items[1] or "")
                local callback = opts.Callback or function() end
                
                self._order = self._order + 1
                local selected  = default
                local open      = false
                
                local wrapper = makeFrame(self._frame, UDim2.new(1, 0, 0, 52), nil, Color3.new(0,0,0), 1)
                wrapper.LayoutOrder = self._order
                wrapper.ClipsDescendants = false
                
                makeLabel(wrapper, label, 12, _theme.TextSecondary)
                
                local dropBtn = Instance.new("TextButton")
                dropBtn.Text              = selected .. "  ▼"
                dropBtn.Font              = _theme.Font
                dropBtn.TextSize          = 12
                dropBtn.TextColor3        = _theme.TextPrimary
                dropBtn.BackgroundColor3  = _theme.Dropdown_BG
                dropBtn.BorderSizePixel   = 0
                dropBtn.Size              = UDim2.new(1, 0, 0, 30)
                dropBtn.Position          = UDim2.new(0, 0, 0, 20)
                dropBtn.AutoButtonColor   = false
                dropBtn.TextXAlignment    = Enum.TextXAlignment.Left
                dropBtn.ClipsDescendants  = false
                dropBtn.Parent            = wrapper
                corner(dropBtn)
                stroke(dropBtn, _theme.Border)
                pad(dropBtn, 0, 8, 0, 8)
                
                local listFrame = makeFrame(nil, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 1, 2), _theme.Dropdown_BG)
                listFrame.ZIndex          = 10
                listFrame.ClipsDescendants = true
                listFrame.Visible         = false
                listFrame.AutomaticSize   = Enum.AutomaticSize.Y
                listFrame.Parent          = dropBtn
                corner(listFrame)
                stroke(listFrame, _theme.Border)
                
                local listLayout = Instance.new("UIListLayout")
                listLayout.SortOrder = Enum.SortOrder.LayoutOrder
                listLayout.Parent    = listFrame
                pad(listFrame, 4, 4, 4, 4)
                
                for i, item in ipairs(items) do
                    local itemBtn = Instance.new("TextButton")
                    itemBtn.Text             = item
                    itemBtn.Font             = _theme.Font
                    itemBtn.TextSize         = 12
                    itemBtn.TextColor3       = _theme.TextSecondary
                    itemBtn.BackgroundColor3 = _theme.Dropdown_BG
                    itemBtn.BorderSizePixel  = 0
                    itemBtn.Size             = UDim2.new(1, 0, 0, 26)
                    itemBtn.AutoButtonColor  = false
                    itemBtn.TextXAlignment   = Enum.TextXAlignment.Left
                    itemBtn.LayoutOrder      = i
                    itemBtn.ZIndex           = 11
                    itemBtn.Parent           = listFrame
                    corner(itemBtn, UDim.new(0, 4))
                    pad(itemBtn, 0, 6, 0, 6)
                    
                    itemBtn.MouseEnter:Connect(function()
                        tween(itemBtn, {BackgroundColor3 = _theme.TertiaryBg, TextColor3 = _theme.TextPrimary}, 0.1)
                    end)
                    itemBtn.MouseLeave:Connect(function()
                        tween(itemBtn, {BackgroundColor3 = _theme.Dropdown_BG, TextColor3 = _theme.TextSecondary}, 0.1)
                    end)
                    itemBtn.MouseButton1Click:Connect(function()
                        selected       = item
                        dropBtn.Text   = item .. "  ▼"
                        open           = false
                        listFrame.Visible = false
                        pcall(callback, item)
                    end)
                end
                
                dropBtn.MouseButton1Click:Connect(function()
                    open = not open
                    listFrame.Visible = open
                end)
                
                local ddAPI = {}
                function ddAPI:Get() return selected end
                function ddAPI:Set(v)
                    selected     = v
                    dropBtn.Text = v .. "  ▼"
                end
                return ddAPI
            end
            
            -- ─── LABEL ──────────────────────────────────────
            function sectionObj:AddLabel(opts)
                opts = opts or {}
                local text  = opts.Name or opts.Text or ""
                local color = opts.Color or _theme.TextSecondary
                
                self._order = self._order + 1
                local lbl = makeLabel(self._frame, text, 12, color)
                lbl.LayoutOrder = self._order
                
                local lblAPI = {}
                function lblAPI:Set(v) lbl.Text = v end
                function lblAPI:Get()  return lbl.Text end
                return lblAPI
            end
            
            -- ─── SEPARATOR ──────────────────────────────────
            function sectionObj:AddSeparator()
                self._order = self._order + 1
                local sep = makeFrame(self._frame, UDim2.new(1, 0, 0, 1), nil, _theme.Border)
                sep.LayoutOrder = self._order
            end
            
            return sectionObj
        end
        
        return tabObj
    end
    
    -- ─── BUILT-IN TABS ────────────────────────────────────────
    -- Chat tab
    local chatTab = winObj:AddTab({Name = "💬 Chat", Icon = ""})
    chatTab._scroll:Destroy()
    
    local chatScrollFrame, chatInputBar = buildChatTab()
    chatScrollFrame.Parent = chatTab._container
    chatInputBar.Parent    = chatTab._container
    
    -- Settings tab (for API key)
    local settingsTab = winObj:AddTab({Name = "⚙ Settings", Icon = ""})
    local settingsSection = settingsTab:AddSection("AI Configuration")
    
    settingsSection:AddLabel({Text = "Claude API Key (from console.anthropic.com)"})
    local keyBox = settingsSection:AddTextBox({
        Placeholder = "sk-ant-...",
        Callback = function(val)
            _aiKey = val ~= "" and val or nil
        end,
    })
    
    settingsSection:AddButton({
        Name = "Clear AI Chat History",
        Callback = function()
            _aiHistory = {}
            AetherUI:Notify({Title = "AetherUI", Message = "Chat history cleared.", Type = "Info"})
        end,
    })
    
    settingsSection:AddSeparator()
    settingsSection:AddLabel({Text = "AetherUI v1.0.0 — github.com/YOUR_USER/AetherUI"})
    
    table.insert(_windows, winObj)
    return winObj
end

-- ─── INIT ─────────────────────────────────────────────────────
function AetherUI:Init(options)
    options = options or {}
    -- Merge custom theme over defaults
    _theme = {}
    for k, v in pairs(DefaultTheme) do
        _theme[k] = options.Theme and options.Theme[k] or v
    end
    return self
end

-- Auto-init with default theme if someone skips Init()
setmetatable(AetherUI, {
    __index = function(t, k)
        if not next(_theme) then
            AetherUI:Init()
        end
        return rawget(t, k)
    end
})

return AetherUI