-- ============================================================
--  AetherUI v2.1.0 — Roblox UI Library
--  Visual: Dark panel, two-column plugin grid, macOS titlebar
--  v2.1: AI Script Writer — fetches live game, generates + executes Lua
--  GitHub: loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/AetherUI/main/AetherUI.lua"))()
-- ============================================================

local AetherUI = {}
AetherUI.__index = AetherUI

-- ─── SERVICES ────────────────────────────────────────────────
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local HttpService        = game:GetService("HttpService")
local CoreGui            = game:GetService("CoreGui")
local RunService         = game:GetService("RunService")

local LP    = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- ─── STATE ───────────────────────────────────────────────────
local _theme     = {}
local _windows   = {}
local _aiKey     = nil
local _aiHistory = {}

-- ─── THEME ───────────────────────────────────────────────────
local Theme = {
    -- Window chrome
    WindowBG       = Color3.fromRGB(20, 20, 24),
    TitlebarBG     = Color3.fromRGB(15, 15, 19),
    SidebarBG      = Color3.fromRGB(12, 12, 16),
    MainBG         = Color3.fromRGB(20, 20, 24),
    HeaderBG       = Color3.fromRGB(20, 20, 24),

    -- Borders
    Border         = Color3.fromRGB(40, 40, 50),
    BorderLight    = Color3.fromRGB(30, 30, 38),

    -- Text
    TextPrimary    = Color3.fromRGB(235, 235, 240),
    TextSecondary  = Color3.fromRGB(120, 120, 135),
    TextDisabled   = Color3.fromRGB(65, 65, 80),
    TextMuted      = Color3.fromRGB(80, 80, 95),

    -- Nav
    NavActiveBG    = Color3.fromRGB(38, 38, 48),
    NavHoverBG     = Color3.fromRGB(28, 28, 36),
    NavActiveText  = Color3.fromRGB(235, 235, 240),

    -- Plugin cards
    PluginCardBG   = Color3.fromRGB(25, 25, 30),
    PluginCardHover= Color3.fromRGB(32, 32, 40),

    -- Toggle
    ToggleON       = Color3.fromRGB(34, 197, 94),
    ToggleOFF      = Color3.fromRGB(45, 45, 58),
    ToggleKnob     = Color3.fromRGB(255, 255, 255),

    -- Badge
    BadgeOnBG      = Color3.fromRGB(20, 50, 28),
    BadgeOnText    = Color3.fromRGB(74, 222, 128),
    BadgeOffBG     = Color3.fromRGB(35, 35, 45),
    BadgeOffText   = Color3.fromRGB(80, 80, 100),

    -- Tabs
    TabActive      = Color3.fromRGB(235, 235, 240),
    TabInactive    = Color3.fromRGB(80, 80, 100),

    -- Search
    SearchBG       = Color3.fromRGB(28, 28, 35),

    -- Buttons
    BtnPrimary     = Color3.fromRGB(50, 50, 65),
    BtnPrimaryText = Color3.fromRGB(180, 180, 200),

    -- macOS dots
    DotRed         = Color3.fromRGB(255, 95, 87),
    DotYellow      = Color3.fromRGB(255, 189, 46),
    DotGreen       = Color3.fromRGB(40, 201, 64),

    -- AI Chat
    MsgUserBG      = Color3.fromRGB(40, 35, 70),
    MsgAIBG        = Color3.fromRGB(28, 28, 36),

    -- Input
    InputBG        = Color3.fromRGB(22, 22, 30),

    -- Separator
    Separator      = Color3.fromRGB(35, 35, 45),

    -- Notification
    NotifyBG       = Color3.fromRGB(22, 22, 32),
    NotifyBorder   = Color3.fromRGB(74, 222, 128),
    NotifyText     = Color3.fromRGB(74, 222, 128),

    -- Radius
    RadiusWindow   = UDim.new(0, 10),
    RadiusCard     = UDim.new(0, 8),
    RadiusSmall    = UDim.new(0, 6),
    RadiusBadge    = UDim.new(0, 5),

    -- Font
    Font           = Enum.Font.GothamMedium,
    FontBold       = Enum.Font.GothamBold,
    FontSemibold   = Enum.Font.GothamSemibold,
}

-- ─── UTILS ───────────────────────────────────────────────────
local function tw(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.15,
            style or Enum.EasingStyle.Quart,
            dir   or Enum.EasingDirection.Out),
        props):Play()
end

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or Theme.RadiusCard
    c.Parent = p
    return c
end

local function stroke(p, col, thick)
    local s = Instance.new("UIStroke")
    s.Color     = col or Theme.Border
    s.Thickness = thick or 0.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local function pad(p, t, r, b, l)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, t or 6)
    u.PaddingRight  = UDim.new(0, r or 8)
    u.PaddingBottom = UDim.new(0, b or 6)
    u.PaddingLeft   = UDim.new(0, l or 8)
    u.Parent = p
end

local function frame(parent, size, pos, color, alpha)
    local f = Instance.new("Frame")
    f.Size                = size  or UDim2.new(1,0,0,30)
    f.Position            = pos   or UDim2.new(0,0,0,0)
    f.BackgroundColor3    = color or Theme.MainBG
    f.BackgroundTransparency = alpha or 0
    f.BorderSizePixel     = 0
    f.Parent              = parent
    return f
end

local function label(parent, text, size, color, font, xalign)
    local l = Instance.new("TextLabel")
    l.Text              = text  or ""
    l.TextSize          = size  or 13
    l.TextColor3        = color or Theme.TextPrimary
    l.Font              = font  or Theme.Font
    l.BackgroundTransparency = 1
    l.BorderSizePixel   = 0
    l.TextXAlignment    = xalign or Enum.TextXAlignment.Left
    l.TextYAlignment    = Enum.TextYAlignment.Center
    l.TextWrapped       = true
    l.Size              = UDim2.new(1,0,0,20)
    l.Parent            = parent
    return l
end

local function textbtn(parent, text, size, pos, bgcol, textcol)
    local b = Instance.new("TextButton")
    b.Text              = text   or "Button"
    b.Size              = size   or UDim2.new(1,0,0,32)
    b.Position          = pos    or UDim2.new(0,0,0,0)
    b.BackgroundColor3  = bgcol  or Theme.BtnPrimary
    b.TextColor3        = textcol or Theme.TextPrimary
    b.Font              = Theme.Font
    b.TextSize          = 12
    b.BorderSizePixel   = 0
    b.AutoButtonColor   = false
    b.Parent            = parent
    return b
end

-- ─── DRAG ────────────────────────────────────────────────────
local function makeDraggable(win, handle)
    local drag, dragIn, mPos, fPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag  = true
            mPos  = i.Position
            fPos  = win.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then drag = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then dragIn = i end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i == dragIn and drag then
            local d = i.Position - mPos
            win.Position = UDim2.new(fPos.X.Scale, fPos.X.Offset+d.X, fPos.Y.Scale, fPos.Y.Offset+d.Y)
        end
    end)
end

-- ─── TOGGLE COMPONENT ────────────────────────────────────────
local function makeToggle(parent, state, onChanged)
    local bg = frame(parent, UDim2.new(0,34,0,18), nil, state and Theme.ToggleON or Theme.ToggleOFF)
    corner(bg, UDim.new(1,0))

    local knob = frame(bg, UDim2.new(0,14,0,14),
        state and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7),
        Theme.ToggleKnob)
    corner(knob, UDim.new(1,0))

    local btn = Instance.new("TextButton")
    btn.Text = "" btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1,0,1,0) btn.Parent = bg

    local current = state
    btn.MouseButton1Click:Connect(function()
        current = not current
        tw(bg,   {BackgroundColor3 = current and Theme.ToggleON or Theme.ToggleOFF}, 0.15)
        tw(knob, {Position = current and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)}, 0.15)
        if onChanged then pcall(onChanged, current) end
    end)

    local api = {}
    function api:Set(v)
        current = v
        tw(bg,   {BackgroundColor3 = v and Theme.ToggleON or Theme.ToggleOFF}, 0.15)
        tw(knob, {Position = v and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)}, 0.15)
    end
    function api:Get() return current end
    return api, bg
end

