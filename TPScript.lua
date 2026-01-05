-- ServerScriptService/LobbyTeleportIntake.server.lua

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local STORE = DataStoreService:GetDataStore("PlayerData")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local tpEvent = Remotes:WaitForChild("TP") -- RemoteEvent

local function toJSON(t)
	local ok, s = pcall(function() return HttpService:JSONEncode(t) end)
	return ok and s or "<json-fail>"
end

local function keyFor(userId)
	return "user_" .. tostring(userId)
end

local function coerceInt(v)
	if v == nil then return 0 end
	local n = tonumber(v)
	if not n then return 0 end
	if n >= 0 then return math.floor(n + 1e-5) else return math.ceil(n - 1e-5) end
end

local appliedOnce = {} -- [userId] = true (avoid double-apply)

local function applyTeleportRewards(userId, tp, source)
	-- Prevent double-rewarding
	if appliedOnce[userId] then return end

	-- Sanitize inputs
	local result   = (typeof(tp.result) == "string") and tp.result or "ok"
	local addCreds = coerceInt(tp.credits)
	local addXp    = coerceInt(tp.xp)

	local finalCreds, finalXp
	local ok, err = pcall(function()
		STORE:UpdateAsync(keyFor(userId), function(old)
			old = typeof(old) == "table" and old or {}
			old.credits = tonumber(old.credits) or 0
			old.xp      = tonumber(old.xp)      or 0

			old.credits = math.max(0, old.credits + addCreds)
			old.xp      = math.max(0, old.xp + addXp)

			-- optional audit fields if you want them:
			-- old.lastResult   = result
			-- old.lastResultAt = os.time()

			finalCreds, finalXp = old.credits, old.xp
			return old
		end)
	end)

	if ok then
		appliedOnce[userId] = true

		print(string.format("[LobbyTP][%s] user=%d  delta=%s  totals=%s",
			source or "teleport",
			userId,
			toJSON({result = result, credits = addCreds, xp = addXp}),
			toJSON({credits = finalCreds, xp = finalXp})
			))

		-- Fire the event to just this player
		local plr = Players:GetPlayerByUserId(userId)
		if plr and tpEvent and tpEvent:IsA("RemoteEvent") then
			tpEvent:FireClient(plr, {
				result = result,
				credits = addCreds,
				xp = addXp,
				totals = { credits = finalCreds, xp = finalXp },
			})
		end
	else
		warn(string.format("[LobbyTP] Failed to apply rewards for %d: %s", userId, tostring(err)))
	end
end

Players.PlayerAdded:Connect(function(plr)
	local ok, join = pcall(function() return plr:GetJoinData() end)
	if not ok or not join then return end

	-- Optional: only accept teleports from the same game/universe
	if join.SourceGameId and join.SourceGameId ~= game.GameId then return end

	local tp = join.TeleportData
	if typeof(tp) ~= "table" then return end
	if typeof(tp.result) ~= "string" and tp.credits == nil and tp.xp == nil then return end

	print(string.format("[LobbyTP] %s arrived with TeleportData=%s", plr.Name, toJSON(tp)))
	applyTeleportRewards(plr.UserId, tp, "teleport")
end)

Players.PlayerRemoving:Connect(function(plr)
	appliedOnce[plr.UserId] = nil
end)
