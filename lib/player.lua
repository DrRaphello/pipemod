--- Player global creation.
-- This module adds player helper functions, it does not automatically register events unless Player.register_events() is called
-- @module Player
-- @usage
-- local Player = require('__stdlib__/stdlib/event/player').register_events()
-- -- The fist time this is required it will register player creation events

local Event = require('lib/event')

local Player = {
    _module = 'Player'
}

local Is = require('lib/is')
local Game = require('lib/game')
local table = require('lib/table')

-- Return new default player object consiting of index, name, force
local function new(player_index)
    local pdata = {
        index = player_index,
        name = game.players[player_index].name,
        force = game.players[player_index].force.name
    }
    if Player._new_player_data then
        if type(Player._new_player_data) == 'table' then
            table.merge(pdata, table.deepcopy(Player._new_player_data))
        elseif type(Player._new_player_data) == 'function' then
            local new_data = Player._new_player_data(player_index)
            if type(new_data) == 'table' then
                table.merge(pdata, new_data)
            else
                error('new_player_data did not return a table')
            end
        else
            error('new_player_data present but is not a function or table')
        end
    end
    return pdata
end

function Player.additional_data(func_or_table)
    Player._new_player_data = func_or_table
    return Player
end

--- Get `game.players[index]` & `players[index]`, or create `players[index]` if it doesn't exist.
-- @tparam number|string|LuaPlayer player the player index to get data for
-- @treturn LuaPlayer the player instance
-- @treturn table the player's global data
-- @usage
-- local Player = require('__stdlib__/stdlib/event/player')
-- local player, player_data = Player.get(event.player_index)
function Player.get(player)
    player = Game.get_player(player)
    Is.Assert(player, 'Missing player to retrieve')
    return player, players and players[player.index] or Player.init(player.index)
end

--- Merge a copy of the passed data to all players in `players`.
-- @tparam table data a table containing variables to merge
-- @usage local data = {a = 'abc', b = 'def'}
-- Player.add_data_all(data)
function Player.add_data_all(data)
    local pdata = players
    table.each(
        pdata,
        function(v)
            table.merge(v, table.deepcopy(data))
        end
    )
end

--- Remove data for a player when they are deleted.
-- @tparam table event event table containing the `player_index`
function Player.remove(event)
    local player = Game.get_player(event)
    if player then
        players[player.index] = nil
    end
end

--- Init or re-init a player or players.
-- Passing a `nil` event will iterate all existing players.
-- @tparam[opt] number|table|string|LuaPlayer event
-- @tparam[opt=false] boolean overwrite the player data
function Player.init(event, overwrite)
    -- Create the players table if it doesn't exisit
    players = players or {}

    --get a valid player object or nil
    local player = Game.get_player(event)

    if player then --If player is not nil then we are working with a valid player.
        if not players[player.index] or (players[player.index] and overwrite) then
            players[player.index] = new(player.index)
            return players[player.index]
        end
    else --Check all players
        for index in pairs(game.players) do
            if not players[index] or (players[index] and overwrite) then
                players[index] = new(index)
            end
        end
    end

    if _print_queue then
        table.each(
            _print_queue,
            function(msg)
                game.print(tostring(msg))
            end
        )
        _print_queue = nil
    end
    return Player
end

function Player.update_force(event)
    local player, pdata = Player.get(event.player_index)
    pdata.force = player.force.name
end

function Player.register_init()
    Event.register(Event.core_events.init, Player.init)
    return Player
end

function Player.register_events(do_on_init)
    Event.register(defines.events.on_player_created, Player.init)
    Event.register(defines.events.on_player_changed_force, Player.update_force)
    Event.register(defines.events.on_player_removed, Player.remove)
    if do_on_init then
        Player.register_init()
    end
    return Player
end

return Player
