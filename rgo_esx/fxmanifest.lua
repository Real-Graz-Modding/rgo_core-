fx_version 'cerulean'
game 'gta5'

name 'rgo_esx'
author 'Real-Graz-Modding'
description 'ESX compatibility layer for rgo_core'
version '1.0.0'

dependencies {
  '/server:12913',
  'ox_core',
  'oxmysql',
}

server_scripts {
  'server/db.lua',
  'server/main.lua',
}

client_scripts {
  'client/main.lua',
}
