include("shared.lua")
local LocalPlayer = LocalPlayer
local pi, max, floor
do
	local _obj_0 = math
	pi, max, floor = _obj_0.pi, _obj_0.max, _obj_0.floor
end
local gemotions = gemotions
local CurTime = CurTime
local Add = hook.Add
CreateClientConVar("gemotions_user_audio", "1", true, true, "Enables audio playback for emotions that support this feature.", 0, 1)
local PRE_HOOK = PRE_HOOK or HOOK_MONITOR_HIGH
local enabled = gemotions.convars.enabled
concommand.Add("+gemotions", function(ply, _, args)
	if not enabled:GetBool() then
		return
	end
	local keyCode = args[1]
	if keyCode ~= nil and #keyCode > 0 then
		keyCode = tonumber(keyCode)
		if keyCode ~= nil then
			local bind = input.LookupKeyBinding(keyCode)
			if bind ~= nil and #bind > 0 and bind ~= "+gemotions" then
				return
			end
		end
	end
	if not IsValid(gemotions.panel) then
		gemotions.panel = vgui.Create("G-Emotions::Menu")
	end
	gemotions.panel:Show()
	return
end)
concommand.Add("-gemotions", function(ply, _, args)
	if not IsValid(gemotions.panel) then
		return
	end
	if enabled:GetBool() then
		return gemotions.panel:Hide()
	else
		gemotions.panel:Remove()
		gemotions.panel = nil
	end
end)
local screenWidth, screenHeight, screenCenterX, vmin = 0, 0, 0, 0
do
	local ReadPlayer, ReadUInt, ReadBool
	do
		local _obj_0 = net
		ReadPlayer, ReadUInt, ReadBool = _obj_0.ReadPlayer, _obj_0.ReadUInt, _obj_0.ReadBool
	end
	local packages, GetEmotion = gemotions.packages, gemotions.GetEmotion
	local lifetime = gemotions.convars.lifetime
	local PlayURL = sound.PlayURL
	local Remove = hook.Remove
	local length = 0
	local queue = gemotions.queue
	if not queue then
		queue = { }
		gemotions.queue = queue
	end
	local curTime = 0
	local functions = {
		[0] = function()
			local data = net.ReadTable(true)
			for _index_0 = 1, #data do
				local packageData = data[_index_0]
				local emotions = packageData.emotions
				if emotions == nil then
					packageData.count = 0
					packageData.step = 0
					packageData.radius = 0
				else
					length = #emotions
					for index = 1, length do
						local emotion = emotions[index]
						if emotion ~= nil then
							emotion.scale = 1
							emotion.material = emotion.material or false
						end
					end
					packageData.count = length
					packageData.step = (pi * 2) / length
					packageData.radius = max(vmin * 10, ((vmin * 8) * length) / (2 * pi))
				end
			end
			for index = 1, #packages do
				packages[index] = nil
			end
			length = #data
			for index = 1, length do
				packages[index] = data[index]
			end
			gemotions.packagesCount = length
			local panel = gemotions.panel
			if panel and panel:IsValid() then
				panel:Remove()
			end
			return
		end,
		[1] = function()
			local ply = ReadPlayer()
			if not (ply or ply:IsValid()) then
				return
			end
			local emotion, noSound = GetEmotion(ReadUInt(10), ReadUInt(14)), ReadBool()
			if not emotion then
				return
			end
			curTime = CurTime()
			local oldData = queue[ply]
			if oldData and oldData[1] == emotion and (curTime - oldData[2]) <= oldData[3] then
				oldData[2] = curTime
				return
			end
			queue[ply] = {
				emotion,
				curTime,
				emotion.lifetime or lifetime:GetFloat(),
				0
			}
			local oldChannel = ply.m_GEmotionsAudioChannel
			if oldChannel and oldChannel:IsValid() then
				Remove("Think", oldChannel)
				oldChannel:Stop()
			end
			if noSound then
				return
			end
			PlayURL(emotion.sound, "3d", function(channel)
				if not (channel and channel:IsValid() and ply:IsValid() and ply:Alive() and not ply:IsDormant()) then
					return
				end
				ply.m_GEmotionsAudioChannel = channel
				Add("Think", channel, function()
					if not channel:IsValid() then
						Remove("Think", channel)
						return
					end
					if not (ply:IsValid() and ply:Alive() and not ply:IsDormant()) then
						Remove("Think", channel)
						channel:Stop()
						return
					end
					local data = queue[ply]
					if not data or data[1] ~= emotion or (CurTime() - data[2]) > data[3] then
						Remove("Think", channel)
						channel:Stop()
						return
					end
					channel:SetPos(ply:WorldSpaceCenter(), ply:GetAimVector())
					return
				end)
				return channel:Play()
			end)
			return
		end
	}
	net.Receive("GEmotions::Networking", function()
		local func = functions[ReadUInt(2)]
		if func ~= nil then
			return func()
		end
	end)
