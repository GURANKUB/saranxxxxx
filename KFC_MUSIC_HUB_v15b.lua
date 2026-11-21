--[[
    KFC MUSIC HUB v15b — NullGhost II
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    แก้ปัญหา v15: BAIT_ID ไม่มีเสียง

    กลยุทธ์ใหม่ NullGhost II:
      SoundId payload = rbxassetid://REAL_BAIT_AUDIO%00[alpha junk]
        REAL_BAIT_AUDIO = เสียงเงียบ/เสียงสั้น Roblox จริง
        (%00 ทำให้ C++ ไม่ใช้ bait เล่น — เล่นจาก ToolMusic rawId แทน)
        Layer 3 fallback ดึง BAIT_AUDIO แทน realId

      ToolMusic rawId = ID จริง → เสียงออกปกติ

    ⚠️ ข้อจำกัดคงเดิม: hookmetamethod FireServer ยังดัก rawId ได้
       แต่ 11111.lua ใช้ SoundId scan → กันได้
]]

local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = workspace.CurrentCamera
end)

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local gethui = gethui or function() return game:GetService("CoreGui") end
local GuiParent = (function()
	local ok, res = pcall(gethui)
	if ok and res then return res end
	ok, res = pcall(function() return game:GetService("CoreGui") end)
	if ok and res then return res end
	return LocalPlayer:WaitForChild("PlayerGui")
end)()

for _, name in ipairs({
	"KFC_LOLASSR5_Root","KFC_LOLASSR5_Toggle",
	"KFC_Stage1Trap_Root","KFC_Stage1Trap_Toggle",
	"KFC_MusicHub_Root","KFC_MusicHub_Toggle",
}) do
	local c = GuiParent:FindFirstChild(name)
	if c then c:Destroy() end
end

-- ═══════════════════════════════════════════════════════════════════
-- THEME
-- ═══════════════════════════════════════════════════════════════════
local T = {
	Glass  = Color3.fromRGB(14,16,22),   GlassT  = 0.18,
	Card   = Color3.fromRGB(22,26,36),   CardT   = 0.26,
	Border = Color3.fromRGB(255,255,255),BorderT = 0.45,
	Btn    = Color3.fromRGB(30,36,50),   BtnT    = 0.28,
	BtnHov = Color3.fromRGB(46,54,74),
	White  = Color3.fromRGB(255,255,255),
	Muted  = Color3.fromRGB(142,154,176),
	Accent = Color3.fromRGB(195,255,30),
	Red    = Color3.fromRGB(244,67,54),
	Green  = Color3.fromRGB(46,204,113),
	Amber  = Color3.fromRGB(245,158,11),
	Blue   = Color3.fromRGB(66,165,245),
}
local Font     = Enum.Font.GothamBold
local FontNorm = Enum.Font.Gotham

-- ═══════════════════════════════════════════════════════════════════
-- UI HELPERS
-- ═══════════════════════════════════════════════════════════════════
local function playClickSound()
	pcall(function()
		local s = Instance.new("Sound", workspace)
		s.SoundId = "rbxassetid://6895079853"
		s.Volume = 0.4; s:Play()
		game:GetService("Debris"):AddItem(s, 2)
	end)
end

local function newFrame(parent, size, pos, color, trans)
	local f = Instance.new("Frame")
	f.Size = size or UDim2.new(1,0,1,0)
	f.Position = pos or UDim2.new(0,0,0,0)
	f.BackgroundColor3 = color or T.Glass
	f.BackgroundTransparency = trans or T.GlassT
	f.BorderSizePixel = 0
	if parent then f.Parent = parent end
	return f
end

local function newLabel(parent, text, size, pos, fs, color, font)
	local l = Instance.new("TextLabel")
	l.Size = size or UDim2.new(1,0,0,22)
	l.Position = pos or UDim2.new(0,0,0,0)
	l.BackgroundTransparency = 1
	l.Text = text or ""
	l.TextSize = fs or 13
	l.TextColor3 = color or T.White
	l.Font = font or FontNorm
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextWrapped = true
	if parent then l.Parent = parent end
	return l
