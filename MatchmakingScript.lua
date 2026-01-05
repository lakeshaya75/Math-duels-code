-- ServerScriptService/Matchmaking.server.lua

local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService   = game:GetService("MessagingService")
local TeleportService    = game:GetService("TeleportService")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")

local IS_STUDIO = RunService:IsStudio()

local Remotes           = ReplicatedStorage:WaitForChild("Remotes")
local matchmakingEvent  = Remotes:WaitForChild("Matchmaking")

-- IMPORTANT: These must be child places in THIS experience (same universe)
local PLACE_ID     = 119889798448967   -- PvP place
local BOT_PLACE_ID = 121468471958121   -- Bot place

-- Tunables
local INVIS_TIMEOUT         = 60
local QUEUE_TTL             = 60          -- >= READ_WAIT_TIMEOUT
local READ_WAIT_TIMEOUT     = 10          -- <= QUEUE_TTL
local SOFT_REQUEUE_INTERVAL = 10          -- how long before we refresh their queue item
local HARD_BOT_DEADLINE     = 25          -- ABSOLUTE wait before bot (seconds)  << set 20–30 as you like
local POLL_INTERVAL         = 1
local MAX_RESERVE_ATTEMPTS  = 3

local TOPIC = "mm_teleport_v1"

local queues = {
	Classic  = MemoryStoreService:GetQueue("MatchmakingQueue_Classic",  INVIS_TIMEOUT),
	Survival = MemoryStoreService:GetQueue("MatchmakingQueue_Survival", INVIS_TIMEOUT),
}

-- waitingPlayers[userId] = {
--   mode,banner,avatar,emotes,
--   firstAt,        -- first time they entered ANY queue this session (absolute deadline uses this)
--   startTime,      -- last time we (re)queued them (soft timeout uses this)
--   attempts,       -- reserve/publish attempts
--   matchedAt,      -- used to block immediate bot after a match is found
-- }
local waitingPlayers = {}

-- ------------------------
-- Helpers
-- ------------------------
local function sanitizeMode(mode)
	return (mode == "Classic" or mode == "Survival") and mode or "Classic"
end
local function sanitizeString(v, default)
	return (typeof(v) == "string" and v ~= "" and v) or default
end
local function sanitizeEmotes(t)
	if typeof(t) ~= "table" then return {} end
	local out = {}
	for i = 1, 3 do
		local k = t[i]
		if typeof(k) == "string" and k ~= "" then out[i] = k end
	end
	return out
end

local function addPlayerToQueue(player, mode, banner, avatar, emotes)
	mode   = sanitizeMode(mode)
	banner = sanitizeString(banner, "Basic")
	avatar = sanitizeString(avatar, "Default")
	emotes = sanitizeEmotes(emotes)

	local now = os.time()

	waitingPlayers[player.UserId] = waitingPlayers[player.UserId] or {}
	local slot = waitingPlayers[player.UserId]
	slot.mode, slot.banner, slot.avatar, slot.emotes = mode, banner, avatar, emotes
	slot.firstAt   = slot.firstAt or now   -- only set once
	slot.startTime = now                    -- refreshed on each (re)queue
	slot.attempts  = slot.attempts or 0
	slot.matchedAt = nil

	local q = queues[mode]
	if not q then warn("[Queue] Invalid mode:", mode) return end

	local ok, err = pcall(function()
		q:AddAsync(player.UserId, QUEUE_TTL)
	end)
	if not ok then
		warn("[Queue] AddAsync failed:", err)
	else
		print(("[Queue] Added %s → %s"):format(player.Name, mode))
	end
end

local function removePlayer(player)
	waitingPlayers[player.UserId] = nil
	print("[Queue] Removed", player.Name)
end

-- ------------------------
-- Cross-server subscriber (for players not hosted here)
-- ------------------------
local function onTeleportMessage(msg)
	local data = msg.Data
	if typeof(data) ~= "table" then return end

	local userId   = tonumber(data.userId)
	local placeId  = tonumber(data.placeId)
	local code     = data.serverCode
	local tDataAll = data.tDataAll -- shared map

	if not (userId and placeId and code and typeof(tDataAll) == "table") then return end

	local plr = Players:GetPlayerByUserId(userId)
	if not plr then return end

	matchmakingEvent:FireClient(plr)

	local ok, err = pcall(function()
		TeleportService:TeleportToPrivateServer(placeId, code, { plr }, "", tDataAll)
	end)
	if not ok then
		warn("[MM] Teleport subscriber failed for", userId, err)
	else
		print("[MM] Teleported", plr.Name, "→ reserved PvP")
	end
