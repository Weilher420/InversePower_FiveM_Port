-- Linear mapping function
local function map(value, inMin, inMax, outMin, outMax)
    return outMin + (outMax - outMin) * ((value - inMin) / (inMax - inMin))
end

-- Clamping function
local function clamp(value, minVal, maxVal)
    return math.max(minVal, math.min(value, maxVal))
end

-- Utility function to display 3D text
local function drawText3D(x, y, z, text, scale)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(scale, scale)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextWrap(0.0, 1.0)
    SetTextOutline()
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

-- Function to update vehicles
local function updateVehicles(isPlayer)
    local playerPed = PlayerPedId()
    local playerVehicle = GetVehiclePedIsUsing(playerPed)
    local vehiclesToUpdate = {}

    if playerVehicle ~= 0 and GetPedInVehicleSeat(playerVehicle, -1) == playerPed and IsThisModelACar(GetEntityModel(playerVehicle)) then
        table.insert(vehiclesToUpdate, playerVehicle)
    end

    if config.EnableForNPCs then
        for _, vehicle in ipairs(GetGamePool('CVehicle')) do
            if vehicle ~= playerVehicle and DoesEntityExist(vehicle) and IsThisModelACar(GetEntityModel(vehicle)) and GetIsVehicleEngineRunning(vehicle) then
                table.insert(vehiclesToUpdate, vehicle)
            end
        end
    end

    -- Update the collected vehicles
    for _, vehicle in ipairs(vehiclesToUpdate) do
        local speed = GetEntitySpeed(vehicle)
        local relVector = GetEntitySpeedVector(vehicle, true)
        local angle = speed > 0 and math.deg(math.acos(relVector.y / speed)) or 0

        local speedMod = clamp(map(speed, config.SpeedStart, config.SpeedEnd, config.SpeedStartTorqueMod, 0.0), 0.0, config.SpeedStartTorqueMod)
        local torqueMod = clamp(map(angle, config.AngleStart, config.AngleEnd, config.AngleStartTorqueMod, config.AngleEndTorqueMod), config.AngleEndTorqueMod, config.AngleStartTorqueMod)

        local torqueMult = (angle > config.AngleStart and angle < config.AngleEnd) and (1.0 + speedMod * torqueMod) or 1.0
        SetVehicleCheatPowerIncrease(vehicle, torqueMult)

        if config.Debug and (vehicle == playerVehicle) then
            local pos = GetEntityCoords(vehicle, true)
            for i, text in ipairs({
                ("Angle: %.2f"):format(angle),
                ("Speed: %.2f"):format(speed),
                ("SpeedMod: %.2f"):format(speedMod),
                ("TorqueMult: %.2f"):format(torqueMult)
            }) do
                drawText3D(pos.x, pos.y, pos.z - i * 0.1, text, 0.3)
            end
        end
    end
end

-- Main loop
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)  
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed) then
            updateVehicles(true) 
        else
            Citizen.Wait(500) 
        end
    end
end)