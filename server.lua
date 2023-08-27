RegisterNetEvent("simple_v:binoculars_enabled")
RegisterNetEvent("simple_v:binoculars_disabled")

AddEventHandler("simple_v:binoculars_enabled", function()
    local playerSource = source
    local playerName = GetPlayerName(playerSource)
    local playerCoords = GetEntityCoords(GetPlayerPed(playerSource))
    print(("Le joueur %s - (%s) a activé le mode jumelles. (x = %s, y = %s, z = %s)"):format(playerName, playerSource, playerCoords.x, playerCoords.y, playerCoords.z))
end)

AddEventHandler("simple_v:binoculars_disabled", function()
    local playerSource = source
    local playerName = GetPlayerName(playerSource)
    print(("Le joueur %s - (%s) a désactivé le mode jumelles."):format(playerName, playerSource))
end)
