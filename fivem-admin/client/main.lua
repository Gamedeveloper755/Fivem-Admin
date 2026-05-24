--[[ ============================================================
     CLIENT MAIN - Azioni lato client
============================================================ ]]

local isFrozen   = false
local isNoclip   = false
local isSpectate = false
local spectateTarget = nil

-- ============================================================
-- FREEZE
-- ============================================================
RegisterNetEvent('adminSystem:client:freeze', function(state)
    isFrozen = state
    FreezeEntityPosition(PlayerPedId(), state)
    if state then
        lib_notify('Sei stato freezato da un admin.', 'warning')
    else
        lib_notify('Sei stato scongelato.', 'info')
    end
end)

-- ============================================================
-- BRING (teleporta questo client verso un ped)
-- ============================================================
RegisterNetEvent('adminSystem:client:bringToAdmin', function(adminPed)
    local coords = GetEntityCoords(GetPlayerPed(PlayerId()))  -- fallback
    -- Recupera coords del ped admin tramite network entity
    local netPed = NetworkGetEntityFromNetworkId(adminPed)
    if netPed and netPed ~= 0 then
        coords = GetEntityCoords(netPed)
    end
    SetEntityCoords(PlayerPedId(), coords.x + 2.0, coords.y, coords.z, false, false, false, false)
    lib_notify('Sei stato portato da un admin.', 'info')
end)

-- ============================================================
-- GOTO (teleporta questo client verso un target ped)
-- ============================================================
RegisterNetEvent('adminSystem:client:gotoPlayer', function(targetPed)
    local netPed = NetworkGetEntityFromNetworkId(targetPed)
    if netPed and netPed ~= 0 then
        local coords = GetEntityCoords(netPed)
        SetEntityCoords(PlayerPedId(), coords.x + 2.0, coords.y, coords.z, false, false, false, false)
        lib_notify('Teletrasportato al player.', 'info')
    end
end)

-- ============================================================
-- REVIVE
-- ============================================================
RegisterNetEvent('adminSystem:client:revive', function()
    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPlayerDead(PlayerId()) then
        NetworkResurrectLocalPlayer(GetEntityCoords(ped), 0.0, true, false)
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        ClearPedBloodDamage(ped)
    end
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    lib_notify('Sei stato revivato.', 'success')
end)

-- ============================================================
-- NOCLIP TOGGLE
-- ============================================================
RegisterNetEvent('adminSystem:client:toggleNoclip', function()
    isNoclip = not isNoclip
    lib_notify('Noclip: ' .. (isNoclip and 'ATTIVATO' or 'DISATTIVATO'), 'info')
end)

-- Noclip tick
CreateThread(function()
    while true do
        Wait(0)
        if isNoclip then
            local ped    = PlayerPedId()
            local speed  = IsControlPressed(0, 21) and 2.0 or 0.5  -- SHIFT = veloce
            local fwd    = GetEntityForwardVector(ped)
            local coords = GetEntityCoords(ped)

            local moveX = GetDisabledControlNormal(0, 30)
            local moveY = GetDisabledControlNormal(0, 31)
            local moveZ = 0.0

            if IsControlPressed(0, 22) then moveZ =  0.5 end  -- SPACE = su
            if IsControlPressed(0, 44) then moveZ = -0.5 end  -- Q = giù

            local newX = coords.x + (fwd.x * moveY * speed) + (moveX * speed * GetEntityRightVector(ped).x)
            local newY = coords.y + (fwd.y * moveY * speed) + (moveX * speed * GetEntityRightVector(ped).y)
            local newZ = coords.z + moveZ * speed

            SetEntityVelocity(ped, 0.0, 0.0, 0.0)
            SetEntityCoords(ped, newX, newY, newZ, false, false, false, false)
            SetEntityCollision(ped, false, false)

            -- Invisibilità opzionale durante noclip
            SetLocalPlayerVisibleLocally(false)
        else
            SetEntityCollision(PlayerPedId(), true, true)
            SetLocalPlayerVisibleLocally(true)
        end
    end
end)

-- ============================================================
-- TASTO APERTURA MENU
-- ============================================================
RegisterCommand('adminmenu', function()
    TriggerEvent('adminSystem:client:openMenu')
end, false)

RegisterKeyMapping('adminmenu', 'Apri menu admin', 'keyboard', Config.Menu.openKey)

-- ============================================================
-- NOTIFY HELPER
-- ============================================================
function lib_notify(msg, notifType)
    -- Compatibile con ox_lib, ESX, QBCore e standalone
    if GetResourceState('ox_lib') == 'started' then
        lib.notify({ title = 'Admin System', description = msg, type = notifType or 'inform' })
    elseif GetResourceState('es_extended') == 'started' then
        TriggerEvent('esx:showNotification', msg)
    elseif GetResourceState('qb-core') == 'started' then
        TriggerEvent('QBCore:Notify', msg, notifType or 'primary')
    else
        -- Fallback: notifica NUI custom
        TriggerEvent('adminSystem:client:showNUINotify', msg, notifType)
    end
end

-- ============================================================
-- RECEIVE NOTIFY DAL SERVER
-- ============================================================
RegisterNetEvent('adminSystem:client:notify', function(msg, notifType)
    lib_notify(msg, notifType)
end)
