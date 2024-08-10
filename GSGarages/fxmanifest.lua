fx_version 'cerulean'

game 'gta5'

lua54 'yes'

author 'Genesis Scripts'
description 'ESX Garage system with Police Raids'
version '1.0.0'

client_scripts{
    'client/client.lua',
    'client/police.lua',
    'client/insureance.lua',
    'config.lua',
}

server_scripts{
    '@oxmysql/lib/MySQL.lua',
    '@mysql-async/lib/MySQL.lua',
    'server/server.lua',
    'server/server_raid.lua',
    'config.lua',
}

shared_scripts {
    '@ox_lib/init.lua',
  }