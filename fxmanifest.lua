name 'rgo_core'
author 'Real-Graz-Modding'
version '1.0.0'
description 'Ein modernes FiveM-Framework von Real-Graz-Modding, basierend auf ox_core.'
fx_version 'cerulean'
game 'gta5'
node_version '22'

files {
	'lib/init.lua',
	'lib/client/**.lua',
	'locales/*.json',
	'common/data/*.json',
}

dependencies {
	'/server:12913',
	'/onesync',
}

client_scripts {
	'dist/client.js',
}

server_scripts {
	'dist/server.js',
}
