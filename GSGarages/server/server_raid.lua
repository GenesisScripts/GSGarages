ESX.RegisterServerCallback('GSG:GetPlayerInfoForRaid', function(source, cb, serverId)
    local xPlayer = ESX.GetPlayerFromId(serverId)
    if xPlayer then
        cb(xPlayer.getName())
    else
        cb('Unknown')
    end
end)

ESX.RegisterServerCallback('GSG:GetPlayerJob', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        cb({
            job = xPlayer.job
        })
    else
        cb({ job = { name = '' } })
    end
end)

ESX.RegisterServerCallback('GSG:getPlayersWithStoredRaidVehicles', function(source, cb)
    MySQL.Async.fetchAll('SELECT DISTINCT owner FROM owned_vehicles WHERE stored = 3', {}, function(results)
        local players = {}

        if #results > 0 then
            local identifiers = {}
            for _, result in ipairs(results) do
                table.insert(identifiers, result.owner)
            end

            local placeholders = {}
            for i = 1, #identifiers do
                table.insert(placeholders, '?')
            end
            local sqlQuery = string.format('SELECT identifier, firstname, lastname FROM users WHERE identifier IN (%s)', table.concat(placeholders, ', '))

            -- Fetch player details based on identifiers
            MySQL.Async.fetchAll(sqlQuery, identifiers, function(userResults)
                for _, user in ipairs(userResults) do
                    table.insert(players, {
                        name = user.firstname .. " " .. user.lastname,
                        identifier = user.identifier
                    })
                end
                cb(players)
            end)
        else
            cb(players)
        end
    end)
end)


RegisterServerEvent('GSG:RequestRaidVehiclesByOwner')
AddEventHandler('GSG:RequestRaidVehiclesByOwner', function(owner)
    local _source = source

    if not owner or owner == "" then
        TriggerClientEvent('GSG:showVehicleList', _source, {})
        return
    end

    MySQL.Async.fetchAll('SELECT plate FROM owned_vehicles WHERE owner = @owner AND stored = 3', {
        ['@owner'] = owner
    }, function(results)
        local plates = {}
        for _, result in ipairs(results) do
            table.insert(plates, result.plate)
        end

        TriggerClientEvent('GSG:showVehicleList', _source, plates)
    end)
end)

RegisterServerEvent('GSG:getVehicleModelByPlate')
AddEventHandler('GSG:getVehicleModelByPlate', function(plate)
    local _source = source

    if not plate or plate == "" then
        TriggerClientEvent('GSG:receiveVehicleModel', _source, nil, plate)
        return
    end

    MySQL.Async.fetchScalar('SELECT vehicle FROM owned_vehicles WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(vehicleData)
        if vehicleData then
            local vehicle = json.decode(vehicleData)
            local model = vehicle.model
            local primaryColor = vehicle.primaryColor
            local secondaryColor = vehicle.secondaryColor

            TriggerClientEvent('GSG:receiveVehicleModel', _source, model, plate, primaryColor, secondaryColor)
        else
            TriggerClientEvent('GSG:receiveVehicleModel', _source, nil, plate)
        end
    end)
end)

RegisterServerEvent('GSG:updateVehicleStatus')
AddEventHandler('GSG:updateVehicleStatus', function(plate)
    if not plate or plate == "" then
        return
    end

    local storedStatus = 4 -- Status value to update

    MySQL.Async.execute('UPDATE owned_vehicles SET stored = @stored WHERE plate = @plate', {
        ['@stored'] = storedStatus,
        ['@plate'] = plate
    }, function(rowsChanged)
    end)
end)

