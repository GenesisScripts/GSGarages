ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

StoreVehiclesOnResourceStart = true 

if StoreVehiclesOnResourceStart then
    MySQL.ready(function()
        MySQL.Async.execute(' UPDATE owned_vehicles SET stored = @stored WHERE stored = false ', {
            ['@stored'] = true
        }, function(affectedRows)
        end)
    end)
end

ESX.RegisterServerCallback('GSG:BringPlayerCars', function(source, callback)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local ownedVehicles = {}

    MySQL.Async.fetchAll('SELECT plate, stored, vehicle FROM owned_vehicles WHERE owner = @owner', {
        ['@owner'] = xPlayer.getIdentifier()
    }, function(data)
        for _, v in ipairs(data) do
            local vehicle = json.decode(v.vehicle)
            table.insert(ownedVehicles, {
                vehicle = vehicle,
                plate = v.plate,
                stored = v.stored
                -- Removed primaryColor and secondaryColor
            })
        end
        callback(ownedVehicles)
    end)
end)

ESX.RegisterServerCallback('GSG:VerifyOwner', function(source, callback, vehiclePlate)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        callback(false)
        return
    end

    local owner = xPlayer.getIdentifier()
    
    MySQL.Async.fetchAll('SELECT 1 FROM owned_vehicles WHERE `owner` = @owner AND `plate` = @plate', {
        ['@owner'] = owner,
        ['@plate'] = vehiclePlate,
    }, function(results)
        -- Check if any rows are returned
        callback(#results > 0)
    end)
end)

RegisterNetEvent('GSG:EnsureCarDamage')
AddEventHandler('GSG:EnsureCarDamage', function(vehicle)
    if not vehicle or not vehicle.plate or vehicle.plate == "" then
        return
    end

    local vehicleData = json.encode(vehicle)

    MySQL.Async.execute('UPDATE owned_vehicles SET `vehicle` = @vehicle WHERE `plate` = @plate', {
        ['@vehicle'] = vehicleData,
        ['@plate'] = vehicle.plate,
    }, function(affectedRows)
    end)
end)

RegisterNetEvent('GSG:StatusOfVehicle')
AddEventHandler('GSG:StatusOfVehicle', function(vehiclePlate, stored)
    if not vehiclePlate or vehiclePlate == "" then
        return
    end
    
    local storedStatus = stored and 1 or 0

    MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = @stored WHERE `plate` = @plate', {
        ['@stored'] = storedStatus,
        ['@plate'] = vehiclePlate,
    }, function(rowsChanged)
    end)
end)

ESX.RegisterServerCallback('GSG:getVehiclePlates', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        print('Error: Player not found.')
        cb({})
        return
    end

    MySQL.Async.fetchAll('SELECT plate, vehicle FROM owned_vehicles WHERE owner = @owner AND stored = 0', {
        ['@owner'] = xPlayer.identifier
    }, function(result)
        local vehicleData = {}

        for _, vehicle in ipairs(result) do
            local vehicleInfo = json.decode(vehicle.vehicle)
            
            if vehicleInfo and vehicleInfo.model then
                table.insert(vehicleData, {
                    plate = vehicle.plate,
                    vehicle = { model = vehicleInfo.model }
                })
            else
                print(('Error: Malformed vehicle data for plate %s'):format(vehicle.plate))
            end
        end

        cb(vehicleData)
    end, function(err)
        print('Error fetching vehicle plates from database:', err)
        cb({})
    end)
end)

RegisterServerEvent('GSG:processInsuranceClaim')
AddEventHandler('GSG:processInsuranceClaim', function(data)
    local xPlayer = ESX.GetPlayerFromId(source)

    -- Validate input data
    if not data.plates or not data.claim or not data.name or not xPlayer then
        TriggerClientEvent('esx:showNotification', source, 'Error: Missing required data for insurance claim or player not found.')
        print('Error: Missing required data for insurance claim or player not found.')
        return
    end

    local vehicles = data.plates
    local numVehicles = #vehicles
    local totalCost = Config.insurencePrice * numVehicles

    -- Check if the player has enough money
    if xPlayer.getMoney() < totalCost then
        TriggerClientEvent('esx:showNotification', source, 'You do not have enough money to process this claim.')
        print('Error: Player does not have enough money to process this claim.')
        return
    end

    local placeholders = {}
    for i = 1, numVehicles do
        table.insert(placeholders, "?")
    end
    local placeholdersStr = table.concat(placeholders, ",")

    local updateQuery = 'UPDATE owned_vehicles SET stored = 1 WHERE plate IN (' .. placeholdersStr .. ') AND owner = ? AND stored = 0'

    local updateParams = { table.unpack(vehicles) }
    table.insert(updateParams, xPlayer.identifier)


    local queries = {
        { query = updateQuery, values = updateParams }
    }
    
    exports.oxmysql:transaction(queries, function(success)
        if success then 
         xPlayer.removeMoney(totalCost)
        end
    end)
end)
