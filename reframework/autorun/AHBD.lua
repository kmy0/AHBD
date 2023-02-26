local config = {
    enabled=true,
    ignore_small_monsters=false,
    ignore_big_monsters=false,
    ignore_otomo=false,
    ignore_players=false,
    ignore_props=false,
    ignore_creatures=false,
    ignore_windbox=false,
    ignore_custom_shapes=false,
    use_single_color=false,
    monster_color=1020343074,
    otomo_color=1020343074,
    player_color=1020343074,
    creature_color=1020343074,
    prop_color=1020343074,
    color=1020343074,
    windbox_color=1020343074,
    show_player_hurtbox=true,
    hide_when_invulnerable=false,
    player_hurtbox_color=1020343074,
    conditional_hitbox_colopr=1020343074,
    unguardable_color=1020343074,
    ignore_conditional_hitbox=false,
    ignore_0_mv=false,
    table_size=100,
    missing_shapes={}
}
local version = '1.0.2'
local name = 'AHBD'
local config_path = name .. '/config.json'
local window = {
    flags=0,
    pos=Vector2f.new(50, 50),
    pivot=Vector2f.new(0, 0),
    size=Vector2f.new(500, 600),
    condition=1 << 3,
    is_opened=false
}

local char_objects = {}
local rsc_controllers = {}
local attacks = {}
local damage_types = {
    names={},
    ids={},
    sort={}
}
local guard_id = {
    [0]='Yes',
    [1]='Skill',
    [2]='No'
}
local table_ = {
    name='monitor',
    flags=1 << 9|1 << 8|1 << 7|1 << 0|1 << 10,
    col_count=16,
    headers={
        'Parent',
        'ID',
        'Name',
        'Damage Type',
        'Sharpness Type',
        'Motion Value',
        'Element Modifier',
        'Element Value',
        'Element',
        'Debuff Modifier',
        'Debuff Value',
        'Debuff',
        'Hitbox Count',
        'Guardable',
        'Start Delay',
        'End Delay',
    },
    header_to_key={
        ['Parent']='parent',
        ['ID']='id',
        ['Name']='name',
        ['Damage Type']='damage_type',
        ['Motion Value']='motion_value',
        ['Element Modifier']='ele_mod',
        ['Element']='element',
        ['Element Value']='element_value',
        ['Sharpness Type']='sharpness',
        ['Debuff Modifier']='debuff_mod',
        ['Debuff']='debuff_1',
        ['Debuff Value']='debuff_value',
        ['Hitbox Count']='col_count',
        ['Guardable']='guardable',
        ['Start Delay']='start_delay',
        ['End Delay']='end_delay',
    }
}

local monitor_data = {}
local sharpness_id = {}
local element_id = {}
local debuff_id = {}
local master_player = nil
local player_hurtbox = nil


local function get_fields(type_def, write_to_config, t)
    local damage_type_type_def = sdk.find_type_definition(type_def)
    local fields = damage_type_type_def:get_fields()

    for _, field in pairs(fields) do
        local name = field:get_name()
        local data = field:get_data()
        if name ~= 'Max' and name ~= 'value__' then
            if write_to_config then
                config['ignore_' .. name] = false
                t.names[name] = data
                t.ids[tostring(data)] = name
                table.insert(t.sort,name)
            else
                t[tostring(data)] = name
            end
        end
    end

    if write_to_config then
        table.sort(
            t.sort,
            function(x, y)
                return t.names[x] < t.names[y]
            end
        )
    end
end

local function load_config()
    local loaded_config = json.load_file(config_path)
    if loaded_config then
        for k,v in pairs(loaded_config) do
            config[k] = v
        end
    end
end

local function save_config()
    json.dump_file(config_path, config)
end

local function get_component(game_object, type_name)
    local t = sdk.typeof(type_name)

    if t == nil then
        return nil
    end

    return game_object:call("getComponent(System.Type)", t)
end

