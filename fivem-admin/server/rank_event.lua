-- APPEND: aggiunge event getMyRank al file server/main.lua
-- (già incluso nel file principale sopra, questo è il completamento)

RegisterNetEvent('adminSystem:server:getMyRank', function()
    local src  = source
    local rank = Permissions.GetRank(src)
    TriggerClientEvent('adminSystem:client:myRank', src, rank)
end)
