fx_version 'cerulean'
game 'gta5'

name 'es_extended'
author 'Real-Graz-Modding'
description 'ESX compatibility layer for rgo_core (es_extended shim)'
version '1.9.4'

dependencies {
  '/server:12913',
  'oxmysql',
}

server_scripts {
  'server/db.lua',
  'server/main.lua',
}

client_scripts {
  'client/main.lua',
}
