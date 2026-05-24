--[[ ============================================================
     CLIENT MENU - Gestione NUI admin panel
============================================================ ]]

local menuOpen   = false
local playerRank = 0

-- ============================================================
-- OPEN MENU
-- ============================================================
AddEventHandler('adminSystem:client:openMenu', function()
    -- Verifica rank lato client (il server farà il check reale)
    TriggerServerEvent('adminSystem:server:verifyAdmin', function(rank)
        playerRank = rank
        if rank < 1 then
            lib_notify('Non hai permessi admin!', 'error')
            return
        end
        OpenAdminPanel()
    end)
    -- Workaround: richiedi rank via evento
    TriggerServerEvent('adminSystem:server:getMyRank')
end)

RegisterNetEvent('adminSystem:client:myRank', function(rank)
    playerRank = rank
    if rank < 1 then
        lib_notify('Non hai permessi admin!', 'error')
        return
    end
    OpenAdminPanel()
end)

function OpenAdminPanel()
    menuOpen = true
    SetNuiFocus(true, true)
    -- Richiedi lista player
    TriggerServerEvent('adminSystem:server:getPlayers')
    SendNUIMessage({ action = 'open', rank = playerRank })
    lib_notify('Menu admin aperto', 'info')
end

-- ============================================================
-- CLOSE MENU
-- ============================================================
RegisterNUICallback('closeMenu', function(data, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    cb({})
end)

-- ============================================================
-- NUI → SERVER ACTIONS
-- ============================================================

-- Ban
RegisterNUICallback('banPlayer', function(data, cb)
    TriggerServerEvent('adminSystem:server:ban', data.targetId, data.reason, data.duration)
    cb({})
end)

-- Kick
RegisterNUICallback('kickPlayer', function(data, cb)
    TriggerServerEvent('adminSystem:server:kick', data.targetId, data.reason)
    cb({})
end)

-- Warn
RegisterNUICallback('warnPlayer', function(data, cb)
    TriggerServerEvent('adminSystem:server:warn', data.targetId, data.reason)
    cb({})
end)

-- Freeze
RegisterNUICallback('freezePlayer', function(data, cb)
    TriggerServerEvent('adminSystem:server:freeze', data.targetId, data.state)
    cb({})
end)

-- Bring
RegisterNUICallback('bringPlayer', function(data, cb)
    TriggerServerEvent('adminSystem:server:bring', data.targetId)
    cb({})
end)

-- Goto
RegisterNUICallback('gotoPlayer', function(data, cb)
    TriggerServerEvent('adminSystem:server:goto', data.targetId)
    cb({})
end)

-- Revive
RegisterNUICallback('revivePlayer', function(data, cb)
    TriggerServerEvent('adminSystem:server:revive', data.targetId)
    cb({})
end)

-- Give Money
RegisterNUICallback('giveMoney', function(data, cb)
    TriggerServerEvent('adminSystem:server:giveMoney', data.targetId, data.amount, data.accountType)
    cb({})
end)

-- Set Money
RegisterNUICallback('setMoney', function(data, cb)
    TriggerServerEvent('adminSystem:server:setMoney', data.targetId, data.amount, data.accountType)
    cb({})
end)

-- Set Rank
RegisterNUICallback('setRank', function(data, cb)
    TriggerServerEvent('adminSystem:server:setRank', data.targetId, data.rank)
    cb({})
end)

-- Whitelist Add
RegisterNUICallback('whitelistAdd', function(data, cb)
    TriggerServerEvent('adminSystem:server:whitelistAdd', data.identifier, data.name)
    cb({})
end)

-- Whitelist Remove
RegisterNUICallback('whitelistRemove', function(data, cb)
    TriggerServerEvent('adminSystem:server:whitelistRemove', data.identifier)
    cb({})
end)

-- Noclip toggle
RegisterNUICallback('toggleNoclip', function(data, cb)
    TriggerEvent('adminSystem:client:toggleNoclip')
    cb({})
end)

-- Ricarica players
RegisterNUICallback('refreshPlayers', function(data, cb)
    TriggerServerEvent('adminSystem:server:getPlayers')
    cb({})
end)

-- ============================================================
-- SERVER → NUI DATA
-- ============================================================
RegisterNetEvent('adminSystem:client:playersList', function(list)
    SendNUIMessage({ action = 'playersList', data = list })
end)

RegisterNetEvent('adminSystem:client:playerMoney', function(data)
    SendNUIMessage({ action = 'playerMoney', data = data })
end)

RegisterNetEvent('adminSystem:client:banList', function(data)
    SendNUIMessage({ action = 'banList', data = data })
end)

RegisterNetEvent('adminSystem:client:whitelist', function(data)
    SendNUIMessage({ action = 'whitelist', data = data })
end)

RegisterNetEvent('adminSystem:client:adminList', function(data)
    SendNUIMessage({ action = 'adminList', data = data })
end)

-- ============================================================
-- ESC per chiudere menu
-- ============================================================
CreateThread(function()
    while true do
        Wait(0)
        if menuOpen and IsControlJustPressed(0, 200) then  -- ESC
            menuOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'close' })
        end
    end
end)

-- SERVER: rispondi con rank
RegisterNetEvent('adminSystem:client:myRank', function(rank)
    playerRank = rank
    if rank >= 1 then
        OpenAdminPanel()
    else
        lib_notify('Non hai permessi admin!', 'error')
    end
end)
