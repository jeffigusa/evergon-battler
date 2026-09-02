local utils = require 'main.utils.basic_utils'
local Unit = require 'main.unit.unit'
local Player = require 'main.player.player'
local urls = require 'main.urls'
local M = {}

M.combat_started = false
M.units = {}

M.add_unit = function(unit, position)
    unit.position = position or unit.position
    unit.previous_position = position or unit.position
    table.insert(M.units, unit)
end

M.remove_unit = function(unit)
    for i, v in ipairs(M.units) do
        if v.id == unit.id then table.remove(M.units, i) break end
    end
end

M.undo_add_unit = function()
    local most_recent = M.units[#M.units]
    if most_recent and hash(most_recent.team) == hash('player') then
        M.remove_unit(most_recent)
        return most_recent
    end
end

M.get_unit = function(id)
    for i, v in ipairs(M.units) do if v.id == id then return v end end
end

M.get_nearby = function(unit, radius, conditional)
    local r = {}
    local radius_sq = radius ^ 2
    for i, v in ipairs(M.units) do
        if v.id ~= unit.id then
            local distance_sq = vmath.length_sqr(v.position - unit.position)
            if distance_sq < radius_sq and (not conditional or conditional(v)) then
                table.insert(r, v)
            end
        end
    end
    return r
end

M.get_target = function(unit)
    local acquisition_range = 9999
    local unit_data = Unit.get_data(unit.prototype)
    -- handle defensive stance
    if unit.stance and hash(unit.stance) == hash('defensive') then
        if #M.get_nearby(unit, 200, function(v) return hash(v.state) == hash('attacking') end) == 0 then
            acquisition_range = math.max(200, unit_data.range)
        else
            unit.stance = 'aggressive'
        end
    end
    local closest, closest_distance
    local set_closest = function(v, distance) if distance > acquisition_range then return end closest = v closest_distance = distance end
    for i, v in ipairs(M.units) do
        local is_valid = v.id ~= unit.id and v.team ~= unit.team
        if is_valid then
            local distance = vmath.length(v.position - unit.position)
            if not closest then set_closest(v, distance)
            elseif distance < closest_distance then
                set_closest(v, distance)
            end
        end
    end
    if not closest then return end
    if unit.stance and hash(unit.stance) == hash('defensive') then unit.stance = 'aggressive' end
    unit.target = closest.id
    M.update_facing(unit)
end

M.update_facing = function(attacker)
    local defender = M.get_unit(attacker.target)
    if not defender then return end
    local offset = defender.position - attacker.position
    if offset.x < 0 and hash(attacker.facing) == hash('right') then
        attacker.facing = 'left'
        msg.post(urls.battle_proxy, 'unit_facing', {unit=attacker})
    elseif offset.x > 0 and hash(attacker.facing) == hash('left') then
        attacker.facing = 'right'
        msg.post(urls.battle_proxy, 'unit_facing', {unit=attacker})
    end
end

M.acquire_target = function(attacker)
    assert(attacker.target, attacker.prototype..' '..attacker.id..' does not have a target to acquire')
    local defender = M.get_unit(attacker.target)
    if not defender then attacker.state = 'idle' return end
    local attacker_data = Unit.get_data(attacker.prototype)
    local offset = defender.position - attacker.position
    local distance_between = vmath.length(offset)
    if distance_between <= attacker_data.range then
        attacker.state = 'starting_attack'
    else
        attacker.state = 'advancing'
    end
end

M.attack = function(attacker)
    M.update_facing(attacker)
    attacker.state = 'attacking'
    local attacker_data = Unit.get_data(attacker.prototype)
    local attack_time = 1/attacker_data.attack_speed
    attacker.attack_cooldown = attack_time
    local defender = M.get_unit(attacker.target)
    timer.delay(attack_time/2, false, function()
        if not attacker or not defender then return end
        if attacker.hp > 0 and defender.hp > 0 then
            if attacker_data.is_ranged then
                local distance_to_target = vmath.length(defender.position - attacker.position)
                local time_to_target = distance_to_target / attacker_data.projectile_speed
                timer.delay(time_to_target, false, function() M.hit(attacker, defender) end)
            else
                M.hit(attacker, defender)
            end
        end
    end)
    msg.post(urls.battle_proxy, 'unit_attacked', {unit=attacker})
end

M.handle_attacking = function(attacker, dt)
    local defender = M.get_unit(attacker.target)
    if not defender or defender.hp <= 0 or attacker.attack_cooldown <= 0 then
        msg.post(urls.battle_proxy, 'unit_attack_cancelled', {unit=attacker})
        attacker.state = 'acquiring_target'
        attacker.attack_cooldown = 0
    else
        attacker.attack_cooldown = attacker.attack_cooldown - dt
    end
end

local avoidance_radius = 40
local stuck_detour_duration = 0.5 -- how long to attempt to get around obstacle before trying again
local advance_attempts_before_new_target = 20 -- how long to attempt to advance before getting a new target
local escape_search_radius = 200
local escape_attempts_before_switching_directions = 50
local escape_search_angle = math.pi * 0.5

M.get_avoidance = function(attacker)
    local avoidance = vmath.vector3()
    local defender = M.get_unit(attacker.target)
    local offset = defender.position - attacker.position
    for i, v in ipairs(M.units) do
        if v.id ~= defender.id and v.id ~= attacker.id
        then
            local offset_avoidance = attacker.position - v.position
            local distance = vmath.length(offset_avoidance)
            if distance == 0 then offset_avoidance = vmath.vector3(math.random(), math.random(), 0) end
            if distance < avoidance_radius then
                local avoidance_strength = 1 - distance / avoidance_radius
                local unit_data = Unit.get_data(v.prototype) if distance < unit_data.radius then avoidance_strength = avoidance_strength * 10 end
                avoidance = avoidance + vmath.normalize(offset_avoidance) * avoidance_strength
            end
        end
    end
    return avoidance
end

M.get_escape_direction = function(attacker)
    local escape_scalar = 0
    local defender = M.get_unit(attacker.target)
    local offset = defender.position - attacker.position

    for i, v in ipairs(M.units) do
        if v.id ~= defender.id and v.id ~= attacker.id and hash(v.team) == hash(attacker.team) then
            local offset_escape = v.position - attacker.position
            local offset_escape_length = vmath.length(offset_escape)
            if offset_escape_length < escape_search_radius then
                local dot = vmath.dot(offset, offset_escape)
                local cross = vmath.cross(offset, offset_escape).z
                local angle = math.atan2(cross, dot)
                local weight = 1 if hash(v.state) == hash('attacking') then weight = 2 end
                if math.abs(angle) < escape_search_angle then
                    escape_scalar = escape_scalar + math.sin(angle) * weight
                end
            end
        end
    end
    if escape_scalar > 0 then return 'right' else return 'left' end
end

M.move = function(unit, position)
    if position.x < unit.position.x then unit.facing = 'left' elseif position.x > unit.position.x then unit.facing = 'right' end
    unit.position = position

    msg.post(urls.battle_proxy, 'unit_moved', {unit=unit})
end

M.advance = function(attacker, dt)
    local attacker_data = Unit.get_data(attacker.prototype)
    local defender = M.get_unit(attacker.target)
    if not defender then attacker.state = 'idle' return end
    local offset = defender.position - attacker.position
    local distance_to_defender = vmath.length(defender.position - attacker.position)
    if distance_to_defender <= attacker_data.range then
        attacker.state = 'starting_attack'
        attacker.stuck_direction = nil
        attacker.is_stuck = false
        attacker.escape_attempts = nil
        attacker.advance_attempts = 0
        return
    end

    local direction = vmath.normalize(offset)
    local avoidance = M.get_avoidance(attacker)
    local escape = vmath.vector3()

    local normalized_direction
    if direction == -avoidance then
        normalized_direction = vmath.vector3()
    else
        normalized_direction = vmath.normalize(direction + avoidance)
    end

    local cannot_advance = vmath.dot(direction, normalized_direction) <= 0
    if cannot_advance and not attacker.is_stuck then
        attacker.is_stuck = true
        if not attacker.escape_attempts then
            attacker.escape_attempts = 0
        end
        attacker.escape_attempts = attacker.escape_attempts + 1
        if attacker.escape_attempts > escape_attempts_before_switching_directions then
            if hash(attacker.stuck_direction) == hash('right') then attacker.stuck_direction = 'left' else attacker.stuck_direction = 'right' end
        end
        -- M.get_target(attacker)
        if not attacker.stuck_direction then attacker.stuck_direction = M.get_escape_direction(attacker) end
        timer.delay(stuck_detour_duration, false, function() attacker.is_stuck = false end)
    end

    attacker.advance_attempts = attacker.advance_attempts + 1
    if attacker.advance_attempts >= advance_attempts_before_new_target then
        M.get_target(attacker)
        attacker.advance_attempts = 0
    end

    -- if stuck, add escape vector
    if attacker.is_stuck then
        escape = vmath.vector3(-direction.y, direction.x, 0)
        if hash(attacker.stuck_direction) == hash('right') then
            escape.x = -escape.x
            escape.y = -escape.y
        end
    end
    local desired_direction = direction + avoidance + escape *2
    normalized_direction = vmath.normalize(desired_direction + attacker.momentum)

    local velocity = normalized_direction * attacker_data.move_speed
    attacker.momentum = normalized_direction * 3
    local desired_position = attacker.position + velocity * dt

    -- avoid going off the map
    desired_position = vmath.clamp(desired_position, vmath.vector3(-775, -375, 0), vmath.vector3(775, 375, 0))

    -- move the unit
    M.move(attacker, desired_position)
end

M.start_combat = function()
    M.combat_started = true
end

M.tick_combat = function(dt)
    if not M.combat_started then return end
    for i, v in ipairs(M.units) do
        if hash(v.state) == hash('idle') then M.get_target(v) if v.target then v.state = 'acquiring_target' end
        elseif hash(v.state) == hash('acquiring_target') then M.acquire_target(v)
        elseif hash(v.state) == hash('advancing') then M.advance(v, dt)
        elseif hash(v.state) == hash('attacking') then M.handle_attacking(v, dt)
        elseif hash(v.state) == hash('starting_attack') then M.attack(v)
        end
    end
end

M.hit = function(attacker, defender)
    -- if defender is not aggro-ed, then aggro the attacker
    if not defender.target and hash(defender.state) == hash('idle') then defender.target = attacker.id M.update_facing(attacker) end
    local attacker_data, defender_data = Unit.get_data(attacker.prototype), Unit.get_data(defender.prototype)
    local dmg = attacker_data.attack - defender_data.defense
    dmg = math.max(1, dmg)
    M.take_dmg(defender, dmg)
end

M.take_dmg = function(unit, dmg)
    unit.hp = unit.hp - dmg
    if unit.hp > 0 then
        msg.post(urls.battle_proxy, 'unit_took_dmg', {unit=unit, dmg=dmg})
    else
        if hash(unit.state) ~= hash('defeated') then
            M.defeat_unit(unit)
        end
    end
end

M.defeat_unit = function(unit)
    unit.state = 'defeated'
    msg.post(urls.battle_proxy, 'unit_defeated', {unit=unit})

    M.remove_unit(unit)
    -- check for victory/defeat
    local num_player_units = utils.occurences(M.units, function(v) return hash(v.team) == hash('player') end)
    local num_enemy_units = utils.occurences(M.units, function(v) return hash(v.team) == hash('enemy') end)
    
    if num_enemy_units == 0 then M.party = M.units M.clean_up() msg.post(urls.gamestate, 'reward')
    elseif num_player_units == 0 then M.clean_up() msg.post(urls.gamestate, 'gameover')
    end
end

M.clean_up = function()
    M.units = {}
    M.combat_started = false
    Player.day = Player.day + 1
    for i, v in ipairs(Player.party) do
        Unit.reset(v)
    end
    utils.remove_all(Player.party, function(w) return w.hp <= 0 end)
end




return M