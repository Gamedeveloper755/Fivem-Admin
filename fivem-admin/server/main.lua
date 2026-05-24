--[[ ============================================================
     SERVER MAIN - Gestione player e azioni admin
============================================================ ]]

-- ============================================================
-- KICK
-- ============================================================
RegisterNetEvent('adminSystem:server:kick', function(targetId, reason)
    local src    = source
    if not Permissions.CanKick(src) then
        TriggerClientEvent('adminSystem:client:notify', src, 'Non hai il permesso di kickare!', 'error')
        return
    end
    local target = tonumber(targetId)
    local targetName = GetPlayerName(target)
    local adminName  = GetPlayerName(src)

    DropPlayer(target, ('[AdminSystem] Sei stato kickato.\nMotivo: %s\nAdmin: %s'):format(
        reason or 'Nessun motivo', adminName))

    TriggerClientEvent('adminSystem:client:notify', src,
        ('Kickato %s - Motivo: %s'):format(targetName, reason), 'success')

    Logs.Send('kick', ('**%s** ha kickato **%s**'):format(adminName, targetName), {
        { name = 'Motivo', value = reason or 'Nessun motivo', inline = true },
    })
end)

-- ============================================================
-- WARN
-- ============================================================
local warns = {}  -- { [identifier] = { {reason, admin, ts}, ... } }

RegisterNetEvent('adminSystem:server:warn', function(targetId, reason)
    local src = source
    if not Permissions.IsAdmin(src, 1) then return end
    local target = tonumber(targetId)
    local id = Utils.GetMainIdentifier(target)
    if not warns[id] then warns[id] = {} end
    table.insert(warns[id], {
        reason = reason,
        admin  = GetPlayerName(src),
        ts     = os.time(),
    })
    local count = #warns[id]
    TriggerClientEvent('adminSystem:client:notify', target,
        ('Hai ricevuto un warn [%d/3]: %s'):format(count, reason), 'warning')
    TriggerClientEvent('adminSystem:client:notify', src,
        ('Warn inviato a %s [%d/3]'):format(GetPlayerName(target), count), 'success')
    Logs.Send('warn', ('**%s** ha warnato **%s** [%d/3]'):format(GetPlayerName(src), GetPlayerName(target), count), {
        { name = 'Motivo', value = reason, inline = true },
    })
    -- Auto-kick a 3 warn
    if count >= 3 then
        DropPlayer(target, '[AdminSystem] Hai raggiunto 3 warn. Sei stato kickato automaticamente.')
    end
end)

-- ============================================================
-- FREEZE / UNFREEZE
-- ============================================================
RegisterNetEvent('adminSystem:server:freeze', function(targetId, state)
    local src = source
    if not Permissions.CanFreeze(src) then return end
    local target = tonumber(targetId)
    TriggerClientEvent('adminSystem:client:freeze', target, state)
    TriggerClientEvent('adminSystem:client:notify', src,
        ('%s %s'):format(state and 'Frozen:' or 'Unfrozen:', GetPlayerName(target)), 'info')
end)

-- ============================================================
-- BRING (teleporta da player ad admin)
-- ============================================================
RegisterNetEvent('adminSystem:server:bring', function(targetId)
    local src = source
    if not Permissions.IsAdmin(src, 1) then return end
    TriggerClientEvent('adminSystem:client:bringToAdmin', tonumber(targetId), GetPlayerPed(src))
end)

-- ============================================================
-- GOTO (teleporta admin dal player)
-- ============================================================
RegisterNetEvent('adminSystem:server:goto', function(targetId)
    local src = source
    if not Permissions.IsAdmin(src, 1) then return end
    TriggerClientEvent('adminSystem:client:gotoPlayer', src, GetPlayerPed(tonumber(targetId)))
end)

-- ============================================================
-- REVIVE
-- ============================================================
RegisterNetEvent('adminSystem:server:revive', function(targetId)
    local src = source
    if not Permissions.IsAdmin(src, 1) then return end
    local target = targetId and tonumber(targetId) or src
    TriggerClientEvent('adminSystem:client:revive', target)
    if targetId then
        TriggerClientEvent('adminSystem:client:notify', src,
            ('Revivato: %s'):format(GetPlayerName(target)), 'success')
    end
end)

-- ============================================================
-- GET PLAYERS LIST (per NUI menu)
-- ============================================================
RegisterNetEvent('adminSystem:server:getPlayers', function()
    local src = source
    if not Permissions.IsAdmin(src, 1) then return end
    local list = {}
    for _, pid in ipairs(GetPlayers()) do
        local p = tonumber(pid)
        list[#list+1] = {
            id    = p,
            name  = GetPlayerName(p),
            ping  = GetPlayerPing(p),
            rank  = Permissions.GetRank(p),
            rankName = Utils.GetRankName(Permissions.GetRank(p)),
        }
    end
    TriggerClientEvent('adminSystem:client:playersList', src, list)
end)

-- ============================================================
-- STAFF LIST (comando pubblico)
-- ============================================================
RegisterCommand(Config.Commands.stafflist, function(source)
    local admins = Permissions.GetOnlineAdmins()
    if #admins == 0 then
        TriggerClientEvent('adminSystem:client:notify', source, 'Nessuno staff online al momento.', 'info')
        return
    end
    local msg = '--- STAFF ONLINE ---\n'
    for _, a in ipairs(admins) do
        msg = msg .. ('[%s] %s\n'):format(a.rankName, a.name)
    end
    TriggerClientEvent('adminSystem:client:notify', source, msg, 'info')
end, false)
