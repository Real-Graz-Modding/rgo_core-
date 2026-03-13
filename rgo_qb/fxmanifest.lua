fx_version 'cerulean'
game 'gta5'

name 'QBCore'
author 'Real-Graz-Modding'
description 'QBCore compatibility layer for rgo_core (QBCore shim)'
version '1.3.0'

dependencies {
  '/server:12913',
}

server_scripts {
  'server/db.lua',
  'server/main.lua',
}

client_scripts {
  'client/main.lua',
}
