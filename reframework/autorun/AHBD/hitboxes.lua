local hitboxes = {}

local config
local data
local misc
local drawing
local utilities

local rsc_controllers = {}
local to_draw = {}
local attacks_cache = {}
local active_attacks = {}
local parent_type_to_name = {
    player = "Player",
    bossenemy = "Big Monster",
    smallenemy = "Small Monster",
    otomo = "Otomo",
    creature = "Creature",
    prop = "Prop"
}


local function get_attack_data(attack)
    if attacks_cache[attack.key] then
        return attacks_cache[attack.key]
    end

    local attack_data = {}

    if attack.parent.type == 'player' and attack.parent.master_player then
        attack_data.parent = 'Master Player'
    elseif attack.parent.type == 'otomo' and attack.parent.servant then
        attack_data.parent = 'OtomoServant'
    else
        attack_data.parent = parent_type_to_name[attack.parent.type]
    end

    attack_data.name = attack.rs_data:ToString()
    attack_data.motion_value = attack.rs_data._BaseDamage
    attack_data.damage_type = attack.rs_data._DamageType
    attack_data.damage_type_name = data.damage_types.ids[attack_data.damage_type]
    attack_data.guardable = attack.rs_data:get_GuardableType()
    attack_data.col_count = attack.rsc_controller:getNumCollidables(attack.res_idx, attack.rs_id)
    attack_data.ele_mod = attack.rs_data['<SubRate>k__BackingField']
    attack_data.ele_mod = attack_data.ele_mod or "None"
    attack_data.debuff_mod = attack.rs_data['<DebuffRate>k__BackingField']
    attack_data.debuff_mod = attack_data.debuff_mod or 'None'
    attack_data.id = attack.parent.id or "None"
    attack_data.power = attack.rs_data._Power
    attack_data.element = data.element_id[attack.rs_data['<AttackElement>k__BackingField']]
    attack_data.element_value = attack.rs_data._BaseAttackElement
    attack_data.debuff_value = attack.rs_data['<DebuffValue>k__BackingField']
    attack_data.debuff_1 = data.debuff_id[attack.rs_data['<DebuffType>k__BackingField']]
    attack_data.sharpness = data.sharpness_id[attack.rs_data['<SharpnessType>k__BackingField']]
    attack_data.guardable = data.guard_id[attack_data.guardable]
    attack_data.start_delay = attack.rs_data._HitStartDelay
    attack_data.end_delay = attack.rs_data._HitStartDelay
    attack_data.collidables = {}

    return attack_data
end

local function get_collidable_info(collidable, col_data)
    local col_info = {}
    col_info.userdata = collidable:get_UserData()
    col_info.is_windbox = col_info.userdata:get_type_definition():is_a("snow.hit.userdata.HitAttackAppendShapeData")
    col_info.is_frontal = col_info.userdata._EnemyHitCheckVec == 0
    col_info.attack_condition = col_info.userdata._ConditionMatchHitAttr
    col_info.type = 'hitbox'

    if not col_info.attack_condition then
        col_info.attack_condition = 0
    end

    col_info.attack_condition_name = data.att_cond_match_hit_attr.ids[col_info.attack_condition]
    if not col_info.attack_condition_name then
        col_info.attack_condition_name = 'Invalid'
    end

    local is_custom, shape_type = utilities.check_custom_shape(col_data, col_info.userdata)

    if is_custom then
        col_info.custom_shape_type = shape_type
        col_info.shape_name = data.custom_shape_id[shape_type]
    else
        col_info.shape_type = shape_type
        col_info.shape_name = data.shape_id[shape_type]
    end

    return col_info
end

function hitboxes.get_attacks(args)
    local attack_work = sdk.to_managed_object(args[2])
    local rsc_controller = attack_work['<RSCCtrl>k__BackingField']
    local parent = rsc_controllers[rsc_controller]

    if not parent then
        local game_object = rsc_controller:get_GameObject()
        local char_base = utilities.get_component(game_object, 'snow.CharacterBase')

        if char_base then
            local char_obj = data.char_objects[char_base]

            if not char_obj then
                local char_type = char_base:getCharacterType()

                if char_type == 4 then      --shell
                    char_base = char_base:get_OwnerObject()

                    if char_base then
                        char_obj = data.char_objects[char_base]

                        if not char_obj then
                            char_type = char_base:getCharacterType()
                            data.char_objects[char_base] = utilities.get_parent_data(char_type,char_base)
                            parent = data.char_objects[char_base]
                        else
                            parent = char_obj
                        end
                    else
                        parent = {}
                        parent.type = 'prop'
                        parent.distance = 0
                    end
                else
                    data.char_objects[char_base] = utilities.get_parent_data(char_type,char_base)
                    rsc_controllers[rsc_controller] = data.char_objects[char_base]
                    parent = data.char_objects[char_base]
                end
            else
                parent = char_obj
                rsc_controllers[rsc_controller] = char_obj
            end
        else
            parent = {}
            parent.type = 'prop'
            parent.distance = 0
        end
    end

    if parent and not config.current[string.format('ignore_%s', parent.type)] then
        local res_idx = sdk.to_int64(args[5]) & 0xFF
        local rs_id = sdk.to_int64(args[6]) & 0xFF
        local key = string.format("%i|%i|%i", rsc_controller:get_address(), res_idx, rs_id)

        if not config.current.ignore_duplicate_hitboxes or not active_attacks[key] then
            table.insert(to_draw, {
                rsc_controller = rsc_controller,
                parent = parent,
                attack_work = attack_work,
                rs_data = sdk.to_managed_object(args[8]),
                res_idx = res_idx,
                rs_id = rs_id,
                key = key
            })

            active_attacks[key] = true
        end
    end
