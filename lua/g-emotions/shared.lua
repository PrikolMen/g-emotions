gemotions = gemotions or { }
gemotions.title = "GEmotions"
gemotions.color = Color(193, 118, 255)
file.CreateDir("g-emotions")
do
	local FCVAR_FLAGS = bit.bor(FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE)
	gemotions.convars = {
		key = CreateConVar("gemotions_key", tostring(KEY_T), FCVAR_FLAGS, "Default key to open g-emotions menu, uses keys from https://wiki.facepunch.com/gmod/Enums/KEY", 0, 256),
		audio = CreateConVar("gemotions_audio", "1", FCVAR_FLAGS, "Allows emotions to emit sounds on server.", 0, 1),
		lifetime = CreateConVar("gemotions_lifetime", "5", FCVAR_FLAGS, "Default emotion lifetime.", 0, 2 ^ 30),
		enabled = CreateConVar("gemotions_enabled", "1", FCVAR_FLAGS, "Allows using emotions on server.", 0, 1)
	}
end
do
	local head = "[" .. gemotions.title .. "] "
	local color_text = Color(210, 210, 210)
	local MsgC = MsgC
	gemotions.Log = function(...)
		return MsgC(gemotions.color, head, color_text, ..., "\n")
	end
end
do
	local packages = gemotions.packages
	if not packages then
		packages = { }
		gemotions.packages = packages
	end
	gemotions.GetPackage = function(packageName)
		return packages[packageName]
	end
	gemotions.GetPackages = function()
		return packages
	end
	gemotions.GetEmotion = function(packageID, emotionID)
		local package = packages[packageID]
		if not package then
			return
		end
		local emotions = package.emotions
		if not emotions then
			return
		end
		return emotions[emotionID]
	end
end
do
	local GetTable = sound.GetTable
	local Exists = file.Exists
	local soundExists
	soundExists = function(filePath)
		if Exists(filePath, "GAME") then
			return true
		end
		local _list_0 = GetTable()
		for _index_0 = 1, #_list_0 do
			local soundName = _list_0[_index_0]
			if soundName == filePath then
				return true
			end
		end
		return false
	end
	gemotions.SoundExists = soundExists
end
if file.Exists("ulib/shared/hook.lua", "LUA") then
	return include("ulib/shared/hook.lua")
end