local function popup_yesno(str,key)
    local bool = false
    if imgui.begin_popup(key) then
        imgui.spacing()
        imgui.text('   '..str..'   ')
        imgui.spacing()
        if imgui.button('Yes') then
            imgui.close_current_popup()
            bool = true
        end
        imgui.same_line()
        if imgui.button('No') then
            imgui.close_current_popup()
        end
        imgui.spacing()
        imgui.end_popup()
    end
    return bool
end

local function draw_menu()
    imgui.set_next_window_pos(window.pos, window.condition, window.pivot)
    imgui.set_next_window_size(window.size, window.condition)
    imgui.push_style_var(11, 5.0) -- Rounded elements
    imgui.push_style_var(2, 10.0) -- Window Padding

    window.is_opened = imgui.begin_window(name .. " " .. version, window.is_opened, window.flags)

    if not window.is_opened then
        imgui.pop_style_var(2)
        imgui.end_window()
        save_config()
        return
    end

    imgui.spacing()
    imgui.indent(10)

    _, config.enabled = imgui.checkbox('Enabled', config.enabled)
    imgui.separator()
    imgui.spacing()
    imgui.unindent(10)

    if imgui.collapsing_header('Hitboxes') then
        imgui.indent(10)
        _, config.ignore_small_monsters = imgui.checkbox('Ignore Small Monsters', config.ignore_small_monsters)
        _, config.ignore_big_monsters = imgui.checkbox('Ignore Big Monsters', config.ignore_big_monsters)
        _, config.ignore_otomo = imgui.checkbox('Ignore Otomo', config.ignore_otomo)
        _, config.ignore_players = imgui.checkbox('Ignore Players', config.ignore_players)
        _, config.ignore_props = imgui.checkbox('Ignore Props', config.ignore_props)
        _, config.ignore_creatures = imgui.checkbox('Ignore Creatures', config.ignore_creatures)
        _, config.ignore_windbox = imgui.checkbox('Ignore Wind Boxes', config.ignore_windbox)
        _, config.ignore_conditional_hitbox = imgui.checkbox('Ignore Conditional Hitboxes', config.ignore_conditional_hitbox)
        imgui.same_line()
        imgui.text('(?)')
        if imgui.is_item_hovered() then
            imgui.set_tooltip("Those hitboxes either can't interact with the player at all\nor collision has to be registered at certain angle.\nTigrex has a lot of those.")
        end
        _, config.ignore_custom_shapes = imgui.checkbox('Ignore Custom Shapes', config.ignore_custom_shapes)
        imgui.same_line()
        imgui.text('(?)')
        if imgui.is_item_hovered() then
            imgui.set_tooltip('Those hitboxes are very likely to be drawn wrong. E.g. Narwa rings.')
        end
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end

    if imgui.collapsing_header('Damage Types') then
        imgui.indent(10)

        _, config.ignore_0_mv = imgui.checkbox('Ignore 0 MV Attacks', config.ignore_0_mv)
        for _, k in pairs(damage_types.sort) do
            _, config['ignore_' .. k] = imgui.checkbox('Ignore ' .. k, config['ignore_' .. k])
        end

        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end
    if imgui.collapsing_header('Player Hurtbox') then
        imgui.indent(10)
        _, config.show_player_hurtbox = imgui.checkbox('Show Player Hurtbox', config.show_player_hurtbox)
        _, config.hide_when_invulnerable = imgui.checkbox('Hide When Invulnerable', config.hide_when_invulnerable)
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end

    if imgui.collapsing_header('Colors') then
        imgui.indent(10)
        _, config.use_single_color = imgui.checkbox('Use Single Color', config.use_single_color)
        imgui.spacing()
        if config.use_single_color then
            _, config.color = imgui.color_edit('Hitbox Color', config.color)
        else
            if imgui.button('Apply Hitbox Color To All') then
                imgui.open_popup('confirm')
            end
            if popup_yesno('Are you sure?','confirm') then
                config.monster_color = config.color
                config.otomo_color = config.color
                config.player_color = config.color
                config.prop_color = config.color
                config.creature_color = config.color
                config.windbox_color = config.color
                config.conditional_hitbox_color = config.color
                config.unguardable_color = config.color
                config.player_hurtbox_color = config.color
            end
            _, config.monster_color = imgui.color_edit('Monster Color', config.monster_color)
            _, config.otomo_color = imgui.color_edit('Otomo Color', config.otomo_color)
            _, config.player_color = imgui.color_edit('Player Color', config.player_color)
            _, config.prop_color = imgui.color_edit('Prop Color', config.prop_color)
            _, config.creature_color = imgui.color_edit('Creature Color', config.creature_color)
            _, config.windbox_color = imgui.color_edit('Windbox Color', config.windbox_color)
            _, config.conditional_hitbox_color = imgui.color_edit('Conditional Hitbox Color', config.conditional_hitbox_color)
            _, config.unguardable_color = imgui.color_edit('Unguardable Color', config.unguardable_color)
            _, config.player_hurtbox_color = imgui.color_edit('Player Hurtbox Color', config.player_hurtbox_color)
        end
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end

    if imgui.collapsing_header('Attack Monitor') then
        imgui.indent(10)
        _, config.pause_monitor = imgui.checkbox('Pause', config.pause_monitor)
        _, config.table_size = imgui.slider_int('Row Count', config.table_size, 10, 1000)
        if imgui.button('Reset') then
            monitor_data = {}
        end
        imgui.spacing()
        if #monitor_data ==  0 then
            imgui.text('Go attack something')
        end
        if imgui.begin_table(table_.name, table_.col_count, table_.flags) and #monitor_data > 0 then
            local header = nil
            local data = nil
            local end_ = config.table_size
            if end_ > #monitor_data then
                end_ = #monitor_data
            end
            for row=0, end_ do
                if row == 0 then
                    imgui.table_next_row(1)
                else
                    imgui.table_next_row()
                    data = monitor_data[row]
                end
                for col=0, table_.col_count-1 do
                    imgui.table_set_column_index(col)
                    header = table_.headers[col+1]
                    if row == 0 then
                        imgui.text(header)
                    else
                        imgui.text(data[table_.header_to_key[header]])
                    end
                end
            end
            imgui.end_table()
        end
        imgui.spacing()
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end

    imgui.pop_style_var(2)
    imgui.end_window()
