-- AetherUI v2.0 | erebmig
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/erebmig/AetherUI/refs/heads/main/AetherUI.lua"))()

local AetherUI = {}
AetherUI.__index = AetherUI

-- ══════════════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════════════
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local LP               = Players.LocalPlayer

-- ══════════════════════════════════════════════════
-- THEME — dark, kompakt, fotoğraftaki gibi
-- ══════════════════════════════════════════════════
local T = {
    BG         = Color3.fromRGB(18, 18, 20),
    Surface    = Color3.fromRGB(26, 26, 30),
    SurfaceAlt = Color3.fromRGB(32, 32, 38),
    Border     = Color3.fromRGB(48, 48, 58),
    BorderFocus= Color3.fromRGB(99, 102, 241),
    Accent     = Color3.fromRGB(99, 102, 241),
    Text       = Color3.fromRGB(235, 235, 240),
    TextSub    = Color3.fromRGB(130, 130, 150),
    TextDim    = Color3.fromRGB(75, 75, 90),
    On         = Color3.fromRGB(99, 102, 241),
    Off        = Color3.fromRGB(50, 50, 60),
    Red        = Color3.fromRGB(255, 59, 48),
    Yellow     = Color3.fromRGB(255, 149, 0),
    Green      = Color3.fromRGB(50, 215, 75),
    UserBubble = Color3.fromRGB(99, 102, 241),
    BotBubble  = Color3.fromRGB(32, 32, 38),
}

-- ══════════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════════
local function tw(obj, props, t, s, d)
    TweenService:Create(obj, TweenInfo.new(t or 0.18, s or Enum.EasingStyle.Quint, d or Enum.EasingDirection.Out), props):Play()
end

local function round(f, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = f; return c
end

local function stroke(f, col, thick)
    local s = Instance.new("UIStroke")
    s.Color = col or T.Border; s.Thickness = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = f; return s
end

local function pad(f, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0,t or 6); p.PaddingBottom = UDim.new(0,b or 6)
    p.PaddingLeft = UDim.new(0,l or 6); p.PaddingRight = UDim.new(0,r or 6)
    p.Parent = f; return p
end

local function lbl(parent, txt, sz, col, font)
    local l = Instance.new("TextLabel")
    l.Text = txt or ""; l.TextSize = sz or 13
    l.TextColor3 = col or T.Text; l.Font = font or Enum.Font.GothamMedium
    l.BackgroundTransparency = 1; l.TextXAlignment = Enum.TextXAlignment.Left
    l.Size = UDim2.new(1,0,1,0); l.Parent = parent; return l
end

local function listLayout(parent, dir, pad_, align)
    local ll = Instance.new("UIListLayout")
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.FillDirection = dir or Enum.FillDirection.Vertical
    ll.Padding = UDim.new(0, pad_ or 4)
    if align then ll.HorizontalAlignment = align end
    ll.Parent = parent; return ll
end

-- Drag — OFFSET tabanlı, ClipsDescendants sorunu yok
local function makeDraggable(frame, handle)
    local dragging = false
    local dragStart, objStart

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        dragging = true
        dragStart = inp.Position
        objStart  = frame.Position
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local d = inp.Position - dragStart
        frame.Position = UDim2.new(
            objStart.X.Scale, objStart.X.Offset + d.X,
            objStart.Y.Scale, objStart.Y.Offset + d.Y
        )
    end)
end

