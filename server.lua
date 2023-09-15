RegisterNetEvent("binoculars_script:binoculars_enabled")
RegisterNetEvent("binoculars_script:binoculars_disabled")

local playersTokens = {}

local GenerateToken = function()
    local token = ""
    local characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    math.randomseed(os.time())

    for i = 1, 32 do
        local character = characters:sub(math.random(1, #characters), math.random(1, #characters))
        token = token .. character
    end

    return token
end

local SetPlayerToken = function(playerSource, token)
    local playerName = GetPlayerName(playerSource)
    playersTokens[playerSource] = token
    TriggerClientEvent("binoculars_script:set_client_token", playerSource, token)
end

local VerifyToken = function(playerSource, token)
    local playerToken = playersTokens[playerSource]

    if playerToken and playerToken == token then
        return true
    else
        return false
    end
end

AddEventHandler("playerJoining", function()
    local playerSource = source
    local token = GenerateToken()
    SetPlayerToken(playerSource, token)
end)

AddEventHandler("binoculars_script:binoculars_enabled", function(token)
    local playerSource = source
    
    if VerifyToken(playerSource, token) then
        local playerName = GetPlayerName(playerSource)
        local playerCoords = GetEntityCoords(GetPlayerPed(playerSource))
        print(("Le joueur %s - (%s) a activé le mode jumelles. (x = %s, y = %s, z = %s)"):format(playerName, playerSource, playerCoords.x, playerCoords.y, playerCoords.z))    
    else
        DropPlayer(playerSource, "Assurez vous de ne pas utiliser de cheat.")
    end
end)

AddEventHandler("binoculars_script:binoculars_disabled", function(token)
    local playerSource = source

    if VerifyToken(playerSource, token) then
        local playerName = GetPlayerName(playerSource)
        print(("Le joueur %s - (%s) a désactivé le mode jumelles."):format(playerName, playerSource))
    else
        DropPlayer(playerSource, "Assurez vous de ne pas utiliser de cheat.")
    end
end)