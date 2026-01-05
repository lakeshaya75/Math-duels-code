local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local getDataFunc = Remotes:WaitForChild("GetData") 
local updDataEvent = Remotes:WaitForChild("UpdData")

local STORE = DataStoreService:GetDataStore("PlayerData")

local DEFAULT = {
	credits = 350,
	xp = 0,
	lvl = 0,
	banner = "Basic",
	banners = {"Basic"},
	avatar = "Default",
	avatars = {"Default"},
	currEmotes = {},
	emotes = {},
}

local session = {}

local function toJSON(t)
	local ok, s = pcall(function() return HttpService:JSONEncode(t) end)
	return ok and s or "<unable to JSON-encode>"
end

local function deepClone(t)
	local out = {}
	for k,v in pairs(t) do
		out[k] = (typeof(v) == "table") and deepClone(v) or v
	end
	return out
end

local function deepMerge(defaults, loaded)
	local out = deepClone(defaults)
	if typeof(loaded) == "table" then
		for k,v in pairs(loaded) do
			if typeof(v) == "table" and typeof(out[k]) == "table" then
				out[k] = deepMerge(out[k], v)
			else
				out[k] = v
			end
		end
	end
	return out
end

local function keyFor(userId)
	return "user_" .. tostring(userId)
end

local function loadPlayer(userId)
	local key = keyFor(userId)
	local data
	local ok, err = pcall(function()
		data = STORE:GetAsync(key)
	end)
	if not ok then
		warn("[DataStore] GetAsync failed for", userId, err)
	end
	session[userId] = deepMerge(DEFAULT, data or {})
end

local function savePlayer(userId)
	local data = session[userId]
	if not data then return true end
	local key = keyFor(userId)

	-- Log the full snapshot we're about to save
	print(("[DataStore] Saving user %d snapshot: %s"):format(userId, toJSON(data)))

	local tries, ok, err = 0, false, nil
	repeat
		tries += 1
		ok, err = pcall(function()
			STORE:UpdateAsync(key, function(_old)
				-- Write the latest session state
				return data
			end)
		end)

		if not ok then
			local msg = tostring(err)
			warn(string.format("[DataStore] UpdateAsync failed for %d (try %d): %s", userId, tries, msg))
			-- If Studio API access is off, don't keep retrying
			if msg:find("StudioAccessToApisNotAllowed") then
				break
			end
			task.wait(math.min(2^(tries-1), 8)) -- backoff: 1s,2s,4s,8s cap
		end
	until ok or tries >= 3

	if ok then
		print(("[DataStore] Save OK for %d"):format(userId))
	end
	return ok
end

task.spawn(function()
	while true do
		task.wait(60)
		for _, plr in ipairs(Players:GetPlayers()) do
			savePlayer(plr.UserId)
		end
	end
end)

local function resetPlayer(userId)
	local key = keyFor(userId)
	STORE:RemoveAsync(key)
	session[userId] = deepClone(DEFAULT)
	print("Player reset to defaults:", toJSON(session[userId]))
end

Players.PlayerAdded:Connect(function(plr)
	--resetPlayer(plr.UserId)
	loadPlayer(plr.UserId)
end)

Players.PlayerRemoving:Connect(function(plr)
	savePlayer(plr.UserId)
	session[plr.UserId] = nil
end)

game:BindToClose(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		savePlayer(plr.UserId)
	end
end)

local function isStringArray(t)
	if typeof(t) ~= "table" then return false end
	for i, v in ipairs(t) do
		if typeof(v) ~= "string" then return false end
	end
	return true
end

local validators = {
	credits = function(v) return typeof(v) == "number" end,
	xp = function(v) return typeof(v) == "number" end,
	banner   = function(v) return typeof(v) == "string" end,
	banners = function(v) return typeof(v) == "table" end,
	avatar = function(v) return typeof(v) == "string" end,
	avatars = function(v) return typeof(v) == "table" end,
	currEmotes = function(v) return isStringArray(v) end,
	emotes = function(v) return isStringArray(v) end,
}

getDataFunc.OnServerInvoke = function(plr)
	local data = session[plr.UserId] or deepClone(DEFAULT)
	return deepClone(data)
end

updDataEvent.OnServerEvent:Connect(function(plr, patch)
	print(patch)
	if typeof(patch) ~= "table" then return end
	local data = session[plr.UserId]
	if not data then return end

	for k, v in pairs(patch) do
		local validate = validators[k]
		if validate and validate(v) then
			data[k] = v
		else
			warn("[DataStore] Rejected field from client:", k)
		end
	end
end)


