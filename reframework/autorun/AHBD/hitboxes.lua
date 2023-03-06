local hitboxes = {}

local config
local data
local misc
local drawing

local valid_shapes = {1,2,3,4,5}
local valid_custom_shapes = {0,1,4}
local char_objects = {}
local rsc_controllers = {}
local attacks = {}
local attacks_cache = {}
local max_garbage = 30
local garbage_count = 0
hitboxes.dummy_shapes = {}


local function get_parent_data(char_type,char_base)
    local char = {}
    if char_type == 0 then      --player
        char.player = true
        char.id = char_base:getPlayerIndex()
        char.servant = char_base:checkServant(char.id)
    elseif char_type == 1 then      --enemy
        char.enemy = {
            boss=char_base:get_isBossEnemy()
        }
        char.id = char_base:get_EnemyType()
    elseif char_type == 2 then      --otomo
        char.otomo = true
        local otomo_quest_param = char_base:get_OtQuestParam()
        char.id = otomo_quest_param:get_OtomoID()
        char.servant = char_base:get_IsServantOtomo()
    elseif char_type == 5 then      --envcreature
        char.creature = true
    end
    return char
end

local function draw_dummies()
    for shape, pos in pairs(hitboxes.dummy_shapes) do
        if shape == 'Sphere' then
            drawing.sphere(
                pos[1],
                pos[2],
                config.default.color,
                config.default.sphere_show_outline,
                config.default.sphere_show_wireframe
            )
        elseif shape == 'Cylinder' then
            drawing.cylinder(
                pos[1],
                pos[2],
                pos[3],
                config.default.color,
                config.slider_data.cylinder_segments[tostring(config.default.cylinder_segments)],
                true,
                config.default.cylinder_show_outline,
                config.default.cylinder_show_outline_sides
            )
        elseif shape == 'Capsule' then
            if config.default.hitbox_capsule == 1 then
                draw.capsule(
                    pos[1],
                    pos[2],
                    pos[3],
                    config.default.color,
                    config.default.capsule_show_outline
                )
            else
                drawing.capsule(
                    pos[1],
                    pos[2],
                    pos[3],
                    config.default.color,
                    config.slider_data.capsule_segments[tostring(config.default.capsule_segments)],
                    config.default.capsule_show_outline,
                    config.default.capsule_show_outline_spheres
                )
            end
        elseif shape == 'Box' then
            drawing.box(
                pos[1],
                pos[2],
                config.default.color,
                config.default.box_show_outline
            )
        elseif shape == 'Ring' then
            drawing.ring(
                pos[1],
                pos[2],
                pos[3],
                pos[4],
                config.default.color,
                config.slider_data.ring_segments[tostring(config.default.ring_segments)],
                config.default.ring_show_outline,
                config.default.ring_show_outline_sides
            )
        end
    end
end