RegisterNetEvent('GSG:impoundAllVehicles')
AddEventHandler('GSG:impoundAllVehicles', function(targetPlayerId)
    local source = source -- Get the source of the event, i.e., the player who initiated it
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        print(string.format('[%s] Failed to fetch player data for player %d', os.date(), source))
        return
    end

    if xPlayer.job.name ~= 'police' then
        TriggerClientEvent('esx:showNotification', source, "This action has been logged because you are not a police officer")
        print(string.format('[%s] Player %d attempted to impound all vehicles without being a police officer.', os.date(), source))
        return
    end

    -- Fetch the target player's data
    local targetPlayer = ESX.GetPlayerFromId(targetPlayerId)
    if not targetPlayer then
        print(string.format('[%s] Target player %d not found', os.date(), targetPlayerId))
        return
    end

    -- Get all vehicles for the target player
    MySQL.Async.fetchAll('SELECT plate FROM owned_vehicles WHERE owner = @owner AND stored = @currentStatus', {
        ['@owner'] = targetPlayer.identifier,
        ['@currentStatus'] = 1
    }, function(data)
        for _, v in ipairs(data) do
            MySQL.Async.execute('UPDATE owned_vehicles SET stored = @stored WHERE plate = @plate AND stored = @currentStatus', {
                ['@stored'] = 3,
                ['@plate'] = v.plate,
                ['@currentStatus'] = 1
            }, function(rowsChanged)
                if rowsChanged == 0 then
                    print(string.format('[%s] Failed to impound vehicle with plate %s for player %d', os.date(), v.plate, targetPlayerId))
                end
            end)
        end
    end)
end)

RegisterNetEvent('GSG:impoundVehicle')
AddEventHandler('GSG:impoundVehicle', function(plate)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        print(string.format('[%s] Failed to fetch player data for player %d', os.date(), source))
        return
    end

    if xPlayer.job.name ~= 'police' then
        TriggerClientEvent('esx:showNotification', source, "This action has been logged because you are not a police officer")
        print(string.format('[%s] Player %d attempted to impound a vehicle without being a police officer.', os.date(), source))
        return
    end

    -- Impound the vehicle with the given plate
    MySQL.Async.execute('UPDATE owned_vehicles SET stored = @stored WHERE plate = @plate AND stored = @currentStatus', {
        ['@stored'] = 3,
        ['@plate'] = plate,
        ['@currentStatus'] = 1
    }, function(rowsChanged)
        if rowsChanged == 0 then
            print(string.format('[%s] Failed to impound vehicle with plate %s', os.date(), plate))
        end
    end)
end)

-- Callback to fetch all vehicles owned by the target player
ESX.RegisterServerCallback('GSG:GetPlayerGarageForRaid', function(source, callback, targetPlayerId)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        print(string.format('[%s] Failed to fetch player data for player %d', os.date(), source))
        callback({})
        return
    end

    if xPlayer.job.name ~= 'police' then
        TriggerClientEvent('esx:showNotification', source, "This action has been logged because you are not a police officer")
        print(string.format('[%s] Player %d attempted to fetch vehicles without being a police officer.', os.date(), source))
        callback({})
        return
    end

    local targetPlayer = ESX.GetPlayerFromId(targetPlayerId)
    if not targetPlayer then
        print(string.format('[%s] Target player %d not found', os.date(), targetPlayerId))
        callback({})
        return
    end

    MySQL.Async.fetchAll('SELECT plate, stored, vehicle FROM owned_vehicles WHERE owner = @owner', {
        ['@owner'] = targetPlayer.identifier
    }, function(data)
        local ownedVehicles = {}
        for _, v in ipairs(data) do
            if v.stored ~= 3 then -- Filter out already impounded vehicles
                local vehicle = json.decode(v.vehicle)
                table.insert(ownedVehicles, {
                    vehicle = vehicle,
                    plate = v.plate,
                    stored = v.stored
                })
            end
        end
        callback(ownedVehicles)
    end)
end)

RegisterServerEvent('GSG:resetVehicleStorage')
AddEventHandler('GSG:resetVehicleStorage', function(plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.job.name ~= 'police' then
        print(('police_raid:resetVehicleStorage: %s attempted to reset vehicle storage status'):format(xPlayer.identifier))
        return
    end

    MySQL.Async.execute('UPDATE owned_vehicles SET stored = 1 WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(rowsChanged)
        if rowsChanged == 0 then
            print(('police_raid:resetVehicleStorage: %s attempted to reset vehicle storage status for non-existent vehicle'):format(xPlayer.identifier))
        end
    end)
end)
