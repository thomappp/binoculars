local binocularsActive = false
local binocularsCamera = nil
local binocularsScaleform = false
local playerPedCoords = nil

local binocularsPitch = 0.0
local binocularsHeading = 0.0

local binocularsZoom = 70.0
local binocularsMinZoom = 0.0
local binocularsMaxZoom = 70.0

local lastBinocularsUsage = 0
local binocularsUsageCooldown = 5000

local isThermalVisionActive = false
local binocularsDistance = 0.0

local Config = {
    command = "jumelles",
    binocularsSpeed = 2.0,
    binocularsZoomSpeed = 2.0,
    exitMode = 194,
    toggleThermalVision = 38,
    showDistance = true,
    playerPedFollowsCamera = false
}

local ShowNotification = function(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(true, true)
end

local CanUseBinoculars = function()
    local playerPed = PlayerPedId()

    if IsPedInAnyVehicle(playerPed, false) then
        ShowNotification("Vous ne pouvez pas utiliser vos jumelles dans un véhicule.")
        return false
    elseif IsEntityInWater(playerPed) then
        ShowNotification("Vous ne pouvez pas utiliser vos jumelles dans l'eau.")
        return false
    end

    return true
end

local EnterBinocularsMode = function()
    binocularsScaleform = true
    SetCurrentPedWeapon(PlayerPedId(), GetHashKey("WEAPON_UNARMED"), true)

    binocularsZoom = 70.0
    binocularsPitch = 0.0
    binocularsHeading = GetEntityHeading(PlayerPedId())

    playerPedCoords = GetEntityCoords(PlayerPedId())
    binocularsCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

    SetCamCoord(binocularsCamera, playerPedCoords.x, playerPedCoords.y, playerPedCoords.z + 1.0)
    SetCamActive(binocularsCamera, true)
    RenderScriptCams(true, false, 0, true, true)

    TriggerServerEvent("simple_v:binoculars_enabled")
end

local ExitBinocularsMode = function()
    binocularsScaleform = false
    ClearPedTasks(PlayerPedId())
    
    if binocularsCamera ~= nil then
        SetCamActive(binocularsCamera, false)
        DestroyCam(binocularsCamera, false)
        RenderScriptCams(false, true, 500, true, true)
        binocularsCamera = nil
    end

    if isThermalVisionActive then
        isThermalVisionActive = false
        SetSeethrough(false)
    end

    TriggerServerEvent("simple_v:binoculars_disabled")
end

local Button = function(controlButton)
    N_0xe83a3e3557a56640(controlButton)
end

local RegisterButton = function(id, controls, text)
    PushScaleformMovieFunction(scaleformButton, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(id)

    for _, control in pairs(controls) do
        Button(GetControlInstructionalButton(2, control, true))
    end

    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
    PopScaleformMovieFunctionVoid()
end

local SetupScaleform = function(scaleformSelected)
    scaleformButton = RequestScaleformMovie(scaleformSelected)
    while not HasScaleformMovieLoaded(scaleformButton) do
        Citizen.Wait(0)
    end

    DrawScaleformMovieFullscreen(scaleformButton, 255, 255, 255, 0, 0)

    PushScaleformMovieFunction(scaleformButton, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()
    
    PushScaleformMovieFunction(scaleformButton, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    RegisterButton(0, { Config.exitMode }, "Ranger les jumelles")
    RegisterButton(1, { Config.toggleThermalVision }, "Vision thermique")
    RegisterButton(2, { 97, 96 }, "Utiliser le zoom")

    if Config.showDistance then
        RegisterButton(3, { nil }, ("Distance %sm"):format(binocularsDistance))
    end

    PushScaleformMovieFunction(scaleformButton, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleformButton, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(80)
    PopScaleformMovieFunctionVoid()

    return scaleformButton
end

local ScreenToWorld = function(screenPosition, maxDistance)
	local fov = GetGameplayCamFov()
	local camRight, camForward, camUp, camPos = GetCamMatrix(binocularsCamera)

	screenPosition = vector2(screenPosition.x - 0.5, screenPosition.y - 0.5) * 2.0

	local fovRadians = (fov * 3.14) / 180.0
	local to = camPos + camForward + (camRight * screenPosition.x * fovRadians * GetAspectRatio(false) * 0.534375) - (camUp * screenPosition.y * fovRadians * 0.534375)

	local direction = (to - camPos) * maxDistance
	local endPoint = camPos + direction

	local rayHandle = StartShapeTestRay(camPos.x, camPos.y, camPos.z, endPoint.x, endPoint.y, endPoint.z, -1, nil, 0)
	local _, hit, worldPosition, normalDirection, entity = GetShapeTestResult(rayHandle)

	if (hit == 1) then
		return true, worldPosition, normalDirection, entity
	else
		return false, vector3(0, 0, 0), vector3(0, 0, 0), nil
	end
end

RegisterCommand(Config.command, function()

    local currentTime = GetGameTimer()

    if currentTime - lastBinocularsUsage >= binocularsUsageCooldown then
        lastBinocularsUsage = currentTime

        if CanUseBinoculars() then

            binocularsActive = not binocularsActive

            if binocularsActive then
                TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_BINOCULARS", 0, true)
                Citizen.Wait(1000)
                EnterBinocularsMode()
            else
                ExitBinocularsMode()
            end
        end
    else
        local countTime = math.floor((lastBinocularsUsage + binocularsUsageCooldown - currentTime) / 1000)
        if countTime > 0 then
            ShowNotification(("Vous devez attendre %s seconde(s) pour utiliser cette commande."):format(countTime))
        elseif countTime == 0 then
            ShowNotification("Attendez encore un petit instant...")
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if binocularsScaleform then
            local scaleform = RequestScaleformMovie("binoculars")
            local form = SetupScaleform("instructional_buttons")

            while not HasScaleformMovieLoaded(scaleform) do
                Citizen.Wait(0)
            end

            DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
            DrawScaleformMovieFullscreen(form, 255, 255, 255, 255, 0)
        end

        if binocularsActive then

            local playerPed = PlayerPedId()
            local isInVehicle = IsPedInAnyVehicle(playerPed, false)
            local isInWater = IsEntityInWater(playerPed)

            if isInVehicle or isInWater then
                binocularsActive = false
                ExitBinocularsMode()
            end

            if Config.showDistance then
                local hitSomething, worldPosition, normalDir, hitEntity = ScreenToWorld(vector2(0.5, 0.5), 1200.0)
            
                if hitSomething then
                    binocularsDistance = #(playerPedCoords - worldPosition)
                    binocularsDistance = tonumber(string.format("%.1f", binocularsDistance))
                end
            end

            HudWeaponWheelIgnoreSelection()
            DisableControlAction(1, 37, true)
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 199, true)

            if IsControlJustReleased(0, Config.toggleThermalVision) then
                isThermalVisionActive = not isThermalVisionActive
                SetSeethrough(isThermalVisionActive)
            end

            if IsControlJustReleased(0, Config.exitMode) then
                binocularsActive = false
                ExitBinocularsMode()
            end

            local pitchChange = -GetDisabledControlNormal(0, 2) * Config.binocularsSpeed
            local yawChange = -GetDisabledControlNormal(0, 1) * Config.binocularsSpeed

            binocularsPitch = math.max(-80.0, math.min(80.0, binocularsPitch + pitchChange))
            binocularsHeading = binocularsHeading + yawChange

            local scrollEnabled = 0
            if IsControlJustReleased(0, 96) then
                scrollEnabled = 1
            elseif IsControlJustReleased(0, 97) then
                scrollEnabled = -1
            end
   
            local newZoom = binocularsZoom

            if scrollEnabled > 0 then
                newZoom = math.max(binocularsMinZoom, binocularsZoom - Config.binocularsZoomSpeed)
            elseif scrollEnabled < 0 then
                newZoom = math.min(binocularsMaxZoom, binocularsZoom + Config.binocularsZoomSpeed)
            end

            if newZoom ~= binocularsZoom then
                binocularsZoom = newZoom
                SetCamFov(binocularsCamera, binocularsZoom)
            end

            SetCamRot(binocularsCamera, binocularsPitch, 0.0, binocularsHeading, 2)

            if binocularsHeading ~= 0.0 and Config.playerPedFollowsCamera then
                SetEntityHeading(playerPed, binocularsHeading)
            end
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        ClearPedTasks(PlayerPedId())

        if isThermalVisionActive then
            SetSeethrough(false)
        end
    end
end)