local hitboxes = {}

local config
local data
local misc
local drawing
local utilities

local rsc_controllers = {}
local attacks = {}
local attacks_cache = {}
local dummy_shapes = {}


local function draw_dummies()
    for shape, pos in pairs(dummy_shapes) do

        if (pos[1] - data.master_player.pos):length() > config.current.draw_distance then
            goto next
        end

        if shape == 'Sphere' then
            draw.sphere(
                pos[1],
                pos[2],
                config.current.color,
                config.current.sphere_show_outline
            )
        elseif shape == 'Cylinder' then
            drawing.cylinder(
                pos[1],
                pos[2],
                pos[3],
                config.current.color,
                config.slider_data.cylinder_segments[tostring(config.current.cylinder_segments)],
                true,
                config.current.cylinder_show_outline,
                config.current.cylinder_show_outline_sides,
                false
            )
        elseif shape == 'Capsule' then
            if config.current.hitbox_capsule == 1 then
                draw.capsule(
                    pos[1],
                    pos[2],
                    pos[3],
                    config.current.color,
                    true
                )
            else
                drawing.capsule(
                    pos[1],
                    pos[2],
                    pos[3],
                    config.current.color,
                    config.slider_data.capsule_segments[tostring(config.current.capsule_segments)],
                    config.current.capsule_show_outline,
                    config.current.capsule_show_outline_spheres
                )
            end
        elseif shape == 'Box' then
            drawing.box(
                pos[1],
                pos[2],
                config.current.color,
                config.current.box_show_outline
            )
        elseif shape == 'Ring' then
            drawing.ring(
                pos[1],
                pos[2],
                pos[3],
                pos[4],
                config.current.color,
                config.slider_data.ring_segments[tostring(config.current.ring_segments)],
                config.current.ring_show_outline,
                config.current.ring_show_outline_sides
            )
        end

        ::next::
    end
end

function hitboxes.spawn_dummy_shape(shape_name)
    local shape = misc.table_copy(data.dummy_shapes[shape_name])
    local player_pos = utilities.get_player_pos()
    if player_pos then
        if shape_name == 'Sphere' or shape_name == 'Box' then
            shape[1] = shape[1] + player_pos
        else
            shape[1] = shape[1] + player_pos
            shape[2] = shape[2] + player_pos
        end
        dummy_shapes[shape_name] = shape
    end
end

function hitboxes.clear_dummy_shapes()
    dummy_shapes = {}
end

function hitboxes.get_attacks(args)
    local attack_work = sdk.to_managed_object(args[2])
    local rsc_controller = attack_work:get_RSCCtrl()
    local parent = rsc_controllers[rsc_controller]
    local rs_data = sdk.to_managed_object(args[8])

    if not parent then
        local game_object = rsc_controller:get_GameObject()
        local char_base = utilities.get_component(game_object, 'snow.CharacterBase')

        if char_base then
            local char_obj = data.char_objects[char_base]

            if not char_obj then
                local char_type = char_base:getCharacterType()
                if char_type == 4 then      --shell
                    char_base = char_base:get_OwnerObject()
                    char_obj = data.char_objects[char_base]

                    if not char_obj then
                        char_type = char_base:getCharacterType()
                        data.char_objects[char_base] = utilities.get_parent_data(char_type,char_base)
                        parent = data.char_objects[char_base]
                    else
                        parent = char_obj
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
            parent.props = true
            parent.distance = 0
        end
    end

    if (
        parent.player
        and not config.current.ignore_players
        or (
            parent.otomo
            and not config.current.ignore_otomo
        ) or (
              parent.enemy
              and (
                   not config.current.ignore_big_monsters
                   and parent.enemy.boss
                   or (
                       not config.current.ignore_small_monsters
                       and not parent.enemy.boss
                   )
              )
          ) or (
                parent.props
                and not config.current.ignore_props
            ) or (
                  parent.creature
                  and not config.current.ignore_creatures
              )
    ) then
        table.insert(attacks, {
            rsc_controller=rsc_controller,
            parent=parent,
            attack_work=attack_work,
            rs_data=rs_data,
            res_idx=args[5],
            rs_id=args[6]
        })
    end
end

function hitboxes.reset()
    attacks = {}
    rsc_controllers = {}
    data.char_objects = {}
    attacks_cache = {}
    dummy_shapes = {}
end

