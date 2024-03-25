local acos, cos, sin, pi, sqrt, ceil
do
	local _obj_0 = math
	acos, cos, sin, pi, sqrt, ceil = _obj_0.acos, _obj_0.cos, _obj_0.sin, _obj_0.pi, _obj_0.sqrt, _obj_0.ceil
end
local GetPhrase = language.GetPhrase
local gemotions = gemotions
local PlaySound = surface.PlaySound
local screenWidth, screenHeight, screenCenterX, screenCenterY, vmin = 0, 0, 0, 0, 0
local font1 = "G-Emotions::Header"
local font2 = "G-Emotions::Body"
local resolutionChanged
resolutionChanged = function()
	screenWidth, screenHeight = ScrW(), ScrH()
	vmin = math.min(screenWidth, screenHeight) / 100
	screenCenterX, screenCenterY = screenWidth / 2, screenHeight / 2
	surface.CreateFont(font1, {
		font = "Roboto",
		size = vmin * 6,
		extended = true
	})
	return surface.CreateFont(font2, {
		font = "Roboto",
		size = vmin * 4,
		extended = true
	})
end
hook.Add("OnScreenSizeChanged", "G-Emotions::Menu", resolutionChanged)
resolutionChanged()
local PANEL = { }
PANEL.Init = function(self)
	self.PackageName = "Missing Name"
	self.SelectedEmotion = nil
	self.SelectedPackage = 1
	self:SetVisible(false)
	self.CircleRadius = 128
	self.Selected = false
	self.IconSize = 16
	self.Emotions = { }
	self:SetAlpha(0)
	return
end
PANEL.PerformLayout = function(self)
	self:SetSize(screenWidth, screenHeight)
	self:SetPos(0, 0)
	local packageData = self:GetSelectedPackage()
	if not packageData then
		return
	end
	local packageStep, packageRadius = packageData.step, packageData.radius
	self.PackageName = language.GetPhrase(packageData.name)
	local emotions = self.Emotions
	local iconSize = vmin * 4
	local radian = 0
	for index = 1, #emotions do
		emotions[index] = nil
	end
	self.IconSize = iconSize
	local circleRadius = iconSize * 2
	for index, emotion in ipairs(packageData.emotions) do
		radian = index * packageStep - packageStep
		local x = screenCenterX + cos(radian) * packageRadius - iconSize / 2
		local y = screenCenterY + sin(radian) * packageRadius - iconSize / 2
		circleRadius = math.max(circleRadius, x - screenCenterX, y - screenCenterY)
		local data = {
			x = x,
			y = y,
			alpha = 0,
			size = iconSize,
			scale = 1,
			selected = false
		}
		table.Merge(data, emotion)
		emotions[index] = data
	end
	self.CircleRadius = circleRadius - iconSize
end
do
	local GetPackage = gemotions.GetPackage
	PANEL.GetSelectedPackage = function(self)
		return GetPackage(self.SelectedPackage or 0)
	end
end
do
	local GetEmotion = gemotions.GetEmotion
	PANEL.GetSelectedEmote = function(self)
		return GetEmotion(self.SelectedPackage or 0, self.SelectedEmotion or 0)
	end
end
local packagesCount = 0
do
	local angle, length, index = 0, 0, 0
	PANEL.OnCursorMoved = function(self, x, y)
		local packageData = self:GetSelectedPackage()
		if not packageData then
			return
		end
		x, y = x - screenCenterX, y - screenCenterY
		length = sqrt(x ^ 2 + y ^ 2)
		if length < self.CircleRadius then
			self.SelectedEmotion = nil
			return
		end
		angle = acos(x / length)
		if y < 0 then
			angle = (pi * 2) - angle
		end
		index = ceil(angle / packageData.step) % (packageData.count + 1)
		if index ~= self.SelectedEmotion then
			PlaySound("g-emotions/ui/switch.ogg")
			self.SelectedEmotion = index
		end
	end
end
do
	local curTime = 0
	PANEL.OnMouseWheeled = function(self, delta)
		packagesCount = gemotions.packagesCount
		if packagesCount < 2 then
			return
		end
		curTime = CurTime()
		if (curTime - (self.LastMouseWheeled or 0)) < 0.1 then
			return
		end
		self.LastMouseWheeled = curTime
		local index = self.SelectedPackage or 0
		if delta > 0 then
			index = index + 1
			if index > packagesCount then
				index = 1
			end
		elseif delta < 0 then
			index = index - 1
			if index < 1 then
				index = packagesCount
			end
		end
		self.SelectedPackage = index
		self.SelectedEmotion = nil
		PlaySound("g-emotions/ui/rollover.ogg")
		self:InvalidateLayout()
		return
	end