end

do
	local ok, connOrErr = pcall(function()
		return MessagingService:SubscribeAsync(TOPIC, onTeleportMessage)
	end)
	if not ok then
		warn("[MM] MessagingService subscribe failed; cross-server teleports may not work:", connOrErr)
	end
end

-- ------------------------
-- Matchmaking loop
-- ------------------------
task.spawn(function()
	while true do
		task.wait(POLL_INTERVAL)

		for mode, q in pairs(queues) do
			local ok, ids = pcall(function()
				return q:ReadAsync(2, true, READ_WAIT_TIMEOUT)
			end)

			if ok and ids and #ids == 2 then
				print("[Match]", mode, "→", ids[1], ids[2])

				local now = os.time()
				for _, uid in ipairs(ids) do
					local wp = waitingPlayers[uid]
					if wp then wp.matchedAt = now end
				end

				-- Build shared TeleportData (all participants share it)
				local dataByUserId = {}
				for _, uid in ipairs(ids) do
					local d = waitingPlayers[uid]
					dataByUserId[uid] = {
						mode   = d and d.mode   or "Classic",
						banner = d and d.banner or "Basic",
						avatar = d and d.avatar or "Default",
						emotes = d and d.emotes or {},
					}
				end
				local tDataAll = {
					participants = { ids[1], ids[2] },
					dataByUserId = dataByUserId,
				}

				-- Split by presence in THIS server
				local localPlayers, remoteUserIds = {}, {}
				for _, uid in ipairs(ids) do
					local plr = Players:GetPlayerByUserId(uid)
					if plr then
						table.insert(localPlayers, plr)
					else
						table.insert(remoteUserIds, uid)
					end
				end

				-- Try to reserve a private server
				local reserveOk, serverCodeOrErr = pcall(function()
					return TeleportService:ReserveServer(PLACE_ID)
				end)

				if not reserveOk then
					warn("[Teleport] ReserveServer failed:", serverCodeOrErr)

					-- If BOTH are here, fallback to TeleportAsync (non-reserved, but grouped)
					if #localPlayers == 2 then
						for _, p in ipairs(localPlayers) do matchmakingEvent:FireClient(p) end
						local options = Instance.new("TeleportOptions")
						options:SetTeleportData(tDataAll)
						local tpOk, tpErr = pcall(function()
							return TeleportService:TeleportAsync(PLACE_ID, localPlayers, options)
						end)
						if tpOk then
							print("[Teleport] Fallback TeleportAsync succeeded for local pair.")
							for _, p in ipairs(localPlayers) do
								waitingPlayers[p.UserId] = nil
							end
						else
							warn("[Teleport] Fallback TeleportAsync failed:", tpErr)
							-- Requeue both (retry later; no bot yet)
							for _, p in ipairs(localPlayers) do
								local d = waitingPlayers[p.UserId]
								if d then
									d.attempts  = (d.attempts or 0) + 1
									d.startTime = os.time()
									d.matchedAt = nil
									local qq = queues[d.mode]
									if qq then pcall(function() qq:AddAsync(p.UserId, QUEUE_TTL) end) end
								end
							end
						end

					else
						-- Requeue whoever we couldn’t teleport (e.g., cross-server case)
						for _, uid in ipairs(ids) do
							local d = waitingPlayers[uid]
							if d then
								d.attempts  = (d.attempts or 0) + 1
								d.startTime = os.time()
								d.matchedAt = nil
								local qq = queues[d.mode]
								if qq then pcall(function() qq:AddAsync(uid, QUEUE_TTL) end) end
								print(("[Retry] Requeued %d (attempt %d)"):format(uid, d.attempts))
							end
						end
					end

				else
					local serverCode = serverCodeOrErr

					-- 1) Group-teleport all local players TOGETHER to the reserved server
					if #localPlayers > 0 then
						for _, p in ipairs(localPlayers) do matchmakingEvent:FireClient(p) end
						local tpOk, tpErr = pcall(function()
							return TeleportService:TeleportToPrivateServer(PLACE_ID, serverCode, localPlayers, "", tDataAll)
						end)
						if not tpOk then
							warn("[Teleport] Group TeleportToPrivateServer failed:", tpErr)
							-- Requeue locals
							for _, p in ipairs(localPlayers) do
								local d = waitingPlayers[p.UserId]
								if d then
									d.attempts  = (d.attempts or 0) + 1
									d.startTime = os.time()
									d.matchedAt = nil
									local qq = queues[d.mode]
									if qq then pcall(function() qq:AddAsync(p.UserId, QUEUE_TTL) end) end
								end
							end
						else
							for _, p in ipairs(localPlayers) do
								waitingPlayers[p.UserId] = nil
							end
						end
					end

					-- 2) For players in other lobbies, publish the same reserved code & shared data
					for _, uid in ipairs(remoteUserIds) do
						local pubOk, pubErr = pcall(function()
							MessagingService:PublishAsync(TOPIC, {
								userId   = uid,
								placeId  = PLACE_ID,
								serverCode = serverCode,
								tDataAll = tDataAll,
							})
						end)
						if not pubOk then
							warn("[MM] Publish failed for", uid, pubErr)
							local d = waitingPlayers[uid]
							if d then
								d.attempts  = (d.attempts or 0) + 1
								d.startTime = os.time()
								d.matchedAt = nil
								local qq = queues[d.mode]
								if qq then pcall(function() qq:AddAsync(uid, QUEUE_TTL) end) end
							end
						else
							waitingPlayers[uid] = nil
						end
					end
				end

			elseif not ok then
				warn("[Poll] ReadAsync failed:", ids)
			end
		end

		-- SOFT requeue + HARD bot deadline
		local now = os.time()
		for userId, data in pairs(waitingPlayers) do
			local sinceFirst = now - (data.firstAt or now)     -- absolute time in queue
			local sinceLast  = now - (data.startTime or now)    -- since last (re)queue
			local recentMatchBlock = data.matchedAt and (now - data.matchedAt < SOFT_REQUEUE_INTERVAL)

			-- 1) Absolute deadline → BOT (regardless of attempts)
			if sinceFirst >= HARD_BOT_DEADLINE and not recentMatchBlock then
				local plr = Players:GetPlayerByUserId(userId)
				if plr then
					matchmakingEvent:FireClient(plr)
					local tData = {
						mode   = data.mode,
						banner = data.banner,
						avatar = data.avatar,
						emotes = data.emotes,
					}
					local tpOk, tpErr = pcall(function()
						return TeleportService:Teleport(BOT_PLACE_ID, plr, tData)
					end)
					if not tpOk then
						warn("[Teleport][BOT] Failed for", plr.Name, tpErr)
					else
						print(("[BOT] HARD deadline (%.0fs) → %s"):format(HARD_BOT_DEADLINE, plr.Name))
					end
				else
					print("[BOT] Player left before hard deadline:", userId)
				end
				waitingPlayers[userId] = nil

				-- 2) Soft requeue to keep queue item fresh while we wait
			elseif sinceLast >= SOFT_REQUEUE_INTERVAL and not recentMatchBlock then
				-- requeue with same mode
				local q = queues[data.mode]
				if q then
					data.startTime = now
					local okAdd, errAdd = pcall(function()
						q:AddAsync(userId, QUEUE_TTL)
					end)
					if not okAdd then
						warn("[Queue] Soft requeue failed for", userId, errAdd)
					else
						-- optional: print(("[Queue] Refreshed %d in %s"):format(userId, data.mode))
					end
				end
			end
		end
	end
end)

-- ------------------------
-- Remote hook
-- ------------------------
matchmakingEvent.OnServerEvent:Connect(function(player, mode, start, banner, avatar, emotes)
	if start then
		addPlayerToQueue(player, mode, banner, avatar, emotes)
	else
		removePlayer(player)
	end
end)

Players.PlayerRemoving:Connect(removePlayer)
