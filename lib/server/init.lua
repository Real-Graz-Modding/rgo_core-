--[[
    rgo_core – lib/server/init.lua
    ================================
    Lädt server-seitige Lib-Module.
    ox_core-abhängige Module werden nur geladen wenn ox_core verfügbar ist.
--]]

if GetResourceState('ox_core') == 'started' then
    require 'lib.server.player'
    require 'lib.server.vehicle'
    require 'lib.server.account'
else
    -- Standalone-Modus: minimale Stubs damit Ox.GetPlayer() etc. nicht crashen
    Ox = Ox or {}

    function Ox.GetPlayer(playerId)
        return nil
    end

    function Ox.GetPlayers(filter)
        return {}
    end

    function Ox.GetPlayerFromUserId(userId)
        return nil
    end

    function Ox.GetPlayerFromCharId(charId)
        return nil
    end

    function Ox.GetPlayerFromFilter(filter)
        return nil
    end
end
