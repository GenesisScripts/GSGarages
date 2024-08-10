local pedIsNearMenuBlip = false
local pedIsInVehicleAndNearReturn = false
local inRange = false

PlayerData = {}
ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        Citizen.Wait(0)
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(PlayerData)
    PlayerData = xPlayer
end)


Citizen.CreateThread(function()
    GarageBlips()
    while true do
        Citizen.Wait(500)
        playerPed = PlayerPedId()
        playerCoords = GetEntityCoords(playerPed)
        isPedInVehicle = IsPedInAnyVehicle(playerPed, false)

        GaragePlayerDistanceCheck()
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        if pedIsNearMenuBlip and not isPedInVehicle and not inMenu then
            DrawMarker(1, currentMarker.x, currentMarker.y, currentMarker.z-1, 0, 0, 0, 0, 0, 0, 1.5, 1.5, 0.5, 19, 175, 214, 155, false, false, 0, 0)
        elseif pedIsInVehicleAndNearReturn then
            DrawMarker(1, currentMarker.x, currentMarker.y, currentMarker.z-1, 0, 0, 0, 0, 0, 0, 2.5, 2.5, 0.5, 230, 34, 28, 155, false, false, 0, 0)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if inRange and pedIsNearMenuBlip then
            if IsControlJustReleased(0, 51) then
                TriggerEvent('GSG:OpenGarage')
            end
        end
        if inRange and pedIsInVehicleAndNearReturn then
            if IsControlJustReleased(0, 51) then
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                StoreVehicle(vehicle)
            end
        end
    end
end)

RegisterNetEvent('GSG:OpenGarage')
AddEventHandler('GSG:OpenGarage', function(garageName)
    local searchQuery = ""

    local function updateMenu()
        ESX.TriggerServerCallback('GSG:BringPlayerCars', function(ownedVehicles)
            local menuOptions = {}
            local searchQueryLower = searchQuery:lower()

            table.insert(menuOptions, {
                icon = 'search',
                iconColor = 'blue',
                title = 'Search',
                description = 'Search through your vehicles',
                onSelect = function()
                    local input = lib.inputDialog('Search for your vehicle', {
                        {type = 'input', label = 'Search', placeholder = 'Enter vehicle name or plate'}
                    })

                    searchQuery = input and input[1] or ""
                    updateMenu()
                end
            })

            for _, v in ipairs(ownedVehicles) do
                local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))
                local vehiclePlate = v.vehicle.plate
                local vehicleNameLower = vehicleName:lower()
                local vehiclePlateLower = vehiclePlate:lower()

                if vehicleNameLower:find(searchQueryLower, 1, true) or vehiclePlateLower:find(searchQueryLower, 1, true) then
                    table.insert(menuOptions, {
                        icon = v.stored == 1 and 'car' or 'xmark',
                        iconColor = v.stored == 1 and 'green' or 'red',
                        title = vehicleName .. (v.stored == 1 and '' or ''),
                        description = 'Plate: ' .. vehiclePlate,
                        onSelect = function()
                            if v.stored == 1 then
                                ShowVehicleDetails(v.vehicle, garageName)
                            else
                                ESX.ShowNotification('Vehicle is not in the garage.')
                            end
                        end
                    })
                end
            end

            lib.registerContext({
                id = 'garage_menu',
                title = garageName or 'Garage',
                canClose = true,
                options = menuOptions
            })

            lib.showContext('garage_menu')
        end)
    end

    updateMenu()
end)