end

local function table_remove(t, fn_keep)
    local i, j, n = 1, 1, #t;
    while i <= n do
        if (fn_keep(t, i, j)) then
            local k = i
            repeat
                i = i + 1;
            until i>n or not fn_keep(t, i, j+i-k)
            --if (k ~= j) then
                table.move(t,k,i-1,j);
            --end
            j = j + i - k;
        end
        i = i + 1;
    end
    table.move(t,n+1,n+n-j+1,j);
    return t;
end

local function table_contains(list, x)
    for _, v in pairs(list) do
        if v == x then
            return true
        end
    end
    return false
end

local function get_shape_type(collidable)
    local shape = collidable:get_TransformedShape()
    return shape:get_ShapeType()
end

local function get_player_hurtbox()
    local playman = sdk.get_managed_singleton("snow.player.PlayerManager")
    local master_player = playman:findMasterPlayer()
    if master_player then
        local game_object = master_player:get_GameObject()
        local rscc = get_component(game_object, 'snow.RSCController')
        local collidable = rscc:getCollidable(0, 0, 0)
        local data = {
            col=collidable,
            shape_type=get_shape_type(collidable)
        }
        return master_player,data
    end
    return nil,nil
end

local function draw_shape(collidable)
    if collidable.col:get_Enabled() then
        local shape = collidable.col:get_TransformedShape()
        if shape then
            if collidable.shape_type == 3 then --Capsule
                draw.capsule(
                    shape:get_PosA(),
                    shape:get_PosB(),
                    shape:get_Radius(),
                    collidable.color,
                    true
                )
            elseif collidable.shape_type == 4 then --ContinuousCapsule
                shape = shape:get_Capsule()
                draw.capsule(
                    shape:get_StartPosition(),
                    shape:get_EndPosition(),
                    shape:get_Radius(),
                    collidable.color,
                    true
                )
            elseif collidable.shape_type == 1 or collidable.shape_type == 2 then --Sphere
                if collidable.shape_type == 2 then --ContinuousSphere
                    shape = shape:get_Sphere()
                end
                draw.sphere(
                    shape:get_Center(),
                    shape:get_Radius(),
                    collidable.color,
                    true
                )
            elseif collidable.shape_type == 5 then --Box
                local obb = shape:get_Box()
                local pos = obb:get_Position()
                local extent = obb:get_Extent()
                local min = pos - extent
                local max = pos + extent
                local c1 = draw.world_to_screen(Vector3f.new(min.x, min.y, min.z))
                local c2 = draw.world_to_screen(Vector3f.new(max.x, min.y, min.z))
                local c3 = draw.world_to_screen(Vector3f.new(max.x, max.y, min.z))
                local c4 = draw.world_to_screen(Vector3f.new(min.x, max.y, min.z))
                local c5 = draw.world_to_screen(Vector3f.new(min.x, max.y, max.z))
                local c6 = draw.world_to_screen(Vector3f.new(min.x, min.y, max.z))
                local c7 = draw.world_to_screen(Vector3f.new(max.x, min.y, max.z))
                local c8 = draw.world_to_screen(Vector3f.new(max.x, max.y, max.z))
                if c1 and c2 and c3 and c4 and c5 and c6 and c7 and c8 then
                    draw.filled_quad(c1.x, c1.y, c2.x, c2.y, c3.x, c3.y, c4.x, c4.y, collidable.color)
                    draw.filled_quad(c1.x, c1.y, c4.x, c4.y, c5.x, c5.y, c6.x, c6.y, collidable.color)
                    draw.filled_quad(c1.x, c1.y, c2.x, c2.y, c7.x, c7.y, c6.x, c6.y, collidable.color)
                    draw.filled_quad(c2.x, c2.y, c3.x, c3.y, c8.x, c8.y, c7.x, c7.y, collidable.color)
                    draw.filled_quad(c3.x, c3.y, c4.x, c4.y, c5.x, c5.y, c8.x, c8.y, collidable.color)
                    draw.filled_quad(c5.x, c5.y, c6.x, c6.y, c7.x, c7.y, c8.x, c8.y, collidable.color)
                    draw.outline_quad(c1.x, c1.y, c2.x, c2.y, c3.x, c3.y, c4.x, c4.y, 4278190080)
                    draw.outline_quad(c1.x, c1.y, c4.x, c4.y, c5.x, c5.y, c6.x, c6.y, 4278190080)
                    draw.outline_quad(c1.x, c1.y, c2.x, c2.y, c7.x, c7.y, c6.x, c6.y, 4278190080)
                    draw.outline_quad(c2.x, c2.y, c3.x, c3.y, c8.x, c8.y, c7.x, c7.y, 4278190080)
                    draw.outline_quad(c3.x, c3.y, c4.x, c4.y, c5.x, c5.y, c8.x, c8.y, 4278190080)
                    draw.outline_quad(c5.x, c5.y, c6.x, c6.y, c7.x, c7.y, c8.x, c8.y, 4278190080)
                end
            else
                if not table_contains(config.missing_shapes, collidable.shape_type) then
                    table.insert(config.missing_shapes, collidable.shape_type)
                end
            end
        end
    end
