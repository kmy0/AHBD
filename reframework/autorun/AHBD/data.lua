local data = {}

local config
local misc

data.dummy_shapes = {
    Sphere={Vector3f.new(0, 1, 0), 2},
    Cylinder={Vector3f.new(-1, 2, 0), Vector3f.new(3, 1 ,0), 2},
    Capsule={Vector3f.new(-1, 2 ,0), Vector3f.new(3, 1, 0), 2},
    Box={Vector3f.new(0, 2 ,0), Vector3f.new(3, 1, 2)},
    Ring={Vector3f.new(-1, 3, 0), Vector3f.new(1, 1 ,0), 4, 0.5},
}
data.damage_types = {
    names={},
    ids={},
    sort={}
}
data.att_cond_match_hit_attr = {
    names={None=0},
    ids={['0']='None'},
    sort={},
}
data.guard_id = {
    [0]='Yes',
    [1]='Skill',
    [2]='No'
}
data.monitor = {}
data.sharpness_id = {}
data.element_id = {}
data.debuff_id = {}
data.shape_id = {}
data.custom_shape_id = {}

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
                config['ignore_' .. name] = false

                if write_color then
                    config[name .. '_color'] = 1020343074
                    config['enable_' .. name .. '_color'] = true
                end

                t.names[name] = data
                t.ids[tostring(data)] = name
                table.insert(t.sort,name)
            else
                t[tostring(data)] = name
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