end

local function newButton(parent, text, size, pos, fs, color)
	local b = Instance.new("TextButton")
	b.Size = size or UDim2.new(1,-8,0,40)
	b.Position = pos or UDim2.new(0,4,0,0)
	b.BackgroundColor3 = color or T.Btn
	b.BackgroundTransparency = T.BtnT
	b.BorderSizePixel = 0
	b.Text = text or "Button"
	b.TextSize = fs or 13
	b.TextColor3 = T.White
	b.Font = Font
	b.AutoButtonColor = false
	if parent then b.Parent = parent end
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = b
	local s = Instance.new("UIStroke"); s.Color = T.Border; s.Transparency = T.BorderT; s.Thickness = 1; s.Parent = b
	b.MouseEnter:Connect(function() b.BackgroundColor3 = T.BtnHov end)
	b.MouseLeave:Connect(function() b.BackgroundColor3 = T.Btn end)
	return b
end

local function addCorner(p, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,r or 10); c.Parent = p
end
local function addStroke(p, col, tr, th)
	local s = Instance.new("UIStroke"); s.Color = col or T.Border; s.Transparency = tr or T.BorderT; s.Thickness = th or 1; s.Parent = p
end
local function addListLayout(p, pad)
	local l = Instance.new("UIListLayout"); l.Padding = UDim.new(0,pad or 6); l.SortOrder = Enum.SortOrder.LayoutOrder; l.Parent = p
end
local function addPadding(p, h, v)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0,h or 8); pad.PaddingRight = UDim.new(0,h or 8)
	pad.PaddingTop = UDim.new(0,v or 6); pad.PaddingBottom = UDim.new(0,v or 6)
	pad.Parent = p
end

-- ═══════════════════════════════════════════════════════════════════
-- NULLGHOST II PAYLOAD
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- โครงสร้าง payload:
--   rbxassetid://BAIT_AUDIO_ID%00[alpha junk ล้วน ไม่มีตัวเลข]
--
-- BAIT_AUDIO_ID คือเสียงจริงใน Roblox (เสียงเงียบ/สั้น)
-- %00 null byte → C++ sound engine ตัด base part → ไม่เล่น BAIT
--   (เล่นจาก ToolMusic rawId แทน → เสียงออกปกติ)
-- Layer 3 fallback ของ 11111/STAGE1 ดึง BAIT_AUDIO_ID แทน realId
-- ไม่มี &id= ใดๆ → Layer 1, 2 fail
--
-- BAIT_AUDIO_IDs (เสียงจริง Roblox ที่ไม่ใช่เพลงของผู้ใช้):
-- ใช้หลายตัวสลับกัน random ทุกครั้ง → ทำให้ hard-coded detection ยากขึ้น
-- ═══════════════════════════════════════════════════════════════════

local BAIT_AUDIO_POOL = {
	-- เสียง Roblox สั้นๆ ที่มีอยู่จริง (ไม่ใช่เพลงของผู้ใช้)
	"6895079853",   -- UI click sound
	"5982891368",   -- ambient
	"9120541476",   -- short sfx
	"6042053626",   -- notification
	"5917172446",   -- ambient2
	"9113688259",   -- ui sfx
	"6895079853",
	"7148030707",
	"6031233544",
	"5917172446",
}

local JUNK_ALPHA = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-~!@#^*"

