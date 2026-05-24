--[[ ============================================================
     BAN SYSTEM - Gestione ban permanenti e temporanei
============================================================ ]]

Bans = {}
local banData = {}  -- { [identifier] = { reason, expiry, bannedBy, timestamp } }

-- ============================================================
-- INIT: carica ban da file
-- ============================================================
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Bans.Load()
end)

function Bans.Load()
    local raw = LoadResourceFile(GetCurrentResourceName(), Config.BanSettings.banFile)
    if raw then
        banData = Utils.JSONToTable(raw)
        -- Pulizia ban scaduti
        local removed = 0
        for id, ban in pairs(banData) do
            if ban.expiry and ban.expiry ~= 0 and ban.expiry < os.time() then
                banData[id] = nil
                removed = removed + 1
            end
        end
        if removed > 0 then
            Bans.Save()
            print('^3[AdminSystem] Rimossi ' .. removed .. ' ban scaduti^7')
        end
        print('^2[AdminSystem] Caricati ' .. Bans.Count() .. ' ban attivi^7')
    else
        banData = {}
        Bans.Save()
    end
end

function Bans.Save()
    SaveResourceFile(GetCurrentResourceName(), Config.BanSettings.banFile, Utils.TableToJSON(banData), -1)
end

function Bans.Count()
    local n = 0
    for _ in pairs(banData) do n = n + 1 end
    return n
end

-- ============================================================
-- CONTROLLA BAN AL JOIN
-- ============================================================
if Config.BanSettings.checkOnJoin then
    AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
        local src = source
        deferrals.defer()
        Wait(0)
        local banned, ban = Bans.CheckPlayer(src)
        if banned then
            local expiry = Utils.FormatBanExpiry(ban.expiry)
            local msg = Config.BanSettings.kickMessage:format(
                ban.reason or 'Nessun motivo',
                expiry
            )
            deferrals.done(msg)
        else
            deferrals.done()
        end
    end)
end

-- ============================================================
-- CONTROLLA SE UN PLAYER E' BANNATO
-- ============================================================
function Bans.CheckPlayer(source)
    local ids = Utils.GetIdentifiers(source)
    for prefix, id in pairs(ids) do
        if banData[id] then
            local ban = banData[id]
            -- Controlla scadenza
            if ban.expiry and ban.expiry ~= 0 and ban.expiry < os.time() then
                banData[id] = nil
                Bans.Save()
                return false, nil
            end
            return true, ban
        end
    end
    return false, nil
end

-- ============================================================
-- ESEGUI BAN
-- ============================================================
function Bans.BanPlayer(adminSrc, targetSrc, reason, duration)
    if not Permissions.CanBan(adminSrc) then
        TriggerClientEvent('adminSystem:client:notify', adminSrc, 'Non hai il permesso di bannare!', 'error')
        return false
    end

    local targetName = GetPlayerName(targetSrc)
    local adminName  = GetPlayerName(adminSrc)
    local ids        = Utils.GetIdentifiers(targetSrc)
    local expiry     = Utils.ParseDuration(duration)  -- 0 = perm
    local banEntry   = {
        name      = targetName,
        reason    = reason,
        expiry    = expiry,
        bannedBy  = adminName,
        timestamp = os.time(),
    }

    -- Salva su tutti gli identifier
    for _, id in pairs(ids) do
        banData[id] = banEntry
    end
    if Config.BanSettings.checkHWID and ids.hwid then
        banData[ids.hwid] = banEntry
    end
    Bans.Save()

    -- Kick dal server
    local expiryStr = Utils.FormatBanExpiry(expiry)
    local kickMsg = Config.BanSettings.kickMessage:format(reason, expiryStr)
    DropPlayer(targetSrc, kickMsg)

    -- Notifica admin
    TriggerClientEvent('adminSystem:client:notify', adminSrc,
        ('Ban eseguito su %s | Motivo: %s | Durata: %s'):format(targetName, reason, expiryStr), 'success')

    -- Log
    Logs.Send('ban', ('**%s** ha bannato **%s**'):format(adminName, targetName), {
        { name = 'Motivo',   value = reason,    inline = true },
        { name = 'Durata',   value = expiryStr, inline = true },
        { name = 'License',  value = ids.license or 'N/A', inline = true },
        { name = 'Steam',    value = ids.steam   or 'N/A', inline = true },
        { name = 'Discord',  value = ids.discord or 'N/A', inline = true },
    })

    print(('[AdminSystem] BAN: %s ha bannato %s | Motivo: %s | Durata: %s'):format(
        adminName, targetName, reason, expiryStr))
    return true
end

-- ============================================================
-- RIMUOVI BAN
-- ============================================================
function Bans.UnbanPlayer(adminSrc, identifier)
    if not banData[identifier] then
        TriggerClientEvent('adminSystem:client:notify', adminSrc, 'Nessun ban trovato per questo identifier.', 'warning')
        return false
    end
    local bannedName = banData[identifier].name or identifier
    banData[identifier] = nil
    Bans.Save()
    TriggerClientEvent('adminSystem:client:notify', adminSrc, ('Ban rimosso per: %s'):format(bannedName), 'success')
    Logs.Send('ban', ('**%s** ha rimosso il ban di **%s**'):format(GetPlayerName(adminSrc), bannedName))
    return true
end

-- ============================================================
-- NETWORK EVENTS
-- ============================================================
RegisterNetEvent('adminSystem:server:ban', function(targetId, reason, duration)
    local src = source
    Bans.BanPlayer(src, tonumber(targetId), reason, duration)
end)

RegisterNetEvent('adminSystem:server:unban', function(identifier)
    local src = source
    if not Permissions.IsAdmin(src, 2) then return end
    Bans.UnbanPlayer(src, identifier)
end)

RegisterNetEvent('adminSystem:server:getBanList', function()
    local src = source
    if not Permissions.IsAdmin(src, 2) then return end
    TriggerClientEvent('adminSystem:client:banList', src, banData)
end)
