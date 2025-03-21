local config = {}

local misc

config.default = {
    enabled=true,
    enabled_hurtboxes=true,

    ignore_smallenemy=false,
    ignore_bossenemy=false,
    ignore_otomo=false,
    ignore_player=false,
    ignore_prop=false,
    ignore_creature=false,

    bossenemy_color=1020343074,
    smallenemy_color=1020343074,
    otomo_color=1020343074,
    player_color=1020343074,
    creature_color=1020343074,
    prop_color=1020343074,

    ignore_None=false,
    ignore_frontal=false,
    ignore_windbox=false,
    ignore_unguardable=false,
    enable_frontal_color=true,
    enable_windbox_color=true,
    enable_unguardable_color=true,
    frontal_color=1023344383,
    windbox_color=1020382754,
    unguardable_color=1010501306,
    HitDuringCantVacuumPlayer_color=1012675641,
    HitDuringWire_color=1015772206,
    HitOnGroundFoEnemy_color=1008906339,
    HitOnGround_color=1013448798,
    HitOnWall_color=1007118233,
    NoHitDuringWire_color=1006632960,
    NoHitInAirForPlayer_color=1012356998,
    HitFloatingPlayer_color=1011830610,

    ignore_hurtbox_smallenemy=false,
    ignore_hurtbox_bossenemy=false,
    ignore_hurtbox_otomo=false,
    ignore_hurtbox_masterplayer=false,
    ignore_hurtbox_player=false,
    ignore_hurtbox_creature=false,

    hurtbox_bossenemy_color=1020343074,
    hurtbox_smallenemy_color=1020343074,
    hurtbox_otomo_color=1020343074,
    hurtbox_masterplayer_color=1020343074,
    hurtbox_player_color=1020343074,
    hurtbox_creature_color=1020343074,

    draw_distance=100,
    ignore_duplicate_hitboxes=false,
    show_outline=true,
    hitbox_use_single_color=false,
    hurtbox_use_single_color=false,
    color=1020343074,
    hurtbox_color=1020343074,
    outline_color=4278190080,
    hurtbox_highlight_color=1021633775,
    show_player_hurtbox=true,
    hide_when_invulnerable=false,

    table_size=25,
    hitzone_conditions={}
}
config.current = {}
config.version = '1.1.5'
config.name = 'AHBD'
config.config_path = config.name .. '/config.json'
config.max_table_size = 1000
config.max_updates = 3
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

    config.load()
    config.write_hitzone_conditions()
end

return config
