-- AetherUI Library v1.0
-- GitHub: loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/AetherUI/main/AetherUI.lua"))()
-- Usage: local AetherUI = loadstring(...)()

local AetherUI = {}
AetherUI.__index = AetherUI

-- ══════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ══════════════════════════════════════════
-- THEME (macOS / WindUI inspired)
-- ══════════════════════════════════════════
local Theme = {
    Background     = Color3.fromRGB(20, 20, 22),
    Surface        = Color3.fromRGB(28, 28, 32),
    SurfaceHover   = Color3.fromRGB(36, 36, 42),
    Border         = Color3.fromRGB(55, 55, 65),
    BorderActive   = Color3.fromRGB(100, 100, 255),
    Accent         = Color3.fromRGB(99, 102, 241),
    AccentHover    = Color3.fromRGB(118, 121, 255),
    Text           = Color3.fromRGB(240, 240, 245),
    TextMuted      = Color3.fromRGB(140, 140, 160),
    TextDim        = Color3.fromRGB(90, 90, 110),
    Success        = Color3.fromRGB(52, 199, 89),
    Warning        = Color3.fromRGB(255, 159, 10),
    Danger         = Color3.fromRGB(255, 69, 58),
    Toggle_ON      = Color3.fromRGB(99, 102, 241),
    Toggle_OFF     = Color3.fromRGB(55, 55, 65),
    Scrollbar      = Color3.fromRGB(60, 60, 75),
    WindowShadow   = Color3.fromRGB(0, 0, 0),
    AIBubble_User  = Color3.fromRGB(99, 102, 241),
    AIBubble_Bot   = Color3.fromRGB(36, 36, 44),
    TitleBar       = Color3.fromRGB(22, 22, 26),
}

-- ══════════════════════════════════════════
-- UTILITY
-- ══════════════════════════════════════════
local function Tween(obj, props, duration, style, dir)
    style = style or Enum.EasingStyle.Quint
    dir   = dir   or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(duration or 0.2, style, dir), props):Play()
end