end
local GetAlpha = FindMetaTable("Panel").GetAlpha
do
	local SetMaterial, SetDrawColor, DrawTexturedRect, DrawRect, DrawCircle, DrawText, GetTextSize, SetFont, SetTextColor, SetTextPos
	do
		local _obj_0 = surface
		SetMaterial, SetDrawColor, DrawTexturedRect, DrawRect, DrawCircle, DrawText, GetTextSize, SetFont, SetTextColor, SetTextPos = _obj_0.SetMaterial, _obj_0.SetDrawColor, _obj_0.DrawTexturedRect, _obj_0.DrawRect, _obj_0.DrawCircle, _obj_0.DrawText, _obj_0.GetTextSize, _obj_0.SetFont, _obj_0.SetTextColor, _obj_0.SetTextPos
	end
	local UpdateScreenEffectTexture = render.UpdateScreenEffectTexture
	local DrawEmoteQuad = gemotions.DrawEmoteQuad
	local packageStep, packageRadius, isSelected = 0, 0, false
	local blur = Material("pp/blurscreen")
	local SetFloat, Recompute = blur.SetFloat, blur.Recompute
	PANEL.Paint = function(self, width, height)
		SetFloat(blur, "$blur", GetAlpha(self) / 64)
		Recompute(blur)
		UpdateScreenEffectTexture()
		SetMaterial(blur)
		SetDrawColor(255, 255, 255, 255)
		DrawTexturedRect(0, 0, width, height)
		SetDrawColor(32, 32, 32, 240)
		DrawRect(0, 0, width, height)
		DrawCircle(screenCenterX, screenCenterY, self.CircleRadius, 128, 128, 128, 32)
		SetTextColor(255, 255, 255, 255)
		local text = self.PackageName
		SetFont(font1)
		local textWidth, textHeight = GetTextSize(text)
		local y = screenCenterY - (self.CircleRadius * 2) - self.IconSize - (textHeight / 2)
		SetTextPos(screenCenterX - textWidth / 2, y)
		y = y + (textHeight / 2)
		DrawText(text)
		packagesCount = gemotions.packagesCount
		if packagesCount > 1 then
			text = string.format("%d/%d", self.SelectedPackage, packagesCount)
			SetFont(font2)
			textWidth, textHeight = GetTextSize(text)
			SetTextPos(screenCenterX - textWidth / 2, screenCenterY - textHeight / 2)
			DrawText(text)
		end
		local emotions, selected = self.Emotions, self.SelectedEmotion
		for index = 1, #emotions do
			if selected == index then
				goto _continue_0
			end
			local emotion = emotions[index]
			if not emotion then
				goto _continue_0
			end
			DrawEmoteQuad(emotion, emotion.x, emotion.y, emotion.size, emotion.size, emotion.alpha)
			::_continue_0::
		end
		if selected ~= nil then
			local emotion = emotions[selected]
			if emotion ~= nil then
				DrawEmoteQuad(emotion, emotion.x, emotion.y, emotion.size, emotion.size, emotion.alpha)
				text = GetPhrase(emotion.name)
				SetFont(font2)
				textWidth, textHeight = GetTextSize(text)
				y = y + (textHeight / 2)
				SetTextPos(screenCenterX - textWidth / 2, y)
				return DrawText(text)
			end
		end
	end
end
do
	local alpha, iconSize, selected, scale, radian, size = 0, 0, 0, 0, 0, 0
	local Lerp, RealFrameTime = Lerp, RealFrameTime
	PANEL.Think = function(self)
		local packageData = self:GetSelectedPackage()
		if not packageData then
			return
		end
		alpha, iconSize, selected = GetAlpha(self), self.IconSize, self.SelectedEmotion
		local packageStep, packageRadius = packageData.step, packageData.radius
		local emotions = self.Emotions
		for index = 1, #emotions do
			local emotion = emotions[index]
			if emotion ~= nil then
				emotion.selected = index == selected
				emotion.alpha = alpha * (emotion.selected and 1 or 0.9)
				emotion.scale = Lerp(RealFrameTime() * 12, emotion.scale, emotion.selected and 2 or 1)
				emotion.size = iconSize * emotion.scale
				radian = index * packageStep - packageStep
				emotion.x = screenCenterX + cos(radian) * packageRadius - emotion.size / 2
				emotion.y = screenCenterY + sin(radian) * packageRadius - emotion.size / 2
			end
		end
	end
end
local gemotions_user_quick_select = CreateClientConVar("gemotions_user_quick_select", "1", true, false, "Allows you to quickly select an emotion.", 0, 1)
do
	local animDuration = 0.16
	local animHide
	animHide = function(_, pnl)
		pnl.Selected = false
		pnl:SetVisible(false)
		pnl:IsMouseInputEnabled(true)
		return
	end
	PANEL.Show = function(self)
		if self:IsVisible() then
			return
		end
		local emote = self:GetSelectedEmote()
		if emote ~= nil then
			emote.scale = 1
		end
		self.SelectedEmotion = nil
		self:Stop()
		self:SetVisible(true)
		self:AlphaTo(255, animDuration)
		self:MakePopup()
		self:SetKeyboardInputEnabled(false)
		return
	end
	PANEL.Hide = function(self, isClick)
		if not self:IsVisible() then
			return
		end
		if not self.Selected and self.SelectedEmotion ~= nil and (isClick or gemotions_user_quick_select:GetBool()) then
			RunConsoleCommand("gemotion", self.SelectedPackage, self.SelectedEmotion)
			self.Selected = true
		end
		self:Stop()
		self:AlphaTo(0, animDuration, _, animHide)
		self:SetKeyboardInputEnabled(false)
		CloseDermaMenus()
		return
	end
end
PANEL.OnMouseReleased = function(self, keyCode)
	if keyCode > 106 and keyCode < 109 then
		PlaySound("g-emotions/ui/bong.ogg")
		self:Hide(true)
		return
	end
end
return vgui.Register("G-Emotions::Menu", PANEL, "EditablePanel")
