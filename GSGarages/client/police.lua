local impoundedVehicles = {}

Citizen.CreateThread(function()
    for _, target in pairs(Config.Targets) do
        exports.ox_target:addBoxZone({
            name = target.name,
            coords = target.coords,
            size = target.size,
            debug = target.debug,
            options = target.options,
        })
    end
end)

lib.registerContext({
    id = 'police_station_menu',
    title = 'Police Station Menu',
    options = {
        {
            title = 'Raid Menu',
            description = 'Menu to open players Garage',
            icon = 'user',
            onSelect = function()
                openNearbyPlayersMenu()
            end
        }
    }
})

function openNearbyPlayersMenu()
    local players = ESX.Game.GetPlayersInArea(GetEntityCoords(PlayerPedId()), 10.0)

    if #players == 0 then
        ESX.ShowNotification('No players nearby')
        return
    end

    local options = {}
    for _, playerId in ipairs(players) do
        local playerServerId = GetPlayerServerId(playerId)
        ESX.TriggerServerCallback('GSG:GetPlayerInfoForRaid', function(name)
            table.insert(options, {
                title = name .. ' (' .. playerServerId .. ')',
                onSelect = function()
                    openPlayerVehiclesMenu(playerServerId)
                end
            })

            if #options == #players then
                lib.registerContext({
                    id = 'nearby_players_menu',
                    title = 'Choose people to Raid',
                    options = options
                })

                lib.showContext('nearby_players_menu')
            end
        end, playerServerId)
    end
end

function openPlayerVehiclesMenu(playerId)
    local searchQuery = "" 

    local function updateMenu()
        ESX.TriggerServerCallback('GSG:GetPlayerGarageForRaid', function(vehicles)
            local options = {}
            local searchQueryLower = searchQuery:lower() 

            table.insert(options, {
                icon = 'search',
                iconColor = 'blue',
                title = 'Search',
                description = 'Search through vehicles',
                onSelect = function()
                    local input = lib.inputDialog('Search for vehicle', {
                        {type = 'input', label = 'Search', placeholder = 'Enter vehicle name or plate'}
                    })

                    searchQuery = input and input[1] or ""
                    updateMenu()
                end
            })

            table.insert(options, {
                icon = 'ban',
                iconColor = 'red',
                title = 'Impound All Vehicles',
                description = 'Impound all vehicles owned by this player',
                onSelect = function()
                    impoundAllVehicles(playerId)
                end
            })

            for _, v in ipairs(vehicles) do
                local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))
                local vehiclePlate = v.plate
                local vehicleNameLower = vehicleName:lower()
                local vehiclePlateLower = vehiclePlate:lower()

                if not impoundedVehicles[vehiclePlate] and (vehicleNameLower:find(searchQueryLower, 1, true) or vehiclePlateLower:find(searchQueryLower, 1, true)) then
                    table.insert(options, {
                        icon = v.stored == 1 and 'car' or 'xmark',
                        iconColor = v.stored == 1 and 'green' or 'red',
                        title = vehicleName,
                        description = 'Plate: ' .. vehiclePlate,
                        onSelect = function()
                            impoundVehicle(vehiclePlate)
                        end
                    })
                end
            end

            lib.registerContext({
                id = 'player_vehicles_menu',
                title = 'Player Vehicles',
                options = options
            })

            lib.showContext('player_vehicles_menu')
        end, playerId)
    end

    updateMenu()
end

function impoundVehicle(plate)
    if plate then
        TriggerServerEvent('GSG:impoundVehicle', plate)
        ESX.ShowNotification('Vehicle with plate ' .. plate .. ' has been impounded.')
    else
        ESX.ShowNotification('Failed to impound vehicle.')
    end
end

function impoundAllVehicles(targetPlayerId)
    TriggerServerEvent('GSG:impoundAllVehicles', targetPlayerId)
    ESX.ShowNotification('All vehicles for', name ..  '(' .. playerServerId .. ')', 'have been impounded.')
end