end
local preformMaterial = nil
do
	local default = Material("icon16/arrow_refresh.png", "ignorez")
	local ErrorNoHaltWithStack = ErrorNoHaltWithStack
	local GetExtensionFromFilename, find
	do
		local _obj_0 = string
		GetExtensionFromFilename, find = _obj_0.GetExtensionFromFilename, _obj_0.find
	end
	file.CreateDir("g-emotions/cache")
	local Exists, Write
	do
		local _obj_0 = file
		Exists, Write = _obj_0.Exists, _obj_0.Write
	end
	local Material = Material
	local Fetch = http.Fetch
	local MD5 = util.MD5
	local cache = { }
	preformMaterial = function(filePath)
		if cache[filePath] == nil then
			if find(filePath, "^https?://.+$") ~= nil then
				local cachePath = "g-emotions/cache/" .. MD5(filePath) .. "." .. (GetExtensionFromFilename(filePath) or "png")
				if Exists(cachePath, "DATA") then
					cache[filePath] = Material("data/" .. cachePath, "smooth ignorez")
				else
					Fetch(filePath, function(content, _, __, code)
						if code ~= 200 then
							ErrorNoHaltWithStack("Failed to download '" .. filePath .. "' (" .. code .. ")")
							return
						end
						Write(cachePath, content)
						cache[filePath] = Material("data/" .. cachePath, "smooth ignorez")
					end, ErrorNoHaltWithStack)
				end
			elseif Exists("materials/" .. filePath, "GAME") then
				cache[filePath] = Material(filePath, "smooth ignorez")
			end
			if not cache[filePath] then
				cache[filePath] = default
			end
		end
		return cache[filePath]
	end
end
do
	local Begin, Color, Position, TexCoord, AdvanceVertex, End
	do
		local _obj_0 = mesh
		Begin, Color, Position, TexCoord, AdvanceVertex, End = _obj_0.Begin, _obj_0.Color, _obj_0.Position, _obj_0.TexCoord, _obj_0.AdvanceVertex, _obj_0.End
	end
	local SetUnpacked = FindMetaTable("Vector").SetUnpacked
	local SetMaterial = render.SetMaterial
	local mesh1, mesh2, mesh3, mesh4 = Vector(0, 0, 0), Vector(0, 0, 0), Vector(0, 0, 0), Vector(0, 0, 0)
	local right, bot = 0, 0
	local drawTexturedRect
	drawTexturedRect = function(x, y, width, height, material, alpha)
		right, bot = x + width, y + height
		SetUnpacked(mesh1, x, y, 0)
		SetUnpacked(mesh2, right, y, 0)
		SetUnpacked(mesh3, right, bot, 0)
		SetUnpacked(mesh4, x, bot, 0)
		if not alpha then
			alpha = 255
		end
		SetMaterial(material)
		Begin(7, 1)
		Position(mesh1)
		Color(255, 255, 255, alpha)
		TexCoord(0, 0, 0)
		AdvanceVertex()
		Position(mesh2)
		Color(255, 255, 255, alpha)
		TexCoord(0, 1, 0)
		AdvanceVertex()
		Position(mesh3)
		Color(255, 255, 255, alpha)
		TexCoord(0, 1, 1)
		AdvanceVertex()
		Position(mesh4)
		Color(255, 255, 255, alpha)
		TexCoord(0, 0, 1)
		AdvanceVertex()
		End()
		return
	end
	gemotions.DrawTexturedRect = drawTexturedRect
	gemotions.DrawEmote = function(emotion, x, y, width, height, alpha)
		drawTexturedRect(x, y, width, height, preformMaterial("https://i.imgur.com/zZfip8v.png"), alpha)
		drawTexturedRect(x + width * 0.075, y + width * 0.075, width * 0.85, width * 0.85, preformMaterial(emotion.material), alpha)
		return
	end
	gemotions.DrawEmoteQuad = function(emotion, x, y, width, height, alpha)
		drawTexturedRect(x, y, width, height, preformMaterial("https://i.imgur.com/bjDvQJq.png"), alpha)
		drawTexturedRect(x + width * 0.075, y + height * 0.075, width * 0.85, height * 0.85, preformMaterial(emotion.material), alpha)
		return
	end
