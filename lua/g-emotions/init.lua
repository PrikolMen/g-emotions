AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
local gemotions = gemotions
local isstring = isstring
local istable = istable
local Log = gemotions.Log
local Send = net.Send
local PRE_HOOK = PRE_HOOK or HOOK_MONITOR_HIGH
resource.AddWorkshop("3198355085")
do
	local packages = gemotions.packages
	gemotions.RegisterPackage = function(packageName, emotions)
		assert(isstring(packageName), "Package name must be a string!")
		assert(istable(emotions), "Package emotions must be a table!")
		local packageData = packages[packageName]
		local packageIndex = packageData == nil and (#packages + 1) or packageData.id
		for index = 1, #emotions do
			local emotion = emotions[index]
			if emotion ~= nil then
				emotion.id = index
			end
		end
		packageData = {
			name = packageName,
			emotions = emotions,
			id = packageIndex
		}
		Log("Package '" .. packageName .. "' was registered.")
		packages[packageIndex] = packageData
		packages[packageName] = packageData
		return
	end
end
do
	local match, sub, upper, GetFileFromFilename
	do
		local _obj_0 = string
		match, sub, upper, GetFileFromFilename = _obj_0.match, _obj_0.sub, _obj_0.upper, _obj_0.GetFileFromFilename
	end
	local RegisterPackage = gemotions.RegisterPackage
	gemotions.Register = function(packageName, packageData)
		for index = 1, #packageData do
			local emotion = packageData[index]
			if emotion ~= nil then
				local fileName = match(GetFileFromFilename(emotion[1]), "([^.]+)")
				packageData[index] = {
					name = upper(sub(fileName, 1, 1)) .. sub(fileName, 2),
					material = emotion[1],
					sound = emotion[2]
				}
			end
		end
		RegisterPackage(packageName, packageData)
		return
	end
end
util.AddNetworkString("GEmotions::Networking")
local startNetSync
startNetSync = function()
	net.Start("GEmotions::Networking")
	net.WriteUInt(0, 2)
	return net.WriteTable(gemotions.packages, true)
end
gemotions.StartNetSync = startNetSync
hook.Add("SetupMove", "GEmotions::SetupMove", function(ply, _, cmd)
	if ply.m_bGEmotionsInitialized or not (cmd:IsForced() or ply:IsBot()) then
		return
	end
	if not ply:IsBot() then
		startNetSync()
		Send(ply)
	end
	Log("Player '" .. tostring(ply) .. "' was initialized.")
	ply.m_bGEmotionsInitialized = true
	return
end, PRE_HOOK)
if game.SinglePlayer() then
	local enabled, key
	do
		local _obj_0 = gemotions.convars
		enabled, key = _obj_0.enabled, _obj_0.key
	end
	hook.Add("PlayerButtonDown", "G-Emotions::Open", function(ply, keyCode)
		if keyCode == key:GetInt() and enabled:GetBool() then
			ply:ConCommand("+gemotions " .. keyCode)
			return
		end
	end, PRE_HOOK)
	hook.Add("PlayerButtonUp", "G-Emotions::Close", function(ply, keyCode)
		if keyCode == key:GetInt() and enabled:GetBool() then
			ply:ConCommand("-gemotions " .. keyCode)
			return
		end
	end, PRE_HOOK)
end
concommand.Add("gemotions_reload", function(ply)
	if not ply or (ply:IsValid() and ply:IsSuperAdmin()) then
		gemotions.LoadConfigs()
		startNetSync()
		net.Broadcast()
		return Log("Configs reloaded.")
	end
end)
do
	local Start, WriteUInt, WritePlayer, WriteBool
	do
		local _obj_0 = net
		Start, WriteUInt, WritePlayer, WriteBool = _obj_0.Start, _obj_0.WriteUInt, _obj_0.WritePlayer, _obj_0.WriteBool
	end
	local GetPackage, SoundExists = gemotions.GetPackage, gemotions.SoundExists
	local CHAN_STATIC = CHAN_STATIC
	local tonumber = tonumber
	local random = math.random
	local find = string.find
	local recipientFilter = RecipientFilter()
	concommand.Add("gemotion", function(ply, _, args)
		local package = GetPackage(tonumber(args[1] or "") or -1)
		if not package then
			return
		end
		local emotion = package.emotions[tonumber(args[2] or "") or -1]
		if not emotion then
			return
		end
		local noSound = true
		if ply:GetInfo("gemotions_user_audio") == "1" then
			local soundPath = emotion.sound
			if istable(soundPath) then
				soundPath = soundPath[random(1, #soundPath)]
			end
			if isstring(soundPath) then
				if find(soundPath, "^https?://.+$") ~= nil then
					noSound = false
				elseif SoundExists(soundPath) then
					entity:EmitSound(soundPath, 60, random(90, 110), 1, CHAN_STATIC, 0, 1)
				end
			end
		end
		recipientFilter:RemoveAllPlayers()
		recipientFilter:AddPlayer(ply)
		recipientFilter:AddPVS(ply:EyePos())
		Start("GEmotions::Networking")
		WriteUInt(1, 2)
		WritePlayer(ply)
		WriteUInt(package.id, 10)
		WriteUInt(emotion.id, 14)
		WriteBool(noSound)
		Send(recipientFilter)
		return
	end)
end
file.CreateDir("g-emotions/packages")
gemotions.LoadConfigs = function()
	if #file.Find("g-emotions/packages/*.json", "DATA") == 0 then
		file.Write("g-emotions/packages/default.json", util.TableToJSON({
			name = "Default Emotions",
			emotions = {
				{
					name = "Bye",
					material = "https://i.imgur.com/Js0BaH8.png"
				},
				{
					name = "Hi",
					material = "https://i.imgur.com/zGyb8kg.png"
				},
				{
					name = "Clap",
					material = "https://i.imgur.com/uDw75yg.png"
				},
				{
					name = "Happy",
					material = "https://i.imgur.com/eViUp2a.png"
				},
				{
					name = "Evil",
					material = "https://i.imgur.com/LwE4zvb.png"
				},
				{
					name = "Huh",
					material = "https://i.imgur.com/5lVtSdh.png"
				},
				{
					name = "Rage",
					material = "https://i.imgur.com/3mWmxDC.png"
				},
				{
					name = "Wow",
					material = "https://i.imgur.com/HwVJ2gU.png"
				},
				{
					name = "Yawn",
					material = "https://i.imgur.com/HDuxGW0.png"
				},
				{
					name = "Sleep",
					material = "https://i.imgur.com/q9nlpst.png"
				},
				{
					name = "Think",
					material = "https://i.imgur.com/IwyGXWk.png"
				},
				{
					name = "Sob",
					material = "https://i.imgur.com/74iJPOT.png"
				},
				{
					name = "Shock",
					material = "https://i.imgur.com/buNncWq.png"
				},
				{
					name = "Rofl",
					material = "https://i.imgur.com/E8gJerG.png"
				},
				{
					name = "Scream",
					material = "https://i.imgur.com/T2bc8Ed.png"
				},
				{
					name = "Nerd",
					material = "https://i.imgur.com/yyLZbGw.png"
				},
				{
					name = "RMF Dance",
					material = "https://raw.githubusercontent.com/rauchg/twemoji-cdn-1/gh-pages/72x72/1f4fb.png",
					sound = "http://195.150.20.5:8000/rmf_dance",
					lifetime = 300
				}
			}
		}, true))
		Log("Default package created.")
	end
	local packages = file.Find("g-emotions/packages/*.json", "DATA")
	for index = 1, #packages do
		local fileName = packages[index]
		if not fileName then
			goto _continue_0
		end
		local json = file.Read("g-emotions/packages/" .. fileName, "DATA")
		if not json then
			goto _continue_0
		end
		local data = util.JSONToTable(json)
		if not data then
			goto _continue_0
		end
		gemotions.RegisterPackage(data.name or fileName, data.emotions)
		do
			return
		end
		::_continue_0::
	end
end
hook.Add("InitPostEntity", "G-Emotions::LoadConfigs", gemotions.LoadConfigs, PRE_HOOK)
local _list_0 = file.Find("g-emotions/packages/*.lua", "LUA")
for _index_0 = 1, #_list_0 do
	local fileName = _list_0[_index_0]
	include("g-emotions/packages/" .. fileName)
end
local _list_1 = file.Find("gemotions/*.lua", "LUA")
for _index_0 = 1, #_list_1 do
	local fileName = _list_1[_index_0]
	include("gemotions/" .. fileName)
end