end

function hitboxes.reset()
    to_draw = {}
    rsc_controllers = {}
    data.char_objects = {}
    attacks_cache = {}
    active_attacks = {}
end

function hitboxes.get()
    if config.current.enabled then

        local function remove(idx, key)
            to_draw[idx] = nil
            active_attacks[key] = nil
        end

        for idx, attack in pairs(to_draw) do

            if attack.parent.distance > config.current.draw_distance then
                remove(idx, attack.key)
                goto continue
            end

            local phase = attack.attack_work['<Phase>k__BackingField']

            if (
                phase == 3
                or attack.attack_work:get_reference_count() == 1
                or (
                    attack.collidables
                    and #attack.collidables == 0
                )
            ) then
                remove(idx, attack.key)
                goto continue

            elseif phase == 2 then
                if not attack.collidables then
                    local attack_data = get_attack_data(attack)
                    attack.collidables = {}

                    if (
                        attack_data.guardable == 2
                        and config.current.ignore_unguardable
                        or config.current[string.format("ignore_%s", attack_data.damage_type_name)]
                    ) then
                        goto continue
                    end

                    local am_data = {
                        attack_condition_types = {},
                        shape_count = {},
                        windbox_count = 0,
                        frontal_count = 0,
                        active_count = 0
                    }
                    local color = config.current[string.format("%s_color", attack.parent.type)]

                    for i=0, attack_data.col_count-1 do
                        local collidable = attack.rsc_controller:getCollidable(attack.res_idx, attack.rs_id, i)
                        local col_info
                        local col_data = {
                            col = collidable,
                            pos = Vector3f.new(0, 0 ,0),
                            distance = 0,
                            sort = 0,
                            color = config.current.color,
                            shape = collidable:get_TransformedShape()
                        }

                        if attack_data.cache then
                            col_info = attack_data.collidables[i]
                        else
                            col_info = get_collidable_info(collidable, col_data)
                            attack_data.collidables[i] = col_info
                        end

                        col_data.info = col_info
                        am_data.active_count = am_data.active_count + 1
                        am_data.shape_count = misc.add_count(am_data.shape_count, col_info.shape_name)

                        if col_info.is_windbox then
                            am_data.windbox_count = am_data.windbox_count + 1
                        end

                        if col_info.is_frontal then
                            am_data.frontal_count = am_data.frontal_count + 1
                        end

                        if not misc.table_contains(am_data.attack_condition_types, col_info.attack_condition_name) then
                            table.insert(am_data.attack_condition_types, col_info.attack_condition_name)
                        end

                        if (
                            config.current[string.format("ignore_%s", col_info.attack_condition_name)]
                            or (
                                col_info.is_windbox
                                and config.current.ignore_windbox
                            ) or (
                                  col_info.is_frontal
                                  and config.current.ignore_frontal
                              )
                        ) then
                            goto next
                        end

                        if not config.current.hitbox_use_single_color then
                            col_data.color = color

                            if col_info.is_windbox and config.current.enable_windbox_color then
                                col_data.color = config.current.windbox_color
                            end

                            if col_info.is_frontal and config.current.enable_frontal_color then
                                col_data.color = config.current.frontal_color
                            end

                            if attack_data.guardable == 2 and config.current.enable_unguardable_color then
                                col_data.color = config.current.unguardable_color
                            end

                            if (
                                col_info.attack_condition_name
                                and col_info.attack_condition_name ~= 'None'
                                and config.current[string.format("enable_%s_color", col_info.attack_condition_name)]
                            ) then
                                col_data.color = config.current[string.format("%s_color", col_info.attack_condition_name)]
                            end
                        end

                        table.insert(attack.collidables, col_data)

                        utilities.update_collidable(col_data)

                        if col_data.enabled and col_data.updated then
                            table.insert(drawing.cache, col_data)
                        end

                        ::next::
                    end

                    if not attack_data.cache and #attack.collidables ~= 0 then
                        attacks_cache[attack.key] = attack_data
                        attack_data.cache = true
                    end

                    if not config.current.pause_monitor and #attack.collidables ~= 0 then
                        am_data.shape_count = misc.join_table(am_data.shape_count)
                        am_data.attack_condition_types = table.concat(am_data.attack_condition_types, "\n")
                        table.insert(data.monitor, 1, {attack_data, am_data})
                    end

                    if #data.monitor > 2 * config.max_table_size then
                        misc.table_remove(
                            data.monitor,
                            function(t, i, j)
                                if i > config.max_table_size then
                                    return false
                                else
                                    return true
                                end
                            end
                        )
                    end
                else
                    for _, collidable in pairs(attack.collidables) do
                        utilities.update_collidable(collidable)

                        if collidable.enabled and collidable.updated then
                            table.insert(drawing.cache, collidable)
                        end
                    end
                end
            end

            ::continue::
        end
    end
end

function hitboxes.init()
    config = require("AHBD.config")
    data = require("AHBD.data")
    misc = require("AHBD.misc")
    drawing = require("AHBD.drawing")
    utilities = require("AHBD.utilities")
end

return hitboxes
