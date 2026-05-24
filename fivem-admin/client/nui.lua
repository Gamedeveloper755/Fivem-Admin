--[[ ============================================================
     NUI HELPER - Notifiche fallback (senza framework)
============================================================ ]]

AddEventHandler('adminSystem:client:showNUINotify', function(msg, notifType)
    SendNUIMessage({
        action  = 'notify',
        message = msg,
        type    = notifType or 'info',
    })
end)

-- Registra getMyRank server event  
RegisterNetEvent('adminSystem:server:getMyRank', function() end)  -- placeholder

-- Il server risponde a getMyRank
