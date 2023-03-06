local config_menu = {}

local config
local data
local misc
local hitboxes

config_menu.is_opened = false

local window = {
    flags=0,
    pos=Vector2f.new(50, 50),
    pivot=Vector2f.new(0, 0),
    size=Vector2f.new(800, 700),
    condition=1 << 3,
    font=nil
}
local table_ = {
    name='monitor',
    flags=1 << 8|1 << 7|1 << 0|1 << 10|1 << 1|1 << 2|1 << 27|1 << 5|3 << 13,
    col_count=22,
    headers={
        'Row',
        'Parent',
        'ID',
        'Name',
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
        ['ID']='id',
        ['Name']='name',
        ['Damage Type']='damage_type_name',
        ['Motion Value']='motion_value',
        ['Element Modifier']='ele_mod',
        ['Element']='element',
        ['Element Value']='element_value',
        ['Sharpness Type']='sharpness',
        ['Debuff Modifier']='debuff_mod',
        ['Debuff']='debuff_1',
        ['Debuff Value']='debuff_value',
        ['Hitbox Count']='col_count',
        ['Power']='power',
        ['Shapes']='shape_count',
        ['Condition']='condition',
        ['Frontal Count']='frontal_count',
        ['Windbox Count']='windbox_count',
        ['Guardable']='guardable',
        ['Start Delay']='start_delay',
        ['End Delay']='end_delay',
    }
}
local spawn_combo = {
    'Sphere',
    'Cylinder',
    'Capsule',
    'Box',
    'Ring'
}
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

