--[[
    rgo_esx – imports.lua
    =====================
    Legacy compatibility shim for resources that reference
    @es_extended/imports.lua in their fxmanifest.lua.

    Usage (in another resource's shared_scripts or server_scripts):
        shared_scripts { '@es_extended/imports.lua' }
        -- or
        server_scripts { '@es_extended/imports.lua', 'server/main.lua' }

    After this file is executed, the global `ESX` variable is available.
--]]

ESX = exports['es_extended']:getSharedObject()