local function randomAlpha(len)
	local t = {}
	for i = 1, len do
		local r = math.random(1, #JUNK_ALPHA)
		t[i] = JUNK_ALPHA:sub(r, r)
	end
	return table.concat(t)
end

local function pickBait(realId)
	-- เลือก bait ที่ไม่ซ้ำกับ realId
	local pool = {}
	for _, v in ipairs(BAIT_AUDIO_POOL) do
		if v ~= realId then
			table.insert(pool, v)
		end
	end
	return pool[math.random(1, #pool)]
end

local function buildNullGhost2(rawId)
	local realId = tostring(rawId):match("%d+") or tostring(rawId)
	local bait = pickBait(realId)

	-- โครงสร้าง: rbxassetid://BAIT%00alpha-junk
	-- ไม่มี & หรือ = หรือ digit ใดๆ หลัง %00
	local junk = randomAlpha(math.random(20, 40)) .. "-" .. randomAlpha(math.random(15, 25))
	return "rbxassetid://" .. bait .. "%00" .. junk
end

-- ═══════════════════════════════════════════════════════════════════
-- MUSIC
-- ═══════════════════════════════════════════════════════════════════
local function getRemote(name)
	local RE = ReplicatedStorage:FindFirstChild("RE")
	return RE and RE:FindFirstChild(name)
end

local function PlayMusic(audioId, useVehicle)
	local id = tostring(audioId):match("%d+") or tostring(audioId)
	if id == "" then return end

	local payload = buildNullGhost2(id)

	local ToolEv    = getRemote("PlayerToolEvent")
	local ScooterEv = getRemote("1NoMoto1rVehicle1s")
	             or getRemote("1NoMo1torVeh1icle1s")
	             or getRemote("PlayerScooterEvent")

	if not ToolEv then return end

	pcall(function()
		ToolEv:FireServer("ToolMusicStop", "", nil)
		task.wait(0.12)
		ToolEv:FireServer("ToolMusicText", payload, nil, true)
		task.wait(0.05)
		ToolEv:FireServer("ToolMusic", id, 1)
		task.wait(0.03)
		ToolEv:FireServer("ToolMusicPlay", "", nil)
	end)

	if useVehicle and ScooterEv then
		pcall(function()
			ScooterEv:FireServer("PickingScooterMusicStop", "", nil)
			task.wait(0.12)
			ScooterEv:FireServer("PickingScooterMusicText", payload, nil, true)
			task.wait(0.05)
			ScooterEv:FireServer("PickingScooterMusic", id, 1)
			task.wait(0.03)
			ScooterEv:FireServer("PickingScooterMusicPlay", "", nil)
		end)
	end
end

local function StopMusic()
	local ToolEv    = getRemote("PlayerToolEvent")
	local ScooterEv = getRemote("1NoMoto1rVehicle1s")
	             or getRemote("1NoMo1torVeh1icle1s")
	             or getRemote("PlayerScooterEvent")
	if ToolEv then
		pcall(function()
			ToolEv:FireServer("ToolMusicStop", "", nil)
			ToolEv:FireServer("ToolMusicText", "")
		end)
	end
	if ScooterEv then
		pcall(function()
			ScooterEv:FireServer("PickingScooterMusicStop", "", nil)
			ScooterEv:FireServer("PickingScooterMusicText", "")
		end)
	end
end

_G.KFC_PlayMusic = PlayMusic
_G.KFC_StopMusic = StopMusic

-- ═══════════════════════════════════════════════════════════════════
-- UI
-- ═══════════════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KFC_MusicHub_Root"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = GuiParent

local uiScale = Instance.new("UIScale")
uiScale.Parent = ScreenGui
local function updateUIScale()
	if not Camera then return end
	local vp = Camera.ViewportSize
	uiScale.Scale = math.clamp(math.min(vp.X/400, vp.Y/600), 0.65, 1.0)
end
updateUIScale()
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateUIScale)

local panelW  = isMobile and 310 or 340
local panelH  = isMobile and 420 or 460
local btnH    = isMobile and 44 or 38
local fontSize  = isMobile and 14 or 13
local fontSizeS = isMobile and 12 or 11

-- Toggle Button
local ToggleSG = Instance.new("ScreenGui")
ToggleSG.Name = "KFC_MusicHub_Toggle"
ToggleSG.ResetOnSpawn = false
ToggleSG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ToggleSG.IgnoreGuiInset = true
ToggleSG.DisplayOrder = 99999
ToggleSG.Parent = GuiParent

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0,50,0,50)
ToggleBtn.Position = UDim2.new(0,10,0.5,-25)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(14,16,22)
ToggleBtn.BackgroundTransparency = 0.1
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "⚡"
ToggleBtn.TextSize = 24
ToggleBtn.TextColor3 = T.Accent
ToggleBtn.Font = Font
ToggleBtn.AutoButtonColor = false
ToggleBtn.Parent = ToggleSG
addCorner(ToggleBtn, 25)
addStroke(ToggleBtn, T.Accent, 0.3, 2)

local toggleDragging  = false
local toggleDidDrag   = false
local toggleStartPos
local toggleStartMouse

ToggleBtn.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.Touch
		or inp.UserInputType == Enum.UserInputType.MouseButton1 then
		toggleDragging   = true
		toggleDidDrag    = false
		toggleStartPos   = ToggleBtn.Position
		toggleStartMouse = inp.Position
	end
end)

