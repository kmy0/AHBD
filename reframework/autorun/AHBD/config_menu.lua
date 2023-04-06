local config_menu = {}

local config
local data
local misc
local dummies
local hurtboxes
local utilities

config_menu.is_opened = false

local window = {
    flags=0,
    pos=Vector2f.new(50, 50),
    pivot=Vector2f.new(0, 0),
    size=Vector2f.new(800, 700),
    condition=1 << 3,
    font=nil
}
local attack_monitor = {
    flags=0,
    pos=Vector2f.new(50, 50),
    pivot=Vector2f.new(0, 0),
    size=Vector2f.new(800, 700),
    condition=1 << 3,
}
local hurtbox_monitor = {
    flags=0,
    pos=Vector2f.new(50, 50),
    pivot=Vector2f.new(0, 0),
    size=Vector2f.new(800, 700),
    condition=1 << 3,
}
local table_ = {
    name='monitor',
    flags=1 << 8|1 << 7|1 << 0|1 << 10|1 << 1|1 << 2|1 << 27|1 << 5|3 << 13,
    col_count=22,
    headers={
        'Row',
        'Parent',
        'Parent ID',
        'Attack Name',
        'Damage Type',
        'Sharpness Type',
        'Power',
        'Motion Value',
        'Element Modifier',
        'Element Value',
        'Element',
        'Debuff Modifier',
        'Debuff Value',
        'Debuff',
        'Hitbox Count',
        'Shapes',
        'Frontal Count',
        'Windbox Count',
        'Condition',
        'Guardable',
        'Start Delay',
        'End Delay',
    },
    header_to_key={
        ['Parent']='parent',
        ['Parent ID']='id',
        ['Attack Name']='name',
        ['Damage Type']='damage_type_name',
        ['Motion Value']='motion_value',
        ['Element Modifier']='ele_mod',
        ['Element']='element',
        ['Element Value']='element_value',
        ['Sharpness Type']='sharpness',
        ['Debuff Modifier']='debuff_mod',
        ['Debuff']='debuff_1',
        ['Debuff Value']='debuff_value',
        ['Hitbox Count']='col_active_count',
        ['Power']='power',
        ['Shapes']='col_shape_count',
        ['Condition']='col_attack_condition_types',
        ['Frontal Count']='col_frontal_count',
        ['Windbox Count']='col_windbox_count',
        ['Guardable']='guardable',
        ['Start Delay']='start_delay',
        ['End Delay']='end_delay',
    }
}
local table_2 = {
    name='h_monitor',
    flags=1 << 8|1 << 7|1 << 0|1 << 10|1 << 1|1 << 2|1 << 27|1 << 5|3 << 13,
    col_count=13,
    headers={
        'Part Name',
        'Visible',
        'Highlight',
        'Hurtbox Count',
        'Shapes',
        'Slash',
        'Strike',
        'Shell',
        'Fire',
        'Water',
        'Ice',
        'Elect',
        'Dragon'
    },
    header_to_key={
        ['Slash']=1,
        ['Strike']=2,
        ['Shell']=3,
        ['Fire']=4,
        ['Water']=5,
        ['Ice']=6,
        ['Elect']=7,
        ['Dragon']=8
    }
}
local spawn_combo = {
    'Sphere',
    'Cylinder',
    'Capsule',
    'Box',
    'Ring',
    'Triangle'
}
local colors = {
    bad=0xff1947ff,
    good=0xff47ff59,
    info=0xff27f3f5
}


local function set_pos(x, y)
    if not y then y = 0 end
    local pos = imgui.get_cursor_pos()
    pos.x = pos.x + x
    pos.y = pos.y + y
    imgui.set_cursor_pos(pos)
end

local function spaced(str, x)
    return string.rep(" ", x) .. str .. string.rep(" ", x)
end

local function set_tooltip(str, add_q)
    if add_q then
        imgui.same_line()
        imgui.text('(?)')
    end
    if imgui.is_item_hovered() then
        imgui.set_tooltip(str)
    end
end

