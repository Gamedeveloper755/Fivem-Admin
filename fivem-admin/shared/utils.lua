--[[ ============================================================
     UTILS - Funzioni condivise client/server
============================================================ ]]

Utils = {}

-- Rileva framework in uso
function Utils.DetectFramework()
    if Config.Framework ~= 'auto' then
        return Config.Framework
    end
    if GetResourceState('es_extended') == 'started' then
        return 'esx'
    elseif GetResourceState('qb-core') == 'started' then
        return 'qbcore'
    else
        return 'standalone'
    end
end

-- Formatta il tempo rimanente di un ban
function Utils.FormatBanExpiry(timestamp)
    if not timestamp or timestamp == 0 then return 'Permanente' end
    local remaining = timestamp - os.time()
    if remaining <= 0 then return 'Scaduto' end
    local days    = math.floor(remaining / 86400)
    local hours   = math.floor((remaining % 86400) / 3600)
    local minutes = math.floor((remaining % 3600) / 60)
    if days > 0    then return days .. 'g ' .. hours .. 'h' end
    if hours > 0   then return hours .. 'h ' .. minutes .. 'm' end
    return minutes .. ' minuti'
end

-- Converte durata stringa -> secondi
-- es. "7d", "24h", "30m", "perm"
function Utils.ParseDuration(str)
    if not str or str == 'perm' or str == '0' then return 0 end
    local n, unit = str:match('(%d+)([dhm])')
    if not n then return nil end
    n = tonumber(n)
    if unit == 'd' then return os.time() + (n * 86400) end
    if unit == 'h' then return os.time() + (n * 3600)  end
    if unit == 'm' then return os.time() + (n * 60)    end
    return nil
end

-- Ottieni tutti gli identifier di un player
function Utils.GetIdentifiers(source)
    local ids = {}
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id then
            local prefix = id:match('^(.-):[^:]+$')
            ids[prefix] = id
        end
    end
    ids.hwid = GetPlayerToken(source, 0) or 'unknown'
    return ids
end

-- Identifier principale (license > steam > discord)
function Utils.GetMainIdentifier(source)
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and id:find('license:') then return id end
    end
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and id:find('steam:') then return id end
    end
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and id:find('discord:') then return id end
    end
    return tostring(source)
end

-- Trova un player per nome parziale o ID
function Utils.FindPlayer(query)
    local num = tonumber(query)
    if num and GetPlayerName(num) then return num end
    query = query:lower()
    for _, pid in ipairs(GetPlayers()) do
        local name = GetPlayerName(tonumber(pid))
        if name and name:lower():find(query, 1, true) then
            return tonumber(pid)
        end
    end
    return nil
end

-- Colore rank
function Utils.GetRankColor(rank)
    if Config.Ranks[rank] then return Config.Ranks[rank].color end
    return '#FFFFFF'
end

-- Nome rank
function Utils.GetRankName(rank)
    if Config.Ranks[rank] then return Config.Ranks[rank].name end
    return 'Giocatore'
end

-- Tabella JSON serialization semplice (per file bans)
function Utils.TableToJSON(t)
    return json.encode(t)
end

function Utils.JSONToTable(s)
    if not s or s == '' then return {} end
    local ok, result = pcall(json.decode, s)
    if ok then return result else return {} end
end
