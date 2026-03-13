fx_version 'cerulean'
game 'gta5'

name 'es_extended'
author 'Real-Graz-Modding'
description 'ESX compatibility layer for rgo_core (es_extended shim)'
version '1.9.4'

-- WICHTIG: Kein harter Dependency auf oxmysql – oxmysql wird zur Laufzeit
-- geprüft, damit rgo_esx auch ohne oxmysql startbar ist (reines Compat-Layer).
dependencies {
  '/server:12913',
}

-- imports.lua MUSS in files stehen, damit andere Resources
-- @es_extended/imports.lua via shared_scripts einbinden können.
files {
  'imports.lua',
}

server_scripts {
  'server/db.lua',
  'server/main.lua',
}

client_scripts {
  'client/main.lua',
}