function hitboxes.get_attacks(args)
    local attack_work = sdk.to_managed_object(args[2])
    local rsc_controller = attack_work:get_RSCCtrl()
    local parent = rsc_controllers[rsc_controller]
    local rs_data = sdk.to_managed_object(args[8])

    if not parent then
        local game_object = rsc_controller:get_GameObject()
        local char_base = misc.get_component(game_object, 'snow.CharacterBase')

        if char_base then
            local char_type = char_base:getCharacterType()
            if char_type == 4 then      --shell
                char_base = char_base:get_OwnerObject()
                char_obj = char_objects[char_base]

                if not char_obj then
                    char_type = char_base:getCharacterType()
                    char_objects[char_base] = get_parent_data(char_type,char_base)
                    parent = char_objects[char_base]
                else
                    parent = char_obj
                end
            else
                char_objects[char_base] = get_parent_data(char_type,char_base)
                rsc_controllers[rsc_controller] = char_objects[char_base]
                parent = char_objects[char_base]
            end
        else
            parent = {}
            parent.props = true
        end
    end

    if (
        parent.player
        and not config.default.ignore_players
        or (
            parent.otomo
            and not config.default.ignore_otomo
        ) or (
              parent.enemy
              and (
                   not config.default.ignore_big_monsters
                   and parent.enemy.boss
                   or (
                       not config.default.ignore_small_monsters
                       and not parent.enemy.boss
                   )
              )
          ) or (
                parent.props
                and not config.default.ignore_props
            ) or (
                  parent.creature
                  and not config.default.ignore_creatures
              )
    ) then
        table.insert(attacks,{
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
    char_objects = {}
    attacks_cache = {}
    hitboxes.dummy_shapes = {}
end

function hitboxes.draw()
    if config.default.enabled then
        draw_dummies()

        for idx, att in pairs(attacks) do
            local phase = att.attack_work:get_Phase()
            if (
                not att.remove
                and (
                    phase == 3
                    or att.attack_work:get_reference_count() == 1
                    or (
                        att.collidables
                        and #att.collidables == 0
                    )
                )
            ) then
                garbage_count = garbage_count + 1
                att.remove = true
                goto continue

            elseif phase == 2 and not att.remove then
                if not att.collidables then
                    att.collidables = {}
                    local attack_data = {}

                    if not config.default.pause_monitor then

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

                        local key = attack_data.parent .. attack_data.id .. attack_data.name
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

                    if config.default['ignore_' .. attack_data.damage_type_name] then
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
                            color=config.default.color,
                            type='hitbox'
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

                        if config.default['ignore_' .. att_cond_name] then
                            goto next
                        end

                        if windbox and config.default.ignore_windbox then
                            goto next
                        end

                        if frontal and config.default.ignore_conditional_hitbox then
                            goto next
                        end


                        if custom_shape ~= 0 then
                            shape_name = data.custom_shape_id[tostring(custom_shape)]
                            col_data.custom_shape_type = custom_shape
                            col_data.userdata = userdata
                            if not misc.table_contains(valid_custom_shapes, custom_shape) then
                                if not misc.table_contains(config.default.missing_custom_shapes, custom_shape) then
                                    table.insert(config.default.missing_custom_shapes, custom_shape)
                                end
                            end
                        else
                            col_data.shape_type = misc.get_shape_type(collidable)
                            shape_name = data.shape_id[tostring(col_data.shape_type)]
                            if not misc.table_contains(valid_shapes, col_data.shape_type) then
                                if not misc.table_contains(config.default.missing_shapes, col_data.shape_type) then
                                    table.insert(config.default.missing_shapes, col_data.shape_type)
                                end
                            end
                        end

                        if not attack_data.cache then
                            attack_data.shape_count = misc.add_count(attack_data.shape_count, shape_name)
                        end

                        if not config.default.use_single_color then
                            if att.parent.prop then
                                col_data.color = config.default.prop_color
                            elseif att.parent.enemy then
                                col_data.color = config.default.monster_color
                            elseif att.parent.player then
                                col_data.color = config.default.player_color
                            elseif att.parent.otomo then
                                col_data.color = config.default.otomo_color
                            elseif att.parent.creature then
                                col_data.color = config.default.creature_color
                            end

                            if windbox and config.default.enable_winbox_color then
                                col_data.color = config.default.windbox_color
                            end

                            if frontal and config.default.enable_conditional_hitbox_color then
                                col_data.color = config.default.conditional_hitbox_color
                            end

                            if attack_data.guardable == 2 and config.default.enable_unguardable_color then
                                col_data.color = config.default.unguardable_color
                            end

                            if att_cond_name and att_cond_name ~= 'None' and config.default['enable_' .. att_cond_name .. '_color'] then
                                col_data.color = config.default[att_cond_name .. '_color']
                            end
                        end

                        table.insert(att.collidables, col_data)
                        drawing.shape(col_data)
                        ::next::
                    end

                    if not config.default.pause_monitor and not attack_data.cache then

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

                        table.insert(data.monitor,1,attack_data)
                        attacks_cache[attack_data.parent .. attack_data.id .. attack_data.name] = attack_data
                    elseif not config.default.pause_monitor and attack_data.cache then
                        table.insert(data.monitor,1,attack_data)
                    end

                    if #data.monitor > 2 * config.max_table_size then
                        misc.table_remove(
                            data.monitor,
                            function(t, i, j)
                                if i > config.default.table_size then
                                    return false
                                else
                                    return true
                                end
                            end
                        )
                    end
                else
                    for _, collidable in pairs(att.collidables) do
                        drawing.shape(collidable)
                    end
                end
            end
            ::continue::
        end

        if garbage_count >= max_garbage then
            misc.table_remove(
                attacks,
                function(t, i, j)
                    if t[i].remove then
                        return false
                    else
                        return true
                    end
                end
            )
            garbage_count = 0
        end
    else
        hitboxes.reset()
    end
end

function hitboxes.init()
    config = require("AHBD.config")
    data = require("AHBD.data")
    misc = require("AHBD.misc")
    drawing = require("AHBD.drawing")
end

return hitboxes