local CanUseBinoculars = function()
    local playerPed = PlayerPedId()

    local count = exports.ox_inventory:Search('count', 'binoculars')
    if count > 0 then
        if IsPedInAnyVehicle(playerPed, false) then
            ShowNotification("Vous ne pouvez pas utiliser vos jumelles dans un véhicule.")
            return false
        elseif IsEntityInWater(playerPed) then
            ShowNotification("Vous ne pouvez pas utiliser vos jumelles dans l'eau.")
            return false
        elseif IsPedRagdoll(playerPed) then
            ShowNotification("Vous ne pouvez pas utiliser vos jumelles en tombant.")
            return false
        elseif IsPedFalling(playerPed) then
            ShowNotification("Vous ne pouvez pas utiliser vos jumelles en tombant.")
            return false
        elseif IsPedRunning(playerPed) then
            ShowNotification("Vous ne pouvez pas utiliser vos jumelles en courant.")
            return false
        elseif IsPedSprinting(playerPed) then
            ShowNotification("Vous ne pouvez pas utiliser vos jumelles en courant.")
            return false
        elseif IsPedShooting(playerPed) then
            ShowNotification("Vous ne pouvez pas utiliser vos jumelles en utilisant une arme.")
            return false
        end

        return true
    else
        ShowNotification("Vous n'avez pas de jumelles dans votre inventaire.")
        return false
    end
end


-- ox_inventory/data/items.lua
['binoculars'] = {
		label = 'Jumelles',
		weight = 500
},