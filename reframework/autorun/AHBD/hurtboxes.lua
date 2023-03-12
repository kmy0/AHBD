local hurtboxes = {}

local config
local drawing
local misc
local utilities
local data

local hurtbox_cache = {}
local cache_cleared = false
local to_draw = {}

local to_load
local loading = false
local timer = os.clock()
local update_count = 0
local max_updates = 20


local function create_hurtbox_monitor_entry(name, group, parent, meat, part_group)
    if not data.hurtbox_monitor[name] or not data.hurtbox_monitor[name].groups[group] then
        local entry = {
            visible=true,
            highlight=false,
            meat=meat,
            part_group=part_group,
            collidables={}
        }
        if not data.hurtbox_monitor[name] then
            data.hurtbox_monitor[name] = {
                groups={
                    [group]=entry
                },
                parent=parent,
                real_name=utilities.get_monster_name(parent.id)
            }
        else
            data.hurtbox_monitor[name].groups[group] = entry
        end
    end
    return data.hurtbox_monitor[name].groups[group]
end

local function add_collidable(name, col, parent, meat, group, part_group)
    local col_data = {
        parent=parent,
        col=col,
        color=config.current.hurtbox_color,
        type='hurtbox',
        group=group,
        part_group=part_group,
        name=name,
        meat=meat,
        shape_type=utilities.get_shape_type(col),
        enabled=col:get_Enabled()
    }

    if parent.master_player then
        table.insert(
            misc.get_nested_table(
                misc.get_nested_table(to_draw, 'master_player'), name), col_data
            )
    elseif parent.player then
        table.insert(
            misc.get_nested_table(
                misc.get_nested_table(to_draw, 'player'), name), col_data
            )
    elseif parent.enemy then
        if parent.enemy.boss then
            table.insert(
                misc.get_nested_table(
                    misc.get_nested_table(to_draw, 'bossenemy'), name), col_data
                )

            table.insert(create_hurtbox_monitor_entry(name, group, parent, meat, part_group).collidables, col_data)
        else
            table.insert(
                misc.get_nested_table(
                    misc.get_nested_table(to_draw, 'smallenemy'), name), col_data
                )
        end
    elseif parent.creature then
        table.insert(
            misc.get_nested_table(
                misc.get_nested_table(to_draw, 'creature'), name), col_data
            )

    elseif parent.otomo then
        table.insert(
            misc.get_nested_table(
                misc.get_nested_table(to_draw, 'otomo'), name), col_data
            )
    end
end

local function create_parent_data(char_base)
    local char_type = char_base:getCharacterType()

    if char_type == 4 or char_type == 3 then return end  --Shell, Npc

    data.char_objects[char_base] = utilities.get_parent_data(char_type, char_base)
    return data.char_objects[char_base]
end

local function load_hurtboxes_from_json()
    local cache = json.load_file(config.hurtbox_cache_path)
    if cache then
        local transforms = utilities.get_all_transfroms()
        for i=0, transforms:get_Count()-1 do
            local transform = transforms:get_Item(i)
            local game_object = transform:get_GameObject()
            local game_object_name = game_object:get_Name()
            local game_object_address = game_object:get_address()
            local key = game_object_name .. '@' .. game_object_address

            if cache[key] then
                local char_base = utilities.get_component(game_object, 'snow.CharacterBase')
                if char_base then
                    local parent = create_parent_data(char_base)
                    if parent then
                        parent.rsc = utilities.get_component(game_object, 'via.physics.RequestSetCollider')
                        data.to_update[char_base] = true
                        data.char_objects[char_base] = parent
                        for rs_id, _ in pairs(cache[key]) do
                            local t = {
                                parent=parent,
                                rs_id=tonumber(rs_id)
                            }
                            to_load = misc.set_nested_table(to_load, key, rs_id, t)
                            timer = os.clock()
                        end
                    end
                end
            end
        end
    end
end

local function load_hurtboxes()
    if to_load and os.clock() - timer > 3 then

        loading = true
        update_count = 0

        for name, t in pairs(to_load) do
            if update_count_load == config.max_updates then
                return
            end

            for rs_string, collidable in pairs(t) do
                hurtbox_cache = misc.set_nested_table(hurtbox_cache, name, rs_string, true)

                if collidable.parent.player or collidable.parent.otomo then
                    local col = collidable.parent.rsc:call('getCollidableFromIndex(System.UInt32, System.UInt32, System.UInt32)', 0, 0, 0)
                    if col then
                        add_collidable(name, col, collidable.parent)
                    end
                else
                    for i=0 ,collidable.parent.rsc:getNumRequestSetIds(collidable.rs_id)-1 do
                        for j=0, collidable.parent.rsc:getNumCollidablesFromIndex(i)-1 do
                            local col = collidable.parent.rsc:call('getCollidableFromIndex(System.UInt32, System.UInt32, System.UInt32)', collidable.rs_id, i, j)
                            if col then
                                local userdata = col:get_UserData()
                                if collidable.parent.creature then
                                    add_collidable(name, col, collidable.parent)
                                elseif userdata:get_type_definition():is_a("snow.hit.userdata.EmHitDamageShapeData") then
                                    local parent_userdata = userdata:get_ParentUserData()

                                    if not parent_userdata:get_type_definition():is_a("snow.hit.userdata.EmHitDamageRSData") then
                                        goto next
                                    end

                                    local meat = userdata:get_Meat()
                                    local group = parent_userdata:get_Name()
                                    local part_group = parent_userdata:get_Group()

                                    misc.set_nested_table(collidable.parent.meat, tostring(meat), tostring(part_group), true)
                                    add_collidable(name, col, collidable.parent, meat, group, part_group)
                                end
                            end
                            ::next::
                        end
                    end
                end
            end

            update_count = update_count + 1
            to_load[name] = nil
        end

        if update_count == 0 then
            json.dump_file(config.hurtbox_cache_path, hurtbox_cache)
            cache_cleared = false
            to_load = nil
            loading = false
        end
    end