end
if not game.SinglePlayer() then
	local LookupKeyBinding = input.LookupKeyBinding
	local key = gemotions.convars.key
	Add("PlayerButtonDown", "G-Emotions::Open", function(ply, keyCode)
		if enabled:GetBool() and key:GetInt() == keyCode then
			local binding = LookupKeyBinding(keyCode)
			if binding and #binding ~= 0 then
				return
			end
			RunConsoleCommand("+gemotions")
			return
		end
	end, PRE_HOOK)
	Add("PlayerButtonUp", "G-Emotions::Close", function(ply, keyCode)
		if enabled:GetBool() and key:GetInt() == keyCode then
			local binding = LookupKeyBinding(keyCode)
			if binding and #binding ~= 0 then
				return
			end
			RunConsoleCommand("-gemotions")
			return
		end
	end, PRE_HOOK)
end
Add("InitPostEntity", "G-Emotions::Init", function()
	gemotions.LocalPlayer = LocalPlayer()
	gemotions.LocalPlayerIndex = gemotions.LocalPlayer:EntIndex()
end, PRE_HOOK)
local SetUnpackedVector = FindMetaTable("Vector").SetUnpacked
local SetUnpackedAngle = FindMetaTable("Angle").SetUnpacked
local Lerp, RealFrameTime = Lerp, RealFrameTime
local InOutBack = math.ease.InOutBack
local DrawEmote = gemotions.DrawEmote
local abs = math.abs
local curTime, scale = 0, 0
local queue = gemotions.queue
Add("EntityRemoved", "G-Emotions::Clean", function(ply)
	if ply:IsPlayer() then
		queue[ply] = nil
	end
end, PRE_HOOK)
do
	local Start3D2D, End3D2D
	do
		local _obj_0 = cam
		Start3D2D, End3D2D = _obj_0.Start3D2D, _obj_0.End3D2D
	end
	local Iterator = player.Iterator
	Add("PostDrawTranslucentRenderables", "G-Emotions::WorldDraw", function()
		if not enabled:GetBool() then
			return
		end
		local eyePos = EyePos()
		for _, ply in Iterator() do
			local data = queue[ply]
			if not data or (ply:EntIndex() == gemotions.LocalPlayerIndex and not ply:ShouldDrawLocalPlayer()) then
				goto _continue_0
			end
			curTime = CurTime()
			local fraction = 1 - (curTime - data[2]) / data[3]
			if fraction > 1 then
				fraction = 1
			elseif fraction < 0 then
				fraction = 0
			end
			if fraction == 0 or not ply:Alive() then
				queue[ply] = nil
				goto _continue_0
			end
			scale = Lerp(RealFrameTime() * 8, data[4], fraction > 0.01 and 0.45 or 0)
			data[4] = scale
			local bone, origin = ply:LookupBone("ValveBiped.Bip01_Head1"), nil
			if bone and bone >= 0 then
				local angles
				origin, angles = ply:GetBonePosition(bone)
				if origin == ply:GetPos() then
					origin = ply:GetShootPos()
				end
				local hitboxset = ply:GetHitboxSet()
				for hitbox = 0, ply:GetHitBoxCount(hitboxset) do
					if bone == ply:GetHitBoxBone(hitbox, hitboxset) then
						local mins, maxs = ply:GetHitBoxBounds(hitbox, hitboxset)
						origin = origin + (angles:Forward() * (maxs[3] - mins[3]) * 1.5)
						break
					end
				end
			else
				origin = ply:EyePos()
				local _update_0 = 3
				origin[_update_0] = origin[_update_0] + 10
			end
			local angle = (origin - eyePos):Angle()
			SetUnpackedAngle(angle, (InOutBack(abs((curTime * 2) % 2 - 1)) - 0.5) * 15, angle[2] - 90, 90)
			Start3D2D(origin, angle, scale)
			DrawEmote(data[1], -16, -38, 32, 38)
			End3D2D()
			::_continue_0::
		end
	end)
