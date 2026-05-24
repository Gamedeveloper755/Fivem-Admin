--[[ ============================================================
     PERMISSIONS - Gestione ruoli admin
============================================================ ]]

Permissions = {}
local adminList = {}  -- { [identifier] = rank }

-- ============================================================
-- INIT: carica admins da file o database
-- ============================================================
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Permissions.LoadAdmins()
end)

function Permissions.LoadAdmins()
    -- Carica da file admins.json
    local rawFile = LoadResourceFile(GetCurrentResourceName(), 'admins.json')
    if rawFile then
        adminList = Utils.JSONToTable(rawFile)
        print('^2[AdminSystem] Caricati ' .. Permissions.CountAdmins() .. ' admin dal file^7')
    else
        -- Crea file vuoto
        adminList = {}
        Permissions.SaveAdmins()
    end
    -- Aggiungi owners automaticamente al rank 4
    for _, id in ipairs(Config.Owners) do
        if not adminList[id] then
            adminList[id] = 4
        end
    end
end

function Permissions.SaveAdmins()
    SaveResourceFile(GetCurrentResourceName(), 'admins.json', Utils.TableToJSON(adminList), -1)
end

function Permissions.CountAdmins()
    local n = 0
    for _ in pairs(adminList) do n = n + 1 end
    return n
end

-- ============================================================
-- VERIFICA PERMESSI
-- ============================================================
function Permissions.GetRank(source)
    local ids = Utils.GetIdentifiers(source)
    -- Controlla ogni identifier
    for _, id in pairs(ids) do
        if adminList[id] then
            return adminList[id]
        end
    end
    return 0
end

function Permissions.IsAdmin(source, minRank)
    minRank = minRank or 1
    return Permissions.GetRank(source) >= minRank
end

function Permissions.CanBan(source)
    local rank = Permissions.GetRank(source)
    return rank >= 1 and Config.Ranks[rank] and Config.Ranks[rank].canBan
end

function Permissions.CanKick(source)
    local rank = Permissions.GetRank(source)
    return rank >= 1 and Config.Ranks[rank] and Config.Ranks[rank].canKick
end

function Permissions.CanFreeze(source)
    local rank = Permissions.GetRank(source)
    return rank >= 1 and Config.Ranks[rank] and Config.Ranks[rank].canFreeze
end

-- ============================================================
-- SET / REMOVE RANK
-- ============================================================
function Permissions.SetRank(identifier, rank)
    if rank == 0 then
        adminList[identifier] = nil
    else
        adminList[identifier] = rank
    end
    Permissions.SaveAdmins()
end

function Permissions.RemoveAdmin(identifier)
    adminList[identifier] = nil
    Permissions.SaveAdmins()
end

-- ============================================================
-- LISTA ADMIN ONLINE
-- ============================================================
function Permissions.GetOnlineAdmins()
    local list = {}
    for _, pid in ipairs(GetPlayers()) do
        local src = tonumber(pid)
        local rank = Permissions.GetRank(src)
        if rank > 0 then
            table.insert(list, {
                source = src,
                name   = GetPlayerName(src),
                rank   = rank,
                rankName = Utils.GetRankName(rank),
                color  = Utils.GetRankColor(rank),
            })
        end
    end
    return list
end

-- ============================================================
-- NETWORK EVENTS
-- ============================================================
RegisterNetEvent('adminSystem:server:setRank', function(targetId, rank)
    local src = source
    if not Permissions.IsAdmin(src, 4) then
        Logs.Send('warn', 'Tentativo non autorizzato di setRank da ' .. GetPlayerName(src))
        return
    end
    local target = tonumber(targetId)
    if not target then return end
    local identifier = Utils.GetMainIdentifier(target)
    Permissions.SetRank(identifier, rank)
    TriggerClientEvent('adminSystem:client:notify', target, 'Il tuo ruolo admin è stato aggiornato a: ' .. Utils.GetRankName(rank), 'info')
    Logs.Send('admin', ('**%s** ha impostato il rank di **%s** a **%s**'):format(
        GetPlayerName(src), GetPlayerName(target), Utils.GetRankName(rank)
    ))
end)

RegisterNetEvent('adminSystem:server:getAdminList', function()
    local src = source
    if not Permissions.IsAdmin(src, 1) then return end
    TriggerClientEvent('adminSystem:client:adminList', src, Permissions.GetOnlineAdmins())
end)