local function set_color_w_cb(str,key)
    _, config.default['enable_' .. key] = imgui.checkbox('##' .. str, config.default['enable_' .. key])
    imgui.same_line()
    if not config.default['enable_' .. key] then
        imgui.push_style_var(0,0.4)
    end
    _, config.default[key] = imgui.color_edit(str, config.default[key])
    if not config.default['enable_' .. key] then
        imgui.pop_style_var()
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

    config_menu.is_opened  = imgui.begin_window(config.name .. " " .. config.version, config_menu.is_opened , window.flags)

    if not config_menu.is_opened then
        imgui.pop_style_var(2)
        imgui.end_window()
        config.save()
        return
    end

    imgui.spacing()
    imgui.indent(10)

    local string_1 = table.concat(config.default.missing_shapes, ", ")
    local string_2 = table.concat(config.default.missing_custom_shapes, ", ")
    if string_1 ~= '' then
        imgui.text('Missing Shape Types: ' .. string_)
    end
    if string_2 ~= '' then
        imgui.text('Missing Custom Shape Types: ' .. string_)
    end
    if string_1 ~= '' or string_2 ~= '' then
        set_tooltip('If you see this please leave a comment on Nexus with the numbers so I can add missing shapes')
    end

    _, config.default.enabled = imgui.checkbox('Enabled', config.default.enabled)
    imgui.separator()
    imgui.spacing()
    imgui.unindent(10)

    if imgui.collapsing_header('Hitboxes') then
        imgui.indent(10)
        _, config.default.ignore_small_monsters = imgui.checkbox('Ignore Small Monsters', config.default.ignore_small_monsters)
        _, config.default.ignore_big_monsters = imgui.checkbox('Ignore Big Monsters', config.default.ignore_big_monsters)
        _, config.default.ignore_otomo = imgui.checkbox('Ignore Otomo', config.default.ignore_otomo)
        _, config.default.ignore_players = imgui.checkbox('Ignore Players', config.default.ignore_players)
        _, config.default.ignore_props = imgui.checkbox('Ignore Props', config.default.ignore_props)
        _, config.default.ignore_creatures = imgui.checkbox('Ignore Creatures', config.default.ignore_creatures)
        _, config.default.ignore_windbox = imgui.checkbox('Ignore Wind Boxes', config.default.ignore_windbox)
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end

    if imgui.collapsing_header('Hitbox Conditions') then
        set_tooltip('Condition that has to be satisfied for hit to register')
        imgui.indent(10)

        _, config.default.ignore_conditional_hitbox = imgui.checkbox('Ignore Frontal Hitboxes', config.default.ignore_conditional_hitbox)

        _, config.default.ignore_none = imgui.checkbox('Ignore None', config.default.ignore_none)

        for _, k in pairs(data.att_cond_match_hit_attr.sort) do
            _, config.default['ignore_' .. k] = imgui.checkbox('Ignore ' .. k, config.default['ignore_' .. k])
        end

        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    else
        set_tooltip('Condition that has to be satisfied for hit to register')
    end

    if imgui.collapsing_header('Damage Types') then
        imgui.indent(10)

        for _, k in pairs(data.damage_types.sort) do
            _, config.default['ignore_' .. k] = imgui.checkbox('Ignore ' .. k, config.default['ignore_' .. k])
        end

        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end

    if imgui.collapsing_header('Player Hurtbox') then
        imgui.indent(10)
        _, config.default.show_player_hurtbox = imgui.checkbox('Show Player Hurtbox', config.default.show_player_hurtbox)
        _, config.default.hide_when_invulnerable = imgui.checkbox('Hide When Invulnerable', config.default.hide_when_invulnerable)
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end

    if imgui.collapsing_header('Look And Performance') then
        imgui.indent(10)

        imgui.text('Spawn:')
        imgui.same_line()
        _, config.default.spawn = imgui.combo('', config.default.spawn, spawn_combo)
        imgui.same_line()
        if imgui.button('Go') then
            local shape_name = spawn_combo[config.default.spawn]
            local shape = misc.table_copy(data.dummy_shapes[shape_name])
            local player_pos = misc.get_player_pos()
            if player_pos then
                if shape_name == 'Sphere' or shape_name == 'Box' then
                    shape[1] = shape[1] + player_pos
                else
                    shape[1] = shape[1] + player_pos
                    shape[2] = shape[2] + player_pos
                end
                hitboxes.dummy_shapes[shape_name] = shape
            end
        end
        imgui.same_line()
        if imgui.button('Clear') then
            hitboxes.dummy_shapes = {}
        end
        set_tooltip('Spawns shape at player position',true)

        if imgui.tree_node('Sphere') then
            _, config.default.sphere_show_outline = imgui.checkbox('Show Outline', config.default.sphere_show_outline)
            _, config.default.sphere_show_wireframe = imgui.checkbox('Show Wireframe', config.default.sphere_show_wireframe)
            _, config.default.sphere_wireframe_segments = imgui.slider_int('Wireframe Segments', config.default.sphere_wireframe_segments, 2, 126, config.slider_data.sphere_wireframe_segments[tostring(config.default.sphere_wireframe_segments)])
            set_tooltip('Higher number = more detail, less performance',true)
            imgui.tree_pop()
        end

        if imgui.tree_node('Cylinder') then
            _, config.default.cylinder_show_outline = imgui.checkbox('Show Outline', config.default.cylinder_show_outline)
            _, config.default.cylinder_show_outline_sides = imgui.checkbox('Show Sides Outline', config.default.cylinder_show_outline_sides)
            _, config.default.cylinder_segments = imgui.slider_int('Segments', config.default.cylinder_segments, 2, 126, config.slider_data.cylinder_segments[tostring(config.default.cylinder_segments)])
            set_tooltip('Higher number = more detail, less performance',true)
            imgui.tree_pop()
        end

        if imgui.tree_node('Capsule') then
            _, config.default.hitbox_capsule = imgui.combo('Hitbox Capsule Type', config.default.hitbox_capsule, {'REF Capsule', config.name .. ' Capsule'})
            set_tooltip(config.name .. ' Capsule will absolutely obliterate performance if high number of hitboxes is present', true)
            _, config.default.hurtbox_capsule = imgui.combo('Hurtbox Capsule Type', config.default.hurtbox_capsule, {'REF Capsule', config.name .. ' Capsule'})
            set_tooltip(config.name .. ' Capsule will absolutely obliterate performance if high number of hitboxes is present', true)
            _, config.default.capsule_show_outline = imgui.checkbox('Show Outline', config.default.capsule_show_outline)

            if config.default.hitbox_capsule == 1 and config.default.hurtbox_capsule == 1 then imgui.push_style_var(0,0.4) end
            _, config.default.capsule_show_outline_spheres = imgui.checkbox('Show Spheres Outline', config.default.capsule_show_outline_spheres)
            _, config.default.capsule_segments = imgui.slider_int('Segments', config.default.capsule_segments, 2, 126, config.slider_data.capsule_segments[tostring(config.default.capsule_segments)])
            set_tooltip('Higher number = more detail, less performance',true)
            if config.default.hitbox_capsule == 1 and config.default.hurtbox_capsule == 1 then imgui.pop_style_var() end
            imgui.tree_pop()
        end

        if imgui.tree_node('Box') then
            _, config.default.box_show_outline = imgui.checkbox('Show Outline', config.default.box_show_outline)
            imgui.tree_pop()
        end

        if imgui.tree_node('Ring') then
            _, config.default.ring_show_outline = imgui.checkbox('Show Outline', config.default.ring_show_outline)
            _, config.default.ring_show_outline_sides = imgui.checkbox('Show Sides Outline', config.default.ring_show_outline_sides)
            _, config.default.ring_segments = imgui.slider_int('Segments', config.default.ring_segments, 4, 34, config.slider_data.ring_segments[tostring(config.default.ring_segments)])
            set_tooltip('Higher number = more detail, less performance',true)
            imgui.tree_pop()
        end

        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end

    if imgui.collapsing_header('Colors') then
        imgui.indent(10)

        _, config.default.use_single_color = imgui.checkbox('Use Single Color', config.default.use_single_color)

        imgui.spacing()

        if config.default.use_single_color then
            _, config.default.color = imgui.color_edit('Hitbox', config.default.color)
        end

        _, config.default.outline_color = imgui.color_edit('Outline', config.default.outline_color)

        if not config.default.use_single_color then
            if imgui.button('Apply Hitbox Color To All') then
                imgui.open_popup('confirm')
            end

            if popup_yesno('Are you sure?','confirm') then
                config.default.monster_color = config.default.color
                config.default.otomo_color = config.default.color
                config.default.player_color = config.default.color
                config.default.prop_color = config.default.color
                config.default.creature_color = config.default.color
                config.default.windbox_color = config.default.color
                config.default.conditional_hitbox_color = config.default.color
                config.default.unguardable_color = config.default.color
                config.default.player_hurtbox_color = config.default.color

                for _, k in pairs(data.att_cond_match_hit_attr.sort) do
                    config.default[k .. '_color'] = config.default.color
                end
            end

            _, config.default.monster_color = imgui.color_edit('Monster', config.default.monster_color)
            _, config.default.otomo_color = imgui.color_edit('Otomo', config.default.otomo_color)
            _, config.default.player_color = imgui.color_edit('Player', config.default.player_color)
            _, config.default.prop_color = imgui.color_edit('Prop', config.default.prop_color)
            _, config.default.creature_color = imgui.color_edit('Creature', config.default.creature_color)
            _, config.default.player_hurtbox_color = imgui.color_edit('Player Hurtbox', config.default.player_hurtbox_color)

            imgui.spacing()

            if imgui.tree_node('Conditional Colors') then
                set_color_w_cb('Windbox','windbox_color')
                set_color_w_cb('Unguardable','unguardable_color')
                for _, k in pairs(data.att_cond_match_hit_attr.sort) do
                    set_color_w_cb(k ,k .. '_color')
                end
                imgui.tree_pop()
            end
        end
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end

    if imgui.collapsing_header('Attack Monitor') then
        imgui.indent(10)
        _, config.default.pause_monitor = imgui.checkbox('Pause', config.default.pause_monitor)
        _, config.default.table_size = imgui.slider_int('Row Count', config.default.table_size, 10, config.max_table_size)

        if imgui.button('Reset') then
            data.monitor = {}
        end

        imgui.spacing()

        if #data.monitor == 0 then
            imgui.text('Go attack something')
        end

        if imgui.begin_table(table_.name, table_.col_count, table_.flags) and #data.monitor > 0 then
            local header = nil
            local end_ = config.default.table_size

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
                        if header == 'Name' then
                            imgui.push_font(window.font)
                        end

                        imgui.text(data.monitor[row+1][table_.header_to_key[header]])

                        if header == 'Name' then
                            imgui.pop_font()
                        end
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

function config_menu.init()
    config = require("AHBD.config")
    data = require("AHBD.data")
    misc = require("AHBD.misc")
    hitboxes = require("AHBD.hitboxes")
end

return config_menu