function hitboxes.get()
    if config.current.enabled then
        draw_dummies()

        for idx, att in pairs(attacks) do

            if att.parent.distance > config.current.draw_distance then
                attacks[idx] = nil
                goto continue
            end

            local phase = att.attack_work:get_Phase()

            if (
                phase == 3
                or att.attack_work:get_reference_count() == 1
                or (
                    att.collidables
                    and #att.collidables == 0
                )
            ) then
                attacks[idx] = nil
                goto continue

            elseif phase == 2 then
                if not att.collidables then
                    att.collidables = {}
                    local attack_data = {}
                    local ignore_monitor
                    local key

                    if not config.current.pause_monitor then

                        attack_data.id = att.parent.id
                        if not attack_data.id then
                            attack_data.id = 'None'
                        end
                        attack_data.name = att.rs_data:ToString()

                        attack_data.parent = ''
                        if att.parent.prop then
                            attack_data.parent = 'Prop'
                        elseif att.parent.enemy then
                            if att.parent.enemy.boss then
                                attack_data.parent = 'Big Monster'
                            else
                                attack_data.parent = 'Small Monster'
                            end
                        elseif att.parent.player then
                            if att.parent.servant then
                                attack_data.parent = 'Servant'
                            else
                                attack_data.parent = 'Player'
                            end
                        elseif att.parent.otomo then
                            if att.parent.servant then
                                attack_data.parent = 'OtomoServant'
                            else
                                attack_data.parent = 'Otomo'
                            end
                        elseif att.parent.creature then
                            attack_data.parent = 'Creature'
                        end

                        key = attack_data.parent .. attack_data.id .. attack_data.name
                        if attacks_cache[key] then
                            attack_data = attacks_cache[key]
                            attack_data.cache = true
                        end
                    end

                    if not attack_data.cache then
                        attack_data.motion_value = att.rs_data._BaseDamage
                        attack_data.damage_type = att.rs_data._DamageType
                        attack_data.damage_type_name = data.damage_types.ids[tostring(attack_data.damage_type)]
                        attack_data.att_cond_types = {}
                        attack_data.shape_count = {}
                        attack_data.windbox_count = 0
                        attack_data.frontal_count = 0
                        attack_data.guardable = att.rs_data:get_GuardableType()
                    end

                    if (
                        attack_data.guardable == 2
                        and config.current.ignore_unguardable
                        or config.current['ignore_' .. attack_data.damage_type_name]
                    ) then
                        if key and attacks_cache[key] and not attacks_cache[key].cache then
                            attacks_cache[key] = nil
                        end
                        goto continue
                    end

                    attack_data.col_count = att.rsc_controller:getNumCollidables(att.res_idx, att.rs_id)
                    for i=0, attack_data.col_count-1 do
                        local collidable = att.rsc_controller:getCollidable(att.res_idx, att.rs_id, i)
                        local userdata = collidable:get_UserData()
                        local frontal = userdata._EnemyHitCheckVec == 0
                        local att_cond = userdata._ConditionMatchHitAttr
                        local custom_shape = userdata._CustomShapeType
                        local att_cond_name = nil
                        local shape_name = nil
                        local windbox = userdata:get_type_definition():is_a("snow.hit.userdata.HitAttackAppendShapeData")
                        local col_data = {
                            col=collidable,
                            color=config.current.color,
                            type='hitbox',
                            pos=Vector3f.new(0, 0 ,0),
                            distance=0,
                            sort=0,
                            att=att
                        }

                        if not att_cond then
                            att_cond = 0
                        end

                        if windbox and not attack_data.cache then
                            attack_data.windbox_count = attack_data.windbox_count + 1
                        end

                        if frontal and not attack_data.cache then
                            attack_data.frontal_count = attack_data.frontal_count + 1
                        end

                        att_cond_name = data.att_cond_match_hit_attr.ids[tostring(att_cond)]
                        if not att_cond_name then
                            att_cond_name = 'Invalid'
                        end

                        if not attack_data.cache and not misc.table_contains(attack_data.att_cond_types, att_cond_name) then
                            table.insert(attack_data.att_cond_types, att_cond_name)
                        end

                        if custom_shape ~= 0 then
                            shape_name = data.custom_shape_id[tostring(custom_shape)]
                            col_data.custom_shape_type = custom_shape
                            col_data.userdata = userdata
                            if not misc.table_contains(data.valid_custom_shapes, custom_shape) then
                                if not misc.table_contains(config.current.missing_custom_shapes, custom_shape) then
                                    table.insert(config.current.missing_custom_shapes, custom_shape)
                                end
                            end
                        else
                            col_data.shape_type = utilities.get_shape_type(collidable)
                            shape_name = data.shape_id[tostring(col_data.shape_type)]
                            if not misc.table_contains(data.valid_shapes, col_data.shape_type) then
                                if not misc.table_contains(config.current.missing_shapes, col_data.shape_type) then
                                    table.insert(config.current.missing_shapes, col_data.shape_type)
                                end
                            end
                        end

                        if not attack_data.cache then
                            attack_data.shape_count = misc.add_count(attack_data.shape_count, shape_name)
                        end

                        if (
                            config.current['ignore_' .. att_cond_name]
                            or (
                                windbox
                                and config.current.ignore_windbox
                            ) or (
                                  frontal
                                  and config.current.ignore_frontal
                              )
                        ) then
                            ignore_monitor = true
                            goto next
                        end

                        if not config.current.hitbox_use_single_color then
                            if att.parent.prop then
                                col_data.color = config.current.prop_color
                            elseif att.parent.enemy then
                                if att.parent.enemy.boss then
                                    col_data.color = config.current.big_monster_color
                                else
                                    col_data.color = config.current.small_monster_color
                                end
                            elseif att.parent.player then
                                col_data.color = config.current.player_color
                            elseif att.parent.otomo then
                                col_data.color = config.current.otomo_color
                            elseif att.parent.creature then
                                col_data.color = config.current.creature_color
                            end

                            if windbox and config.current.enable_windbox_color then
                                col_data.color = config.current.windbox_color
                            end

                            if frontal and config.current.enable_frontal_color then
                                col_data.color = config.current.frontal_color
                            end

                            if attack_data.guardable == 2 and config.current.enable_unguardable_color then
                                col_data.color = config.current.unguardable_color
                            end

                            if att_cond_name and att_cond_name ~= 'None' and config.current['enable_' .. att_cond_name .. '_color'] then
                                col_data.color = config.current[att_cond_name .. '_color']
                            end
                        end

                        table.insert(att.collidables, col_data)

                        utilities.update_collidable(col_data)

                        if col_data.enabled and col_data.updated then
                            table.insert(drawing.cache, col_data)
                        end

                        ::next::
                    end

                    if not config.current.pause_monitor and not attack_data.cache then

                        attack_data.ele_mod = att.rs_data:get_field('<SubRate>k__BackingField')
                        attack_data.ele_mod = attack_data.ele_mod and attack_data.ele_mod or not attack_data.ele_mod and "None"
                        attack_data.debuff_mod = att.rs_data:get_field('<DebuffRate>k__BackingField')
                        attack_data.debuff_mod = attack_data.debuff_mod and attack_data.debuff_mod or not attack_data.debuff_mod and 'None'
                        attack_data.id = attack_data.id and attack_data.id or not attack_data.id and 'None'
                        attack_data.condition = table.concat(attack_data.att_cond_types, "\n")
                        attack_data.power = att.rs_data._Power
                        attack_data.shape_count = misc.join_table(attack_data.shape_count)
                        attack_data.element = data.element_id[tostring(att.rs_data:get_field('<AttackElement>k__BackingField'))]
                        attack_data.element_value = att.rs_data._BaseAttackElement
                        attack_data.debuff_value = att.rs_data:get_field('<DebuffValue>k__BackingField')
                        attack_data.debuff_1 = data.debuff_id[tostring(att.rs_data:get_field('<DebuffType>k__BackingField'))]
                        attack_data.sharpness = data.sharpness_id[tostring(att.rs_data:get_field('<SharpnessType>k__BackingField'))]
                        attack_data.guardable = data.guard_id[attack_data.guardable]
                        attack_data.start_delay = att.rs_data._HitStartDelay
                        attack_data.end_delay = att.rs_data._HitStartDelay

                        if not ignore_monitor then
                            table.insert(data.monitor, 1, attack_data)
                            attacks_cache[attack_data.parent .. attack_data.id .. attack_data.name] = attack_data
                        end

                    elseif not config.current.pause_monitor and attack_data.cache and not ignore_monitor then
                        table.insert(data.monitor, 1, attack_data)
                    end

                    if #data.monitor > 2 * config.max_table_size then
                        misc.table_remove(
                            data.monitor,
                            function(t, i, j)
                                if i > config.current.table_size then
                                    return false
                                else
                                    return true
                                end
                            end
                        )
                    end
                else
                    local alive = false
                    for _, collidable in pairs(att.collidables) do
                        utilities.update_collidable(collidable)

                        if collidable.enabled and collidable.updated then
                            alive = true
                            table.insert(drawing.cache, collidable)
                        end
                    end

                    if not alive then
                        attacks[idx] = nil
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
