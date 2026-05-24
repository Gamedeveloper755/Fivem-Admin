--[[ ============================================================
     LOGS - Discord Webhook + file locale
============================================================ ]]

Logs = {}

local colors = {
    ban    = 15158332,  -- rosso
    kick   = 16744272,  -- arancione
    admin  = 3447003,   -- blu
    join   = 5763719,   -- verde
    leave  = 10181046,  -- viola
    econ   = 1752220,   -- ciano
    warn   = 16705372,  -- giallo
    info   = 8311585,   -- grigio
}

local icons = {
    ban   = '🔨',
    kick  = '👢',
    admin = '🛡️',
    join  = '✅',
    leave = '🚪',
    econ  = '💰',
    warn  = '⚠️',
    info  = 'ℹ️',
}

-- ============================================================
-- INVIA LOG A DISCORD
-- ============================================================
function Logs.Send(logType, message, fields)
    if not Config.Logs.enabled then return end

    local webhook = Config.Logs['webhook' .. logType:sub(1,1):upper() .. logType:sub(2)]
    if not webhook or webhook == '' then
        webhook = Config.Logs.webhookAdmin
    end
    if not webhook or webhook == '' then return end

    local icon  = icons[logType]  or 'ℹ️'
    local color = colors[logType] or 8311585

    local embedFields = fields or {}

    local payload = {
        username   = Config.Logs.serverName,
        avatar_url = Config.Logs.serverIcon,
        embeds = {{
            title       = (icon .. ' ' .. (logType:upper())),
            description = message,
            color       = color,
            fields      = embedFields,
            footer      = { text = os.date('%d/%m/%Y %H:%M:%S') },
        }}
    }

    PerformHttpRequest(webhook, function(status)
        if status ~= 204 then
            print('^1[AdminSystem] Webhook error: ' .. tostring(status) .. '^7')
        end
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

-- ============================================================
-- LOG JOIN/LEAVE
-- ============================================================
AddEventHandler('playerConnecting', function(name, _, deferrals)
    local src = source
    if Config.Logs.enabled then
        local ids = Utils.GetIdentifiers(src)
        Logs.Send('join', ('**%s** si è connesso'):format(name), {
            { name = 'Steam',   value = ids.steam   or 'N/A', inline = true },
            { name = 'License', value = ids.license or 'N/A', inline = true },
            { name = 'Discord', value = ids.discord or 'N/A', inline = true },
            { name = 'IP',      value = ids.ip      or 'N/A', inline = true },
        })
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    if Config.Logs.enabled then
        Logs.Send('leave', ('**%s** ha lasciato il server\nMotivo: %s'):format(
            GetPlayerName(src) or 'Unknown', reason or 'sconosciuto'
        ))
    end
end)

-- ============================================================
-- LOG DA CLIENT
-- ============================================================
RegisterNetEvent('adminSystem:server:log', function(logType, message, fields)
    local src = source
    if not Permissions.IsAdmin(src, 1) then return end
    Logs.Send(logType, message, fields)
end)
