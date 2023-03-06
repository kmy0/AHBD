local config = {}

config.default = {
    enabled=true,
    ignore_small_monsters=false,
    ignore_big_monsters=false,
    ignore_otomo=false,
    ignore_players=false,
    ignore_props=false,
    ignore_creatures=false,
    ignore_windbox=false,
    use_single_color=false,
    monster_color=1020343074,
    otomo_color=1020343074,
    player_color=1020343074,
    creature_color=1020343074,
    prop_color=1020343074,
    color=1020343074,
    windbox_color=1020343074,
    outline_color=4278190080,
    enable_windbox_color=true,
    enable_conditional_hitbox_color=true,
    enable_unguardable_color=true,
    show_player_hurtbox=true,
    hide_when_invulnerable=false,
    player_hurtbox_color=1020343074,
    conditional_hitbox_color=1020343074,
    unguardable_color=1020343074,
    ignore_conditional_hitbox=false,
    table_size=25,
    missing_shapes={},
    missing_custom_shapes={},
    ignore_none=false,
    sphere_show_outline=true,
    sphere_show_wireframe=false,
    sphere_wireframe_segments=12,
    cylinder_show_outline=true,
    cylinder_show_outline_sides=true,
    cylinder_segments=12,
    hitbox_capsule=1,
    hurtbox_capsule=2,
    capsule_show_outline=true,
    capsule_show_outline_spheres=true,
    capsule_segments=12,
    box_outline=false,
    ring_segments=12,
    ring_show_outline=true,
    ring_show_sides=true
}
config.version = '1.1.0'
config.name = 'AHBD'
config.config_path = config.name .. '/config.json'
config.max_table_size = 1000
config.slider_data = {}


function config.load()
    local loaded_config = json.load_file(config.config_path)
    if loaded_config then
        for k,v in pairs(loaded_config) do
            config.default[k] = v
        end
    end
end

function config.save()
    json.dump_file(config.config_path, config.default)
end

function config.init()
    for _, v in pairs({'sphere_wireframe_segments', 'cylinder_segments', 'capsule_segments', 'ring_segments'}) do
        config.slider_data[v] = {}
        local c = 6
        for i = 2, 126 do
            if v == 'ring_segments' then
                if i > 3 then
                    config.slider_data[v][tostring(i)] = c
                    c = c + 4
                end
            else
                if i % 2 == 0 then
                     config.slider_data[v][tostring(i)] = i + 2
                else
                     config.slider_data[v][tostring(i)] = i + 1
                end
            end
        end
    end

    config.load()

end

return config
