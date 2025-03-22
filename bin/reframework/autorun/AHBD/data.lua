local data = {}

local config
local misc

data.master_player = {
    obj=nil,
    id=nil,
    pos=Vector3f.new(0, 0, 0)
}
data.valid_shapes = {1, 2, 3, 4, 5}
data.valid_custom_shapes = {0, 1, 3, 4}
data.damage_types = {
    names={},
    ids={},
    sort={}
}
data.att_cond_match_hit_attr = {
    names={None=0},
    ids={[0]='None'},
    sort={},
}
data.guard_id = {
    [0]='Yes',
    [1]='Skill',
    [2]='No'
}
data.damage_elements = {
    'Slash',
    'Strike',
    'Shell',
    'Fire',
    'Water',
    'Ice',
    'Elect',
    'Dragon'
}
data.monitor = {}
data.hurtbox_monitor = {}
data.sharpness_id = {}
data.element_id = {}
data.debuff_id = {}
data.shape_id = {}
data.custom_shape_id = {}
data.char_objects = {}
data.to_update = {}
data.updated = {}
data.monsters = {}


local function get_fields(type_def, write_to_config, t, write_color, ignore)
    local damage_type_type_def = sdk.find_type_definition(type_def)
    local fields = damage_type_type_def:get_fields()

    for _, field in pairs(fields) do
        local name = field:get_name()

        if ignore and misc.table_contains(ignore,name) then
            goto continue
        end

        local data = field:get_data()
        if name ~= 'Max' and name ~= 'value__' then
            if write_to_config then
                config.default['ignore_' .. name] = false

                if write_color then
                    config.default['enable_' .. name .. '_color'] = true

                    if not config.default[name .. '_color'] then
                         config.default[name .. '_color'] = 1020343074
                    end
                end

                t.names[name] = data
                t.ids[data] = name
                table.insert(t.sort,name)
            else
                t[data] = name
            end
        end

        ::continue::
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


function data.init()
    config = require("AHBD.config")
    misc = require("AHBD.misc")

    get_fields('snow.hit.SharpnessType', false, data.sharpness_id)
    get_fields('snow.hit.AttackElement', false, data.element_id)
    get_fields('snow.hit.DamageType', true, data.damage_types)
    get_fields('snow.hit.AttackConditionMatchHitAttr', true, data.att_cond_match_hit_attr, true)
    get_fields('snow.hit.DebuffType', false, data.debuff_id)
    get_fields('via.physics.ShapeType', false, data.shape_id)
    get_fields('snow.hit.CustomShapeType', false, data.custom_shape_id, false, {'None'})
end

return data
