local createdNPCs = {}

Citizen.CreateThread(function()
    for _, npcConfig in ipairs(Config.insurance.npcs) do
        local coordsKey = string.format("%.2f_%.2f_%.2f", npcConfig.coords.x, npcConfig.coords.y, npcConfig.coords.z)

        if createdNPCs[coordsKey] then
            goto continue
        end

        -- Request and load the NPC model
        RequestModel(npcConfig.model)
        while not HasModelLoaded(npcConfig.model) do
            Wait(500)
        end

        -- Create the NPC
        local npc = CreatePed(4, npcConfig.model, npcConfig.coords, npcConfig.heading, false, true)
        SetEntityInvincible(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        SetPedFleeAttributes(npc, 0, 0)
        SetPedCombatAttributes(npc, 17, 1)
        TaskStartScenarioInPlace(npc, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)

        -- Create a blip for the NPC
        local blip = AddBlipForEntity(npc)
        SetBlipSprite(blip, npcConfig.blip.sprite)
        SetBlipColour(blip, npcConfig.blip.color)
        SetBlipScale(blip, npcConfig.blip.scale)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(npcConfig.blip.name)
        EndTextCommandSetBlipName(blip)
        SetBlipDisplay(blip, 3)

        -- Store NPC in the global table to prevent duplication
        createdNPCs[coordsKey] = npc

        -- Add the target action
        exports.ox_target:addLocalEntity({npc}, {
            {
                label = 'Talk to NPC',
                icon = 'fas fa-comments',
                onSelect = function()
                    TriggerEvent('GSG:openInsuranceMenu')
                end
            }
        })

        ::continue::
    end
end)


RegisterNetEvent('GSG:openInsuranceMenu')
AddEventHandler('GSG:openInsuranceMenu', function()
    ESX.TriggerServerCallback('GSG:getVehiclePlates', function(vehicles)
        local formattedPlates = {}

        for _, v in ipairs(vehicles) do
            if v.vehicle and v.vehicle.model then
                local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))
                table.insert(formattedPlates, {
                    label = string.format('%s: %s', vehicleName, v.plate),
                    value = v.plate
                })
            else
                print('Error: Vehicle data is missing or malformed:', json.encode(v))
            end
        end

        local input = lib.inputDialog('Insurance Claim', {
            {type = 'text', label = 'Your Name', default = GetPlayerName(PlayerId()), readOnly = true},
            {type = 'multi-select', label = 'Select Vehicle Plates', options = formattedPlates},
            {type = 'textarea', label = 'Insurance Claim', placeholder = 'Describe what happened', min = 10, required = true},
            {type = 'checkbox', label = 'I agree that the reason is truthful and consent to being billed $5000 for each Vehicle', required = true}
        })

        if not input or not input[4] then
            exports.ox_notify:notify('You must agree to the terms.')
            return
        end

        TriggerServerEvent('GSG:processInsuranceClaim', {
            name = input[1],
            plates = input[2],
            claim = input[3]
        })
    end)
end)