-- ══════════════════════════════════════════════════
-- WINDOW
-- ══════════════════════════════════════════════════
function AetherUI:CreateWindow(cfg)
    cfg = cfg or {}
    local W  = cfg.Width  or 520
    local H  = cfg.Height or 380
    local Title = cfg.Title or "AetherUI"

    -- Eski UI temizle
    local old = LP.PlayerGui:FindFirstChild("AetherUI")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "AetherUI"; sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
    sg.IgnoreGuiInset = true
    sg.Parent = LP.PlayerGui

    -- Ana pencere
    local win = Instance.new("Frame")
    win.Name = "Win"
    win.Size = UDim2.new(0,W,0,H)
    win.Position = UDim2.new(0.5,-W/2,0.5,-H/2)
    win.BackgroundColor3 = T.BG
    win.BorderSizePixel = 0
    win.ClipsDescendants = false
    win.Parent = sg
    round(win, 10)
    stroke(win, T.Border, 1)

    -- Drop shadow (UIStroke yerine ayrı frame)
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1,16,1,16)
    shadow.Position = UDim2.new(0,-8,0,6)
    shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.ZIndex = win.ZIndex - 1
    shadow.Parent = win
    round(shadow, 14)

    -- İçerik clip frame (ClipsDescendants sadece burada)
    local clip = Instance.new("Frame")
    clip.Size = UDim2.new(1,0,1,0)
    clip.BackgroundTransparency = 1
    clip.BorderSizePixel = 0
    clip.ClipsDescendants = true
    clip.Parent = win

    -- ── TITLEBAR ──
    local tb = Instance.new("Frame")
    tb.Name = "TitleBar"
    tb.Size = UDim2.new(1,0,0,40)
    tb.BackgroundColor3 = T.Surface
    tb.BorderSizePixel = 0
    tb.Parent = clip

    -- macOS dots
    local dotF = Instance.new("Frame")
    dotF.Size = UDim2.new(0,56,0,12)
    dotF.Position = UDim2.new(0,12,0.5,-6)
    dotF.BackgroundTransparency = 1
    dotF.Parent = tb
    listLayout(dotF, Enum.FillDirection.Horizontal, 6)

    for _, col in ipairs({T.Red, T.Yellow, T.Green}) do
        local d = Instance.new("Frame")
        d.Size = UDim2.new(0,11,0,11); d.BackgroundColor3 = col
        d.BorderSizePixel = 0; d.Parent = dotF; round(d, 6)
    end

    -- Title
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Text = Title; titleLbl.TextSize = 13
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextColor3 = T.Text
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size = UDim2.new(1,0,1,0)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Center
    titleLbl.Parent = tb

    -- TB alt çizgi
    local tbLine = Instance.new("Frame")
    tbLine.Size = UDim2.new(1,0,0,1); tbLine.Position = UDim2.new(0,0,1,-1)
    tbLine.BackgroundColor3 = T.Border; tbLine.BorderSizePixel = 0; tbLine.Parent = tb

    makeDraggable(win, tb)

    -- ── SIDEBAR ──
    local sb = Instance.new("Frame")
    sb.Name = "Sidebar"
    sb.Size = UDim2.new(0,130,1,-40)
    sb.Position = UDim2.new(0,0,0,40)
    sb.BackgroundColor3 = T.Surface
    sb.BorderSizePixel = 0
    sb.Parent = clip
    pad(sb, 8, 8, 6, 6)
    listLayout(sb, Enum.FillDirection.Vertical, 2)

    local sbLine = Instance.new("Frame")
    sbLine.Size = UDim2.new(0,1,1,0); sbLine.Position = UDim2.new(1,-1,0,0)
    sbLine.BackgroundColor3 = T.Border; sbLine.BorderSizePixel = 0; sbLine.Parent = sb

    -- ── CONTENT ──
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1,-130,1,-40)
    content.Position = UDim2.new(0,130,0,40)
    content.BackgroundColor3 = T.BG
    content.BorderSizePixel = 0
    content.ClipsDescendants = true
    content.Parent = clip

    -- ══════════════════════════════════════════════════
    -- WINDOW OBJECT
    -- ══════════════════════════════════════════════════
    local WinObj = {_tabs = {}, _active = nil, _sb = sb, _content = content, _sg = sg}

    -- ── TAB ──
    function WinObj:AddTab(tcfg)
        tcfg = tcfg or {}
        local name = tcfg.Name or "Tab"
        local icon = tcfg.Icon or ""

        -- Sidebar butonu
        local btn = Instance.new("TextButton")
        btn.Text = icon ~= "" and (icon .. "  " .. name) or name
        btn.TextSize = 12; btn.Font = Enum.Font.GothamMedium
        btn.TextColor3 = T.TextSub
        btn.BackgroundColor3 = T.SurfaceAlt
        btn.BackgroundTransparency = 1
        btn.AutoButtonColor = false
        btn.Size = UDim2.new(1,0,0,30)
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.BorderSizePixel = 0
        btn.LayoutOrder = #self._tabs + 1
        btn.Parent = self._sb
        round(btn, 6); pad(btn, 0,0,8,0)

        -- Aktif stripe
        local stripe = Instance.new("Frame")
        stripe.Size = UDim2.new(0,3,0.55,0)
        stripe.Position = UDim2.new(0,-6,0.225,0)
        stripe.BackgroundColor3 = T.Accent
        stripe.BackgroundTransparency = 1
        stripe.BorderSizePixel = 0
        stripe.Parent = btn; round(stripe, 2)

        -- Sayfa (ScrollingFrame)
        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1,0,1,0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = Color3.fromRGB(60,60,80)
        page.CanvasSize = UDim2.new(0,0,0,0)
        page.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        page.Visible = false
        page.Parent = self._content
        listLayout(page, nil, 6)
        pad(page, 10,10,10,10)

        local TabObj = {_btn=btn, _page=page, _stripe=stripe, _sections={}, _order=0}

        local function activate()
            for _, t in ipairs(WinObj._tabs) do
                tw(t._btn, {TextColor3=T.TextSub, BackgroundTransparency=1}, 0.15)
                tw(t._stripe, {BackgroundTransparency=1}, 0.15)
                t._page.Visible = false
            end
            tw(btn, {TextColor3=T.Text, BackgroundTransparency=0.88}, 0.15)
            btn.BackgroundColor3 = T.SurfaceAlt
            tw(stripe, {BackgroundTransparency=0}, 0.15)
            page.Visible = true
            WinObj._active = TabObj
        end

        btn.MouseButton1Click:Connect(activate)
        btn.MouseEnter:Connect(function()
            if WinObj._active ~= TabObj then
                tw(btn, {BackgroundTransparency=0.94}, 0.1)
                btn.BackgroundColor3 = T.SurfaceAlt
            end
        end)
        btn.MouseLeave:Connect(function()
            if WinObj._active ~= TabObj then
                tw(btn, {BackgroundTransparency=1}, 0.1)
            end
        end)

        table.insert(self._tabs, TabObj)
        if #self._tabs == 1 then activate() end

        -- ── SECTION ──
        function TabObj:AddSection(scfg)
            scfg = scfg or {}
            local sname = scfg.Name or ""

            local sf = Instance.new("Frame")
            sf.BackgroundColor3 = T.Surface
            sf.BorderSizePixel = 0
            sf.Size = UDim2.new(1,0,0,0)
            sf.AutomaticSize = Enum.AutomaticSize.Y
            sf.LayoutOrder = TabObj._order; TabObj._order += 1
            sf.Parent = page
            round(sf, 8); stroke(sf, T.Border, 1); pad(sf, 8,8,10,10)
            listLayout(sf, nil, 6)

            -- Section başlık
            if sname ~= "" then
                local hdr = Instance.new("Frame")
                hdr.Size = UDim2.new(1,0,0,16); hdr.BackgroundTransparency = 1
                hdr.LayoutOrder = 0; hdr.Parent = sf
                lbl(hdr, sname, 10, T.TextDim, Enum.Font.GothamBold)
            end

            local SO = {_frame=sf, _order=1}

            -- ════════════════════════
            -- TOGGLE — ZIndex düzeltildi, Row üstüne tam kapak buton
            -- ════════════════════════
            function SO:AddToggle(c)
                c = c or {}
                local state = c.Default or false
                local cb    = c.Callback or function() end

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1,0,0,30)
                row.BackgroundTransparency = 1
                row.LayoutOrder = SO._order; SO._order += 1
                row.Parent = sf

                -- Label
                local l = Instance.new("TextLabel")
                l.Text = c.Label or "Toggle"; l.TextSize = 13
                l.Font = Enum.Font.GothamMedium; l.TextColor3 = T.Text
                l.BackgroundTransparency = 1
                l.Size = UDim2.new(1,-52,1,0)
                l.TextXAlignment = Enum.TextXAlignment.Left
                l.Parent = row

                -- Track
                local track = Instance.new("Frame")
                track.Size = UDim2.new(0,40,0,22)
                track.Position = UDim2.new(1,-40,0.5,-11)
                track.BackgroundColor3 = state and T.On or T.Off
                track.BorderSizePixel = 0
                track.Parent = row
                round(track, 11)

                -- Knob
                local knob = Instance.new("Frame")
                knob.Size = UDim2.new(0,16,0,16)
                knob.Position = state and UDim2.new(0,21,0.5,-8) or UDim2.new(0,3,0.5,-8)
                knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
                knob.BorderSizePixel = 0
                knob.Parent = track
                round(knob, 8)

                -- Tıklanabilir buton — row'un tamamını kaplar, ZIndex yeterli
                local clickBtn = Instance.new("TextButton")
                clickBtn.Size = UDim2.new(1,0,1,0)
                clickBtn.BackgroundTransparency = 1
                clickBtn.Text = ""; clickBtn.ZIndex = 10
                clickBtn.Parent = row

                clickBtn.MouseButton1Click:Connect(function()
                    state = not state
                    tw(track, {BackgroundColor3 = state and T.On or T.Off}, 0.18)
                    tw(knob, {Position = state and UDim2.new(0,21,0.5,-8) or UDim2.new(0,3,0.5,-8)}, 0.18)
                    cb(state)
                end)

                return {
                    Set = function(_, v)
                        state = v
                        tw(track, {BackgroundColor3 = v and T.On or T.Off}, 0.18)
                        tw(knob, {Position = v and UDim2.new(0,21,0.5,-8) or UDim2.new(0,3,0.5,-8)}, 0.18)
                    end,
                    Get = function() return state end
                }
            end

            -- ════════════════════════
            -- SLIDER — AbsolutePosition tabanlı, çalışır
            -- ════════════════════════
            function SO:AddSlider(c)
                c = c or {}
                local min  = c.Min or 0
                local max  = c.Max or 100
                local val  = c.Default or min
                local suf  = c.Suffix or ""
                local cb   = c.Callback or function() end

                local cont = Instance.new("Frame")
                cont.Size = UDim2.new(1,0,0,42)
                cont.BackgroundTransparency = 1
                cont.LayoutOrder = SO._order; SO._order += 1
                cont.Parent = sf

                -- Üst satır
                local topRow = Instance.new("Frame")
                topRow.Size = UDim2.new(1,0,0,16)
                topRow.BackgroundTransparency = 1
                topRow.Parent = cont

                local nameL = lbl(topRow, c.Label or "Slider", 13, T.Text)
                nameL.Size = UDim2.new(0.65,0,1,0)

                local valL = Instance.new("TextLabel")
                valL.Text = val..suf; valL.TextSize = 12
                valL.Font = Enum.Font.GothamBold; valL.TextColor3 = T.Accent
                valL.BackgroundTransparency = 1
                valL.Size = UDim2.new(0.35,0,1,0)
                valL.Position = UDim2.new(0.65,0,0,0)
                valL.TextXAlignment = Enum.TextXAlignment.Right
                valL.Parent = topRow

                -- Track
                local track = Instance.new("Frame")
                track.Size = UDim2.new(1,0,0,4)
                track.Position = UDim2.new(0,0,0,26)
                track.BackgroundColor3 = T.Border
                track.BorderSizePixel = 0; track.Parent = cont
                round(track, 3)

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new((val-min)/(max-min),0,1,0)
                fill.BackgroundColor3 = T.Accent
                fill.BorderSizePixel = 0; fill.Parent = track
                round(fill, 3)

                local thumb = Instance.new("Frame")
                thumb.Size = UDim2.new(0,13,0,13)
                thumb.AnchorPoint = Vector2.new(0.5,0.5)
                thumb.Position = UDim2.new((val-min)/(max-min),0,0.5,0)
                thumb.BackgroundColor3 = Color3.fromRGB(255,255,255)
                thumb.BorderSizePixel = 0; thumb.ZIndex = 3
                thumb.Parent = track
                round(thumb, 7)

                -- Tıklama alanı
                local hitbox = Instance.new("TextButton")
                hitbox.Size = UDim2.new(1,0,0,20)
                hitbox.Position = UDim2.new(0,0,0.5,-10)
                hitbox.BackgroundTransparency = 1
                hitbox.Text = ""; hitbox.ZIndex = 4
                hitbox.Parent = track

                local function updateVal(inputPos)
                    local rel = math.clamp(
                        (inputPos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X,
                        0, 1
                    )
                    val = math.floor(min + (max-min)*rel + 0.5)
                    fill.Size = UDim2.new(rel,0,1,0)
                    thumb.Position = UDim2.new(rel,0,0.5,0)
                    valL.Text = val..suf
                    cb(val)
                end

                local sliding = false
                hitbox.MouseButton1Down:Connect(function()
                    sliding = true
                    updateVal(UserInputService:GetMouseLocation())
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
                        updateVal(UserInputService:GetMouseLocation())
                    end
                end)

                return {
                    Set = function(_, v)
                        val = math.clamp(v, min, max)
                        local rel = (val-min)/(max-min)
                        fill.Size = UDim2.new(rel,0,1,0)
                        thumb.Position = UDim2.new(rel,0,0.5,0)
                        valL.Text = val..suf
                    end,
                    Get = function() return val end
                }
            end

            -- ════════════════════════
            -- BUTTON
            -- ════════════════════════
            function SO:AddButton(c)
                c = c or {}
                local cb = c.Callback or function() end
                local bg = c.Variant == "danger"  and T.Red
                        or c.Variant == "success" and T.Green
                        or T.Accent

                local btn = Instance.new("TextButton")
                btn.Text = c.Label or "Button"; btn.TextSize = 13
                btn.Font = Enum.Font.GothamMedium
                btn.TextColor3 = Color3.fromRGB(255,255,255)
                btn.BackgroundColor3 = bg
                btn.AutoButtonColor = false
                btn.Size = UDim2.new(1,0,0,30)
                btn.BorderSizePixel = 0
                btn.LayoutOrder = SO._order; SO._order += 1
                btn.Parent = sf
                round(btn, 7)

                btn.MouseEnter:Connect(function() tw(btn,{BackgroundTransparency=0.18},0.1) end)
                btn.MouseLeave:Connect(function() tw(btn,{BackgroundTransparency=0},0.1) end)
                btn.MouseButton1Click:Connect(function()
                    tw(btn,{BackgroundTransparency=0.4},0.06)
                    task.delay(0.12, function() tw(btn,{BackgroundTransparency=0},0.1) end)
                    cb()
                end)
            end

            -- ════════════════════════
            -- INPUT
            -- ════════════════════════
            function SO:AddInput(c)
                c = c or {}
                local cb       = c.Callback or function() end
                local password = c.Password or false

                local cont = Instance.new("Frame")
                cont.Size = UDim2.new(1,0,0,50)
                cont.BackgroundTransparency = 1
                cont.LayoutOrder = SO._order; SO._order += 1
                cont.Parent = sf

                local nameL = Instance.new("TextLabel")
                nameL.Text = c.Label or ""; nameL.TextSize = 11
                nameL.Font = Enum.Font.Gotham; nameL.TextColor3 = T.TextSub
                nameL.BackgroundTransparency = 1
                nameL.Size = UDim2.new(1,0,0,16)
                nameL.TextXAlignment = Enum.TextXAlignment.Left
                nameL.Parent = cont

                local box = Instance.new("TextBox")
                box.PlaceholderText = c.Placeholder or "..."
                box.Text = c.Default or ""
                box.TextSize = 13; box.Font = Enum.Font.Gotham
                box.TextColor3 = T.Text
                box.PlaceholderColor3 = T.TextDim
                box.BackgroundColor3 = T.SurfaceAlt
                box.BorderSizePixel = 0
                box.Size = UDim2.new(1,0,0,30)
                box.Position = UDim2.new(0,0,0,18)
                box.ClearTextOnFocus = false
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.Parent = cont
                round(box, 6); pad(box,0,0,8,8)

                if password then
                    box.TextTransparency = 1
                    local mask = lbl(box,"",13,T.Text,Enum.Font.GothamMedium)
                    mask.Size = UDim2.new(1,-16,1,0); mask.TextWrapped = false
                    box:GetPropertyChangedSignal("Text"):Connect(function()
                        mask.Text = string.rep("•", #box.Text)
                    end)
                end

                local st = stroke(box, T.Border, 1)
                box.Focused:Connect(function() tw(st,{Color=T.BorderFocus},0.15) end)
                box.FocusLost:Connect(function()
                    tw(st,{Color=T.Border},0.15)
                    cb(box.Text)
                end)

                return box
            end

            -- ════════════════════════
            -- DROPDOWN
            -- ════════════════════════
            function SO:AddDropdown(c)
                c = c or {}
                local opts = c.Options or {}
                local sel  = c.Default or (opts[1] or "Select...")
                local cb   = c.Callback or function() end
                local open = false

                local cont = Instance.new("Frame")
                cont.Size = UDim2.new(1,0,0,50)
                cont.BackgroundTransparency = 1
                cont.ClipsDescendants = false
                cont.LayoutOrder = SO._order; SO._order += 1
                cont.Parent = sf

                local nameL = Instance.new("TextLabel")
                nameL.Text = c.Label or ""; nameL.TextSize = 11
                nameL.Font = Enum.Font.Gotham; nameL.TextColor3 = T.TextSub
                nameL.BackgroundTransparency = 1
                nameL.Size = UDim2.new(1,0,0,16)
                nameL.TextXAlignment = Enum.TextXAlignment.Left
                nameL.Parent = cont

                local dropBtn = Instance.new("TextButton")
                dropBtn.Text = sel; dropBtn.TextSize = 13
                dropBtn.Font = Enum.Font.Gotham; dropBtn.TextColor3 = T.Text
                dropBtn.BackgroundColor3 = T.SurfaceAlt
                dropBtn.AutoButtonColor = false
                dropBtn.Size = UDim2.new(1,0,0,30)
                dropBtn.Position = UDim2.new(0,0,0,18)
                dropBtn.TextXAlignment = Enum.TextXAlignment.Left
                dropBtn.BorderSizePixel = 0
                dropBtn.Parent = cont
                round(dropBtn, 6); pad(dropBtn,0,0,8,8)
                stroke(dropBtn, T.Border, 1)

                local arrow = Instance.new("TextLabel")
                arrow.Text = "▾"; arrow.TextSize = 13
                arrow.Font = Enum.Font.GothamBold; arrow.TextColor3 = T.TextSub
                arrow.BackgroundTransparency = 1
                arrow.Size = UDim2.new(0,20,1,0)
                arrow.Position = UDim2.new(1,-22,0,0)
                arrow.TextXAlignment = Enum.TextXAlignment.Center
                arrow.Parent = dropBtn

                local menuH = math.min(#opts, 6) * 28 + 8
                local menu = Instance.new("Frame")
                menu.BackgroundColor3 = T.Surface
                menu.Size = UDim2.new(1,0,0,0)
                menu.Position = UDim2.new(0,0,0,52)
                menu.ClipsDescendants = true
                menu.Visible = false; menu.ZIndex = 20
                menu.BorderSizePixel = 0
                menu.Parent = cont
                round(menu, 7); stroke(menu, T.Border, 1); pad(menu,4,4,4,4)
                listLayout(menu, nil, 2)

                for i, opt in ipairs(opts) do
                    local ob = Instance.new("TextButton")
                    ob.Text = opt; ob.TextSize = 12
                    ob.Font = Enum.Font.Gotham; ob.TextColor3 = T.Text
                    ob.BackgroundColor3 = T.SurfaceAlt
                    ob.BackgroundTransparency = 1
                    ob.AutoButtonColor = false
                    ob.Size = UDim2.new(1,0,0,26)
                    ob.TextXAlignment = Enum.TextXAlignment.Left
                    ob.ZIndex = 21; ob.LayoutOrder = i
                    ob.BorderSizePixel = 0; ob.Parent = menu
                    round(ob, 5); pad(ob,0,0,8,8)

                    ob.MouseEnter:Connect(function() tw(ob,{BackgroundTransparency=0.82},0.1) end)
                    ob.MouseLeave:Connect(function() tw(ob,{BackgroundTransparency=1},0.1) end)
                    ob.MouseButton1Click:Connect(function()
                        sel = opt; dropBtn.Text = opt
                        open = false; menu.Visible = false
                        tw(menu,{Size=UDim2.new(1,0,0,0)},0.12)
                        cont.Size = UDim2.new(1,0,0,50)
                        cb(opt)
                    end)
                end

                dropBtn.MouseButton1Click:Connect(function()
                    open = not open
                    menu.Visible = true
                    if open then
                        cont.Size = UDim2.new(1,0,0,50+menuH+4)
                        tw(menu,{Size=UDim2.new(1,0,0,menuH)},0.18)
                    else
                        tw(menu,{Size=UDim2.new(1,0,0,0)},0.14)
                        task.delay(0.14, function()
                            menu.Visible = false
                            cont.Size = UDim2.new(1,0,0,50)
                        end)
                    end
                end)

                return {Get = function() return sel end}
            end

            -- ════════════════════════
            -- LABEL
            -- ════════════════════════
            function SO:AddLabel(c)
                c = c or {}
                local l = Instance.new("TextLabel")
                l.Text = c.Text or ""; l.TextSize = 11
                l.Font = Enum.Font.Gotham
                l.TextColor3 = c.Color or T.TextSub
                l.BackgroundTransparency = 1
                l.Size = UDim2.new(1,0,0,0)
                l.AutomaticSize = Enum.AutomaticSize.Y
                l.TextWrapped = true
                l.TextXAlignment = Enum.TextXAlignment.Left
                l.LayoutOrder = SO._order; SO._order += 1
                l.Parent = sf
                return l
            end

            -- ════════════════════════
            -- SEPARATOR
            -- ════════════════════════
            function SO:AddSeparator()
                local s = Instance.new("Frame")
                s.Size = UDim2.new(1,0,0,1)
                s.BackgroundColor3 = T.Border; s.BorderSizePixel = 0
                s.LayoutOrder = SO._order; SO._order += 1
                s.Parent = sf
            end

            table.insert(TabObj._sections, SO)
            return SO
        end

        return TabObj
    end

    -- ══════════════════════════════════════════════════
    -- AI CHAT — built-in tab
    -- ══════════════════════════════════════════════════
    function WinObj:AddAIChat(cfg)
        cfg = cfg or {}
        local chatTab = self:AddTab({Name="Chat", Icon="✦"})

        -- API Key section
        local keySection = chatTab:AddSection({Name="API CONFIGURATION"})
        local keyBox = keySection:AddInput({
            Label="Anthropic API Key",
            Placeholder="sk-ant-api03-...",
            Password=true,
            Default=cfg.APIKey or "",
        })
        keySection:AddLabel({Text="Key sadece Anthropic API'ye gönderilir.", Color=T.TextDim})

        -- Chat section
        local chatSection = chatTab:AddSection({Name="CHAT"})

        -- Mesaj geçmişi
        local hist = Instance.new("ScrollingFrame")
        hist.Size = UDim2.new(1,0,0,160)
        hist.BackgroundColor3 = T.BG
        hist.BorderSizePixel = 0
        hist.ScrollBarThickness = 2
        hist.ScrollBarImageColor3 = Color3.fromRGB(60,60,80)
        hist.CanvasSize = UDim2.new(0,0,0,0)
        hist.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        hist.LayoutOrder = chatSection._order; chatSection._order += 1
        hist.Parent = chatSection._frame
        round(hist, 7); stroke(hist, T.Border, 1); pad(hist,6,6,6,6)
        listLayout(hist, nil, 5)

        local msgCount = 0
        local history  = {}

        local function bubble(text, isUser)
            msgCount += 1
            local bub = Instance.new("Frame")
            bub.BackgroundColor3 = isUser and T.UserBubble or T.BotBubble
            bub.BorderSizePixel = 0
            bub.Size = UDim2.new(0.88,0,0,0)
            bub.AutomaticSize = Enum.AutomaticSize.Y
            bub.LayoutOrder = msgCount
            bub.AnchorPoint = isUser and Vector2.new(1,0) or Vector2.new(0,0)
            bub.Position = isUser and UDim2.new(1,0,0,0) or UDim2.new(0,0,0,0)
            bub.Parent = hist
            round(bub, 8); pad(bub,7,7,9,9)

            local t = Instance.new("TextLabel")
            t.Text = text; t.TextSize = 12
            t.Font = Enum.Font.Gotham
            t.TextColor3 = Color3.fromRGB(245,245,245)
            t.BackgroundTransparency = 1
            t.Size = UDim2.new(1,0,0,0)
            t.AutomaticSize = Enum.AutomaticSize.Y
            t.TextWrapped = true
            t.TextXAlignment = Enum.TextXAlignment.Left
            t.Parent = bub

            task.defer(function()
                hist.CanvasPosition = Vector2.new(0, 1e9)
            end)

            return bub
        end

        -- Input satırı
        local inputRow = Instance.new("Frame")
        inputRow.Size = UDim2.new(1,0,0,32)
        inputRow.BackgroundTransparency = 1
        inputRow.LayoutOrder = chatSection._order; chatSection._order += 1
        inputRow.Parent = chatSection._frame

        local chatBox = Instance.new("TextBox")
        chatBox.PlaceholderText = "Bir şey sor..."
        chatBox.Text = ""; chatBox.TextSize = 12
        chatBox.Font = Enum.Font.Gotham; chatBox.TextColor3 = T.Text
        chatBox.PlaceholderColor3 = T.TextDim
        chatBox.BackgroundColor3 = T.SurfaceAlt
        chatBox.BorderSizePixel = 0
        chatBox.Size = UDim2.new(1,-38,1,0)
        chatBox.ClearTextOnFocus = false
        chatBox.TextXAlignment = Enum.TextXAlignment.Left
        chatBox.Parent = inputRow
        round(chatBox, 6); pad(chatBox,0,0,8,8); stroke(chatBox, T.Border, 1)

        local sendBtn = Instance.new("TextButton")
        sendBtn.Text = "▶"; sendBtn.TextSize = 14
        sendBtn.Font = Enum.Font.GothamBold
        sendBtn.TextColor3 = Color3.fromRGB(255,255,255)
        sendBtn.BackgroundColor3 = T.Accent
        sendBtn.AutoButtonColor = false
        sendBtn.Size = UDim2.new(0,32,1,0)
        sendBtn.Position = UDim2.new(1,-32,0,0)
        sendBtn.BorderSizePixel = 0; sendBtn.Parent = inputRow
        round(sendBtn, 6)

        local function send()
            local msg = chatBox.Text
            if msg == "" then return end
            local key = keyBox.Text
            if key == "" then
                bubble("⚠ Önce API key gir.", false); return
            end
            bubble(msg, true)
            table.insert(history, {role="user", content=msg})
            chatBox.Text = ""

            local thinking = bubble("...", false)

            task.spawn(function()
                local ok, res = pcall(function()
                    local body = HttpService:JSONEncode({
                        model="claude-sonnet-4-6",
                        max_tokens=1024,
                        messages=history,
                    })
                    -- Executor'larda game:HttpGet yerine request() kullan
                    local r
                    if syn and syn.request then
                        r = syn.request({
                            Url="https://api.anthropic.com/v1/messages",
                            Method="POST",
                            Headers={
                                ["Content-Type"]="application/json",
                                ["x-api-key"]=key,
                                ["anthropic-version"]="2023-06-01",
                            },
                            Body=body,
                        })
                        return HttpService:JSONDecode(r.Body).content[1].text
                    elseif request then
                        r = request({
                            Url="https://api.anthropic.com/v1/messages",
                            Method="POST",
                            Headers={
                                ["Content-Type"]="application/json",
                                ["x-api-key"]=key,
                                ["anthropic-version"]="2023-06-01",
                            },
                            Body=body,
                        })
                        return HttpService:JSONDecode(r.Body).content[1].text
                    else
                        error("HTTP desteklenmiyor")
                    end
                end)

                thinking:Destroy(); msgCount -= 1

                if ok then
                    table.insert(history, {role="assistant", content=res})
                    bubble(res, false)
                else
                    bubble("⚠ API hatası: "..tostring(res):sub(1,80), false)
                end
            end)
        end

        sendBtn.MouseButton1Click:Connect(send)
        UserInputService.InputBegan:Connect(function(inp)
            if inp.KeyCode == Enum.KeyCode.Return and chatBox:IsFocused() then
                send()
            end
        end)

        return chatTab
    end

    return WinObj
end

return AetherUI