local function popup_yesno(str,key)
    local bool = false
    if imgui.begin_popup(key) then
        imgui.spacing()
        imgui.text(spaced(str, 3 ))
        imgui.spacing()

        if imgui.button(spaced('Yes', 3)) then
            imgui.close_current_popup()
            bool = true
        end

        imgui.same_line()

        if imgui.button(spaced('No', 3)) then
            imgui.close_current_popup()
        end

        imgui.spacing()
        imgui.end_popup()
    end

    return bool
end

local function set_color_w_cb(str,key)
    _, config.current['enable_' .. key] = imgui.checkbox('##' .. str, config.current['enable_' .. key])
    imgui.same_line()

    if not config.current['enable_' .. key] then
        imgui.push_style_var(0, 0.4)
    end

    _, config.current[key] = imgui.color_edit(str, config.current[key])
    if not config.current['enable_' .. key] then
        imgui.pop_style_var()
    end
end

local function create_condition()
    local t = {}
    local key
    for k, _ in pairs(config.current.hitzone_conditions) do
        table.insert(t, tonumber(k))
    end

    if #t ~= 0 then
        table.sort(t)
        key = tostring(t[#t] + 1)
    else
        key = '1'
    end

    config.current.hitzone_conditions[key] = {
        from=0,
        to=0,
        ignore=false,
        type=1,
        color=1020343074
    }

    config.write_hitzone_conditions()
end

local function condition(key)
    local changed
    local save

    changed, config.current.hitzone_conditions[key].ignore = imgui.checkbox(string.format('Ignore Condition %s##ignore_%s', key, key), config.current.hitzone_conditions[key].ignore)
    if changed then save = true end

    imgui.same_line()

    if imgui.button(string.format("%s##remove_%s", spaced('Remove', 3), key)) then
        config.current.hitzone_conditions[key] = nil
        config.write_hitzone_conditions()
        return
    end

    imgui.push_item_width(200)

    changed_s1, config.current.hitzone_conditions[key].from = imgui.slider_int('##from_' .. key, config.current.hitzone_conditions[key].from, 0, 300, 'From ' .. config.current.hitzone_conditions[key].from)
    if changed_s1 then save = true end

    if changed_s1 and config.current.hitzone_conditions[key].from > config.current.hitzone_conditions[key].to then
        config.current.hitzone_conditions[key].to = config.current.hitzone_conditions[key].from
    end

    imgui.same_line()
    changed_s2, config.current.hitzone_conditions[key].to = imgui.slider_int('##to_' .. key, config.current.hitzone_conditions[key].to, 0, 300, 'To ' .. config.current.hitzone_conditions[key].to)
    if changed_s2 then save = true end

    if changed_s2 and config.current.hitzone_conditions[key].to < config.current.hitzone_conditions[key].from  then
        config.current.hitzone_conditions[key].from = config.current.hitzone_conditions[key].to
    end

    imgui.same_line()
    changed, config.current.hitzone_conditions[key].type = imgui.combo('##combo_' .. key, config.current.hitzone_conditions[key].type, data.damage_elements)
    if changed then save = true end

    imgui.pop_item_width()
    imgui.push_item_width(616)

    changed, config.current.hitzone_conditions[key].color = imgui.color_edit('##color' .. key, config.current.hitzone_conditions[key].color)
    if changed then save = true end

    imgui.pop_item_width()
    imgui.separator()

    if save then
        config.write_hitzone_conditions()
    end
end

local function draw_attack_monitor()

    if config.attack_monitor_detach then
        imgui.spacing()
    end

    if imgui.button(spaced('Reset', 3)) then
        data.monitor = {}
    end
    _, config.current.pause_monitor = imgui.checkbox('Pause', config.current.pause_monitor)

    imgui.push_item_width(520)
    _, config.current.table_size = imgui.slider_int('Row Count', config.current.table_size, 10, config.max_table_size)
    imgui.pop_item_width()
    imgui.spacing()

    if imgui.begin_table(table_.name, table_.col_count, table_.flags)then
        local header
        local end_ = config.current.table_size

        if end_ > #data.monitor then
            end_ = #data.monitor
        end

        for i, header in ipairs(table_.headers) do
            imgui.table_setup_column(header)
        end

        imgui.table_headers_row()

        for row=0, end_-1 do

            imgui.table_next_row()

            for col=0, table_.col_count-1 do

                header = table_.headers[col+1]
                imgui.table_set_column_index(col)

                if col == 0 then
                    imgui.text(row+1)
                else
                    if header == 'Attack Name' then
                        imgui.push_font(window.font)
                    end

                    local key = table_.header_to_key[header]
                    local value

                    if misc.starts_with(key, 'col_') then
                        key = string.gsub(key, 'col_', '')
                        value = data.monitor[row+1][2][key]
                    else
                        value = data.monitor[row+1][1][key]
                    end

                    imgui.text(value)

                    if header == 'Attack Name' then
                        imgui.pop_font()
                    end
                end
            end
        end

        imgui.end_table()
    end
end

local function draw_hurtbox_monitor()

    local function sort(t)
        local sorted = {}
        for k, _ in pairs(t) do
            table.insert(sorted, k)
        end

        table.sort(sorted, function(x, y) if x < y then return true else return false end end)

        return sorted
    end

    if config.current.enabled_hurtboxes then
        for i, game_object_name in ipairs(sort(data.hurtbox_monitor)) do

            local monster = data.hurtbox_monitor[game_object_name]
            local in_draw_distance = monster.parent.distance < config.current.draw_distance

            if imgui.tree_node(string.format("%s##%s", monster.real_name, game_object_name)) then
                imgui.spacing()

                set_pos(5)
                imgui.begin_rect()
                imgui.text('In Draw Distance: ')
                imgui.same_line()
                imgui.text_colored(in_draw_distance and 'Yes' or 'No', in_draw_distance and colors.good or colors.bad)
                imgui.text('Distance: ' )
                imgui.same_line()
                imgui.text_colored(string.format("%.3f", monster.parent.distance), colors.info)
                imgui.end_rect(5,10)
                imgui.spacing()

                if imgui.begin_table(table_2.name .. i, table_2.col_count, table_2.flags) then
                    local header = nil
                    local group_names = sort(monster.groups)
                    local part_count = 0

                    for i, header in ipairs(table_2.headers) do
                        imgui.table_setup_column(header)
                    end

                    imgui.table_headers_row()

                    for row=0, #group_names-1 do
                        local shape_count = {}
                        local count = 0
                        local group = monster.groups[group_names[row+1]]
                        local collidables = group.collidables

                        for i, v in pairs(collidables) do
                            if v.remove then
                                collidables[i] = nil
                                goto next
                            end

                            if v.enabled then
                                count = count + 1
                                shape_count = misc.add_count(shape_count, data.shape_id[v.info.shape_type])
                            end

                            ::next::
                        end

                        if count > 0 then
                            imgui.table_next_row()
                            part_count = part_count + 1

                            group.hitzones = {}
                            if monster.parent.hitzones and monster.parent.hitzones[group.meat] then
                                for hitzone, value in ipairs(monster.parent.hitzones[group.meat][group.part_group]) do
                                    group.hitzones[hitzone] = value
                                end
                            end

                            for col=0, table_2.col_count-1 do

                                header = table_2.headers[col+1]
                                imgui.table_set_column_index(col)

                                if header == 'Part Name' then
                                    imgui.push_font(window.font)
                                    imgui.text(group.part_name)
                                    imgui.pop_font()
                                elseif header == 'Visible' then
                                    imgui.spacing()

                                    if not group.visible then

                                        if imgui.button(string.format("%s##1%s%s", spaced('No', 3), game_object_name, row)) then
                                           group.visible = true
                                        end
                                    else
                                        if imgui.button(string.format("%s##1%s%s", spaced('Yes', 3), game_object_name, row)) then
                                            group.visible = false
                                        end
                                    end

                                    imgui.spacing()
                                elseif header == 'Highlight' then
                                    imgui.spacing()

                                    if not group.highlight then
                                        if imgui.button(string.format("%s##2%s%s", spaced('No', 3), game_object_name, row)) then
                                            group.highlight = true
                                        end
                                    else
                                        if imgui.button(string.format("%s##2%s%s", spaced('Yes', 3), game_object_name, row)) then
                                            group.highlight = false
                                        end
                                    end

                                    imgui.spacing()
                                elseif header == 'Hurtbox Count' then
                                    imgui.text(count)
                                elseif header == 'Shapes' then
                                    imgui.text(misc.join_table(shape_count))
                                else
                                    imgui.text(group.hitzones[table_2.header_to_key[header]])
                                end
                            end
                        end
                    end

                    if part_count == 0 and not monster.parent.base:isDispIconMiniMap() then
                        data.hurtbox_monitor[game_object_name] = nil
                    end

                    imgui.end_table()
                end

                imgui.tree_pop()
            end
        end
    end
end

function config_menu.draw()
    if not window.font then
        window.font = imgui.load_font('NotoSansJP-Bold.otf', imgui.get_default_font_size(), {0x1, 0xFFFF, 0})
    end

    imgui.set_next_window_pos(window.pos, window.condition, window.pivot)
    imgui.set_next_window_size(window.size, window.condition)
    imgui.push_style_var(11, 5.0) -- Rounded elements
    imgui.push_style_var(2, 10.0) -- Window Padding

    config_menu.is_opened = imgui.begin_window(string.format("%s %s", config.name, config.version), config_menu.is_opened , window.flags)

    if not config_menu.is_opened then
        imgui.pop_style_var(2)
        imgui.end_window()
        config.save()
        return
    end

    imgui.spacing()
    imgui.indent(10)

    -- local string_1 = table.concat(config.current.missing_shapes, ", ")
    -- local string_2 = table.concat(config.current.missing_custom_shapes, ", ")
    -- if string_1 ~= '' then
    --     imgui.text('Missing Shape Types: ' .. string_1)
    -- end
    -- if string_2 ~= '' then
    --     imgui.text('Missing Custom Shape Types: ' .. string_2)
    -- end

    local changed
    _, config.current.enabled = imgui.checkbox('Draw Hitboxes', config.current.enabled)
    changed, config.current.enabled_hurtboxes = imgui.checkbox('Draw Hurtboxes', config.current.enabled_hurtboxes)

    if changed and config.current.enabled_hurtboxes and utilities.is_in_quest() then
        hurtboxes.get_char_base_in_quest()
    end

    imgui.separator()
    imgui.spacing()
    imgui.unindent(10)

    if imgui.collapsing_header('Hitboxes') then
        imgui.indent(10)
        imgui.spacing()

        imgui.begin_rect()
        _, config.current.ignore_smallenemy = imgui.checkbox('Ignore Small Monsters##1', config.current.ignore_smallenemy)
        _, config.current.ignore_bossenemy = imgui.checkbox('Ignore Big Monsters##2', config.current.ignore_bossenemy)
        _, config.current.ignore_otomo = imgui.checkbox('Ignore Otomo##3', config.current.ignore_otomo)
        _, config.current.ignore_player = imgui.checkbox('Ignore Players##4', config.current.ignore_player)
        _, config.current.ignore_prop = imgui.checkbox('Ignore Props##5', config.current.ignore_prop)
        _, config.current.ignore_creature = imgui.checkbox('Ignore Creatures##6', config.current.ignore_creature)
        imgui.end_rect(5,10)

        imgui.same_line()

        set_pos(5)

        imgui.begin_rect()
        imgui.push_item_width(250)

        if config.current.hitbox_use_single_color then
            imgui.push_style_var(0,0.4)
        end

        _, config.current.smallenemy_color = imgui.color_edit('Small Monsters', config.current.smallenemy_color)
        _, config.current.bossenemy_color = imgui.color_edit('Big Monsters', config.current.bossenemy_color)
        _, config.current.otomo_color = imgui.color_edit('Otomo', config.current.otomo_color)
        _, config.current.player_color = imgui.color_edit('Players', config.current.player_color)
        _, config.current.prop_color = imgui.color_edit('Props', config.current.prop_color)
        _, config.current.creature_color = imgui.color_edit('Creatures', config.current.creature_color)

        if config.current.hitbox_use_single_color then
            imgui.pop_style_var()
        end

        imgui.pop_item_width()
        imgui.end_rect(5,10)

        imgui.spacing()
        imgui.spacing()

        if imgui.tree_node('Conditions') then
            set_tooltip('Condition that has to be satisfied for hit to register\nYou can check those in Attack Monitor', true)
            imgui.spacing()
            imgui.begin_rect()

            _, config.current.ignore_None = imgui.checkbox('Ignore None', config.current.ignore_None)
            _, config.current.ignore_windbox = imgui.checkbox('Ignore Wind Boxes', config.current.ignore_windbox)
            _, config.current.ignore_unguardable = imgui.checkbox('Ignore Unguardable', config.current.ignore_unguardable)
            _, config.current.ignore_frontal = imgui.checkbox('Ignore Frontal', config.current.ignore_frontal)

            for _, k in pairs(data.att_cond_match_hit_attr.sort) do
                _, config.current['ignore_' .. k] = imgui.checkbox('Ignore ' .. k, config.current['ignore_' .. k])
            end

            imgui.end_rect(5,10)
            imgui.same_line()

            if config.current.hitbox_use_single_color then
                imgui.push_style_var(0,0.4)
            end

            set_pos(5)
            imgui.begin_rect()
            imgui.push_item_width(250)
            imgui.invisible_button('',{1, 22})

            set_color_w_cb('Windbox','windbox_color')
            set_color_w_cb('Unguardable','unguardable_color')
            set_color_w_cb('Frontal','frontal_color')

            for _, k in pairs(data.att_cond_match_hit_attr.sort) do
                set_color_w_cb(k ,k .. '_color')
            end

            if config.current.hitbox_use_single_color then
                imgui.pop_style_var()
            end
            imgui.end_rect(5,10)

            imgui.pop_item_width()
            imgui.spacing()
            imgui.tree_pop()
        else
            set_tooltip('Condition that has to be satisfied for hit to register\nYou can check those in Attack Monitor', true)
        end

        if imgui.tree_node('Damage Types') then
            set_tooltip('Damage Type of an attack\nYou can check those in Attack Monitor', true)
            imgui.spacing()
            local count = 0

            imgui.begin_rect()
            for _, k in pairs(data.damage_types.sort) do
                _, config.current['ignore_' .. k] = imgui.checkbox('Ignore ' .. k, config.current['ignore_' .. k])
                count = count + 1
                if count == 11 then
                    imgui.end_rect(5,10)
                    imgui.same_line()
                    set_pos(5)
                    imgui.begin_rect()
                    count = 0
                end
            end

            if count ~= 11 then
                imgui.end_rect(5,10)
            end

            imgui.spacing()
            imgui.tree_pop()
        else
            set_tooltip('Damage Type of an attack\nYou can check those in Attack Monitor', true)
        end

        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end

    if imgui.collapsing_header('Hurtboxes') then
        imgui.indent(10)

        imgui.spacing()

        imgui.begin_rect()
        _, config.current.ignore_hurtbox_smallenemy = imgui.checkbox('Ignore Small Monsters', config.current.ignore_hurtbox_smallenemy)
        _, config.current.ignore_hurtbox_bossenemy = imgui.checkbox('Ignore Big Monsters', config.current.ignore_hurtbox_bossenemy)
        _, config.current.ignore_hurtbox_otomo = imgui.checkbox('Ignore Otomo', config.current.ignore_hurtbox_otomo)
        _, config.current.ignore_hurtbox_masterplayer = imgui.checkbox('Ignore Master Player', config.current.ignore_hurtbox_masterplayer)
        set_tooltip('Thats you', true)
        _, config.current.ignore_hurtbox_player = imgui.checkbox('Ignore Players', config.current.ignore_hurtbox_player)
        _, config.current.ignore_hurtbox_creature = imgui.checkbox('Ignore Creatures', config.current.ignore_hurtbox_creature)
        imgui.end_rect(5,10)

        imgui.same_line()

        set_pos(5)
        imgui.begin_rect()
        imgui.push_item_width(250)

        if config.current.hurtbox_use_single_color then
            imgui.push_style_var(0,0.4)
        end

        _, config.current.hurtbox_smallenemy_color = imgui.color_edit('Small Monsters##2', config.current.hurtbox_smallenemy_color)
        _, config.current.hurtbox_bossenemy_color = imgui.color_edit('Big Monsters##2', config.current.hurtbox_bossenemy_color)
        _, config.current.hurtbox_otomo_color = imgui.color_edit('Otomo##2', config.current.hurtbox_otomo_color)
        _, config.current.hurtbox_masterplayer_color = imgui.color_edit('Master Player##2', config.current.hurtbox_masterplayer_color)
        _, config.current.hurtbox_player_color = imgui.color_edit('Players##2', config.current.hurtbox_player_color)
        _, config.current.hurtbox_creature_color = imgui.color_edit('Creatures##2', config.current.hurtbox_creature_color)

        if config.current.hurtbox_use_single_color then
            imgui.pop_style_var()
        end

        imgui.pop_item_width()
        imgui.end_rect(5,10)

        imgui.spacing()
        imgui.spacing()

        if imgui.tree_node('Hitzone Conditions') then
            if imgui.button(spaced('Create Condition', 3)) then
                create_condition()
            end

            set_tooltip('Changes color or hides hurtboxes if their hitzone value is in from - to range\nIf conditions overlap, whichever gets hit first will apply\n\nCheck order: Exactly as displayed in listbox, Slash->Strike->Shell->etc', true)
            imgui.separator()

            local sorted = {}
            for k, _ in pairs(config.current.hitzone_conditions) do
                table.insert(sorted, k)
            end

            table.sort(sorted, function(x, y) if tonumber(x) > tonumber(y) then return true else return false end end)

            for _, k in ipairs(sorted) do
                condition(k)
            end

            imgui.tree_pop()
        else
            imgui.separator()
        end
        imgui.unindent(10)
        imgui.spacing()
    end

    if imgui.collapsing_header('General Settings') then
        imgui.indent(10)

        imgui.push_item_width(250)
        _, config.current.spawn = imgui.combo('Shape Spawner', config.current.spawn, spawn_combo)
        imgui.pop_item_width()
        imgui.same_line()

        if imgui.button(spaced('Go', 7)) then
            dummies.spawn(spawn_combo[config.current.spawn])
        end

        imgui.same_line()

        if imgui.button(spaced('Clear', 6)) then
            dummies.reset()
        end

        imgui.push_item_width(520)
        set_tooltip('Spawns shape at player position\nWorks in training room and during quests',true)

        _, config.current.draw_distance = imgui.slider_float('Draw Distance', config.current.draw_distance, 0, 10000,  "%.0f")
        _, config.current.show_outline = imgui.checkbox('Show Outline', config.current.show_outline)
        _, config.current.ignore_duplicate_hitboxes = imgui.checkbox('Ignore Duplicate Hitboxes', config.current.ignore_duplicate_hitboxes)
        set_tooltip('Some attacks load the same hitboxes more than once\nYou can ignore them to save on some performance', true)

        if imgui.tree_node('Capsule') then
            _, config.current.capsule_body = imgui.combo('Body', config.current.capsule_body, {'Ellipse', 'Quad'})
            imgui.tree_pop()
        end

        if imgui.tree_node('Colors') then
            _, config.current.outline_color = imgui.color_edit('Outline', config.current.outline_color)
            _, config.current.hitbox_use_single_color = imgui.checkbox('Use Single Color', config.current.hitbox_use_single_color)

            imgui.same_line()

            if imgui.button(spaced('Apply Hitbox Color To All Hitbox Colors', 3)) then
                imgui.open_popup('confirm1')
            end

            if popup_yesno('Are you sure?','confirm1') then
                config.current.bossenemy_color = config.current.color
                config.current.smallenemy_color = config.current.color
                config.current.otomo_color = config.current.color
                config.current.player_color = config.current.color
                config.current.prop_color = config.current.color
                config.current.creature_color = config.current.color
                config.current.windbox_color = config.current.color
                config.current.frontal_color = config.current.color
                config.current.unguardable_color = config.current.color

                for _, k in pairs(data.att_cond_match_hit_attr.sort) do
                    config.current[k .. '_color'] = config.current.color
                end
            end

            if not config.current.hitbox_use_single_color then
                imgui.push_style_var(0,0.4)
            end

            _, config.current.color = imgui.color_edit('Hitbox', config.current.color)

            if not config.current.hitbox_use_single_color then
                imgui.pop_style_var()
            end

            imgui.spacing()
            imgui.spacing()

            _, config.current.hurtbox_use_single_color = imgui.checkbox('Use Single Color##single_2', config.current.hurtbox_use_single_color)

            imgui.same_line()

            if imgui.button(spaced('Apply Hurtbox Color To All Hurtbox Colors', 3)) then
                imgui.open_popup('confirm2')
            end

            if popup_yesno('Are you sure?','confirm2') then
                config.current.hurtbox_bossenemy_color = config.current.hurtbox_color
                config.current.hurtbox_smallenemy_color = config.current.hurtbox_color
                config.current.hurtbox_otomo_color = config.current.hurtbox_color
                config.current.hurtbox_masterplayer_color = config.current.hurtbox_color
                config.current.hurtbox_player_color = config.current.hurtbox_color
                config.current.hurtbox_creature_color = config.current.hurtbox_color
            end

            _, config.current.hurtbox_highlight_color = imgui.color_edit('Hurtbox Highlight', config.current.hurtbox_highlight_color)

            if not config.current.hurtbox_use_single_color then
                imgui.push_style_var(0,0.4)
            end

            _, config.current.hurtbox_color = imgui.color_edit('Hurtbox', config.current.hurtbox_color)

            if not config.current.hurtbox_use_single_color then
                imgui.pop_style_var()
            end

            imgui.tree_pop()
        end

        if imgui.tree_node('Master Player Hurtbox') then
            _, config.current.hide_when_invulnerable = imgui.checkbox('Hide When Invulnerable', config.current.hide_when_invulnerable)
            imgui.tree_pop()
        end

        if imgui.button(spaced('Restore Defaults', 3)) then
            imgui.open_popup('confirm3')
        end

        set_tooltip('Restores all settings to default')

        if popup_yesno('Are you sure?','confirm3') then
            config.restore()
        end

        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end

    if config.attack_monitor_detach then
        attack_monitor.is_opened = imgui.begin_window('Attack Monitor', attack_monitor.is_opened, window.flags)
        imgui.indent(10)
        imgui.spacing()
        draw_attack_monitor()
        imgui.unindent(10)
        imgui.end_window()

        if not attack_monitor.is_opened then
            config.attack_monitor_detach = false
        end
    end

    if imgui.collapsing_header('Attack Monitor') then
        set_tooltip('Information about non ignored attacks that were within draw distance')
        imgui.indent(10)
        imgui.spacing()

        if not config.attack_monitor_detach then

            if imgui.button(spaced('Detach', 3) .. '##det1') then
                config.attack_monitor_detach = true
                attack_monitor.is_opened = true
            end

            draw_attack_monitor()
        else
            imgui.text('Detached')
        end

        imgui.spacing()
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    else
        set_tooltip('Information about non ignored attacks that were within draw distance')
    end

    if config.hurtbox_monitor_detach then
        hurtbox_monitor.is_opened = imgui.begin_window('Hurtbox Monitor', hurtbox_monitor.is_opened, window.flags)
        imgui.indent(10)
        imgui.spacing()
        draw_hurtbox_monitor()
        imgui.unindent(10)
        imgui.end_window()

        if not hurtbox_monitor.is_opened then
            config.hurtbox_monitor_detach = false
        end
    end

    if imgui.collapsing_header('Hurtbox Monitor') then
        set_tooltip('Information about big monster hurtboxes')
        imgui.indent(10)
        imgui.spacing()

        if not config.hurtbox_monitor_detach then

            if imgui.button(spaced('Detach', 3) .. '##det2') then
                config.hurtbox_monitor_detach = true
                hurtbox_monitor.is_opened = true
            end

            draw_hurtbox_monitor()
        else
            imgui.text('Detached')
        end

        imgui.spacing()
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    else
        set_tooltip('Information about big monster hurtboxes')
    end

    imgui.pop_style_var(2)
    imgui.end_window()
end

function config_menu.init()
    config = require("AHBD.config")
    data = require("AHBD.data")
    misc = require("AHBD.misc")
    dummies = require("AHBD.dummies")
    hurtboxes = require("AHBD.hurtboxes")
    utilities = require("AHBD.utilities")
end

return config_menu