function ShowVehicleDetails(vehicle, garageName)
    local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(vehicle.model))
    local vehiclePlate = vehicle.plate

    -- Debugging output
    print('Vehicle Model:', vehicle.model)

    -- Ensure model is not nil
    if not vehicle.model or vehicle.model == '' then
        ESX.ShowNotification('Error: Vehicle model is missing.')
        return
    end

    -- Example: Using default values for health if they are missing
    local engineHealth = vehicle.engineHealth or 1000
    local bodyHealth = vehicle.bodyHealth or 1000
    local fuelLevel = vehicle.fuelLevel or 100

    -- Calculate percentages
    local function getPercentage(value)
        return value / 10
    end

    local function getProgressColor(progress)
        if progress > 75 then return 'green' end
        if progress > 50 then return 'yellow' end
        if progress > 25 then return 'orange' end
        return 'red'
    end

    local engineColor = getProgressColor(getPercentage(engineHealth))
    local bodyColor = getProgressColor(getPercentage(bodyHealth))
    local fuelColor = getProgressColor(getPercentage(fuelLevel))

    -- Register and show vehicle details menu
    lib.registerContext({
        id = 'vehicle_details_menu',
        title = garageName or 'Vehicle Details',
        canClose = true,
        options = {
            {
                icon = "info",
                title = 'Information',
                description = 'Name: ' .. vehicleName .. '\nPlate: ' .. vehiclePlate,
                readOnly = true,
            },
            {
                title = "Body",
                icon = 'car-side',
                readOnly = true,
                progress = getPercentage(bodyHealth),
                colorScheme = bodyColor,
            },
            {
                title = "Engine",
                icon = 'oil-can',
                readOnly = true,
                progress = getPercentage(engineHealth),
                colorScheme = engineColor,
            },
            {
                title = "Fuel",
                icon = 'gas-pump',
                readOnly = true,
                progress = getPercentage(fuelLevel),
                colorScheme = fuelColor,
            },
            {
                title = 'Take The Car For a Spin',
                onSelect = function()
                    VehicleCheckAndSpawn(vehicle)
                end
            }
        }
    })

    lib.showContext('vehicle_details_menu')
end

function DoesVehicleExist(vehicleToCheck)
    local worldVehicles = ESX.Game.GetVehicles()
    local plateToCheck = ESX.Math.Trim(vehicleToCheck.plate)

    for _, vehicle in ipairs(worldVehicles) do
        if DoesEntityExist(vehicle) then
            local vehiclePlate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle))
            if vehiclePlate == plateToCheck then
                return true
            end
        end
    end

    return false
end

function ValueExistsInTable(table, val)
    for _, value in ipairs(table) do
        if value == val then
            return true
        end
    end
    return false
end

function StoreVehicle(vehicle)
    local vehiclePlate = GetVehicleNumberPlateText(vehicle)
    local vehicleSettings = ESX.Game.GetVehicleProperties(vehicle)

    ESX.TriggerServerCallback('GSG:VerifyOwner', function(ownsVehicle)
        if ownsVehicle then
            ESX.Game.DeleteVehicle(vehicle)
            TriggerServerEvent('GSG:StatusOfVehicle', vehiclePlate, true)
            if Config.SaveDamageOnStore then
                TriggerServerEvent('GSG:EnsureCarDamage', vehicleSettings)
            end
        else
            ESX.Game.DeleteVehicle(vehicle)
            ESX.ShowNotification('You do not own this vehicle.')
        end
    end, vehiclePlate)
end


-- Checkin if the vehicle spawn is occupied and spawning the vehicle with it's mods
function VehicleCheckAndSpawn(vehicle)
    local spawnPos = nil

    -- Iterate over spawn positions and check for a clear spot
    for _, pos in ipairs(currentSpawn) do
        local position = vector3(pos.x, pos.y, pos.z)
        if ESX.Game.IsSpawnPointClear(position, 3.0) then
            spawnPos = pos
            break
        end
    end

    if spawnPos then
        -- Load model and spawn vehicle
        LoadModel(vehicle, function()
            ESX.Game.SpawnVehicle(vehicle.model, vector3(spawnPos.x, spawnPos.y, spawnPos.z), spawnPos.h, function(spawnedVehicle)
                if spawnedVehicle then
                    -- Set vehicle properties
                    ESX.Game.SetVehicleProperties(spawnedVehicle, vehicle)

                    -- Trigger server event
                    TriggerServerEvent('GSG:StatusOfVehicle', vehicle.plate, false)

                    -- Set damage properties if required
                    if Config.SaveDamageOnStore then
                        ESX.Game.SetVehicleProperties(spawnedVehicle, {
                            bodyHealth = vehicle.bodyHealth,
                            engineHealth = vehicle.engineHealth
                        })
                    end
                else
                    ESX.ShowNotification('Failed to spawn vehicle.')
                end
            end)
        end)
    else
        ESX.ShowNotification('No available parking spots.')
    end
