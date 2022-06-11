if not CLIENT then return end

local cs_player = chatsounds.Module("Player")

local function get_wanted_sound(sound_data)
	local matching_sounds = chatsounds.Data.Lookup[sound_data.Key]

	local index = math.random(#matching_sounds)
	for _, modifier in ipairs(sound_data.Modifiers) do
		if modifier.OnSelection then
			index, matching_sounds = modifier:OnSelection(index, matching_sounds)
		end
	end

	return matching_sounds[math.min(math.max(1, index), #matching_sounds)]
end

local function play_sound_group_async(ply, sound_group)
	if sound_group.Type ~= "group" then return end

	for _, sound_data in pairs(sound_group.Sounds) do
		local _sound = get_wanted_sound(sound_data)
		local hash = util.SHA1(_sound.Url)
		local sound_path = ("chatsounds/cache/%s/%s.ogg"):format(_sound.Realm, hash)
		local sound_dir_path = sound_path:GetPathFromFilename()
		if not file.Exists(sound_dir_path, "DATA") then
			file.CreateDir(sound_dir_path)
		end

		local download_task = chatsounds.Tasks.new()
		if not _sound.Cached then
			chatsounds.Log("Downloading %s", _sound.Url)
			chatsounds.Http.Get(_sound.Url):next(function(res)
				if res.Status ~= 200 then
					download_task:reject("Failed to download %s: %d", _sound.Url, res.Status)
					return
				end

				file.Write(sound_path, res.Body)
				_sound.Cached = true

				chatsounds.Log("Downloaded %s", _sound.Url)
				download_task:resolve()
			end, chatsounds.Error)
		else
			download_task:resolve()
		end

		download_task:next(function()
			local stream = chatsounds.WebAudio.CreateStream("data/" .. sound_path)
			stream:Play()
			-- modifier bs ?
		end)
	end
end

function cs_player.PlayAsync(ply, str)
	local t = chatsounds.Tasks.new()
	chatsounds.Parser.ParseAsync(str):next(function(sound_group)
		play_sound_group_async(ply, sound_group):next(function()
			t:resolve()
		end, chatsounds.Error)
	end, chatsounds.Error)

	return t
end

hook.Add("OnPlayerChat", "chatsounds.Player", function(ply, text)
	local start_time = SysTime()
	cs_player.PlayAsync(ply, text):next(function()
		chatsounds.Log("parsed and played sounds in " .. (SysTime() - start_time) .. "s")
	end)
end)