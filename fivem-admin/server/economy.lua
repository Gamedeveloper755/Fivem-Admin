--[[ ============================================================
     ECONOMY - Compatibile ESX | QBCore | Standalone
============================================================ ]]

Economy = {}
local framework = nil
local standaloneAccounts = {}  -- usato solo in standalone mode

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Wait(500)  -- aspetta che altri framework si avviino
    framework = Utils.DetectFramework()
    print('^2[AdminSystem] Economy framework: ' .. framework .. '^7')
    if framework == 'standalone' then
        Economy.LoadStandalone()
    end
end)

-- ============================================================
-- STANDALONE - salvataggio locale
-- ============================================================
function Economy.LoadStandalone()
    local raw = LoadResourceFile(GetCurrentResourceName(), 'economy.json')
    if raw then
        standaloneAccounts = Utils.JSONToTable(raw)
    else
        standaloneAccounts = {}
        Economy.SaveStandalone()
    end
end

function Economy.SaveStandalone()
    SaveResourceFile(GetCurrentResourceName(), 'economy.json', Utils.TableToJSON(standaloneAccounts), -1)
end

function Economy.GetOrCreateAccount(identifier, name)
    if not standaloneAccounts[identifier] then
        standaloneAccounts[identifier] = {
            name    = name,
            cash    = Config.Economy.startingMoney,
            bank    = Config.Economy.startingBank,
            created = os.time(),
        }
        Economy.SaveStandalone()
    end
    return standaloneAccounts[identifier]
end

-- ============================================================
-- GETMONEY - ottieni soldi di un player
-- ============================================================
function Economy.GetMoney(source, accountType)
    accountType = accountType or 'cash'
    if framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return 0 end
        if accountType == 'cash' then return xPlayer.getMoney() end
        local acc = xPlayer.getAccount(accountType)
        return acc and acc.money or 0

    elseif framework == 'qbcore' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayer(source)
        if not player then return 0 end
        return player.PlayerData.money[accountType] or 0

    else -- standalone
        local id = Utils.GetMainIdentifier(source)
        local acc = Economy.GetOrCreateAccount(id, GetPlayerName(source))
        return acc[accountType] or 0
    end
end

-- ============================================================
-- GIVEMONEY - dai soldi a un player
-- ============================================================
function Economy.GiveMoney(adminSrc, targetSrc, amount, accountType)
    if not Permissions.IsAdmin(adminSrc, 2) then
        TriggerClientEvent('adminSystem:client:notify', adminSrc, 'Permesso insufficiente!', 'error')
        return
    end
    amount      = tonumber(amount)
    accountType = accountType or 'cash'
    if not amount or amount <= 0 then
        TriggerClientEvent('adminSystem:client:notify', adminSrc, 'Importo non valido!', 'error')
        return
    end

    local targetName = GetPlayerName(targetSrc)

    if framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(targetSrc)
        if not xPlayer then return end
        if accountType == 'cash' then
            xPlayer.addMoney(amount)
        else
            xPlayer.addAccountMoney(accountType, amount)
        end

    elseif framework == 'qbcore' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayer(targetSrc)
        if not player then return end
        player.Functions.AddMoney(accountType, amount)

    else -- standalone
        local id = Utils.GetMainIdentifier(targetSrc)
        local acc = Economy.GetOrCreateAccount(id, targetName)
        acc[accountType] = (acc[accountType] or 0) + amount
        Economy.SaveStandalone()
        TriggerClientEvent('adminSystem:client:notify', targetSrc,
            ('Hai ricevuto %s%s'):format(Config.Economy.currencySymbol, amount), 'success')
    end

    TriggerClientEvent('adminSystem:client:notify', adminSrc,
        ('Dati %s%s a %s [%s]'):format(Config.Economy.currencySymbol, amount, targetName, accountType), 'success')

    Logs.Send('econ', ('**%s** ha dato **%s%s** a **%s** [%s]'):format(
        GetPlayerName(adminSrc), Config.Economy.currencySymbol, amount, targetName, accountType))
end

-- ============================================================
-- SETMONEY - imposta soldi
-- ============================================================
function Economy.SetMoney(adminSrc, targetSrc, amount, accountType)
    if not Permissions.IsAdmin(adminSrc, 2) then return end
    amount      = tonumber(amount)
    accountType = accountType or 'cash'
    if not amount or amount < 0 then return end

    local targetName = GetPlayerName(targetSrc)

    if framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(targetSrc)
        if not xPlayer then return end
        if accountType == 'cash' then
            xPlayer.setMoney(amount)
        else
            xPlayer.setAccountMoney(accountType, amount)
        end

    elseif framework == 'qbcore' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayer(targetSrc)
        if not player then return end
        local current = player.PlayerData.money[accountType] or 0
        local diff    = amount - current
        if diff >= 0 then
            player.Functions.AddMoney(accountType, diff)
        else
            player.Functions.RemoveMoney(accountType, math.abs(diff))
        end

    else -- standalone
        local id = Utils.GetMainIdentifier(targetSrc)
        local acc = Economy.GetOrCreateAccount(id, targetName)
        acc[accountType] = amount
        Economy.SaveStandalone()
    end

    TriggerClientEvent('adminSystem:client:notify', adminSrc,
        ('Soldi di %s impostati a %s%s [%s]'):format(targetName, Config.Economy.currencySymbol, amount, accountType), 'success')
    Logs.Send('econ', ('**%s** ha impostato i soldi di **%s** a **%s%s** [%s]'):format(
        GetPlayerName(adminSrc), targetName, Config.Economy.currencySymbol, amount, accountType))
end

-- ============================================================
-- NETWORK EVENTS
-- ============================================================
RegisterNetEvent('adminSystem:server:giveMoney', function(targetId, amount, accountType)
    Economy.GiveMoney(source, tonumber(targetId), amount, accountType)
end)

RegisterNetEvent('adminSystem:server:setMoney', function(targetId, amount, accountType)
    Economy.SetMoney(source, tonumber(targetId), amount, accountType)
end)

RegisterNetEvent('adminSystem:server:getMoney', function(targetId)
    local src = source
    if not Permissions.IsAdmin(src, 1) then return end
    local target = tonumber(targetId)
    local cash = Economy.GetMoney(target, 'cash')
    local bank = Economy.GetMoney(target, 'bank')
    TriggerClientEvent('adminSystem:client:playerMoney', src, {
        target = target,
        name   = GetPlayerName(target),
        cash   = cash,
        bank   = bank,
    })
end)