local function MakeRound(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = instance
    return corner
end

local function MakeStroke(instance, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = instance
    return stroke
end

local function MakePadding(instance, top, bottom, left, right)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, top    or 8)
    pad.PaddingBottom = UDim.new(0, bottom or 8)
    pad.PaddingLeft   = UDim.new(0, left   or 8)
    pad.PaddingRight  = UDim.new(0, right  or 8)
    pad.Parent = instance
    return pad
end

local function MakeLabel(parent, text, size, color, font)
    local lbl = Instance.new("TextLabel")
    lbl.Text = text or ""
    lbl.TextSize = size or 13
    lbl.TextColor3 = color or Theme.Text
    lbl.Font = font or Enum.Font.GothamMedium
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

local function DraggableFrame(frame, handle)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ══════════════════════════════════════════
-- CORE WINDOW
-- ══════════════════════════════════════════
function AetherUI:CreateWindow(config)
    config = config or {}
    local Title    = config.Title    or "AetherUI"
    local Subtitle = config.Subtitle or "v1.0"
    local Width    = config.Width    or 580
    local Height   = config.Height   or 420

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AetherUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = LocalPlayer.PlayerGui

    -- Shadow layer
    local Shadow = Instance.new("Frame")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(0, Width + 20, 0, Height + 20)
    Shadow.Position = UDim2.new(0.5, -(Width/2) - 10, 0.5, -(Height/2) - 10)
    Shadow.BackgroundColor3 = Theme.WindowShadow
    Shadow.BackgroundTransparency = 0.5
    Shadow.BorderSizePixel = 0
    Shadow.ZIndex = 0
    Shadow.Parent = ScreenGui
    MakeRound(Shadow, 16)

    -- Main window
    local Window = Instance.new("Frame")
    Window.Name = "Window"
    Window.Size = UDim2.new(0, Width, 0, Height)
    Window.Position = UDim2.new(0.5, -Width/2, 0.5, -Height/2)
    Window.BackgroundColor3 = Theme.Background
    Window.BorderSizePixel = 0
    Window.ClipsDescendants = true
    Window.ZIndex = 1
    Window.Parent = ScreenGui
    MakeRound(Window, 12)
    MakeStroke(Window, Theme.Border, 1)

    -- Title bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 48)
    TitleBar.BackgroundColor3 = Theme.TitleBar
    TitleBar.BorderSizePixel = 0
    TitleBar.ZIndex = 2
    TitleBar.Parent = Window

    -- macOS traffic lights
    local TrafficFrame = Instance.new("Frame")
    TrafficFrame.Size = UDim2.new(0, 60, 0, 12)
    TrafficFrame.Position = UDim2.new(0, 14, 0.5, -6)
    TrafficFrame.BackgroundTransparency = 1
    TrafficFrame.ZIndex = 3
    TrafficFrame.Parent = TitleBar

    local list = Instance.new("UIListLayout")
    list.FillDirection = Enum.FillDirection.Horizontal
    list.Padding = UDim.new(0, 8)
    list.VerticalAlignment = Enum.VerticalAlignment.Center
    list.Parent = TrafficFrame

    local dotColors = {Theme.Danger, Theme.Warning, Theme.Success}
    for _, col in ipairs(dotColors) do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 12, 0, 12)
        dot.BackgroundColor3 = col
        dot.BorderSizePixel = 0
        dot.ZIndex = 4
        dot.Parent = TrafficFrame
        MakeRound(dot, 6)
    end

    -- Title text
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text = Title
    TitleLabel.TextSize = 14
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0.5, -60, 0, 0)
    TitleLabel.Size = UDim2.new(0, 120, 1, 0)
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
    TitleLabel.ZIndex = 3
    TitleLabel.Parent = TitleBar

    local SubLabel = Instance.new("TextLabel")
    SubLabel.Text = Subtitle
    SubLabel.TextSize = 11
    SubLabel.Font = Enum.Font.Gotham
    SubLabel.TextColor3 = Theme.TextDim
    SubLabel.BackgroundTransparency = 1
    SubLabel.Position = UDim2.new(0.5, -60, 0, 28)
    SubLabel.Size = UDim2.new(0, 120, 0, 14)
    SubLabel.TextXAlignment = Enum.TextXAlignment.Center
    SubLabel.ZIndex = 3
    SubLabel.Parent = TitleBar

    -- Divider under titlebar
    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, 0, 0, 1)
    Divider.Position = UDim2.new(0, 0, 1, 0)
    Divider.BackgroundColor3 = Theme.Border
    Divider.BorderSizePixel = 0
    Divider.ZIndex = 2
    Divider.Parent = TitleBar

    -- Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 150, 1, -48)
    Sidebar.Position = UDim2.new(0, 0, 0, 48)
    Sidebar.BackgroundColor3 = Theme.Surface
    Sidebar.BorderSizePixel = 0
    Sidebar.ZIndex = 2
    Sidebar.Parent = Window

    local SidebarDivider = Instance.new("Frame")
    SidebarDivider.Size = UDim2.new(0, 1, 1, 0)
    SidebarDivider.Position = UDim2.new(1, 0, 0, 0)
    SidebarDivider.BackgroundColor3 = Theme.Border
    SidebarDivider.BorderSizePixel = 0
    SidebarDivider.ZIndex = 3
    SidebarDivider.Parent = Sidebar

    local SidebarList = Instance.new("UIListLayout")
    SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarList.Padding = UDim.new(0, 2)
    SidebarList.Parent = Sidebar
    MakePadding(Sidebar, 8, 8, 8, 8)

    -- Content area
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -150, 1, -48)
    ContentArea.Position = UDim2.new(0, 150, 0, 48)
    ContentArea.BackgroundColor3 = Theme.Background
    ContentArea.BorderSizePixel = 0
    ContentArea.ZIndex = 2
    ContentArea.ClipsDescendants = true
    ContentArea.Parent = Window

    DraggableFrame(Window, TitleBar)

    -- ── WINDOW OBJECT ──
    local WindowObj = {
        ScreenGui   = ScreenGui,
        Window      = Window,
        Sidebar     = Sidebar,
        ContentArea = ContentArea,
        Tabs        = {},
        ActiveTab   = nil,
    }

    -- ── TAB SYSTEM ──
    function WindowObj:AddTab(tabConfig)
        tabConfig = tabConfig or {}
        local TabName = tabConfig.Name or "Tab"
        local TabIcon = tabConfig.Icon or "☰"

        -- Sidebar button
        local TabBtn = Instance.new("TextButton")
        TabBtn.Text = TabIcon .. "  " .. TabName
        TabBtn.TextSize = 13
        TabBtn.Font = Enum.Font.GothamMedium
        TabBtn.TextColor3 = Theme.TextMuted
        TabBtn.BackgroundColor3 = Theme.Surface
        TabBtn.BackgroundTransparency = 1
        TabBtn.AutoButtonColor = false
        TabBtn.Size = UDim2.new(1, 0, 0, 34)
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        TabBtn.BorderSizePixel = 0
        TabBtn.ZIndex = 3
        TabBtn.LayoutOrder = #self.Tabs + 1
        TabBtn.Parent = self.Sidebar
        MakeRound(TabBtn, 7)
        MakePadding(TabBtn, 0, 0, 10, 0)

        -- Indicator stripe
        local Stripe = Instance.new("Frame")
        Stripe.Size = UDim2.new(0, 3, 0.6, 0)
        Stripe.Position = UDim2.new(0, -10, 0.2, 0)
        Stripe.BackgroundColor3 = Theme.Accent
        Stripe.BorderSizePixel = 0
        Stripe.ZIndex = 4
        Stripe.BackgroundTransparency = 1
        Stripe.Parent = TabBtn
        MakeRound(Stripe, 2)

        -- Tab page (scrollable)
        local Page = Instance.new("ScrollingFrame")
        Page.Name = TabName .. "Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Theme.Scrollbar
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        Page.Visible = false
        Page.ZIndex = 2
        Page.Parent = self.ContentArea

        local PageList = Instance.new("UIListLayout")
        PageList.SortOrder = Enum.SortOrder.LayoutOrder
        PageList.Padding = UDim.new(0, 6)
        PageList.Parent = Page
        MakePadding(Page, 12, 12, 14, 14)

        local TabObj = {
            Button  = TabBtn,
            Page    = Page,
            Stripe  = Stripe,
            Name    = TabName,
            Sections = {},
            _order  = 0,
        }

        -- Activate logic
        local function Activate()
            -- deactivate all
            for _, t in ipairs(WindowObj.Tabs) do
                Tween(t.Button, {TextColor3 = Theme.TextMuted, BackgroundTransparency = 1}, 0.15)
                Tween(t.Stripe, {BackgroundTransparency = 1}, 0.15)
                t.Page.Visible = false
            end
            -- activate this
            Tween(TabBtn, {TextColor3 = Theme.Text, BackgroundTransparency = 0.85}, 0.15)
            TabBtn.BackgroundColor3 = Theme.SurfaceHover
            Tween(Stripe, {BackgroundTransparency = 0}, 0.15)
            Page.Visible = true
            WindowObj.ActiveTab = TabObj
        end

        TabBtn.MouseButton1Click:Connect(Activate)
        TabBtn.MouseEnter:Connect(function()
            if WindowObj.ActiveTab ~= TabObj then
                Tween(TabBtn, {BackgroundTransparency = 0.9}, 0.1)
                TabBtn.BackgroundColor3 = Theme.SurfaceHover
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if WindowObj.ActiveTab ~= TabObj then
                Tween(TabBtn, {BackgroundTransparency = 1}, 0.1)
            end
        end)

        table.insert(self.Tabs, TabObj)
        if #self.Tabs == 1 then Activate() end

        -- ── SECTION ──
        function TabObj:AddSection(sectionConfig)
            sectionConfig = sectionConfig or {}
            local SectionName = sectionConfig.Name or "Section"

            local SectionFrame = Instance.new("Frame")
            SectionFrame.Name = SectionName
            SectionFrame.BackgroundColor3 = Theme.Surface
            SectionFrame.BorderSizePixel = 0
            SectionFrame.Size = UDim2.new(1, 0, 0, 0)
            SectionFrame.AutomaticSize = Enum.AutomaticSize.Y
            SectionFrame.LayoutOrder = TabObj._order
            TabObj._order = TabObj._order + 1
            SectionFrame.Parent = Page
            MakeRound(SectionFrame, 10)
            MakeStroke(SectionFrame, Theme.Border, 1)
            MakePadding(SectionFrame, 10, 10, 12, 12)

            local SectionLayout = Instance.new("UIListLayout")
            SectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
            SectionLayout.Padding = UDim.new(0, 8)
            SectionLayout.Parent = SectionFrame

            -- Section header
            local Header = Instance.new("Frame")
            Header.BackgroundTransparency = 1
            Header.Size = UDim2.new(1, 0, 0, 20)
            Header.LayoutOrder = 0
            Header.Parent = SectionFrame

            local SectionLabel = MakeLabel(Header, SectionName, 11, Theme.TextDim, Enum.Font.GothamBold)
            SectionLabel.Size = UDim2.new(1, 0, 1, 0)
            SectionLabel.TextTransparency = 0

            local HeaderLine = Instance.new("Frame")
            HeaderLine.Size = UDim2.new(1, 0, 0, 1)
            HeaderLine.Position = UDim2.new(0, 0, 1, 4)
            HeaderLine.BackgroundColor3 = Theme.Border
            HeaderLine.BorderSizePixel = 0
            HeaderLine.Parent = Header

            local SectionObj = {Frame = SectionFrame, _order = 1}

            -- ══════════════════════════════
            -- TOGGLE
            -- ══════════════════════════════
            function SectionObj:AddToggle(cfg)
                cfg = cfg or {}
                local Label    = cfg.Label    or "Toggle"
                local Default  = cfg.Default  or false
                local Callback = cfg.Callback or function() end
                local state = Default

                local Row = Instance.new("Frame")
                Row.BackgroundTransparency = 1
                Row.Size = UDim2.new(1, 0, 0, 32)
                Row.LayoutOrder = SectionObj._order
                SectionObj._order = SectionObj._order + 1
                Row.Parent = SectionFrame

                local Lbl = MakeLabel(Row, Label, 13, Theme.Text)
                Lbl.Size = UDim2.new(1, -54, 1, 0)

                local Track = Instance.new("Frame")
                Track.Size = UDim2.new(0, 44, 0, 24)
                Track.Position = UDim2.new(1, -44, 0.5, -12)
                Track.BackgroundColor3 = state and Theme.Toggle_ON or Theme.Toggle_OFF
                Track.BorderSizePixel = 0
                Track.Parent = Row
                MakeRound(Track, 12)

                local Knob = Instance.new("Frame")
                Knob.Size = UDim2.new(0, 18, 0, 18)
                Knob.Position = state and UDim2.new(0, 23, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
                Knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
                Knob.BorderSizePixel = 0
                Knob.Parent = Track
                MakeRound(Knob, 9)

                local Btn = Instance.new("TextButton")
                Btn.Size = UDim2.new(1, 0, 1, 0)
                Btn.BackgroundTransparency = 1
                Btn.Text = ""
                Btn.Parent = Row
                Btn.ZIndex = 5

                Btn.MouseButton1Click:Connect(function()
                    state = not state
                    Tween(Track, {BackgroundColor3 = state and Theme.Toggle_ON or Theme.Toggle_OFF}, 0.2)
                    Tween(Knob, {Position = state and UDim2.new(0,23,0.5,-9) or UDim2.new(0,3,0.5,-9)}, 0.2)
                    Callback(state)
                end)

                return {SetState = function(v)
                    state = v
                    Tween(Track, {BackgroundColor3 = v and Theme.Toggle_ON or Theme.Toggle_OFF}, 0.2)
                    Tween(Knob, {Position = v and UDim2.new(0,23,0.5,-9) or UDim2.new(0,3,0.5,-9)}, 0.2)
                end}
            end

            -- ══════════════════════════════
            -- SLIDER
            -- ══════════════════════════════
            function SectionObj:AddSlider(cfg)
                cfg = cfg or {}
                local Label    = cfg.Label    or "Slider"
                local Min      = cfg.Min      or 0
                local Max      = cfg.Max      or 100
                local Default  = cfg.Default  or Min
                local Suffix   = cfg.Suffix   or ""
                local Callback = cfg.Callback or function() end
                local value = Default

                local Container = Instance.new("Frame")
                Container.BackgroundTransparency = 1
                Container.Size = UDim2.new(1, 0, 0, 44)
                Container.LayoutOrder = SectionObj._order
                SectionObj._order = SectionObj._order + 1
                Container.Parent = SectionFrame

                local TopRow = Instance.new("Frame")
                TopRow.BackgroundTransparency = 1
                TopRow.Size = UDim2.new(1, 0, 0, 18)
                TopRow.Parent = Container

                local Lbl = MakeLabel(TopRow, Label, 13, Theme.Text)
                Lbl.Size = UDim2.new(0.7, 0, 1, 0)

                local ValLabel = MakeLabel(TopRow, tostring(value) .. Suffix, 12, Theme.Accent, Enum.Font.GothamBold)
                ValLabel.Size = UDim2.new(0.3, 0, 1, 0)
                ValLabel.Position = UDim2.new(0.7, 0, 0, 0)
                ValLabel.TextXAlignment = Enum.TextXAlignment.Right

                local Track = Instance.new("Frame")
                Track.Size = UDim2.new(1, 0, 0, 5)
                Track.Position = UDim2.new(0, 0, 0, 28)
                Track.BackgroundColor3 = Theme.Border
                Track.BorderSizePixel = 0
                Track.Parent = Container
                MakeRound(Track, 3)

                local Fill = Instance.new("Frame")
                Fill.Size = UDim2.new((value - Min) / (Max - Min), 0, 1, 0)
                Fill.BackgroundColor3 = Theme.Accent
                Fill.BorderSizePixel = 0
                Fill.Parent = Track
                MakeRound(Fill, 3)

                local Thumb = Instance.new("Frame")
                Thumb.Size = UDim2.new(0, 14, 0, 14)
                Thumb.Position = UDim2.new((value - Min)/(Max - Min), -7, 0.5, -7)
                Thumb.BackgroundColor3 = Color3.fromRGB(255,255,255)
                Thumb.BorderSizePixel = 0
                Thumb.ZIndex = 3
                Thumb.Parent = Track
                MakeRound(Thumb, 7)

                local Drag = Instance.new("TextButton")
                Drag.Size = UDim2.new(1, 0, 0, 20)
                Drag.Position = UDim2.new(0, 0, 0, -7)
                Drag.BackgroundTransparency = 1
                Drag.Text = ""
                Drag.ZIndex = 4
                Drag.Parent = Track

                local dragging = false
                Drag.MouseButton1Down:Connect(function() dragging = true end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                        local rel = (Mouse.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
                        rel = math.clamp(rel, 0, 1)
                        value = math.floor(Min + (Max - Min) * rel)
                        Fill.Size = UDim2.new(rel, 0, 1, 0)
                        Thumb.Position = UDim2.new(rel, -7, 0.5, -7)
                        ValLabel.Text = tostring(value) .. Suffix
                        Callback(value)
                    end
                end)
            end

            -- ══════════════════════════════
            -- BUTTON
            -- ══════════════════════════════
            function SectionObj:AddButton(cfg)
                cfg = cfg or {}
                local Label    = cfg.Label    or "Button"
                local Callback = cfg.Callback or function() end
                local Variant  = cfg.Variant  or "default" -- "default" | "danger" | "success"

                local BG = Variant == "danger" and Theme.Danger
                        or Variant == "success" and Theme.Success
                        or Theme.Accent

                local Btn = Instance.new("TextButton")
                Btn.Text = Label
                Btn.TextSize = 13
                Btn.Font = Enum.Font.GothamMedium
                Btn.TextColor3 = Color3.fromRGB(255,255,255)
                Btn.BackgroundColor3 = BG
                Btn.Size = UDim2.new(1, 0, 0, 34)
                Btn.BorderSizePixel = 0
                Btn.AutoButtonColor = false
                Btn.LayoutOrder = SectionObj._order
                SectionObj._order = SectionObj._order + 1
                Btn.Parent = SectionFrame
                MakeRound(Btn, 8)

                Btn.MouseEnter:Connect(function() Tween(Btn, {BackgroundTransparency = 0.2}, 0.1) end)
                Btn.MouseLeave:Connect(function() Tween(Btn, {BackgroundTransparency = 0}, 0.1) end)
                Btn.MouseButton1Click:Connect(function()
                    Tween(Btn, {BackgroundTransparency = 0.4}, 0.05)
                    task.delay(0.1, function() Tween(Btn, {BackgroundTransparency = 0}, 0.1) end)
                    Callback()
                end)
            end

            -- ══════════════════════════════
            -- TEXTBOX / INPUT
            -- ══════════════════════════════
            function SectionObj:AddInput(cfg)
                cfg = cfg or {}
                local Label       = cfg.Label       or "Input"
                local Placeholder = cfg.Placeholder or "Enter value..."
                local Default     = cfg.Default     or ""
                local Callback    = cfg.Callback    or function() end
                local IsPassword  = cfg.Password    or false

                local Container = Instance.new("Frame")
                Container.BackgroundTransparency = 1
                Container.Size = UDim2.new(1, 0, 0, 54)
                Container.LayoutOrder = SectionObj._order
                SectionObj._order = SectionObj._order + 1
                Container.Parent = SectionFrame

                local Lbl = MakeLabel(Container, Label, 12, Theme.TextMuted)
                Lbl.Size = UDim2.new(1, 0, 0, 18)

                local Box = Instance.new("TextBox")
                Box.PlaceholderText = Placeholder
                Box.Text = Default
                Box.TextSize = 13
                Box.Font = Enum.Font.Gotham
                Box.TextColor3 = Theme.Text
                Box.PlaceholderColor3 = Theme.TextDim
                Box.BackgroundColor3 = Theme.SurfaceHover
                Box.BorderSizePixel = 0
                Box.Size = UDim2.new(1, 0, 0, 32)
                Box.Position = UDim2.new(0, 0, 0, 22)
                Box.ClearTextOnFocus = false
                Box.TextXAlignment = Enum.TextXAlignment.Left
                Box.Parent = Container
                if IsPassword then Box.TextTransparency = 1 end
                MakeRound(Box, 7)
                MakePadding(Box, 0, 0, 10, 10)

                local stroke = MakeStroke(Box, Theme.Border, 1)
                Box.Focused:Connect(function() Tween(stroke, {Color = Theme.BorderActive}, 0.15) end)
                Box.FocusLost:Connect(function()
                    Tween(stroke, {Color = Theme.Border}, 0.15)
                    Callback(Box.Text)
                end)

                -- Password dots
                if IsPassword then
                    local Dots = MakeLabel(Box, "", 16, Theme.Text, Enum.Font.GothamBold)
                    Dots.Size = UDim2.new(1, -20, 1, 0)
                    Box:GetPropertyChangedSignal("Text"):Connect(function()
                        Dots.Text = string.rep("●", #Box.Text)
                    end)
                end

                return Box
            end

            -- ══════════════════════════════
            -- DROPDOWN
            -- ══════════════════════════════
            function SectionObj:AddDropdown(cfg)
                cfg = cfg or {}
                local Label    = cfg.Label    or "Dropdown"
                local Options  = cfg.Options  or {}
                local Default  = cfg.Default  or (Options[1] or "Select...")
                local Callback = cfg.Callback or function() end
                local selected = Default
                local open = false

                local Container = Instance.new("Frame")
                Container.BackgroundTransparency = 1
                Container.Size = UDim2.new(1, 0, 0, 54)
                Container.AutomaticSize = Enum.AutomaticSize.Y
                Container.LayoutOrder = SectionObj._order
                SectionObj._order = SectionObj._order + 1
                Container.Parent = SectionFrame
                Container.ClipsDescendants = false

                local Lbl = MakeLabel(Container, Label, 12, Theme.TextMuted)
                Lbl.Size = UDim2.new(1, 0, 0, 18)

                local DropBtn = Instance.new("TextButton")
                DropBtn.Text = selected
                DropBtn.TextSize = 13
                DropBtn.Font = Enum.Font.Gotham
                DropBtn.TextColor3 = Theme.Text
                DropBtn.BackgroundColor3 = Theme.SurfaceHover
                DropBtn.BorderSizePixel = 0
                DropBtn.AutoButtonColor = false
                DropBtn.Size = UDim2.new(1, 0, 0, 32)
                DropBtn.Position = UDim2.new(0, 0, 0, 22)
                DropBtn.TextXAlignment = Enum.TextXAlignment.Left
                DropBtn.Parent = Container
                MakeRound(DropBtn, 7)
                MakePadding(DropBtn, 0, 0, 10, 10)
                MakeStroke(DropBtn, Theme.Border, 1)

                -- Arrow
                local Arrow = MakeLabel(DropBtn, "▾", 14, Theme.TextMuted, Enum.Font.GothamBold)
                Arrow.Size = UDim2.new(0, 20, 1, 0)
                Arrow.Position = UDim2.new(1, -24, 0, 0)
                Arrow.TextXAlignment = Enum.TextXAlignment.Center

                -- Dropdown menu
                local Menu = Instance.new("Frame")
                Menu.BackgroundColor3 = Theme.Surface
                Menu.BorderSizePixel = 0
                Menu.Size = UDim2.new(1, 0, 0, 0)
                Menu.Position = UDim2.new(0, 0, 0, 56)
                Menu.ClipsDescendants = true
                Menu.ZIndex = 10
                Menu.Visible = false
                Menu.Parent = Container
                MakeRound(Menu, 8)
                MakeStroke(Menu, Theme.Border, 1)

                local MenuList = Instance.new("UIListLayout")
                MenuList.SortOrder = Enum.SortOrder.LayoutOrder
                MenuList.Padding = UDim.new(0, 2)
                MenuList.Parent = Menu
                MakePadding(Menu, 4, 4, 4, 4)

                for i, opt in ipairs(Options) do
                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Text = opt
                    OptBtn.TextSize = 13
                    OptBtn.Font = Enum.Font.Gotham
                    OptBtn.TextColor3 = Theme.Text
                    OptBtn.BackgroundColor3 = Theme.Surface
                    OptBtn.BackgroundTransparency = 1
                    OptBtn.AutoButtonColor = false
                    OptBtn.Size = UDim2.new(1, 0, 0, 30)
                    OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                    OptBtn.ZIndex = 11
                    OptBtn.LayoutOrder = i
                    OptBtn.Parent = Menu
                    MakeRound(OptBtn, 6)
                    MakePadding(OptBtn, 0, 0, 8, 8)

                    OptBtn.MouseEnter:Connect(function()
                        Tween(OptBtn, {BackgroundTransparency = 0.85, BackgroundColor3 = Theme.SurfaceHover}, 0.1)
                    end)
                    OptBtn.MouseLeave:Connect(function()
                        Tween(OptBtn, {BackgroundTransparency = 1}, 0.1)
                    end)
                    OptBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        DropBtn.Text = opt
                        open = false
                        Menu.Visible = false
                        Container.Size = UDim2.new(1, 0, 0, 54)
                        Callback(opt)
                    end)
                end

                local menuH = #Options * 32 + 8

                DropBtn.MouseButton1Click:Connect(function()
                    open = not open
                    Menu.Visible = open
                    if open then
                        Container.Size = UDim2.new(1, 0, 0, 54 + menuH + 4)
                        Tween(Menu, {Size = UDim2.new(1, 0, 0, menuH)}, 0.2)
                    else
                        Tween(Menu, {Size = UDim2.new(1, 0, 0, 0)}, 0.15)
                        task.delay(0.15, function() Container.Size = UDim2.new(1, 0, 0, 54) end)
                    end
                end)
            end

            -- ══════════════════════════════
            -- LABEL (static info)
            -- ══════════════════════════════
            function SectionObj:AddLabel(cfg)
                cfg = cfg or {}
                local Text  = cfg.Text  or ""
                local Color = cfg.Color or Theme.TextMuted
                local lbl = MakeLabel(SectionFrame, Text, 12, Color)
                lbl.Size = UDim2.new(1, 0, 0, 18)
                lbl.LayoutOrder = SectionObj._order
                SectionObj._order = SectionObj._order + 1
                lbl.TextWrapped = true
            end

            -- ══════════════════════════════
            -- SEPARATOR
            -- ══════════════════════════════
            function SectionObj:AddSeparator()
                local Sep = Instance.new("Frame")
                Sep.Size = UDim2.new(1, 0, 0, 1)
                Sep.BackgroundColor3 = Theme.Border
                Sep.BorderSizePixel = 0
                Sep.LayoutOrder = SectionObj._order
                SectionObj._order = SectionObj._order + 1
                Sep.Parent = SectionFrame
            end

            table.insert(TabObj.Sections, SectionObj)
            return SectionObj
        end

        return TabObj
    end

    -- ══════════════════════════════════════════
    -- AI CHAT TAB (built-in)
    -- ══════════════════════════════════════════
    function WindowObj:AddAIChat(cfg)
        cfg = cfg or {}
        local AIKey = cfg.APIKey or ""

        local ChatTab = self:AddTab({Name = "Chat", Icon = "✦"})

        -- Key section
        local KeySection = ChatTab:AddSection({Name = "AI CONFIGURATION"})
        local KeyBox = KeySection:AddInput({
            Label = "Anthropic API Key",
            Placeholder = "sk-ant-...",
            Default = AIKey,
            Password = true,
        })
        KeySection:AddLabel({Text = "Key is stored locally. Not sent anywhere except Anthropic.", Color = Theme.TextDim})

        -- Chat section
        local ChatSection = ChatTab:AddSection({Name = "CHAT"})

        -- Message history frame
        local HistoryFrame = Instance.new("ScrollingFrame")
        HistoryFrame.Size = UDim2.new(1, 0, 0, 180)
        HistoryFrame.BackgroundColor3 = Theme.Background
        HistoryFrame.BorderSizePixel = 0
        HistoryFrame.ScrollBarThickness = 2
        HistoryFrame.ScrollBarImageColor3 = Theme.Scrollbar
        HistoryFrame.CanvasSize = UDim2.new(0,0,0,0)
        HistoryFrame.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        HistoryFrame.LayoutOrder = ChatSection._order
        ChatSection._order = ChatSection._order + 1
        HistoryFrame.Parent = ChatSection.Frame
        MakeRound(HistoryFrame, 8)
        MakeStroke(HistoryFrame, Theme.Border, 1)

        local HList = Instance.new("UIListLayout")
        HList.SortOrder = Enum.SortOrder.LayoutOrder
        HList.Padding = UDim.new(0, 6)
        HList.Parent = HistoryFrame
        MakePadding(HistoryFrame, 8, 8, 8, 8)

        local messageCount = 0
        local history = {}

        local function AddBubble(text, isUser)
            messageCount = messageCount + 1
            local Bubble = Instance.new("Frame")
            Bubble.BackgroundColor3 = isUser and Theme.AIBubble_User or Theme.AIBubble_Bot
            Bubble.BorderSizePixel = 0
            Bubble.Size = UDim2.new(0.85, 0, 0, 0)
            Bubble.AutomaticSize = Enum.AutomaticSize.Y
            Bubble.LayoutOrder = messageCount
            Bubble.Position = isUser and UDim2.new(0.15, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
            Bubble.Parent = HistoryFrame
            MakeRound(Bubble, 8)
            MakePadding(Bubble, 8, 8, 10, 10)

            local BubbleLbl = Instance.new("TextLabel")
            BubbleLbl.Text = text
            BubbleLbl.TextSize = 12
            BubbleLbl.Font = Enum.Font.Gotham
            BubbleLbl.TextColor3 = Color3.fromRGB(255,255,255)
            BubbleLbl.BackgroundTransparency = 1
            BubbleLbl.Size = UDim2.new(1, 0, 0, 0)
            BubbleLbl.AutomaticSize = Enum.AutomaticSize.Y
            BubbleLbl.TextWrapped = true
            BubbleLbl.TextXAlignment = Enum.TextXAlignment.Left
            BubbleLbl.Parent = Bubble

            -- Scroll to bottom
            task.defer(function()
                HistoryFrame.CanvasPosition = Vector2.new(0, math.huge)
            end)
        end

        -- Input row
        local InputRow = Instance.new("Frame")
        InputRow.BackgroundTransparency = 1
        InputRow.Size = UDim2.new(1, 0, 0, 36)
        InputRow.LayoutOrder = ChatSection._order
        ChatSection._order = ChatSection._order + 1
        InputRow.Parent = ChatSection.Frame

        local ChatBox = Instance.new("TextBox")
        ChatBox.PlaceholderText = "Ask anything..."
        ChatBox.Text = ""
        ChatBox.TextSize = 13
        ChatBox.Font = Enum.Font.Gotham
        ChatBox.TextColor3 = Theme.Text
        ChatBox.PlaceholderColor3 = Theme.TextDim
        ChatBox.BackgroundColor3 = Theme.SurfaceHover
        ChatBox.BorderSizePixel = 0
        ChatBox.Size = UDim2.new(1, -46, 1, 0)
        ChatBox.ClearTextOnFocus = false
        ChatBox.TextXAlignment = Enum.TextXAlignment.Left
        ChatBox.Parent = InputRow
        MakeRound(ChatBox, 8)
        MakePadding(ChatBox, 0, 0, 10, 10)
        MakeStroke(ChatBox, Theme.Border, 1)

        local SendBtn = Instance.new("TextButton")
        SendBtn.Text = "▶"
        SendBtn.TextSize = 16
        SendBtn.Font = Enum.Font.GothamBold
        SendBtn.TextColor3 = Color3.fromRGB(255,255,255)
        SendBtn.BackgroundColor3 = Theme.Accent
        SendBtn.BorderSizePixel = 0
        SendBtn.AutoButtonColor = false
        SendBtn.Size = UDim2.new(0, 36, 1, 0)
        SendBtn.Position = UDim2.new(1, -36, 0, 0)
        SendBtn.Parent = InputRow
        MakeRound(SendBtn, 8)

        local function SendMessage()
            local userMsg = ChatBox.Text
            if userMsg == "" then return end
            local apiKey = KeyBox.Text
            if apiKey == "" then
                AddBubble("⚠ Set your API key above first.", false)
                return
            end

            AddBubble(userMsg, true)
            table.insert(history, {role = "user", content = userMsg})
            ChatBox.Text = ""

            AddBubble("...", false)
            local thinkingBubble = HistoryFrame:FindFirstChild("thinking_temp")

            task.spawn(function()
                local ok, result = pcall(function()
                    local payload = HttpService:JSONEncode({
                        model = "claude-sonnet-4-6",
                        max_tokens = 1024,
                        messages = history,
                    })

                    local response = game:HttpGet("https://api.anthropic.com/v1/messages", {
                        Method = "POST",
                        Headers = {
                            ["Content-Type"] = "application/json",
                            ["x-api-key"] = apiKey,
                            ["anthropic-version"] = "2023-06-01",
                        },
                        Body = payload,
                    })

                    local parsed = HttpService:JSONDecode(response)
                    return parsed.content[1].text
                end)

                -- Remove thinking bubble
                for _, child in ipairs(HistoryFrame:GetChildren()) do
                    if child:IsA("Frame") and child.LayoutOrder == messageCount then
                        child:Destroy()
                        messageCount = messageCount - 1
                        break
                    end
                end

                if ok then
                    table.insert(history, {role = "assistant", content = result})
                    AddBubble(result, false)
                else
                    AddBubble("⚠ API error. Check key and HttpService.", false)
                end
            end)
        end

        SendBtn.MouseButton1Click:Connect(SendMessage)
        UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.Return and ChatBox:IsFocused() then
                SendMessage()
            end
        end)

        return ChatTab
    end

    return WindowObj
end

return AetherUI
