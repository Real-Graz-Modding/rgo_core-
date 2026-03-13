--[[
    rgo_core – lib/client/init.lua
    ================================
    Lädt client-seitige Lib-Module.
    ox_core-abhängige Module werden nur geladen wenn ox_core verfügbar ist.
--]]

if GetResourceState('ox_core') == 'started' then
    require 'lib.client.player'
else
    -- Standalone-Modus: minimale Stubs
    Ox = Ox or {}

    function Ox.GetPlayer()
        return nil
    end
end
