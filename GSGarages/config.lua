Config = {}

Config.Targets = {
    police_impound_raid_cars = {
        name = 'police_impound_raid_cars',
        coords = vector3(1853.367065, 3687.956055, 34.250610),
        size = vector3(2.0, 2.0, 2.0),
        debug = false,
        options = {
            { label = 'Open Raid impound menu', groups = { police = 2 }, onSelect = function() openNearbyPlayersMenu() end },
        }
    },

    police_car_raid_zone = { -- This is the Raid garage open target if you change location dont input in menu coords change here 
        name = 'police_car_raid_zone',
        coords = vector3(30.05, -900.72, 29.95),
        size = vector3(2.0, 2.0, 2.0),
        debug = false,
        options = {
            { label = 'Open Raid List', groups = { police = 2 }, onSelect = function() TriggerEvent('GSG:showRaidList') end },
        }
    },
}

Config.insurencePrice = 5000
Config.insurance = {
    npcs = {
        {
            model = `a_m_y_business_01`,
            coords = vector3(-268.41, -957.64, 31.22),
            heading = 205.0,
            blip = {
                sprite = 237,
                color = 69,
                scale = 0.8,
                name = 'Insurance Claims'
            }
        },
    }
}


Config.MarkerDrawDistance = 20.0

Config.SaveDamageOnStore = true 

Config.Garages = {
    LegionGarage = {
        garageName = 'Legion Garage',
        garageType = 'car',
        menuCoords = {x = 216.8, y = -810.8, z = 30.7},
        spawnCoords = {
            {x = 223.03, y = -801.57, z = 30.66, h = 68.92},
            {x = 209.05, y = -796.54, z = 30.95, h = 67.96},
            {x = 220.67, y = -786.34, z = 30.78, h = 249.37},
        },
        returnCoords = {x = 234.68, y = -787.05, z = 30.61},
    },

    RaidGarage = {
        garageName = 'Police Raid Garage',
        garageType = 'car',
        menuCoords = {},
        spawnCoords = {
            {x = 51.08, y = -891.95, z = 30.15, h = 155.90},
            {x = 47.68, y = -891.05, z = 30.15, h = 158.740158},
            {x = 44.54, y = -889.87, z = 30.15, h = 153.070862},
            {x = 41.36, y = -888.26, z = 30.15, h = 155.905502},
            {x = 38.04, y = -887.40, z = 30.15, h = 158.740158},
        },
        returnCoords = {},
    },

    ElRanchoGarage = {
        garageName = 'El Rancho Garage',
        garageType = 'car',
        menuCoords = {x = 1204.65, y = -1084.42, z = 40.48},
        spawnCoords = {
            {x = 1199.92, y = -1059.37, z = 41.14, h = 301.52},
            {x = 1204.44, y = -1062.48, z = 40.64, h = 299.62},
            {x = 1208.21, y = -1065.76, z = 40.21, h = 298.76},
            {x = 1211.22, y = -1069.71, z = 39.90, h = 303.09},
            {x = 1215.04, y = -1073.32, z = 39.51, h = 305.75},
        },
        returnCoords = {x = 1195.72, y = -1056.44, z = 41.55},
    },

    VespucciGarage = {
        garageName = 'Vespucci Blvd Garage',
        garageType = 'car',
        menuCoords = {x = -332.66, y = -781.49, z = 33.96},
        spawnCoords = {
            {x = -334.57, y = -751.31, z = 33.97, h = 179.12},
            {x = -343.02, y = -756.97, z = 33.97, h = 270.03},
            {x = -329.05, y = -750.43, z = 33.97, h = 181.60},
            {x = -323.11, y = -751.78, z = 33.97, h = 156.22},
            {x = -317.46, y = -752.89, z = 33.97, h = 160.17},
        },
        returnCoords = {x = -348.57, y = -761.12, z = 33.97},
    },

    SpanishAveGarage = {
        garageName = 'Spanish Avenue Garage',
        garageType = 'car',
        menuCoords = {x = 76.67, y = 20.34, z = 69.13},
        spawnCoords = {
            {x = 64.70, y = 17.97, z = 69.29, h = 158.63},
            {x = 61.25, y = 19.31, z = 69.37, h = 158.63},
            {x = 58.22, y = 20.33, z = 69.46, h = 161.80},
            {x = 55.25, y = 21.32, z = 69.69, h = 164.56},
        },
        returnCoords = {x = 57.09, y = 28.96, z = 70.06},
    },

    SandyGarage = {
        garageName = 'Sandy Shores Garage',
        garageType = 'car',
        menuCoords = {x = 1527.31, y = 3771.82, z = 34.51},
        spawnCoords = {
            {x = 1512.15, y = 3759.74, z = 34.00, h = 17.32},
            {x = 1498.60, y = 3758.94, z = 33.92, h = 33.92},
            {x = 1495.40, y = 3757.72, z = 33.90, h = 31.92},
        },
        returnCoords = {x = 1504.87, y = 3763.27, z = 34.0},
    },

    PaletoGarage = {
        garageName = 'Paleto Bay Garage',
        garageType = 'car',
        menuCoords = {x = 109.08, y = 6606.11, z = 31.85},
        spawnCoords = {
            {x = 145.55, y = 6600.84, z = 31.85, h = 1.79},
            {x = 140.58, y = 6605.59, z = 31.84, h = 359.21},
            {x = 146.03, y = 6613.43, z = 31.82, h = 180.47},
            {x = 150.98, y = 6609.00, z = 31.87, h = 181.67},
            {x = 150.97, y = 6596.92, z = 31.84, h = 0.24},
        },
        returnCoords = {x = 123.98, y = 6611.3, z = 31.85},
    },

    --[[ TEMPLATE ----
    GarageName = {
        garageName = '',
        garageType = 'car', 
        menuCoords = {x = , y = , z = },
        spawnCoords = {
            {x = , y = , z = , h = },
        },
        returnCoords = {x = , y = , z = },
    },
    ]]
}