RegisterNetEvent('GSG:showRaidList')
AddEventHandler('GSG:showRaidList', function()
    ESX.TriggerServerCallback('GSG:getPlayersWithStoredRaidVehicles', function(players)
        local options = {}
        for _, player in ipairs(players) do
            table.insert(options, {
                title = player.name,
                onSelect = function() TriggerServerEvent('GSG:RequestRaidVehiclesByOwner', player.identifier) end
            })
        end

        lib.registerContext({
            id = 'player_list_menu',
            title = 'Raid Menu',
            canClose = true,
            options = options
        })
        lib.showContext('player_list_menu')
    end)
end)

function RequestVehicleModelByPlate(plate)
    TriggerServerEvent('GSG:getVehicleModelByPlate', plate)
end

RegisterNetEvent('GSG:receiveVehicleModel')
AddEventHandler('GSG:receiveVehicleModel', function(model, plate)
    if model then
        RaidVehicleCheckAndSpawn({model = model, plate = plate})
    else
        ESX.ShowNotification('Vehicle model not found.')
    end
end)

RegisterNetEvent('GSG:showVehicleList')
AddEventHandler('GSG:showVehicleList', function(plates)
    local options = {}
    for _, plate in ipairs(plates) do
        table.insert(options, {
            title = plate,
            icon = 'car',
            onSelect = function() RequestVehicleModelByPlate(plate) end
        })
    end

    lib.registerContext({
        id = 'vehicle_list_menu',
        title = 'Vehicles to raid',
        canClose = true,
        options = options
    })
    lib.showContext('vehicle_list_menu')
end)

function RaidVehicleCheckAndSpawn(vehicle)
    local spawnPos = nil
    local currentGarage = Config.Garages.RaidGarage
    local currentSpawn = currentGarage.spawnCoords

    for i = 1, #currentSpawn do
        if ESX.Game.IsSpawnPointClear(vector3(currentSpawn[i].x, currentSpawn[i].y, currentSpawn[i].z), 3.0) then
            spawnPos = currentSpawn[i]
            break
        end
    end

    if spawnPos then
        LoadModel(vehicle, function()
            ESX.Game.SpawnVehicle(vehicle.model, vector3(spawnPos.x, spawnPos.y, spawnPos.z), spawnPos.h, function(spawnedVehicle)
                if spawnedVehicle then
                    ESX.Game.SetVehicleProperties(spawnedVehicle, {
                        plate = vehicle.plate,
                        bodyHealth = vehicle.bodyHealth or 1000,
                        engineHealth = vehicle.engineHealth or 1000,
                        primaryColor = vehicle.primaryColor or 0,
                        secondaryColor = vehicle.secondaryColor or 0
                    })

                    if Config.SaveDamageOnStore then
                        ESX.Game.SetVehicleProperties(spawnedVehicle, {
                            bodyHealth = vehicle.bodyHealth,
                            engineHealth = vehicle.engineHealth
                        })
                    end

                    -- Add the spawned vehicle to the impounded list
                    impoundedVehicles[vehicle.plate] = spawnedVehicle

                    TriggerServerEvent('GSG:updateVehicleStatus', vehicle.plate)
                else
                    print('Failed to spawn vehicle.')
                end
            end)
        end)
    else
        ESX.ShowNotification('No available parking spots.')
        print('No available parking spots.')
    end
end

exports.ox_target:addGlobalVehicle({
    {
        label = 'Delete Raid Vehicle',
        icon = 'trash',
        canInteract = function(entity, distance, data)
            local plate = ESX.Game.GetVehicleProperties(entity).plate
            return impoundedVehicles[plate] ~= nil
        end,
        distance = 2.5,
        onSelect = function(data)
            local vehicle = data.entity
            local plate = ESX.Game.GetVehicleProperties(vehicle).plate
            ESX.Game.DeleteVehicle(vehicle)
            TriggerServerEvent('GSG:resetVehicleStorage', plate)
            impoundedVehicles[plate] = nil
            ESX.ShowNotification('Raid vehicle with plate ' .. plate .. ' has been deleted and its storage status reset.')
        end
    }
})