end

function hurtboxes.get_hurtboxes(args)
    if not loading and utilities.is_in_quest() then
        local obj = sdk.to_managed_object(args[1])
        local game_object = obj:get_GameObject()
        local game_object_name = game_object:get_Name()
        local char_base = utilities.get_component(game_object, 'snow.CharacterBase')
        local parent = data.char_objects[char_base]
        local address = game_object:get_address()

        if not parent then
            if char_base then
                parent = create_parent_data(char_base)
                data.to_update[char_base] = true
            end
        end

        if parent then
            if not to_load then to_load = {} end
            parent.rsc = obj
            local rs_id = sdk.to_int64(args[2])
            local key = game_object_name .. '@' .. address
            if not to_load[key] then
                to_load[key] = {}
                to_load[key][tostring(rs_id)] = {
                    parent=parent,
                    rs_id=rs_id
                }
            end
        end

        timer = os.clock()
    end
end

function hurtboxes.reset()
    data.char_objects = {}
    hurtbox_cache = {}
    if not cache_cleared then
        json.dump_file(config.hurtbox_cache_path, nil)
        cache_cleared = true
    end
    to_draw = {}
    data.hurtbox_monitor = {}
    to_load = nil
    loading = false
end

function hurtboxes.draw()
    load_hurtboxes()
    if config.current.enabled_hurtboxes then
        for parent_name, parent_data in pairs(to_draw) do
            if (
                parent_name == 'bossenemy'
                and config.current.ignore_hurtbox_big_monsters
                or (
                    parent_name == 'smallenemy'
                    and config.current.ignore_hurtbox_small_monsters
                ) or (
                      parent_name == 'master_player'
                      and config.current.ignore_hurtbox_master_player
                  ) or (
                        parent_name == 'player'
                        and config.current.ignore_hurtbox_players
                    ) or (
                          parent_name == 'otomo'
                          and config.current.ignore_hurtbox_otomo
                      ) or (
                            parent_name == 'creature'
                            and config.current.ignore_hurtbox_creatures
                        )
            ) then
                goto next_parent
            end

            for game_object_name, cols in pairs(parent_data) do
                for idx, col in pairs(cols) do
                    if col.parent.distance > config.current.draw_distance then
                        goto next_game_object
                    end

                    if col.col:get_reference_count() == 1 then
                        col.remove = true
                        to_draw[parent_name][game_object_name][idx] = nil
                        goto next_col
                    end

                    if data.hurtbox_monitor[game_object_name] and not data.hurtbox_monitor[game_object_name].groups[col.group].visible then
                        goto next_col
                    end

                    if data.hurtbox_monitor[game_object_name] and data.hurtbox_monitor[game_object_name].groups[col.group].highlight then
                        col.color = config.current.hurtbox_highlight_color
                    else
                        if not config.current.hurtbox_use_single_color then
                            if col.parent.enemy then
                                if col.parent.enemy.boss then
                                    col.color = config.current.hurtbox_big_monster_color
                                else
                                    col.color = config.current.hurtbox_small_monster_color
                                end
                            elseif col.parent.master_player then
                                col.color = config.current.hurtbox_master_player_color
                            elseif col.parent.player then
                                col.color = config.current.hurtbox_player_color
                            elseif col.parent.otomo then
                                col.color = config.current.hurtbox_otomo_color
                            elseif col.parent.creature then
                                col.color = config.current.hurtbox_creature_color
                            end
                        else
                            col.color = config.current.hurtbox_color
                        end

                        if col.parent.enemy then
                            for type, conditions in pairs(config.raw_hitzone_conditions) do
                                if col.parent.hitzones and col.parent.hitzones[tostring(col.meat)] then
                                    local hitzone = col.parent.hitzones[tostring(col.meat)][tostring(col.part_group)][type]
                                    for _, cond in pairs(conditions) do
                                        if hitzone >= cond.from and hitzone <= cond.to then
                                            if cond.ignore then
                                                goto next_col
                                            else
                                                col.color = cond.color
                                                goto exit
                                            end
                                        end
                                    end
                                end
                            end

                            ::exit::
                        end
                    end

                    drawing.shape(col)
                    ::next_col::
                end

                if data.hurtbox_monitor[game_object_name] then
                    data.hurtbox_monitor[game_object_name].updated = os.clock()
                end

                ::next_game_object::
            end

            ::next_parent::
        end
    end
end

function hurtboxes.init()
    config = require("AHBD.config")
    drawing = require("AHBD.drawing")
    misc = require("AHBD.misc")
    utilities = require("AHBD.utilities")
    data = require("AHBD.data")

    if utilities.is_in_quest() then
        load_hurtboxes_from_json()
    end
end

return hurtboxes
