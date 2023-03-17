local config = {}

local misc

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
    big_monster_color=1020343074,
    small_monster_color=1020343074,
    otomo_color=1020343074,
    player_color=1020343074,
    creature_color=1020343074,
    prop_color=1020343074,
    color=1020343074,
    windbox_color=1020382754,
    frontal_color=1023344383,
    HitDuringCantVacuumPlayer_color=1012675641,
    HitDuringWire_color=1015772206,
    HitOnGroundFoEnemy_color=1008906339,
    HitOnGround_color=1013448798,
    HitOnWall_color=1007118233,
    NoHitDuringWire_color=1006632960,
    NoHitInAirForPlayer_color=1012356998,
    enable_windbox_color=true,
    enable_frontal_color=true,
    enable_unguardable_color=true,
    show_player_hurtbox=true,
    hide_when_invulnerable=false,
    player_hurtbox_color=1020343074,
    unguardable_color=1010501306,
    ignore_conditional_hitbox=false,
    table_size=25,
    missing_shapes={},
    missing_custom_shapes={},
    ignore_None=false,
    sphere_show_outline=true,
    cylinder_show_outline=true,
    cylinder_show_outline_sides=true,
    cylinder_segments=12,
    hitbox_capsule=1,
    hurtbox_capsule=1,
    capsule_show_outline=true,
    capsule_show_outline_spheres=true,
    capsule_segments=12,
    box_show_outline=true,
    ring_segments=12,
    ring_show_outline=true,
    ring_show_outline_sides=true,
    draw_distance=100,
    ignore_hurtbox_small_monsters=false,
    ignore_hurtbox_big_monsters=false,
    ignore_hurtbox_otomo=false,
    ignore_hurtbox_master_player=false,
    ignore_hurtbox_players=false,
    ignore_hurtbox_creatures=false,
    enabled_hurtboxes=true,
    hitzone_conditions={},
    ignore_unguardable=false,
    hurtbox_highlight_color=1007405917,
    hurtbox_color=1020343074,
    hurtbox_big_monster_color=1020343074,
    hurtbox_small_monster_color=1020343074,
    hurtbox_otomo_color=1020343074,
    hurtbox_master_player_color=1020343074,
    hurtbox_player_color=1020343074,
    hurtbox_creature_color=1020343074
}
config.current = {}
config.version = '1.1.1'
config.name = 'AHBD'
config.config_path = config.name .. '/config.json'
config.hurtbox_cache_path = config.name .. '/hurtbox_cache.json'
config.max_table_size = 1000
config.outline_color = 4278190080
config.max_updates = 20
config.slider_data = {}
config.raw_hitzone_conditions = {}
config.default_hitzone_conditions = {
    ['1']={
        color=1009176866,
        from=45,
        ignore=false,
        to=300,
        type=1
    }
}


function config.write_hitzone_conditions()
    config.raw_hitzone_conditions = {}
    for i=1, 8 do
        config.raw_hitzone_conditions[i] = {}
    end

    for k, v in pairs(config.current.hitzone_conditions) do
        local t = {
            from=v.from,
            to=v.to,
            color=v.color,
            ignore=v.ignore,
            key=tonumber(k)
        }
        table.insert(config.raw_hitzone_conditions[v.type], t)
    end

    for i=1, 8 do
        table.sort(
            config.raw_hitzone_conditions[i],
            function(x, y)
                if x.key < y.key then
                    return true
                end
            end
        )
    end
end

function config.load()
    local loaded_config = json.load_file(config.config_path)
    if loaded_config then
        config.current = misc.table_merge(config.default, loaded_config)
    else
        config.current = misc.table_deep_copy(config.default)
        config.current.hitzone_conditions = misc.table_deep_copy(config.default_hitzone_conditions)
    end
end

function config.save()
    json.dump_file(config.config_path, config.current)
end

function config.restore()
    config.current = misc.table_deep_copy(config.default)
    config.current.hitzone_conditions = misc.table_deep_copy(config.default_hitzone_conditions)
    config.write_hitzone_conditions()
    config.save()
end

function config.init()
    misc = require("AHBD.misc")

    for _, v in pairs({'cylinder_segments', 'capsule_segments', 'ring_segments'}) do
        config.slider_data[v] = {}
        for i = 2, 126 do
            if i % 2 == 0 then
                 config.slider_data[v][tostring(i)] = i + 2
            else
                 config.slider_data[v][tostring(i)] = i + 1
            end
        end
    end

    config.load()
    config.write_hitzone_conditions()
end

return config
