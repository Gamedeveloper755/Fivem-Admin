--[[ ============================================================
     COMANDI CHAT - Alias rapidi per tutte le funzioni admin
     Uso: /aban [id] [durata] [motivo]
          /akick [id] [motivo]
          /awarn [id] [motivo]
          /afreeze [id]
          /abring [id]
          /agoto [id]
          /arevive [id?]
          /anoclip
          /asetrank [id] [rank 1-4]
          /agivemoney [id] [importo] [cash/bank]
          /asetmoney [id] [importo] [cash/bank]
          /awhiteadd [identifier] [nome]
          /awhiterem [identifier]
          /stafflist
============================================================ ]]

-- Helper: costruisci stringa motivo da args multipli
local function buildReason(args, start)
    local parts = {}
    for i = start, #args do parts[#parts+1] = args[i] end
    return table.concat(parts, ' ')
end

-- BAN
RegisterCommand(Config.Commands.ban, function(source, args)
    if not Permissions.CanBan(source) then
        TriggerClientEvent('adminSystem:client:notify', source, 'Permesso insufficiente!', 'error')
        return
    end
    local target   = Utils.FindPlayer(args[1])
    local duration = args[2] or 'perm'
    local reason   = buildReason(args, 3)
    if not target then
        TriggerClientEvent('adminSystem:client:notify', source, 'Player non trovato!', 'error')
        return
    end
    if reason == '' then reason = 'Nessun motivo specificato' end
    Bans.BanPlayer(source, target, reason, duration)
end, false)

-- KICK
RegisterCommand(Config.Commands.kick, function(source, args)
    if not Permissions.CanKick(source) then return end
    local target = Utils.FindPlayer(args[1])
    local reason = buildReason(args, 2)
    if not target then
        TriggerClientEvent('adminSystem:client:notify', source, 'Player non trovato!', 'error')
        return
    end
    TriggerEvent('adminSystem:server:kick', target, reason ~= '' and reason or 'Nessun motivo')
end, false)

-- WARN
RegisterCommand(Config.Commands.warn, function(source, args)
    if not Permissions.IsAdmin(source, 1) then return end
    local target = Utils.FindPlayer(args[1])
    local reason = buildReason(args, 2)
    if not target then return end
    TriggerEvent('adminSystem:server:warn', target, reason ~= '' and reason or 'Comportamento non adeguato')
end, false)

-- FREEZE
RegisterCommand(Config.Commands.freeze, function(source, args)
    if not Permissions.IsAdmin(source, 1) then return end
    local target = Utils.FindPlayer(args[1])
    if not target then return end
    TriggerClientEvent('adminSystem:client:freeze', target, true)
    TriggerClientEvent('adminSystem:client:notify', source, 'Player freezato.', 'info')
end, false)

-- BRING
RegisterCommand(Config.Commands.bring, function(source, args)
    if not Permissions.IsAdmin(source, 1) then return end
    local target = Utils.FindPlayer(args[1])
    if not target then return end
    TriggerClientEvent('adminSystem:client:bringToAdmin', target, GetPlayerPed(source))
end, false)

-- GOTO
RegisterCommand(Config.Commands.goto_, function(source, args)
    if not Permissions.IsAdmin(source, 1) then return end
    local target = Utils.FindPlayer(args[1])
    if not target then return end
    TriggerClientEvent('adminSystem:client:gotoPlayer', source, GetPlayerPed(target))
end, false)

-- NOCLIP
RegisterCommand(Config.Commands.noclip, function(source)
    if not Permissions.IsAdmin(source, 1) then return end
    TriggerClientEvent('adminSystem:client:toggleNoclip', source)
end, false)

-- REVIVE
RegisterCommand(Config.Commands.revive, function(source, args)
    if not Permissions.IsAdmin(source, 1) then return end
    local target = args[1] and Utils.FindPlayer(args[1]) or source
    TriggerClientEvent('adminSystem:client:revive', target)
end, false)

-- SETRANK
RegisterCommand(Config.Commands.setrank, function(source, args)
    if not Permissions.IsAdmin(source, 4) then
        TriggerClientEvent('adminSystem:client:notify', source, 'Solo gli Owner possono impostare rank!', 'error')
        return
    end
    local target = Utils.FindPlayer(args[1])
    local rank   = tonumber(args[2])
    if not target or not rank then return end
    local identifier = Utils.GetMainIdentifier(target)
    Permissions.SetRank(identifier, rank)
    TriggerClientEvent('adminSystem:client:notify', source,
        ('Rank di %s impostato a %s'):format(GetPlayerName(target), Utils.GetRankName(rank)), 'success')
    TriggerClientEvent('adminSystem:client:notify', target,
        ('Il tuo rank admin è stato impostato a: %s'):format(Utils.GetRankName(rank)), 'info')
end, false)

-- GIVEMONEY
RegisterCommand(Config.Commands.givemoney, function(source, args)
    if not Permissions.IsAdmin(source, 2) then return end
    local target  = Utils.FindPlayer(args[1])
    local amount  = tonumber(args[2])
    local accType = args[3] or 'cash'
    if not target or not amount then return end
    Economy.GiveMoney(source, target, amount, accType)
end, false)

-- SETMONEY
RegisterCommand(Config.Commands.setmoney, function(source, args)
    if not Permissions.IsAdmin(source, 2) then return end
    local target  = Utils.FindPlayer(args[1])
    local amount  = tonumber(args[2])
    local accType = args[3] or 'cash'
    if not target or not amount then return end
    Economy.SetMoney(source, target, amount, accType)
end, false)

-- WHITELIST ADD
RegisterCommand(Config.Commands.addwhite, function(source, args)
    if not Permissions.IsAdmin(source, 2) then return end
    local identifier = args[1]
    local name       = buildReason(args, 2)
    if not identifier then return end
    Whitelist.Add(source, identifier, name ~= '' and name or identifier)
end, false)

-- WHITELIST REMOVE
RegisterCommand(Config.Commands.remwhite, function(source, args)
    if not Permissions.IsAdmin(source, 2) then return end
    local identifier = args[1]
    if not identifier then return end
    Whitelist.Remove(source, identifier)
end, false)
