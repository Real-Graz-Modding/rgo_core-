name 'rgo_core'
author 'Real-Graz-Modding'
version '1.0.0'
description 'Ein modernes FiveM-Framework von Real-Graz-Modding, basierend auf ox_core.'
fx_version 'cerulean'
game 'gta5'
node_version '22'

files {
    'lib/init.lua',
    'lib/bridge.lua',
    'lib/client/**.lua',
    'locales/*.json',
    'common/data/*.json',
}

-- ox_lib und ox_core sind OPTIONAL.
-- Wenn nicht vorhanden, läuft rgo_core im standalone-Modus.
dependencies {
    '/server:12913',
    '/onesync',
}

-- Server-seitige Lua-Libs (player, vehicle, account wrappers)
server_scripts {
    'lib/server/init.lua',
    'dist/server.js',
}

-- Client-seitige Lua-Libs
client_scripts {
    'lib/client/init.lua',
    'dist/client.js',
}

-- Shared scripts die in BEIDEN Kontexten verfügbar sein sollen
shared_scripts {
    'lib/init.lua',
}