UserInputService.InputChanged:Connect(function(inp)
	if toggleDragging and (inp.UserInputType == Enum.UserInputType.Touch
		or inp.UserInputType == Enum.UserInputType.MouseMovement) then
		local delta = inp.Position - toggleStartMouse
		if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
			toggleDidDrag = true
			local vp = Camera.ViewportSize
			ToggleBtn.Position = UDim2.new(0,
				math.clamp(toggleStartPos.X.Offset + delta.X, 0, vp.X-50),
				0,
				math.clamp(toggleStartPos.Y.Offset + delta.Y, 0, vp.Y-50))
		end
	end
end)

UserInputService.InputEnded:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.Touch
		or inp.UserInputType == Enum.UserInputType.MouseButton1 then
		toggleDragging = false
	end
end)

-- Main Panel
local Panel = newFrame(ScreenGui,
	UDim2.new(0,panelW,0,panelH),
	UDim2.new(0.5,-panelW/2,0.5,-panelH/2),
	T.Glass, T.GlassT)
Panel.ZIndex = 10
addCorner(Panel, 16)
addStroke(Panel, T.Border, T.BorderT, 1.5)

local bg = Instance.new("UIGradient")
bg.Rotation = 135
bg.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(18,22,32)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(14,18,26)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10,13,20)),
})
bg.Parent = Panel

local isPanelVisible = true
local function setPanel(vis)
	isPanelVisible = vis
	Panel.Visible = vis
	ToggleBtn.TextColor3 = vis and T.Accent or T.Muted
end

-- Header
local Header = newFrame(Panel,
	UDim2.new(1,0,0,46),
	UDim2.new(0,0,0,0),
	Color3.fromRGB(18,22,32), 0.1)
Header.ZIndex = 11
addCorner(Header, 14)

local TitleLbl = newLabel(Header, "🎵  KFC MUSIC HUB  v15b",
	UDim2.new(1,-90,0,22), UDim2.new(0,14,0,5), fontSize+1, T.White, Font)
TitleLbl.ZIndex = 12

local SubLbl = newLabel(Header, "NullGhost II",
	UDim2.new(1,-100,0,14), UDim2.new(0,14,0,28), fontSizeS, T.Accent, FontNorm)
SubLbl.ZIndex = 12

local CloseBtn = newButton(Header, "✕",
	UDim2.new(0,28,0,28), UDim2.new(1,-34,0.5,-14), 13)
CloseBtn.ZIndex = 13
CloseBtn.BackgroundColor3 = T.Red
CloseBtn.BackgroundTransparency = 0.3

local MinBtn = newButton(Header, "—",
	UDim2.new(0,28,0,28), UDim2.new(1,-66,0.5,-14), 13)
MinBtn.ZIndex = 13