-- ─── BADGE COMPONENT ─────────────────────────────────────────
local function makeBadge(parent, isOn)
    local bg = frame(parent, UDim2.new(0,60,0,18), nil, isOn and Theme.BadgeOnBG or Theme.BadgeOffBG)
    corner(bg, Theme.RadiusBadge)

    local dot = frame(bg, UDim2.new(0,5,0,5), UDim2.new(0,6,0.5,-2.5),
        isOn and Theme.BadgeOnText or Theme.BadgeOffText)
    corner(dot, UDim.new(1,0))

    local lbl = label(bg, isOn and "Enabled" or "Disabled", 10,
        isOn and Theme.BadgeOnText or Theme.BadgeOffText, Theme.FontBold)
    lbl.Position = UDim2.new(0,14,0,0)
    lbl.Size     = UDim2.new(1,-16,1,0)

    local api = {}
    function api:SetState(v)
        tw(bg, {BackgroundColor3 = v and Theme.BadgeOnBG or Theme.BadgeOffBG}, 0.15)
        tw(dot,{BackgroundColor3 = v and Theme.BadgeOnText or Theme.BadgeOffText}, 0.15)
        lbl.Text       = v and "Enabled" or "Disabled"
        lbl.TextColor3 = v and Theme.BadgeOnText or Theme.BadgeOffText
    end
    return api, bg
end

-- ─── NOTIFICATION ────────────────────────────────────────────
local _notifySG = nil
local function notify(msg, duration)
    if not _notifySG or not _notifySG.Parent then
        _notifySG = Instance.new("ScreenGui")
        _notifySG.Name = "AetherNotify"
        _notifySG.ResetOnSpawn = false
        _notifySG.IgnoreGuiInset = true
        pcall(function() _notifySG.Parent = CoreGui end)
        if not _notifySG.Parent then _notifySG.Parent = LP:WaitForChild("PlayerGui") end
    end

    local card = frame(_notifySG, UDim2.new(0,240,0,40),
        UDim2.new(1,-250, 1,-50), Theme.NotifyBG)
    card.BackgroundTransparency = 1
    corner(card)
    stroke(card, Theme.NotifyBorder)

    local bar = frame(card, UDim2.new(0,3,1,0), UDim2.new(0,0,0,0), Theme.NotifyBorder)
    corner(bar, UDim.new(0,3))

    local lbl = label(card, msg, 12, Theme.NotifyText, Theme.FontSemibold)
    lbl.Position = UDim2.new(0,14,0,0)
    lbl.Size     = UDim2.new(1,-18,1,0)

    tw(card, {BackgroundTransparency = 0}, 0.2)
    task.delay(duration or 3, function()
        tw(card, {BackgroundTransparency = 1}, 0.2)
        task.wait(0.25)
        card:Destroy()
    end)
end

-- ─── WINDOW ──────────────────────────────────────────────────
local Window = {}
Window.__index = Window