end

function LoadModel(vehicle, onModelLoaded)
    if not HasModelLoaded(vehicle.model) then
        RequestModel(vehicle.model)
        BeginTextCommandBusyspinnerOn('STRING')
        AddTextComponentSubstringPlayerName('Loading Vehicle Model')
        EndTextCommandBusyspinnerOn(4)
    end

    Citizen.CreateThread(function()
        while not HasModelLoaded(vehicle.model) do
            Citizen.Wait(0)
            RequestModel(vehicle.model)
        end

        BusyspinnerOff()

        if onModelLoaded then
            onModelLoaded()
        end
    end)
end

function GaragePlayerDistanceCheck()
    local closestDistanceToMenu = Config.MarkerDrawDistance
    local closestDistanceToReturn = Config.MarkerDrawDistance
    local newPedIsNearMenuBlip = false
    local newPedIsInVehicleAndNearReturn = false
    local playerPos = vector3(playerCoords.x, playerCoords.y, playerCoords.z) -- Convert playerCoords to vector3 once

    if not playerCoords or not playerCoords.x or not playerCoords.y or not playerCoords.z then
        return
    end

    for _, v in pairs(Config.Garages) do
        if v.menuCoords and next(v.menuCoords) and v.returnCoords and next(v.returnCoords) then
            local menuCoords = vector3(v.menuCoords.x, v.menuCoords.y, v.menuCoords.z)
            local returnCoords = vector3(v.returnCoords.x, v.returnCoords.y, v.returnCoords.z)

            local distanceToMenu = GetDistanceBetweenCoords(playerPos, menuCoords, true)
            local distanceToReturn = GetDistanceBetweenCoords(playerPos, returnCoords, true)

            -- Check proximity to menu location
            if not isPedInVehicle and distanceToMenu < closestDistanceToMenu then
                closestDistanceToMenu = distanceToMenu
                newPedIsNearMenuBlip = true
                currentMarker = menuCoords
                currentSpawn = v.spawnCoords
                currentGarageName = v.garageName
                currentType = v.garageType

                if distanceToMenu < 2.0 then
                    inRange = true
                    if not uiShown then
                        lib.showTextUI('[E] - Open Vehicle Garage', { position = "right-center", icon = 'car' })
                        uiShown = true
                    end
                else
                    inRange = false
                    if uiShown then
                        lib.hideTextUI()
                        uiShown = false
                    end
                end
            -- Check proximity to return location when in vehicle
            elseif isPedInVehicle and not inMenu and distanceToReturn < closestDistanceToReturn then
                closestDistanceToReturn = distanceToReturn
                newPedIsInVehicleAndNearReturn = true
                currentMarker = returnCoords

                if distanceToReturn < 2.0 then
                    inRange = true
                    if not uiShown then
                        lib.showTextUI('[E] - Store Vehicle', { position = "right-center", icon = 'car' })
                        uiShown = true
                    end
                else
                    inRange = false
                    if uiShown then
                        lib.hideTextUI()
                        uiShown = false
                    end
                end
            end
        end
    end

    if not newPedIsNearMenuBlip and not newPedIsInVehicleAndNearReturn then
        if uiShown then
            lib.hideTextUI()
            uiShown = false
        end
    end

    pedIsNearMenuBlip = newPedIsNearMenuBlip
    pedIsInVehicleAndNearReturn = newPedIsInVehicleAndNearReturn
end


function MenuRangeCheck()
    if not inRange then
        lib.hideContext()
    end
end

function GarageBlips()
    for k, v in pairs(Config.Garages) do
        garageBlip = AddBlipForCoord(v.menuCoords.x, v.menuCoords.y, v.menuCoords.z)

        SetBlipSprite(garageBlip, 357)
        SetBlipScale(garageBlip, 0.4)
        SetBlipColour(garageBlip, 3)
        SetBlipAsShortRange(garageBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString('Garage')
        EndTextCommandSetBlipName(garageBlip)
    end
end