CloseBtn.MouseButton1Click:Connect(function()
	playClickSound()
	ScreenGui:Destroy()
	ToggleSG:Destroy()
end)
MinBtn.MouseButton1Click:Connect(function()
	playClickSound()
	setPanel(false)
end)
ToggleBtn.InputEnded:Connect(function(inp)
	if (inp.UserInputType == Enum.UserInputType.Touch
		or inp.UserInputType == Enum.UserInputType.MouseButton1)
		and not toggleDidDrag then
		playClickSound()
		setPanel(not isPanelVisible)
	end
end)

-- Drag
local dragging = false
local dragStartPos, dragStartPanelPos
Header.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1
		or inp.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStartPos = inp.Position
		dragStartPanelPos = Panel.Position
	end
end)
UserInputService.InputChanged:Connect(function(inp)
	if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
		or inp.UserInputType == Enum.UserInputType.Touch) then
		local delta = inp.Position - dragStartPos
		local vp = Camera.ViewportSize
		Panel.Position = UDim2.new(0,
			math.clamp(dragStartPanelPos.X.Offset + delta.X, 0, vp.X-panelW),
			0,
			math.clamp(dragStartPanelPos.Y.Offset + delta.Y, 0, vp.Y-panelH))
	end
end)
UserInputService.InputEnded:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1
		or inp.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- Scroll Content
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1,0,1,-52)
ScrollFrame.Position = UDim2.new(0,0,0,50)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 3
ScrollFrame.ScrollBarImageColor3 = T.Accent
ScrollFrame.CanvasSize = UDim2.new(0,0,0,0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.ZIndex = 11
ScrollFrame.Parent = Panel

local ContentList = newFrame(ScrollFrame,
	UDim2.new(1,0,0,0), UDim2.new(0,0,0,0),
	Color3.new(0,0,0), 1)
ContentList.AutomaticSize = Enum.AutomaticSize.Y
addListLayout(ContentList, 8)
addPadding(ContentList, 10, 10)
ContentList.ZIndex = 12

-- Input Section
local InputSection = newFrame(ContentList,
	UDim2.new(1,0,0,0), nil, T.Card, T.CardT)
InputSection.AutomaticSize = Enum.AutomaticSize.Y
InputSection.LayoutOrder = 1
addCorner(InputSection, 10)
addPadding(InputSection, 10, 8)
addListLayout(InputSection, 6)
InputSection.ZIndex = 12

local InputLabel = newLabel(InputSection, "🎧  Audio ID",
	UDim2.new(1,0,0,18), nil, fontSizeS, T.Muted)
InputLabel.ZIndex = 13
InputLabel.LayoutOrder = 1

local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(1,0,0,btnH)
InputBox.BackgroundColor3 = Color3.fromRGB(10,13,20)
InputBox.BackgroundTransparency = 0.3
InputBox.BorderSizePixel = 0
InputBox.Text = ""
InputBox.PlaceholderText = "ใส่ Audio ID เช่น 1234567890"
InputBox.PlaceholderColor3 = T.Muted
InputBox.TextColor3 = T.White
InputBox.TextSize = fontSize
InputBox.Font = FontNorm
InputBox.ClearTextOnFocus = false
InputBox.ZIndex = 13
InputBox.LayoutOrder = 2
InputBox.Parent = InputSection
addCorner(InputBox, 8)
addStroke(InputBox, T.Border, 0.6, 1)
local InputPad = Instance.new("UIPadding")
InputPad.PaddingLeft = UDim.new(0,10)
InputPad.PaddingRight = UDim.new(0,10)
InputPad.Parent = InputBox

-- Status
local StatusSection = newFrame(ContentList,
	UDim2.new(1,0,0,36), nil,
	Color3.fromRGB(10,20,10), 0.4)
StatusSection.LayoutOrder = 2
addCorner(StatusSection, 8)
addPadding(StatusSection, 10, 6)

local StatusLbl = newLabel(StatusSection,
	"🛡  NullGhost II — พร้อมใช้งาน",
	UDim2.new(1,0,1,0), nil, fontSizeS, T.Green)
StatusLbl.ZIndex = 13

-- Buttons
local BtnSection = newFrame(ContentList,
	UDim2.new(1,0,0,0), nil, Color3.new(0,0,0), 1)
BtnSection.AutomaticSize = Enum.AutomaticSize.Y
BtnSection.LayoutOrder = 3
addListLayout(BtnSection, 8)

local function getInputId()
	return InputBox.Text:match("%d+") or ""
end

local function setStatus(icon, text, color, id)
	StatusLbl.Text = icon .. "  " .. text .. (id and ("  ID: " .. id) or "")
	StatusLbl.TextColor3 = color
end

-- Boombox
local BoomboxBtn = newButton(BtnSection, "🔊  Boombox",
	UDim2.new(1,0,0,btnH), nil, fontSize)
BoomboxBtn.LayoutOrder = 1
BoomboxBtn.MouseButton1Click:Connect(function()
	playClickSound()
	local id = getInputId()
	if id == "" then
		setStatus("⚠", "กรุณาใส่ Audio ID ก่อน", T.Amber)
		return
	end
	setStatus("⏳", "กำลังเล่น...", T.Blue, id)
	PlayMusic(id, false)
	task.delay(1.5, function()
		setStatus("✅", "กำลังเล่น | NullGhost II", T.Green, id)
	end)
end)

-- Boombox + Skateboard
local ScooterBtn = newButton(BtnSection, "🛹  Boombox + Skateboard",
	UDim2.new(1,0,0,btnH), nil, fontSize)
ScooterBtn.LayoutOrder = 2
ScooterBtn.MouseButton1Click:Connect(function()
	playClickSound()
	local id = getInputId()
	if id == "" then
		setStatus("⚠", "กรุณาใส่ Audio ID ก่อน", T.Amber)
		return
	end
	setStatus("⏳", "กำลังเล่น (Skate)...", T.Blue, id)
	PlayMusic(id, true)
	task.delay(1.5, function()
		setStatus("✅", "กำลังเล่น Skate | NullGhost II", T.Green, id)
	end)
end)

-- Stop
local StopBtn = newButton(BtnSection, "⏹  Stop Music",
	UDim2.new(1,0,0,btnH), nil, fontSize)
StopBtn.BackgroundColor3 = Color3.fromRGB(80,20,20)
StopBtn.BackgroundTransparency = 0.3
StopBtn.LayoutOrder = 3
StopBtn.MouseButton1Click:Connect(function()
	playClickSound()
	StopMusic()
	setStatus("⏹", "หยุดเพลงแล้ว", T.Muted)
end)

-- Info
local InfoSection = newFrame(ContentList,
	UDim2.new(1,0,0,0), nil,
	Color3.fromRGB(8,10,16), 0.3)
InfoSection.AutomaticSize = Enum.AutomaticSize.Y
InfoSection.LayoutOrder = 4
addCorner(InfoSection, 8)
addPadding(InfoSection, 10, 8)
addListLayout(InfoSection, 4)

local function infoLine(text, color)
	local l = newLabel(InfoSection, text,
		UDim2.new(1,0,0,16), nil, fontSizeS-1, color or T.Muted)
	l.TextWrapped = true
	l.ZIndex = 13
	return l
end

infoLine("━━  NullGhost II Protocol  ━━", T.Accent)
infoLine("✓  SoundId scan: กันได้ (11111 / STAGE1)", T.Green)
infoLine("✓  เสียงเล่นปกติ ผู้เล่นอื่นได้ยิน", T.Green)
infoLine("✓  BAIT = เสียงจริง Roblox (random)", T.Green)
infoLine("⚠  hookmetamethod: ยังดัก rawId ได้", T.Amber)
infoLine("   → 11111 ไม่ใช้ hook จึงไม่กระทบ", T.Muted)
