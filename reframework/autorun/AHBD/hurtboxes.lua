local hurtboxes = {}

local config
local drawing
local misc
local utilities
local data

local enemy_hitzone_status = {}
local to_draw = {}
local to_load = {}
local update_count = 0


local function create_hurtbox_monitor_entry(name, internal_name, parent, meat, part_group)
    if not data.hurtbox_monitor[name] or not data.hurtbox_monitor[name].groups[meat] then
        local entry = {
            visible=true,
            highlight=false,
            meat=meat,
            part_name=utilities.get_part_name(meat, parent.id) or internal_name or "???",
            internal_name=internal_name,
            part_group=part_group,
            collidables={}
        }

        if not data.hurtbox_monitor[name] then
            data.hurtbox_monitor[name] = {
                groups={
                    [meat]=entry
                },
                parent=parent,
                real_name=utilities.get_monster_name(parent.id)
            }
        else
            data.hurtbox_monitor[name].groups[meat] = entry
        end
    end

    return data.hurtbox_monitor[name].groups[meat]
end

local function add_collidable(name, col, parent, meat, internal_name, part_group)
    local col_data = {
        parent=parent,
        col=col,
        color=config.current.hurtbox_color,
        sort=0,
        part_group=part_group,
        meat=meat,
        pos=Vector3f.new(0, 0, 0),
        distance=0,
        shape=col:get_TransformedShape(),
        info={
            userdata=col:get_UserData(),
            type='hurtbox'
        },
        enabled=col:get_Enabled()
    }

    local is_custom, shape_type = utilities.check_custom_shape(col_data, col_data.info.userdata)
    if is_custom then
        col_data.info.custom_shape_type = shape_type
        col_data.info.shape_name = data.custom_shape_id[shape_type]
    else
        col_data.info.shape_type = shape_type
        col_data.info.shape_name = data.shape_id[shape_type]
    end

    table.insert(misc.get_nested_table(to_draw, string.format("%s%s", parent.master_player and "master" or "", parent.type), name), col_data)

    if parent.type == 'bossenemy'then
        table.insert(create_hurtbox_monitor_entry(name, internal_name, parent, meat, part_group).collidables, col_data)
    end
end

local function create_parent_data(char_base)
    local char_type = char_base:getCharacterType()

    if char_type == 4 or char_type == 3 then return end  --Shell, Npc

    data.char_objects[char_base] = utilities.get_parent_data(char_type, char_base)

    return data.char_objects[char_base]
end

local function load_hurtboxes()
    update_count = 0

    for idx, char_base_data in pairs(to_load) do

        local parent = char_base_data.parent
        local name = char_base_data.name

        if parent.type == 'player' or parent.type == 'otomo' then
            local col = parent.rsc:call('getCollidableFromIndex(System.UInt32, System.UInt32)', 0, 0)

            if col then
                add_collidable(name, col, parent)
            end
        else
            for i=0, parent.rsc:get_NumRequestSets()-1 do
                for j=0, parent.rsc:getNumCollidablesFromIndex(i)-1 do
                    local col = parent.rsc:call('getCollidableFromIndex(System.UInt32, System.UInt32)', i, j)

                    if col then
                        local userdata = col:get_UserData()

                        if parent.type == 'creature' then
                            add_collidable(name, col, parent)
                        elseif userdata:get_type_definition():is_a("snow.hit.userdata.EmHitDamageShapeData") then
                            local parent_userdata = userdata:get_ParentUserData()

                            if not parent_userdata:get_type_definition():is_a("snow.hit.userdata.EmHitDamageRSData") then
                                goto next
                            end

                            local meat = userdata:get_Meat()
                            local internal_name = parent_userdata:get_Name()
                            local part_group = parent_userdata:get_Group()

                            misc.set_nested_value(parent.meat, part_group, true, meat)
                            add_collidable(name, col, parent, meat, internal_name, part_group)
                        end
                    end

                    ::next::
                end
            end
        end

        update_count = update_count + 1
        to_load[idx] = nil

        if update_count == config.max_updates then
            return
        end
    end
end