end
do
	local Translate, Rotate, Scale
	do
		local _obj_0 = FindMetaTable("VMatrix")
		Translate, Rotate, Scale = _obj_0.Translate, _obj_0.Rotate, _obj_0.Scale
	end
	local PushModelMatrix, PopModelMatrix
	do
		local _obj_0 = cam
		PushModelMatrix, PopModelMatrix = _obj_0.PushModelMatrix, _obj_0.PopModelMatrix
	end
	local Matrix = Matrix
	local angles = Angle()
	local vector = Vector()
	local resolutionChanged
	resolutionChanged = function()
		screenWidth, screenHeight = ScrW(), ScrH()
		vmin = math.min(screenWidth, screenHeight) / 100
		screenCenterX = screenWidth / 2
		local _list_0 = gemotions.packages
		for _index_0 = 1, #_list_0 do
			local packageData = _list_0[_index_0]
			local emotions = packageData.emotions
			if emotions == nil then
				packageData.count = 0
				packageData.step = 0
				packageData.radius = 0
			else
				local length = #emotions
				for index = 1, length do
					local emotion = emotions[index]
					if emotion ~= nil then
						emotion.scale = 1
						emotion.material = emotion.material or false
					end
				end
				packageData.count = length
				packageData.step = (pi * 2) / length
				packageData.radius = max(vmin * 10, ((vmin * 8) * length) / (2 * pi))
			end
		end
		local panel = gemotions.panel
		if panel and panel:IsValid() then
			return panel:Remove()
		end
	end
	Add("OnScreenSizeChanged", "G-Emotions::HUD", resolutionChanged)
	resolutionChanged()
	return Add("HUDPaint", "G-Emotions::HUD", function()
		if not enabled:GetBool() then
			return
		end
		local ply = LocalPlayer()
		if ply:ShouldDrawLocalPlayer() then
			return
		end
		local data = queue[ply]
		if not data then
			return
		end
		curTime = CurTime()
		local fraction = 1 - (curTime - data[2]) / data[3]
		if fraction > 1 then
			fraction = 1
		elseif fraction < 0 then
			fraction = 0
		end
		if fraction == 0 or not ply:Alive() then
			queue[ply] = nil
			return
		end
		scale = Lerp(RealFrameTime() * 8, data[4], fraction > 0.01 and 0.45 or 0)
		data[4] = scale
		local matrix = Matrix()
		SetUnpackedVector(vector, screenCenterX, floor(vmin * 20), 0)
		Translate(matrix, vector)
		SetUnpackedAngle(angles, 0, (InOutBack(abs((curTime * 2) % 2 - 1)) - 0.5) * 15, 0)
		Rotate(matrix, angles)
		SetUnpackedVector(vector, scale, scale, 0)
		Scale(matrix, vector)
		SetUnpackedVector(vector, -screenCenterX, 0, 0)
		Translate(matrix, vector)
		PushModelMatrix(matrix)
		DrawEmote(data[1], screenCenterX - floor(vmin * 14.9), -floor(vmin * 35.2), floor(vmin * 29.7), floor(vmin * 35.2))
		PopModelMatrix()
		return
	end)
end
