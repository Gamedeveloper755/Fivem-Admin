--[[ ============================================================
     WHITELIST SYSTEM
============================================================ ]]

Whitelist = {}
local whitelistData = {}  -- { [identifier] = { name, addedBy, timestamp } }

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    if Config.Whitelist.enabled then
        Whitelist.Load()
    end
end)

function Whitelist.Load()
    local raw = LoadResourceFile(GetCurrentResourceName(), 'whitelist.json')
    if raw then
        whitelistData = Utils.JSONToTable(raw)
        print('^2[AdminSystem] Whitelist: ' .. Whitelist.Count() .. ' giocatori^7')
    else
        whitelistData = {}
        Whitelist.Save()
    end
end

function Whitelist.Save()
    SaveResourceFile(GetCurrentResourceName(), 'whitelist.json', Utils.TableToJSON(whitelistData), -1)
end

function Whitelist.Count()
    local n = 0
    for _ in pairs(whitelistData) do n = n + 1 end
    return n
end

function Whitelist.IsWhitelisted(source)
    if not Config.Whitelist.enabled then return true end
    local ids = Utils.GetIdentifiers(source)
    for _, id in pairs(ids) do
        if whitelistData[id] then return true end
    end
    return false
end

function Whitelist.Add(adminSrc, identifier, playerName)
    whitelistData[identifier] = {
        name      = playerName or identifier,
        addedBy   = GetPlayerName(adminSrc),
        timestamp = os.time(),
    }
    Whitelist.Save()
    TriggerClientEvent('adminSystem:client:notify', adminSrc,
        ('Aggiunto in whitelist: %s (%s)'):format(playerName or '?', identifier), 'success')
    Logs.Send('admin', ('**%s** ha aggiunto **%s** alla whitelist'):format(GetPlayerName(adminSrc), playerName or identifier))
end

function Whitelist.Remove(adminSrc, identifier)
    if not whitelistData[identifier] then
        TriggerClientEvent('adminSystem:client:notify', adminSrc, 'Identifier non trovato in whitelist.', 'warning')
        return
    end
    local name = whitelistData[identifier].name
    whitelistData[identifier] = nil
    Whitelist.Save()
    TriggerClientEvent('adminSystem:client:notify', adminSrc, ('Rimosso dalla whitelist: %s'):format(name), 'success')
    Logs.Send('admin', ('**%s** ha rimosso **%s** dalla whitelist'):format(GetPlayerName(adminSrc), name))
end

-- Check al join
if Config.Whitelist.enabled then
    AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
        local src = source
        deferrals.defer()
        Wait(0)
        if not Whitelist.IsWhitelisted(src) then
            deferrals.done(Config.Whitelist.kickMessage)
        else
            deferrals.done()
        end
    end)
end

-- Network Events
RegisterNetEvent('adminSystem:server:whitelistAdd', function(identifier, playerName)
    local src = source
    if not Permissions.IsAdmin(src, 2) then return end
    Whitelist.Add(src, identifier, playerName)
end)

RegisterNetEvent('adminSystem:server:whitelistRemove', function(identifier)
    local src = source
    if not Permissions.IsAdmin(src, 2) then return end
    Whitelist.Remove(src, identifier)
end)

RegisterNetEvent('adminSystem:server:getWhitelist', function()
    local src = source
    if not Permissions.IsAdmin(src, 2) then return end
    TriggerClientEvent('adminSystem:client:whitelist', src, whitelistData)
end)