function AetherUI:CreateWindow(opts)
    opts = opts or {}
    local winTitle  = opts.Title    or "AetherUI"
    local winSize   = opts.Size     or UDim2.new(0,620,0,480)
    local winPos    = opts.Position or UDim2.new(0.5,-310,0.5,-240)

    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name           = "AetherUI"
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset = true
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = LP:WaitForChild("PlayerGui") end

    -- Root window
    local win = frame(sg, winSize, winPos, Theme.WindowBG)
    win.Name = "Window"
    corner(win, Theme.RadiusWindow)
    stroke(win, Theme.Border, 0.5)
    win.ClipsDescendants = true

    -- ── TITLEBAR ─────────────────────────────────────────────
    local titlebar = frame(win, UDim2.new(1,0,0,38), UDim2.new(0,0,0,0), Theme.TitlebarBG)
    stroke(titlebar, Theme.Border, 0.5)
    -- cover bottom corners
    frame(win, UDim2.new(1,0,0,8), UDim2.new(0,0,0,30), Theme.TitlebarBG)

    -- macOS dots
    local dots = frame(titlebar, UDim2.new(0,60,1,0), UDim2.new(0,12,0,0), Color3.new(0,0,0), 1)
    local dotColors = {Theme.DotRed, Theme.DotYellow, Theme.DotGreen}
    for i=1,3 do
        local d = frame(dots, UDim2.new(0,12,0,12),
            UDim2.new(0,(i-1)*18, 0.5,-6), dotColors[i])
        corner(d, UDim.new(1,0))
    end

    -- Title
    local tLabel = label(titlebar, winTitle, 12, Theme.TextSecondary, Theme.Font, Enum.TextXAlignment.Center)
    tLabel.Size     = UDim2.new(1,0,1,0)
    tLabel.Position = UDim2.new(0,0,0,0)

    makeDraggable(win, titlebar)

    -- ── BODY ─────────────────────────────────────────────────
    local body = frame(win, UDim2.new(1,0,1,-38), UDim2.new(0,0,0,38), Color3.new(0,0,0), 1)

    -- ── SIDEBAR ──────────────────────────────────────────────
    local sidebar = frame(body, UDim2.new(0,148,1,0), UDim2.new(0,0,0,0), Theme.SidebarBG)
    stroke(sidebar, Theme.Border, 0.5)
    -- cover right border artifacts
    frame(body, UDim2.new(0,4,1,0), UDim2.new(0,144,0,0), Theme.SidebarBG)

    -- Logo
    local logoFrame = frame(sidebar, UDim2.new(1,0,0,36), UDim2.new(0,0,0,0), Color3.new(0,0,0), 1)
    pad(logoFrame, 12,10,0,14)
    local logoL = label(logoFrame, winTitle, 14, Theme.TextPrimary, Theme.FontBold)
    logoL.Size = UDim2.new(1,0,1,0)

    -- Nav scroll
    local navScroll = Instance.new("ScrollingFrame")
    navScroll.Size                   = UDim2.new(1,0,1,-36)
    navScroll.Position               = UDim2.new(0,0,0,36)
    navScroll.BackgroundTransparency = 1
    navScroll.BorderSizePixel        = 0
    navScroll.ScrollBarThickness     = 0
    navScroll.CanvasSize             = UDim2.new(0,0,0,0)
    navScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    navScroll.Parent                 = sidebar

    local navLayout = Instance.new("UIListLayout")
    navLayout.Padding   = UDim.new(0,2)
    navLayout.SortOrder = Enum.SortOrder.LayoutOrder
    navLayout.Parent    = navScroll
    pad(navScroll, 6,6,6,6)

    -- ── CONTENT AREA ─────────────────────────────────────────
    local content = frame(body, UDim2.new(1,-150,1,0), UDim2.new(0,150,0,0), Theme.MainBG, 1)
    content.ClipsDescendants = true

    -- ── WINDOW OBJECT ─────────────────────────────────────────
    local W = setmetatable({}, Window)
    W._sg        = sg
    W._win       = win
    W._sidebar   = sidebar
    W._navScroll = navScroll
    W._content   = content
    W._navItems  = {}
    W._pages     = {}
    W._navOrder  = 0
    W._activePage= nil
    W._apiKey    = nil

    -- ── ADD NAV (SEPARATOR) ───────────────────────────────────
    function W:AddSeparator()
        self._navOrder = self._navOrder + 1
        local sep = frame(navScroll, UDim2.new(1,0,0,1), nil, Theme.Separator)
        sep.LayoutOrder = self._navOrder
    end

    -- ── ADD PAGE ─────────────────────────────────────────────
    function W:AddPage(pageOpts)
        pageOpts = pageOpts or {}
        local pageName = pageOpts.Name or "Page"
        local pageIcon = pageOpts.Icon or ""  -- unused, kept for API compat

        self._navOrder = self._navOrder + 1
        local order    = self._navOrder

        -- Nav button
        local navBtn = Instance.new("TextButton")
        navBtn.Text              = pageName
        navBtn.Font              = Theme.Font
        navBtn.TextSize          = 12
        navBtn.TextColor3        = Theme.TextSecondary
        navBtn.BackgroundColor3  = Theme.SidebarBG
        navBtn.BackgroundTransparency = 1
        navBtn.BorderSizePixel   = 0
        navBtn.Size              = UDim2.new(1,0,0,30)
        navBtn.AutoButtonColor   = false
        navBtn.TextXAlignment    = Enum.TextXAlignment.Left
        navBtn.LayoutOrder       = order
        navBtn.Parent            = navScroll
        corner(navBtn, Theme.RadiusSmall)
        pad(navBtn, 0,8,0,10)

        -- Page container
        local pageFrame = frame(content, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Theme.MainBG, 1)
        pageFrame.Visible = false
        pageFrame.ClipsDescendants = true

        local function activate()
            for _, item in ipairs(self._navItems) do
                tw(item.btn, {BackgroundTransparency = 1, TextColor3 = Theme.TextSecondary}, 0.12)
                if item.page then item.page.Visible = false end
            end
            tw(navBtn, {BackgroundTransparency = 0, BackgroundColor3 = Theme.NavActiveBG, TextColor3 = Theme.NavActiveText}, 0.12)
            pageFrame.Visible = true
            self._activePage = pageOpts
        end

        navBtn.MouseButton1Click:Connect(activate)
        navBtn.MouseEnter:Connect(function()
            if self._activePage ~= pageOpts then
                tw(navBtn, {BackgroundTransparency = 0, BackgroundColor3 = Theme.NavHoverBG}, 0.1)
            end
        end)
        navBtn.MouseLeave:Connect(function()
            if self._activePage ~= pageOpts then
                tw(navBtn, {BackgroundTransparency = 1}, 0.1)
            end
        end)

        table.insert(self._navItems, {btn = navBtn, page = pageFrame, opts = pageOpts})
        if #self._navItems == 1 then activate() end

        -- ── PAGE OBJECT ──────────────────────────────────────
        local P = {}
        P._frame  = pageFrame
        P._win    = self

        -- ── PLUGIN LIST LAYOUT ───────────────────────────────
        -- Build: header (title+subtitle+openCfg+tabs+search) + list label + two-column grid
        function P:BuildPluginList(plOpts)
            plOpts = plOpts or {}
            local totalCount = plOpts.Count or 159

            -- Header
            local header = frame(pageFrame, UDim2.new(1,0,0,100), UDim2.new(0,0,0,0), Theme.HeaderBG)
            stroke(header, Theme.Border, 0.5)

            -- Title row
            local titleRow = frame(header, UDim2.new(1,0,0,44), UDim2.new(0,0,0,0), Color3.new(0,0,0), 1)
            pad(titleRow, 12,12,0,14)

            local titleL = label(titleRow, "Plugins", 15, Theme.TextPrimary, Theme.FontBold)
            titleL.Size  = UDim2.new(1,0,0,20)

            local subL = label(titleRow, "Configure and inspect the plugins installed in this deployment.", 11, Theme.TextMuted)
            subL.Position = UDim2.new(0,0,0,22)
            subL.Size     = UDim2.new(1,-110,0,16)

            -- Open cfg button
            local cfgBtn = textbtn(titleRow, "Open configuration file",
                UDim2.new(0,140,0,26), UDim2.new(1,-142,0.5,-13),
                Theme.BtnPrimary, Theme.BtnPrimaryText)
            corner(cfgBtn, Theme.RadiusSmall)
            stroke(cfgBtn, Theme.Border, 0.5)
            cfgBtn.TextSize = 11

            -- Tabs row
            local tabRow = frame(header, UDim2.new(1,0,0,28), UDim2.new(0,0,0,44), Color3.new(0,0,0), 1)
            pad(tabRow, 0,0,0,14)

            local tabCfg = textbtn(tabRow, "Plugin configuration",
                UDim2.new(0,140,1,0), UDim2.new(0,0,0,0),
                Color3.new(0,0,0), Theme.TabInactive)
            tabCfg.BackgroundTransparency = 1
            tabCfg.TextSize = 12
            tabCfg.TextXAlignment = Enum.TextXAlignment.Left

            local tabList = textbtn(tabRow, "Plugin list",
                UDim2.new(0,80,1,0), UDim2.new(0,144,0,0),
                Color3.new(0,0,0), Theme.TabActive)
            tabList.BackgroundTransparency = 1
            tabList.TextSize = 12
            tabList.Font = Theme.FontSemibold
            tabList.TextXAlignment = Enum.TextXAlignment.Left

            -- Active tab underline
            local underline = frame(tabRow, UDim2.new(0,80,0,2),
                UDim2.new(0,144,1,-2), Theme.TextPrimary)

            -- Search bar
            local searchFrame = frame(header, UDim2.new(1,-28,0,32),
                UDim2.new(0,14,0,74), Theme.SearchBG)
            corner(searchFrame, Theme.RadiusSmall)
            stroke(searchFrame, Theme.Border, 0.5)

            -- Search icon (simple circle+line)
            local searchIcon = frame(searchFrame, UDim2.new(0,12,0,12),
                UDim2.new(0,10,0.5,-6), Theme.TextDisabled)
            corner(searchIcon, UDim.new(1,0))

            local searchBox = Instance.new("TextBox")
            searchBox.PlaceholderText   = "Search plugins"
            searchBox.PlaceholderColor3 = Theme.TextDisabled
            searchBox.Text              = ""
            searchBox.Font              = Theme.Font
            searchBox.TextSize          = 12
            searchBox.TextColor3        = Theme.TextPrimary
            searchBox.BackgroundTransparency = 1
            searchBox.Size              = UDim2.new(1,-36,1,0)
            searchBox.Position          = UDim2.new(0,28,0,0)
            searchBox.TextXAlignment    = Enum.TextXAlignment.Left
            searchBox.ClearTextOnFocus  = false
            searchBox.Parent            = searchFrame

            -- List label row
            local listLabel = frame(pageFrame, UDim2.new(1,0,0,24), UDim2.new(0,0,0,100), Color3.new(0,0,0), 1)
            pad(listLabel, 0,14,0,14)

            local listL = label(listLabel, "Plugin list", 11, Theme.TextSecondary, Theme.FontSemibold)
            listL.Size = UDim2.new(0,70,1,0)

            local countL = label(listLabel, tostring(totalCount), 11, Theme.TextDisabled)
            countL.Position = UDim2.new(0,74,0,0)
            countL.Size     = UDim2.new(0,40,1,0)

            -- Two-column grid (ScrollingFrame)
            local gridScroll = Instance.new("ScrollingFrame")
            gridScroll.Size                   = UDim2.new(1,0,1,-124)
            gridScroll.Position               = UDim2.new(0,0,0,124)
            gridScroll.BackgroundTransparency = 1
            gridScroll.BorderSizePixel        = 0
            gridScroll.ScrollBarThickness     = 3
            gridScroll.ScrollBarImageColor3   = Theme.TextDisabled
            gridScroll.CanvasSize             = UDim2.new(0,0,0,0)
            gridScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
            gridScroll.Parent                 = pageFrame

            local gridLayout = Instance.new("UIGridLayout")
            gridLayout.CellSize         = UDim2.new(0.5,-7,0,36)
            gridLayout.CellPadding      = UDim2.new(0,5,0,5)
            gridLayout.SortOrder        = Enum.SortOrder.LayoutOrder
            gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            gridLayout.Parent           = gridScroll
            pad(gridScroll, 4,10,10,10)

            -- Plugin registry
            local plugins = {}
            local pluginFrames = {}

            local function refreshGrid(query)
                for _, pf in ipairs(pluginFrames) do pf:Destroy() end
                pluginFrames = {}
                local idx = 0
                for _, plug in ipairs(plugins) do
                    local q = (query or ""):lower()
                    if q == "" or plug.name:lower():find(q, 1, true) then
                        idx = idx + 1

                        local card = frame(gridScroll, UDim2.new(1,0,0,36), nil, Theme.PluginCardBG)
                        card.LayoutOrder = idx
                        corner(card, Theme.RadiusCard)
                        stroke(card, Theme.Border, 0.5)

                        -- Hover
                        local hoverBtn = Instance.new("TextButton")
                        hoverBtn.Text = "" hoverBtn.BackgroundTransparency = 1
                        hoverBtn.Size = UDim2.new(1,0,1,0)
                        hoverBtn.ZIndex = card.ZIndex + 5
                        hoverBtn.Parent = card
                        hoverBtn.MouseEnter:Connect(function() tw(card, {BackgroundColor3 = Theme.PluginCardHover}, 0.1) end)
                        hoverBtn.MouseLeave:Connect(function() tw(card, {BackgroundColor3 = Theme.PluginCardBG}, 0.1) end)

                        -- Plugin name
                        local nameL = label(card, plug.name, 12, plug.enabled and Theme.TextPrimary or Theme.TextDisabled, Theme.FontSemibold)
                        nameL.Size     = UDim2.new(1,-130,1,0)
                        nameL.Position = UDim2.new(0,10,0,0)

                        -- Badge + Toggle row (right side)
                        local rightFrame = frame(card, UDim2.new(0,120,1,0),
                            UDim2.new(1,-122,0,0), Color3.new(0,0,0), 1)

                        local badgeAPI, badgeBG = makeBadge(rightFrame, plug.enabled)
                        badgeBG.Position = UDim2.new(0,0,0.5,-9)

                        local toggleAPI, toggleBG = makeToggle(rightFrame, plug.enabled, nil)
                        toggleBG.Position = UDim2.new(1,-36,0.5,-9)

                        -- Wire toggle → name color + badge
                        local function onToggle(state)
                            plug.enabled = state
                            nameL.TextColor3 = state and Theme.TextPrimary or Theme.TextDisabled
                            badgeAPI:SetState(state)
                            pcall(function() if plug.callback then plug.callback(state) end end)
                        end

                        -- Re-create toggle with correct callback
                        toggleBG:Destroy()
                        local tAPI, tBG = makeToggle(rightFrame, plug.enabled, onToggle)
                        tBG.Position = UDim2.new(1,-36,0.5,-9)

                        table.insert(pluginFrames, card)
                    end
                end
                countL.Text = tostring(#pluginFrames)
            end

            -- Search filter
            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                refreshGrid(searchBox.Text)
            end)

            -- Tab switching
            local showingList = true
            local function switchTab(isListTab)
                showingList = isListTab
                if isListTab then
                    tw(tabList, {TextColor3 = Theme.TabActive}, 0.12)
                    tw(tabCfg,  {TextColor3 = Theme.TabInactive}, 0.12)
                    tw(underline, {Position = UDim2.new(0,144,1,-2), Size = UDim2.new(0,80,0,2)}, 0.15)
                    gridScroll.Visible  = true
                    listLabel.Visible   = true
                else
                    tw(tabList, {TextColor3 = Theme.TabInactive}, 0.12)
                    tw(tabCfg,  {TextColor3 = Theme.TabActive}, 0.12)
                    tw(underline, {Position = UDim2.new(0,0,1,-2), Size = UDim2.new(0,140,0,2)}, 0.15)
                    gridScroll.Visible  = false
                    listLabel.Visible   = false
                end
            end
            tabList.MouseButton1Click:Connect(function() switchTab(true) end)
            tabCfg.MouseButton1Click:Connect(function() switchTab(false) end)

            -- Plugin list API
            local PL = {}
            function PL:AddPlugin(plugOpts)
                plugOpts = plugOpts or {}
                table.insert(plugins, {
                    name     = plugOpts.Name     or "plugin",
                    enabled  = plugOpts.Default  ~= false,
                    callback = plugOpts.Callback or nil,
                })
                refreshGrid(searchBox.Text)
            end

            function PL:SetPlugins(list)
                plugins = {}
                for _, p in ipairs(list) do
                    table.insert(plugins, {
                        name     = p.Name     or p.name     or "plugin",
                        enabled  = p.Default  ~= false and (p.Enabled ~= false),
                        callback = p.Callback or p.callback or nil,
                    })
                end
                refreshGrid("")
            end

            return PL
        end

        -- ── SECTION (for non-plugin pages) ───────────────────
        function P:AddSection(sOpts)
            sOpts = sOpts or {}
            local sName = sOpts.Name or ""

            local scroll = Instance.new("ScrollingFrame")
            scroll.Size                   = UDim2.new(1,0,1,0)
            scroll.BackgroundTransparency = 1
            scroll.BorderSizePixel        = 0
            scroll.ScrollBarThickness     = 3
            scroll.ScrollBarImageColor3   = Theme.TextDisabled
            scroll.CanvasSize             = UDim2.new(0,0,0,0)
            scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
            scroll.Parent                 = pageFrame

            local sLayout = Instance.new("UIListLayout")
            sLayout.Padding   = UDim.new(0,6)
            sLayout.SortOrder = Enum.SortOrder.LayoutOrder
            sLayout.Parent    = scroll
            pad(scroll, 12,12,12,12)

            if sName ~= "" then
                local sLabel = label(scroll, sName, 10, Theme.TextMuted, Theme.FontBold)
                sLabel.LayoutOrder = 0
                sLabel.Size = UDim2.new(1,0,0,16)
            end

            local S = {_scroll = scroll, _order = 1}

            function S:AddToggle(tOpts)
                tOpts = tOpts or {}
                self._order = self._order + 1

                local row = frame(scroll, UDim2.new(1,0,0,34), nil, Theme.PluginCardBG)
                row.AutomaticSize = Enum.AutomaticSize.None
                row.LayoutOrder   = self._order
                corner(row, Theme.RadiusCard)
                stroke(row, Theme.Border, 0.5)
                pad(row, 0,10,0,12)

                local lbl = label(row, tOpts.Name or "Toggle", 13, Theme.TextPrimary)
                lbl.Size = UDim2.new(1,-50,1,0)

                local tAPI, tBG = makeToggle(row, tOpts.Default or false, tOpts.Callback)
                tBG.Position = UDim2.new(1,-36,0.5,-9)

                return tAPI
            end

            function S:AddSlider(slOpts)
                slOpts = slOpts or {}
                self._order = self._order + 1
                local mn   = slOpts.Min     or 0
                local mx   = slOpts.Max     or 100
                local def  = slOpts.Default or mn
                local suf  = slOpts.Suffix  or ""
                local cb   = slOpts.Callback

                local row = frame(scroll, UDim2.new(1,0,0,48), nil, Theme.PluginCardBG)
                row.LayoutOrder = self._order
                corner(row, Theme.RadiusCard)
                stroke(row, Theme.Border, 0.5)
                pad(row, 6,10,6,12)

                local topR = frame(row, UDim2.new(1,0,0,20), UDim2.new(0,0,0,0), Color3.new(0,0,0), 1)

                local nameL = label(topR, slOpts.Name or "Slider", 13, Theme.TextPrimary)
                nameL.Size = UDim2.new(1,-50,1,0)

                local val = math.clamp(def, mn, mx)
                local valL = label(topR, tostring(val)..suf, 12, Theme.BadgeOnText, Theme.FontBold, Enum.TextXAlignment.Right)
                valL.Size     = UDim2.new(0,45,1,0)
                valL.Position = UDim2.new(1,-45,0,0)

                local track = frame(row, UDim2.new(1,0,0,4), UDim2.new(0,0,0,30), Theme.ToggleOFF)
                corner(track, UDim.new(1,0))

                local fill = frame(track, UDim2.new((val-mn)/(mx-mn),0,1,0), UDim2.new(0,0,0,0), Theme.ToggleON)
                corner(fill, UDim.new(1,0))

                local knob = frame(track, UDim2.new(0,12,0,12),
                    UDim2.new((val-mn)/(mx-mn),-6,0.5,-6), Theme.ToggleKnob)
                corner(knob, UDim.new(1,0))

                local dragging = false
                track.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                        val = math.floor(mn + (mx-mn)*rel)
                        valL.Text    = tostring(val)..suf
                        fill.Size    = UDim2.new(rel,0,1,0)
                        knob.Position= UDim2.new(rel,-6,0.5,-6)
                        pcall(cb, val)
                    end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                        local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                        val = math.floor(mn + (mx-mn)*rel)
                        valL.Text    = tostring(val)..suf
                        fill.Size    = UDim2.new(rel,0,1,0)
                        knob.Position= UDim2.new(rel,-6,0.5,-6)
                        pcall(cb, val)
                    end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)

                local slAPI = {}
                function slAPI:Set(v)
                    val = math.clamp(v, mn, mx)
                    local rel = (val-mn)/(mx-mn)
                    valL.Text    = tostring(val)..suf
                    fill.Size    = UDim2.new(rel,0,1,0)
                    knob.Position= UDim2.new(rel,-6,0.5,-6)
                end
                function slAPI:Get() return val end
                return slAPI
            end

            function S:AddButton(bOpts)
                bOpts = bOpts or {}
                self._order = self._order + 1
                local btn = textbtn(scroll, bOpts.Name or "Button",
                    UDim2.new(1,0,0,34), nil, Theme.BtnPrimary, Theme.TextPrimary)
                btn.LayoutOrder = self._order
                btn.Font        = Theme.FontSemibold
                btn.TextSize    = 12
                corner(btn, Theme.RadiusCard)
                stroke(btn, Theme.Border, 0.5)
                btn.MouseEnter:Connect(function() tw(btn, {BackgroundColor3 = Theme.NavActiveBG}, 0.1) end)
                btn.MouseLeave:Connect(function() tw(btn, {BackgroundColor3 = Theme.BtnPrimary}, 0.1) end)
                btn.MouseButton1Click:Connect(function() pcall(bOpts.Callback or function()end) end)
                return btn
            end

            function S:AddTextBox(txOpts)
                txOpts = txOpts or {}
                self._order = self._order + 1

                local wrapper = frame(scroll, UDim2.new(1,0,0,54), nil, Color3.new(0,0,0), 1)
                wrapper.LayoutOrder = self._order

                local lbl = label(wrapper, txOpts.Name or "Input", 11, Theme.TextMuted)
                lbl.Size = UDim2.new(1,0,0,18)

                local inputF = frame(wrapper, UDim2.new(1,0,0,32), UDim2.new(0,0,0,20), Theme.InputBG)
                corner(inputF, Theme.RadiusSmall)
                stroke(inputF, Theme.Border, 0.5)

                local box = Instance.new("TextBox")
                box.PlaceholderText   = txOpts.Placeholder or ""
                box.PlaceholderColor3 = Theme.TextDisabled
                box.Text              = txOpts.Default or ""
                box.Font              = Theme.Font
                box.TextSize          = 12
                box.TextColor3        = Theme.TextPrimary
                box.BackgroundTransparency = 1
                box.Size              = UDim2.new(1,-16,1,0)
                box.Position          = UDim2.new(0,8,0,0)
                box.TextXAlignment    = Enum.TextXAlignment.Left
                box.ClearTextOnFocus  = false
                box.Parent            = inputF

                box.FocusLost:Connect(function(enter)
                    pcall(txOpts.Callback or function()end, box.Text, enter)
                end)

                local txAPI = {}
                function txAPI:Get() return box.Text end
                function txAPI:Set(v) box.Text = v end
                return txAPI
            end

            function S:AddDropdown(dOpts)
                dOpts = dOpts or {}
                local items   = dOpts.Items   or {}
                local def     = dOpts.Default or items[1] or ""
                local cb      = dOpts.Callback or function()end
                self._order   = self._order + 1
                local selected = def
                local open     = false

                local wrapper = frame(scroll, UDim2.new(1,0,0,54), nil, Color3.new(0,0,0), 1)
                wrapper.LayoutOrder = self._order
                wrapper.ClipsDescendants = false

                local lbl = label(wrapper, dOpts.Name or "Dropdown", 11, Theme.TextMuted)
                lbl.Size = UDim2.new(1,0,0,18)

                local dropBtn = textbtn(wrapper, selected.."  ▾",
                    UDim2.new(1,0,0,32), UDim2.new(0,0,0,20),
                    Theme.InputBG, Theme.TextPrimary)
                dropBtn.TextXAlignment = Enum.TextXAlignment.Left
                dropBtn.TextSize = 12
                corner(dropBtn, Theme.RadiusSmall)
                stroke(dropBtn, Theme.Border, 0.5)
                pad(dropBtn, 0,8,0,10)

                local listF = frame(nil, UDim2.new(1,0,0,0), UDim2.new(0,0,1,2), Theme.SearchBG)
                listF.ZIndex          = 20
                listF.AutomaticSize   = Enum.AutomaticSize.Y
                listF.Visible         = false
                listF.ClipsDescendants = false
                listF.Parent          = dropBtn
                corner(listF, Theme.RadiusSmall)
                stroke(listF, Theme.Border, 0.5)

                local lLayout = Instance.new("UIListLayout")
                lLayout.SortOrder = Enum.SortOrder.LayoutOrder
                lLayout.Parent    = listF
                pad(listF, 4,4,4,4)

                for i, item in ipairs(items) do
                    local iBtn = textbtn(listF, item, UDim2.new(1,0,0,26), nil,
                        Theme.SearchBG, Theme.TextSecondary)
                    iBtn.TextXAlignment = Enum.TextXAlignment.Left
                    iBtn.TextSize = 12
                    iBtn.LayoutOrder = i
                    iBtn.ZIndex = 21
                    corner(iBtn, UDim.new(0,4))
                    pad(iBtn, 0,6,0,6)
                    iBtn.MouseEnter:Connect(function() tw(iBtn,{BackgroundColor3=Theme.NavActiveBG,TextColor3=Theme.TextPrimary},0.1) end)
                    iBtn.MouseLeave:Connect(function() tw(iBtn,{BackgroundColor3=Theme.SearchBG,TextColor3=Theme.TextSecondary},0.1) end)
                    iBtn.MouseButton1Click:Connect(function()
                        selected = item
                        dropBtn.Text = item.."  ▾"
                        open = false; listF.Visible = false
                        pcall(cb, item)
                    end)
                end

                dropBtn.MouseButton1Click:Connect(function()
                    open = not open; listF.Visible = open
                end)

                local ddAPI = {}
                function ddAPI:Get() return selected end
                function ddAPI:Set(v) selected=v; dropBtn.Text=v.."  ▾" end
                return ddAPI
            end

            return S
        end

        -- ── GAME FETCHER ─────────────────────────────────────
        -- Scans the live game and returns a structured context string
        -- that gets injected into every AI script request as context.
        local function fetchGameContext()
            local ctx = {}

            -- Basic game info
            table.insert(ctx, "=== GAME INFO ===")
            table.insert(ctx, "PlaceId: "   .. tostring(game.PlaceId))
            table.insert(ctx, "GameId: "    .. tostring(game.GameId))
            table.insert(ctx, "PlaceName: " .. tostring(game:GetService("MarketplaceService") and "N/A" or "N/A"))

            -- LocalPlayer
            local lp = game:GetService("Players").LocalPlayer
            table.insert(ctx, "\n=== LOCAL PLAYER ===")
            table.insert(ctx, "Name: "        .. tostring(lp.Name))
            table.insert(ctx, "DisplayName: " .. tostring(lp.DisplayName))
            table.insert(ctx, "UserId: "      .. tostring(lp.UserId))
            table.insert(ctx, "Team: "        .. tostring(lp.Team and lp.Team.Name or "None"))

            -- Character
            local char = lp.Character
            if char then
                table.insert(ctx, "\n=== CHARACTER ===")
                table.insert(ctx, "Character: " .. char.Name)
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    table.insert(ctx, "Health: "    .. tostring(math.floor(hum.Health)))
                    table.insert(ctx, "MaxHealth: " .. tostring(math.floor(hum.MaxHealth)))
                    table.insert(ctx, "WalkSpeed: " .. tostring(hum.WalkSpeed))
                    table.insert(ctx, "JumpPower: " .. tostring(hum.JumpPower))
                    table.insert(ctx, "HumState: "  .. tostring(hum:GetState()))
                end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local pos = hrp.Position
                    table.insert(ctx, "Position: "  .. string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z))
                end
                -- Tools in character
                local tools = {}
                for _, v in ipairs(char:GetChildren()) do
                    if v:IsA("Tool") then table.insert(tools, v.Name) end
                end
                if #tools > 0 then
                    table.insert(ctx, "CharTools: " .. table.concat(tools, ", "))
                end
            end

            -- Backpack tools
            local bp = lp:FindFirstChildOfClass("Backpack")
            if bp then
                local tools = {}
                for _, v in ipairs(bp:GetChildren()) do
                    if v:IsA("Tool") then table.insert(tools, v.Name) end
                end
                if #tools > 0 then
                    table.insert(ctx, "\n=== BACKPACK ===")
                    table.insert(ctx, table.concat(tools, ", "))
                end
            end

            -- All players
            table.insert(ctx, "\n=== ALL PLAYERS ===")
            local players = game:GetService("Players"):GetPlayers()
            for _, p in ipairs(players) do
                local pchar  = p.Character
                local health = "?"
                if pchar then
                    local h = pchar:FindFirstChildOfClass("Humanoid")
                    if h then health = tostring(math.floor(h.Health)).."/"..tostring(math.floor(h.MaxHealth)) end
                end
                local pos = "?"
                if pchar and pchar:FindFirstChild("HumanoidRootPart") then
                    local pp = pchar.HumanoidRootPart.Position
                    pos = string.format("%.0f,%.0f,%.0f", pp.X, pp.Y, pp.Z)
                end
                table.insert(ctx, string.format("  [%s] HP:%s Pos:%s Team:%s",
                    p.Name, health, pos, tostring(p.Team and p.Team.Name or "None")))
            end

            -- Workspace top-level objects (first 60, skip baseplate/terrain noise)
            table.insert(ctx, "\n=== WORKSPACE OBJECTS (top-level, up to 60) ===")
            local ws    = game:GetService("Workspace")
            local count = 0
            for _, obj in ipairs(ws:GetChildren()) do
                if count >= 60 then table.insert(ctx, "  ... (truncated)") break end
                local classInfo = obj.ClassName
                local extra = ""
                -- For Models, note primary part name
                if obj:IsA("Model") then
                    local prim = obj.PrimaryPart
                    extra = " [Model" .. (prim and (" PrimaryPart="..prim.Name) or "") .. "]"
                elseif obj:IsA("Part") or obj:IsA("UnionOperation") or obj:IsA("MeshPart") then
                    local pos = obj.Position
                    extra = string.format(" [Part pos=%.0f,%.0f,%.0f]", pos.X, pos.Y, pos.Z)
                elseif obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                    extra = " [Script]"
                elseif obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    extra = " [Remote]"
                elseif obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
                    extra = " [Bindable]"
                elseif obj:IsA("Folder") then
                    extra = " [Folder children=" .. tostring(#obj:GetChildren()) .. "]"
                end
                table.insert(ctx, "  " .. obj.Name .. " (" .. classInfo .. ")" .. extra)
                count = count + 1
            end

            -- RemoteEvents/Functions anywhere in game (for exploit context)
            table.insert(ctx, "\n=== REMOTES (Workspace + ReplicatedStorage, up to 30) ===")
            local remotes = {}
            local function scanRemotes(parent, depth)
                if depth > 4 then return end
                for _, v in ipairs(parent:GetChildren()) do
                    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                        table.insert(remotes, v:GetFullName() .. " [" .. v.ClassName .. "]")
                    end
                    if #remotes < 30 then scanRemotes(v, depth+1) end
                end
            end
            pcall(scanRemotes, ws, 0)
            pcall(scanRemotes, game:GetService("ReplicatedStorage"), 0)
            if #remotes == 0 then
                table.insert(ctx, "  None found")
            else
                for _, r in ipairs(remotes) do
                    table.insert(ctx, "  " .. r)
                end
            end

            -- ReplicatedStorage top-level
            table.insert(ctx, "\n=== REPLICATED STORAGE (top-level) ===")
            local ok, rs = pcall(function() return game:GetService("ReplicatedStorage") end)
            if ok and rs then
                local rsCount = 0
                for _, v in ipairs(rs:GetChildren()) do
                    if rsCount >= 30 then table.insert(ctx, "  ... (truncated)") break end
                    table.insert(ctx, "  " .. v.Name .. " (" .. v.ClassName .. ")")
                    rsCount = rsCount + 1
                end
            end

            -- StarterGui top-level (UI clues)
            table.insert(ctx, "\n=== STARTER GUI (top-level) ===")
            local ok2, sg2 = pcall(function() return game:GetService("StarterGui") end)
            if ok2 and sg2 then
                for _, v in ipairs(sg2:GetChildren()) do
                    table.insert(ctx, "  " .. v.Name .. " (" .. v.ClassName .. ")")
                end
            end

            -- Lighting
            table.insert(ctx, "\n=== LIGHTING ===")
            local lit = game:GetService("Lighting")
            table.insert(ctx, "Ambient: "     .. tostring(lit.Ambient))
            table.insert(ctx, "Brightness: "  .. tostring(lit.Brightness))
            table.insert(ctx, "TimeOfDay: "   .. tostring(lit.TimeOfDay))
            table.insert(ctx, "FogEnd: "      .. tostring(lit.FogEnd))

            return table.concat(ctx, "\n")
        end

        -- ── AI SCRIPT WRITER PAGE ─────────────────────────────
        -- Fetches game context, sends to Claude, returns executable Lua
        function P:BuildScriptAI()
            -- Layout: top toolbar | left: chat | right: code output
            local toolbar = frame(pageFrame, UDim2.new(1,0,0,40), UDim2.new(0,0,0,0), Theme.TitlebarBG)
            stroke(toolbar, Theme.Border, 0.5)
            pad(toolbar, 6,10,6,10)

            -- Toolbar label
            local toolbarLabel = label(toolbar, "🤖  AI Script Writer", 13, Theme.TextPrimary, Theme.FontBold)
            toolbarLabel.Size = UDim2.new(0,200,1,0)

            -- Fetch button
            local fetchBtn = textbtn(toolbar, "⟳  Fetch Game",
                UDim2.new(0,110,0,28), UDim2.new(1,-240,0.5,-14),
                Theme.BtnPrimary, Theme.TextPrimary)
            fetchBtn.TextSize = 11
            corner(fetchBtn, Theme.RadiusSmall)
            stroke(fetchBtn, Theme.Border, 0.5)

            -- Execute button
            local execBtn = textbtn(toolbar, "▶  Execute Script",
                UDim2.new(0,120,0,28), UDim2.new(1,-124,0.5,-14),
                Theme.ToggleON, Theme.TextPrimary)
            execBtn.TextSize = 11
            corner(execBtn, Theme.RadiusSmall)

            -- Status bar
            local statusL = label(toolbar, "Ready — fetch game first", 10, Theme.TextDisabled)
            statusL.Size     = UDim2.new(1,0,0,12)
            statusL.Position = UDim2.new(0,0,1,-2)

            -- Left panel: chat
            local leftPanel = frame(pageFrame, UDim2.new(0.45,0,1,-40), UDim2.new(0,0,0,40), Theme.MainBG)
            local rightDivider = frame(pageFrame, UDim2.new(0,1,1,-40), UDim2.new(0.45,0,0,40), Theme.Border)

            -- Right panel: generated code
            local rightPanel = frame(pageFrame, UDim2.new(0.55,-1,1,-40), UDim2.new(0.45,1,0,40), Theme.SidebarBG)

            -- Right header
            local rightHeader = frame(rightPanel, UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), Theme.TitlebarBG)
            stroke(rightHeader, Theme.Border, 0.5)
            local codeLabel = label(rightHeader, "Generated Script", 11, Theme.TextSecondary, Theme.FontSemibold)
            codeLabel.Position = UDim2.new(0,10,0,0)
            codeLabel.Size     = UDim2.new(1,0,1,0)

            -- Code display (ScrollingFrame with monospace label)
            local codeScroll = Instance.new("ScrollingFrame")
            codeScroll.Size                   = UDim2.new(1,0,1,-28)
            codeScroll.Position               = UDim2.new(0,0,0,28)
            codeScroll.BackgroundTransparency = 1
            codeScroll.BorderSizePixel        = 0
            codeScroll.ScrollBarThickness     = 3
            codeScroll.ScrollBarImageColor3   = Theme.TextDisabled
            codeScroll.CanvasSize             = UDim2.new(0,0,0,0)
            codeScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
            codeScroll.Parent                 = rightPanel
            pad(codeScroll, 8,8,8,8)

            local codeText = Instance.new("TextLabel")
            codeText.Text              = "-- Generated script will appear here\n-- Ask AI to write a script on the left"
            codeText.Font              = Enum.Font.Code
            codeText.TextSize          = 11
            codeText.TextColor3        = Theme.BadgeOnText
            codeText.BackgroundTransparency = 1
            codeText.Size              = UDim2.new(1,0,0,0)
            codeText.AutomaticSize     = Enum.AutomaticSize.Y
            codeText.TextXAlignment    = Enum.TextXAlignment.Left
            codeText.TextYAlignment    = Enum.TextYAlignment.Top
            codeText.TextWrapped       = true
            codeText.RichText          = false
            codeText.Parent            = codeScroll

            -- Left: messages scroll
            local msgScroll = Instance.new("ScrollingFrame")
            msgScroll.Size                   = UDim2.new(1,0,1,-50)
            msgScroll.BackgroundTransparency = 1
            msgScroll.BorderSizePixel        = 0
            msgScroll.ScrollBarThickness     = 3
            msgScroll.ScrollBarImageColor3   = Theme.TextDisabled
            msgScroll.CanvasSize             = UDim2.new(0,0,0,0)
            msgScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
            msgScroll.Parent                 = leftPanel
            pad(msgScroll, 8,8,8,8)

            local msgLayout = Instance.new("UIListLayout")
            msgLayout.Padding   = UDim.new(0,6)
            msgLayout.SortOrder = Enum.SortOrder.LayoutOrder
            msgLayout.Parent    = msgScroll

            -- Left: input row
            local inputRow2 = frame(leftPanel, UDim2.new(1,0,0,44),
                UDim2.new(0,0,1,-44), Theme.TitlebarBG)
            stroke(inputRow2, Theme.Border, 0.5)
            pad(inputRow2, 5,6,5,6)

            local aiInput = Instance.new("TextBox")
            aiInput.PlaceholderText   = "e.g. write an ESP script for all players"
            aiInput.PlaceholderColor3 = Theme.TextDisabled
            aiInput.Text              = ""
            aiInput.Font              = Theme.Font
            aiInput.TextSize          = 12
            aiInput.TextColor3        = Theme.TextPrimary
            aiInput.BackgroundColor3  = Theme.InputBG
            aiInput.BorderSizePixel   = 0
            aiInput.Size              = UDim2.new(1,-42,1,0)
            aiInput.TextXAlignment    = Enum.TextXAlignment.Left
            aiInput.ClearTextOnFocus  = false
            aiInput.Parent            = inputRow2
            corner(aiInput, Theme.RadiusSmall)
            stroke(aiInput, Theme.Border, 0.5)
            pad(aiInput, 0,8,0,10)

            local sendBtn2 = textbtn(inputRow2, "►",
                UDim2.new(0,34,0,34), UDim2.new(1,-36,0.5,-17),
                Theme.ToggleON, Theme.TextPrimary)
            sendBtn2.TextSize = 12
            corner(sendBtn2, Theme.RadiusSmall)

            -- State
            local gameCtx      = nil
            local scriptHistory = {}
            local msgOrder2    = 0
            local lastScript   = ""

            local function addMsg2(text, isUser, isCode)
                msgOrder2 = msgOrder2 + 1
                local bubble = frame(msgScroll, UDim2.new(isUser and 0.9 or 1,0,0,0), nil,
                    isUser and Theme.MsgUserBG or (isCode and Theme.SidebarBG or Theme.MsgAIBG))
                bubble.AutomaticSize = Enum.AutomaticSize.Y
                bubble.LayoutOrder  = msgOrder2
                if isUser then bubble.Position = UDim2.new(0.1,0,0,0) end
                corner(bubble, Theme.RadiusCard)
                if isCode then stroke(bubble, Theme.Border, 0.5) end
                pad(bubble, 6,8,6,8)

                local lbl2 = Instance.new("TextLabel")
                lbl2.Text              = text
                lbl2.TextSize          = isCode and 10 or 12
                lbl2.TextColor3        = isCode and Theme.BadgeOnText or (isUser and Theme.TextPrimary or Theme.TextSecondary)
                lbl2.Font              = isCode and Enum.Font.Code or Theme.Font
                lbl2.BackgroundTransparency = 1
                lbl2.TextWrapped       = true
                lbl2.TextXAlignment    = Enum.TextXAlignment.Left
                lbl2.Size              = UDim2.new(1,0,0,0)
                lbl2.AutomaticSize     = Enum.AutomaticSize.Y
                lbl2.Parent            = bubble

                task.wait()
                msgScroll.CanvasPosition = Vector2.new(0, msgScroll.AbsoluteCanvasSize.Y)
            end

            -- Extract Lua code block from AI response
            local function extractCode(text)
                -- Try ```lua ... ``` first
                local code = text:match("```lua%s*\n(.-)```")
                if code then return code end
                -- Try ``` ... ```
                code = text:match("```%s*\n(.-)```")
                if code then return code end
                -- If entire response looks like Lua (starts with -- or local or game:)
                if text:match("^%-%-") or text:match("^local ") or text:match("^game:") or text:match("^for ") then
                    return text
                end
                return nil
            end

            -- HTTP helper (reused pattern)
            local function httpPost(url, headers, body)
                if syn and syn.request then
                    return syn.request({Url=url,Method="POST",Headers=headers,Body=body})
                elseif http and http.request then
                    return http.request({url=url,method="POST",headers=headers,body=body})
                elseif request then
                    return request({Url=url,Method="POST",Headers=headers,Body=body})
                else
                    error("No HTTP function found. Use Synapse X, KRNL, or Fluxus.")
                end
            end

            -- Core AI call with game context injected as system prompt
            local function callScriptAI(userMsg)
                if not _aiKey or _aiKey == "" then
                    addMsg2("No API key set. Go to Settings and enter your Claude API key.", false)
                    return
                end

                -- Build system prompt with live game data
                local systemPrompt = [[You are an expert Roblox Lua exploit/script developer.
You have access to the live game state below. Use it to write accurate, working scripts.
When writing scripts, always output ONLY the raw Lua code inside a ```lua code block.
No explanations outside the code block unless explicitly asked.
Use the game data to reference correct object names, positions, and remotes.
Scripts should work in an executor environment (Synapse X, KRNL, Fluxus).
Always use game:GetService() for services. Use pcall() for risky operations.

]] .. (gameCtx or "-- No game data fetched yet. User should click 'Fetch Game' first.")

                table.insert(scriptHistory, {role="user", content=userMsg})

                -- Thinking bubble
                local thinking2 = frame(msgScroll, UDim2.new(0.4,0,0,24), nil, Theme.MsgAIBG)
                thinking2.LayoutOrder = msgOrder2 + 1
                corner(thinking2)
                local tl2 = label(thinking2, "Writing script...", 11, Theme.TextSecondary)
                tl2.Size = UDim2.new(1,0,1,0)
                pad(thinking2,0,8,0,8)
                statusL.Text = "AI is writing your script..."

                local ok, result = pcall(function()
                    local body = HttpService:JSONEncode({
                        model      = "claude-sonnet-4-6",
                        max_tokens = 4096,
                        system     = systemPrompt,
                        messages   = scriptHistory,
                    })
                    local resp = httpPost(
                        "https://api.anthropic.com/v1/messages",
                        {["Content-Type"]="application/json",["x-api-key"]=_aiKey,["anthropic-version"]="2023-06-01"},
                        body
                    )
                    local data = HttpService:JSONDecode(resp.Body)
                    if data.error then error(data.error.message) end
                    return data.content[1].text
                end)

                thinking2:Destroy()

                if ok then
                    table.insert(scriptHistory, {role="assistant", content=result})
                    local code = extractCode(result)
                    if code then
                        lastScript = code
                        -- Show preview in chat (first 3 lines)
                        local lines    = {}
                        local lineCount = 0
                        for line in code:gmatch("[^\n]+") do
                            lineCount = lineCount + 1
                            if lineCount <= 4 then table.insert(lines, line) end
                        end
                        local preview = table.concat(lines, "\n") .. (lineCount > 4 and "\n-- ..." or "")
                        addMsg2(preview, false, true)
                        -- Full code in right panel
                        codeText.Text = code
                        statusL.Text  = "Script ready — " .. lineCount .. " lines. Click ▶ Execute to run."
                        addMsg2("Script generated (" .. lineCount .. " lines). Full code shown on the right. Click ▶ Execute.", false, false)
                    else
                        -- Pure text reply (follow-up question etc.)
                        addMsg2(result, false, false)
                        statusL.Text = "AI replied (no code this turn)."
                    end
                else
                    addMsg2("Error: " .. tostring(result), false)
                    statusL.Text = "Error — see message above."
                end
            end

            -- Fetch game button
            fetchBtn.MouseButton1Click:Connect(function()
                statusL.Text = "Fetching game data..."
                tw(fetchBtn, {BackgroundColor3 = Theme.ToggleON}, 0.1)
                task.spawn(function()
                    local ok, ctx = pcall(fetchGameContext)
                    if ok then
                        gameCtx = ctx
                        statusL.Text = "Game fetched ✓ — " .. tostring(#ctx) .. " chars of context"
                        addMsg2("✓ Game data fetched! I can see:\n• " ..
                            tostring(#game:GetService("Players"):GetPlayers()) .. " players\n• Workspace objects\n• Remotes\nAsk me to write a script!", false)
                    else
                        statusL.Text = "Fetch failed: " .. tostring(ctx)
                        addMsg2("Failed to fetch game data: " .. tostring(ctx), false)
                    end
                    tw(fetchBtn, {BackgroundColor3 = Theme.BtnPrimary}, 0.1)
                end)
            end)

            -- Execute button
            execBtn.MouseButton1Click:Connect(function()
                if lastScript == "" then
                    addMsg2("No script generated yet. Ask me to write one first.", false)
                    return
                end
                statusL.Text = "Executing script..."
                local ok2, err2 = pcall(loadstring(lastScript))
                if ok2 then
                    statusL.Text = "✓ Script executed successfully."
                    addMsg2("✓ Script executed successfully.", false)
                else
                    statusL.Text = "✗ Execution error — see message."
                    addMsg2("✗ Execute error: " .. tostring(err2) .. "\n\nAsk me to fix it!", false)
                    -- Auto-send fix request
                    table.insert(scriptHistory, {role="user",
                        content="The script threw this error: " .. tostring(err2) .. "\nFix it and return the corrected full script."})
                    task.spawn(function()
                        callScriptAI("Fix the error above and return the corrected script.")
                    end)
                end
            end)

            -- Send message
            local function handleSend2()
                local msg = aiInput.Text
                if msg == "" or msg:match("^%s*$") then return end
                aiInput.Text = ""
                addMsg2(msg, true)
                task.spawn(callScriptAI, msg)
            end

            sendBtn2.MouseButton1Click:Connect(handleSend2)
            aiInput.FocusLost:Connect(function(enter) if enter then handleSend2() end end)

            -- Welcome message
            addMsg2("👾 AI Script Writer ready!\n\n1. Click ⟳ Fetch Game to scan the game\n2. Ask me anything:\n   • 'write an ESP for all players'\n   • 'make infinite jump'\n   • 'fire RemoteEvent [name] with args'\n   • 'write aimbot using HumanoidRootPart'\n3. Click ▶ Execute to run the script", false)
        end

        -- ── AI CHAT PAGE BUILDER ──────────────────────────────
        function P:BuildChat()
            local msgs_container = Instance.new("ScrollingFrame")
            msgs_container.Size                   = UDim2.new(1,0,1,-50)
            msgs_container.BackgroundTransparency = 1
            msgs_container.BorderSizePixel        = 0
            msgs_container.ScrollBarThickness     = 3
            msgs_container.ScrollBarImageColor3   = Theme.TextDisabled
            msgs_container.CanvasSize             = UDim2.new(0,0,0,0)
            msgs_container.AutomaticCanvasSize    = Enum.AutomaticSize.Y
            msgs_container.Parent                 = pageFrame

            local mLayout = Instance.new("UIListLayout")
            mLayout.Padding   = UDim.new(0,8)
            mLayout.SortOrder = Enum.SortOrder.LayoutOrder
            mLayout.Parent    = msgs_container
            pad(msgs_container, 10,10,10,10)

            local inputRow = frame(pageFrame, UDim2.new(1,0,0,44),
                UDim2.new(0,0,1,-44), Theme.TitlebarBG)
            stroke(inputRow, Theme.Border, 0.5)
            pad(inputRow, 5,8,5,8)

            local chatInput = Instance.new("TextBox")
            chatInput.PlaceholderText   = "Ask AI anything... (set API key in Settings)"
            chatInput.PlaceholderColor3 = Theme.TextDisabled
            chatInput.Text              = ""
            chatInput.Font              = Theme.Font
            chatInput.TextSize          = 12
            chatInput.TextColor3        = Theme.TextPrimary
            chatInput.BackgroundColor3  = Theme.InputBG
            chatInput.BorderSizePixel   = 0
            chatInput.Size              = UDim2.new(1,-44,1,0)
            chatInput.TextXAlignment    = Enum.TextXAlignment.Left
            chatInput.ClearTextOnFocus  = false
            chatInput.Parent            = inputRow
            corner(chatInput, Theme.RadiusSmall)
            stroke(chatInput, Theme.Border, 0.5)
            pad(chatInput, 0,8,0,10)

            local sendBtn = textbtn(inputRow, "►",
                UDim2.new(0,34,0,34), UDim2.new(1,-36,0.5,-17),
                Theme.ToggleON, Theme.TextPrimary)
            sendBtn.TextSize = 12
            corner(sendBtn, Theme.RadiusSmall)

            local msgOrder = 0
            local function addMsg(text, isUser)
                msgOrder = msgOrder + 1
                local bubble = frame(msgs_container, UDim2.new(0.82,0,0,0), nil,
                    isUser and Theme.MsgUserBG or Theme.MsgAIBG)
                bubble.AutomaticSize = Enum.AutomaticSize.Y
                bubble.LayoutOrder  = msgOrder
                if isUser then bubble.Position = UDim2.new(0.18,0,0,0) end
                corner(bubble, Theme.RadiusCard)
                pad(bubble, 8,10,8,10)

                local lbl = Instance.new("TextLabel")
                lbl.Text              = text
                lbl.TextSize          = 12
                lbl.TextColor3        = isUser and Theme.TextPrimary or Theme.TextSecondary
                lbl.Font              = Theme.Font
                lbl.BackgroundTransparency = 1
                lbl.TextWrapped       = true
                lbl.TextXAlignment    = Enum.TextXAlignment.Left
                lbl.Size              = UDim2.new(1,0,0,0)
                lbl.AutomaticSize     = Enum.AutomaticSize.Y
                lbl.Parent            = bubble

                task.wait()
                msgs_container.CanvasPosition = Vector2.new(0, msgs_container.AbsoluteCanvasSize.Y)
            end

            addMsg("Hello! Set your Claude API key in Settings to start chatting.", false)

            local function callAI(userMsg)
                if not _aiKey or _aiKey == "" then
                    addMsg("No API key set. Go to Settings → enter your Claude API key.", false)
                    return
                end
                table.insert(_aiHistory, {role="user", content=userMsg})
                local thinking = frame(msgs_container, UDim2.new(0.3,0,0,28), nil, Theme.MsgAIBG)
                thinking.LayoutOrder = msgOrder + 1
                corner(thinking)
                local tl = label(thinking, "...", 12, Theme.TextSecondary)
                tl.Size = UDim2.new(1,0,1,0)
                pad(thinking,0,10,0,10)

                local ok, result = pcall(function()
                    local body = HttpService:JSONEncode({
                        model      = "claude-sonnet-4-6",
                        max_tokens = 1024,
                        messages   = _aiHistory,
                    })
                    local response
                    if syn and syn.request then
                        response = syn.request({
                            Url="https://api.anthropic.com/v1/messages",Method="POST",
                            Headers={["Content-Type"]="application/json",["x-api-key"]=_aiKey,["anthropic-version"]="2023-06-01"},
                            Body=body})
                    elseif http and http.request then
                        response = http.request({
                            url="https://api.anthropic.com/v1/messages",method="POST",
                            headers={["Content-Type"]="application/json",["x-api-key"]=_aiKey,["anthropic-version"]="2023-06-01"},
                            body=body})
                    elseif request then
                        response = request({
                            Url="https://api.anthropic.com/v1/messages",Method="POST",
                            Headers={["Content-Type"]="application/json",["x-api-key"]=_aiKey,["anthropic-version"]="2023-06-01"},
                            Body=body})
                    else
                        error("No HTTP function found. Use Synapse X, KRNL, or Fluxus.")
                    end
                    local data = HttpService:JSONDecode(response.Body)
                    if data.error then error(data.error.message) end
                    return data.content[1].text
                end)

                thinking:Destroy()
                if ok then
                    table.insert(_aiHistory, {role="assistant",content=result})
                    addMsg(result, false)
                else
                    addMsg("Error: "..tostring(result), false)
                end
            end

            local function handleSend()
                local msg = chatInput.Text
                if msg == "" or msg:match("^%s*$") then return end
                chatInput.Text = ""
                addMsg(msg, true)
                task.spawn(callAI, msg)
            end

            sendBtn.MouseButton1Click:Connect(handleSend)
            chatInput.FocusLost:Connect(function(enter) if enter then handleSend() end end)
        end

        return P
    end

    -- ── BUILT-IN PAGES ────────────────────────────────────────
    -- General (placeholder)
    local genPage = W:AddPage({Name="General"})
    local genSec  = genPage:AddSection({Name="GENERAL SETTINGS"})
    genSec:AddLabel = function(self, lOpts)
        self._order = self._order + 1
        local lbl = label(self._scroll, lOpts.Text or "", 12, Theme.TextMuted)
        lbl.LayoutOrder = self._order
        lbl.Size = UDim2.new(1,0,0,18)
    end

    -- Models (placeholder)
    W:AddPage({Name="Models"})
    W:AddSeparator()

    -- Plugins page — auto-built
    local plugPage  = W:AddPage({Name="Plugins"})
    local pluginList = plugPage:BuildPluginList({Count=159})
    W._pluginList   = pluginList

    -- Separator
    W:AddSeparator()

    -- AI Script Writer page
    local scriptPage = W:AddPage({Name="AI Script"})
    scriptPage:BuildScriptAI()

    -- AI Chat page
    local chatPage = W:AddPage({Name="AI Chat"})
    chatPage:BuildChat()

    -- Settings page
    local settPage = W:AddPage({Name="Settings"})
    local settSec  = settPage:AddSection({Name="AI CONFIGURATION"})

    local keyBox = settSec:AddTextBox({
        Name        = "Claude API Key",
        Placeholder = "sk-ant-api03-...",
        Callback    = function(val)
            _aiKey = val ~= "" and val or nil
        end,
    })

    settSec:AddButton({
        Name = "Save API Key",
        Callback = function()
            _aiKey = keyBox:Get()
            notify(_aiKey and "API key saved." or "Key cleared.")
        end,
    })

    settSec:AddButton({
        Name = "Clear Chat History",
        Callback = function()
            _aiHistory = {}
            notify("Chat history cleared.")
        end,
    })

    -- ── PUBLIC API ────────────────────────────────────────────
    function W:AddPlugin(opts)
        self._pluginList:AddPlugin(opts)
    end

    function W:SetPlugins(list)
        self._pluginList:SetPlugins(list)
    end

    function W:Notify(msg, duration)
        notify(msg, duration)
    end

    table.insert(_windows, W)
    return W
end

-- ─── INIT ────────────────────────────────────────────────────
function AetherUI:Init(opts)
    opts = opts or {}
    if opts.Theme then
        for k, v in pairs(opts.Theme) do Theme[k] = v end
    end
    _theme = Theme
    return self
end

return AetherUI