end

local function get_parent_type(char_type,char_base)
    local char = {}
    if char_type == 0 then --player
        char.player = true
        char.id = char_base:getPlayerIndex()
        char.servant = char_base:checkServant(char.id)
    elseif char_type == 1 then --enemy
        char.enemy = {
            boss=char_base:get_isBossEnemy()
        }
        char.id = char_base:get_EnemyType()
    elseif char_type == 2 then --otomo
        char.otomo = true
        local otomo_quest_param = char_base:get_OtQuestParam()
        char.id = otomo_quest_param:get_OtomoID()
        char.servant = char_base:get_IsServantOtomo()
    elseif char_type == 5 then
        char.creature = true
    end
    return char
end


get_fields('snow.hit.SharpnessType', false, sharpness_id)
get_fields('snow.hit.AttackElement', false, element_id)
get_fields('snow.hit.DamageType', true, damage_types)
get_fields('snow.hit.DebuffType', false, debuff_id)
load_config()


sdk.hook(
    sdk.find_type_definition('snow.VillageState'):get_method('.ctor'),
    function()
        attacks = {}
        rsc_controllers = {}
        char_objects = {}
    end
)

sdk.hook(
    sdk.find_type_definition('snow.hit.AttackWork'):get_method('initialize(System.Single, System.Single, System.UInt32, System.UInt32, System.Int32, snow.hit.userdata.BaseHitAttackRSData)'),
    function(args)
        if config.enabled then
            local attack_work = sdk.to_managed_object(args[2])
            local rsc_controller = attack_work:get_RSCCtrl()
            local parent = rsc_controllers[rsc_controller]
            local rs_data = sdk.to_managed_object(args[8])

            if not parent then
                local char = {}
                local game_object = rsc_controller:get_GameObject()
                local char_base = get_component(game_object, 'snow.CharacterBase')

                if char_base then
                    local char_type = char_base:getCharacterType()
                    if char_type == 4 then --shell
                        char_base = char_base:get_OwnerObject()
                        char_obj = char_objects[char_base]

                        if not char_obj then
                            char_type = char_base:getCharacterType()
                            char_objects[char_base] = get_parent_type(char_type,char_base)
                            char = char_objects[char_base]
                        else
                            char = char_obj
                        end
                    else
                        char_objects[char_base] = get_parent_type(char_type,char_base)
                        rsc_controllers[rsc_controller] = char_objects[char_base]
                    end
                else
                    char.props = true
                end
                parent = char
            end

            if (
                parent.player
                and not config.ignore_players
                or (
                    parent.otomo
                    and not config.ignore_otomo
                ) or (
                      parent.enemy
                      and (
                           not config.ignore_big_monsters
                           and parent.enemy.boss
                           or (
                               not config.ignore_small_monsters
                               and not parent.enemy.boss
                           )
                      )
                  ) or (
                        parent.props
                        and not config.ignore_props
                    ) or (
                          parent.creature
                          and not config.ignore_creatures
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
    end
)

re.on_frame(
    function()
        if config.enabled and config.show_player_hurtbox then
            if not player_hurtbox then
                master_player,player_hurtbox = get_player_hurtbox()
            else
                if player_hurtbox.col:get_reference_count() == 1 then
                    master_player,player_hurtbox = nil,nil
                else
                    if not master_player:get_type_definition():is_a("snow.player.PlayerQuestBase") then
                        return
                    end

                    if config.hide_when_invulnerable and master_player:checkMuteki() then
                        return
                    end
                    player_hurtbox.color = config.player_hurtbox_color
                    draw_shape(player_hurtbox)
                end
            end
        else
            master_player,player_hurtbox = nil,nil
        end
    end
)

re.on_frame(
    function()
        if config.enabled then
            for idx, data in pairs(attacks) do
                local phase = data.attack_work:get_Phase()
                if (
                    phase == 3
                    or data.attack_work:get_reference_count() == 1
                    or (
                        data.collidables
                        and #data.collidables == 0
                    )
                ) then
                    attacks[idx] = nil
                    goto continue

                elseif phase == 2 then
                    if not data.collidables then
                        data.collidables = {}
                        local damage = data.rs_data:get_BaseDamage()
                        local damage_type = data.rs_data:get_DamageType()
                        local damage_type_name = damage_types.ids[tostring(damage_type)]

                        if config['ignore_' .. damage_type_name] or config.ignore_0_mv and damage == 0 then
                            goto continue
                        end

                        local guardable = data.rs_data:get_GuardableType()
                        local col_count = data.rsc_controller:getNumCollidables(data.res_idx, data.rs_id)
                        for i=0, col_count-1 do
                            local collidable = data.rsc_controller:getCollidable(data.res_idx, data.rs_id, i)
                            local userdata = collidable:get_UserData()
                            local enemy_hitcheck = userdata._EnemyHitCheckVec == 0
                            local col_data = {
                                col=collidable,
                                color=config.color
                            }

                            if not config.use_single_color then
                                if data.parent.prop then
                                    col_data.color = config.prop_color
                                elseif data.parent.enemy then
                                    col_data.color = config.monster_color
                                elseif data.parent.player then
                                    col_data.color = config.player_color
                                elseif data.parent.otomo then
                                    col_data.color = config.otomo_color
                                elseif data.parent.creature then
                                    col_data.color = config.creature_color
                                end
                            end

                            if userdata:get_type_definition():is_a("snow.hit.userdata.HitAttackAppendShapeData") then
                                if config.ignore_windbox then
                                    goto next
                                else
                                    if not config.use_single_color then
                                        col_data.color = config.windbox_color
                                    end
                                end
                            end

                            if enemy_hitcheck and config.ignore_conditional_hitbox then
                                goto next
                            elseif enemy_hitcheck then
                                if not config.use_single_color then
                                    col_data.color = config.conditional_hitbox_color
                                end
                            end

                            if guardable == 2 and not config.use_single_color then
                                col_data.color = config.unguardable_color
                            end

                            if userdata:get_CustomShapeType() ~= 0 and config.ignore_custom_shapes then
                                goto next
                            else
                                col_data.shape_type = get_shape_type(collidable)
                            end

                            table.insert(data.collidables, col_data)
                            draw_shape(col_data)
                            ::next::
                        end

                        if not config.pause_monitor then

                            local parent_name = ''
                            if data.parent.prop then
                                parent_name = 'Prop'
                            elseif data.parent.enemy then
                                if data.parent.enemy.boss then
                                    parent_name = 'Big Monster'
                                else
                                    parent_name = 'Small Monster'
                                end
                            elseif data.parent.player then
                                if data.parent.servant then
                                    parent_name = 'Servant'
                                else
                                    parent_name = 'Player'
                                end
                            elseif data.parent.otomo then
                                if data.parent.servant then
                                    parent_name = 'OtomoServant'
                                else
                                    parent_name = 'Otomo'
                                end
                            elseif data.parent.creature then
                                parent_name = 'Creature'
                            end

                            local id = data.parent.id
                            local ele_mod = data.rs_data:get_field('<SubRate>k__BackingField')
                            local debuff_mod = data.rs_data:get_field('<DebuffRate>k__BackingField')

                            local attack_data = {
                                parent=parent_name,
                                id=id ~= nil and id or id == nil and 'None',
                                name=data.rs_data:ToString(),
                                ele_mod=ele_mod ~= nil and ele_mod or ele_mod == nil and 'None',
                                debuff_mod=debuff_mod ~= nil and debuff_mod or debuff_mod == nil and 'None',
                                damage_type=damage_type_name,
                                motion_value=damage,
                                element=element_id[tostring(data.rs_data:get_AttackElement())],
                                element_value=data.rs_data:get_AttackElementValue(),
                                debuff_value=data.rs_data:get_DebuffValue(),
                                debuff_1=debuff_id[tostring(data.rs_data:get_DebuffType())],
                                sharpness=sharpness_id[tostring(data.rs_data:get_SharpnessType())],
                                col_count=col_count,
                                guardable=guard_id[guardable],
                                start_delay=data.rs_data:get_HitStartDelay(),
                                end_delay=data.rs_data:get_HitEndDelay()
                            }
                            table.insert(monitor_data,1,attack_data)

                            if #monitor_data > 3 * config.table_size then
                                table_remove(
                                    monitor_data,
                                    function(t, i, j)
                                        if i > config.table_size then
                                            return false
                                        else
                                            return true
                                        end
                                    end
                                )
                            end
                        end

                    else
                        for _, collidable in pairs(data.collidables) do
                            draw_shape(collidable)
                        end
                    end
                end
                ::continue::
            end
        else
            attacks = {}
            rsc_controllers = {}
            char_objects = {}
        end
    end
)

re.on_draw_ui(
    function()
        if imgui.button(name .. " " .. version) then
            window.is_opened = not window.is_opened
        end
    end
)

re.on_frame(
    function()
        if not reframework:is_drawing_ui() then
            window.is_opened = false
        end

        if window.is_opened then
            pcall(draw_menu)
        end
    end
)

re.on_script_reset(save_config)