function hurtboxes.get_char_base_in_quest()
    local transforms = utilities.get_all_transfroms()

    for i=0, transforms:get_Count()-1 do
        local transform = transforms:get_Item(i)
        local game_object = transform:get_GameObject()
        local rsc = utilities.get_component(game_object, 'via.physics.RequestSetCollider')

        if rsc then
            local char_base = utilities.get_component(game_object, 'snow.CharacterBase')

            if char_base and char_base:get_Started() then
                local parent = create_parent_data(char_base)

                if parent then
                    parent.rsc = rsc
                    data.to_update[char_base] = true

                    table.insert(to_load, {
                        parent=parent,
                        name=game_object:get_Name() .. '@' .. game_object:get_address()
                    })
                end
            end
        end
    end
end

function hurtboxes.get_base(args)
    local char_base = sdk.to_managed_object(args[2])
    local game_object = char_base:get_GameObject()
    local rsc = utilities.get_component(game_object, 'via.physics.RequestSetCollider')

    if rsc then
        local parent = create_parent_data(char_base)

        if parent then
            parent.rsc = rsc
            data.to_update[char_base] = true
            table.insert(to_load, {
                parent=parent,
                name=game_object:get_Name() .. '@' .. game_object:get_address()
            })
        end
    end
end

function hurtboxes.reset()
    data.char_objects = {}
    data.hurtbox_monitor = {}
    to_draw = {}
    to_load = {}
end

function hurtboxes.get()
    if config.current.enabled_hurtboxes then
        load_hurtboxes()

        for parent_name, parent_data in pairs(to_draw) do

            if (
                config.current[string.format("ignore_hurtbox_%s", parent_name)]
                or (
                    parent_name == 'masterplayer'
                    and config.current.hide_when_invulnerable
                    and data.master_player.obj:checkMuteki()
                )
            ) then
                goto next_parent
            end

            for game_object_name, cols in pairs(parent_data) do

                if parent_name == 'bossenemy' or parent_name == 'smallenemy' then
                    enemy_hitzone_status = {}
                end


                local color = config.current[string.format("hurtbox_%s_color", parent_name)]
                for idx, col in pairs(cols) do

                    if col.parent.distance > config.current.draw_distance then
                        goto next_game_object
                    end

                    if col.col:get_reference_count() == 1 then
                        col.remove = true
                        to_draw[parent_name][game_object_name][idx] = nil
                        goto next_col
                    end

                    if data.hurtbox_monitor[game_object_name] and not data.hurtbox_monitor[game_object_name].groups[col.meat].visible then
                        goto next_col
                    end

                    if data.hurtbox_monitor[game_object_name] and data.hurtbox_monitor[game_object_name].groups[col.meat].highlight then
                        col.color = config.current.hurtbox_highlight_color
                    else
                        if not config.current.hurtbox_use_single_color then
                            col.color = color
                        else
                            col.color = config.current.hurtbox_color
                        end

                        if (col.parent.type == 'bossenemy' or col.parent.type == 'smallenemy') and next(config.current.hitzone_conditions) then

                            if enemy_hitzone_status[col.meat] then
                                if enemy_hitzone_status[col.meat].ignore then
                                    goto next_col
                                elseif enemy_hitzone_status[col.meat].color then
                                    col.color = enemy_hitzone_status[col.meat].color
                                end
                            else
                                if col.parent.hitzones and col.parent.hitzones[col.meat] then
                                    enemy_hitzone_status[col.meat] = {}
                                    local hitzones = col.parent.hitzones[col.meat][col.part_group]

                                    for type=1, #data.damage_elements do
                                        local conditions = config.raw_hitzone_conditions[type]
                                        local hitzone = hitzones[type]

                                        for i=1, #conditions do
                                            local cond = conditions[i]

                                            if hitzone >= cond.from and hitzone <= cond.to then
                                                if cond.ignore then
                                                    enemy_hitzone_status[col.meat].ignore = true
                                                    goto next_col
                                                else
                                                    enemy_hitzone_status[col.meat].color = cond.color
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
                    end

                    utilities.update_collidable(col)

                    if col.enabled and col.updated then
                        table.insert(drawing.cache, col)
                    end

                    ::next_col::
                end

                ::next_game_object::
            end

            ::next_parent::
        end
    else
        hurtboxes.reset()
    end
end

function hurtboxes.init()
    config = require("AHBD.config")
    drawing = require("AHBD.drawing")
    misc = require("AHBD.misc")
    utilities = require("AHBD.utilities")
    data = require("AHBD.data")

    if config.current.enabled_hurtboxes and utilities.is_in_quest() then
        hurtboxes.get_char_base_in_quest()
    end
end

return hurtboxes
