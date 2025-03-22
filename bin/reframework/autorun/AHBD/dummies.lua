local dummies = {}

local config
local utilities
local data
local misc
local drawing

local active_dummies = {}
local dummy_shapes = {
    Sphere={
        pos = Vector3f.new(0, 1, 0),
        radius = 2,
        info = {
            shape_type = 1
        }
    },
    Cylinder={
        pos_a = Vector3f.new(-1, 2, 0),
        pos_b = Vector3f.new(3, 1 ,0),
        radius = 2,
        info = {
            custom_shape_type = 1
        }
    },
    Capsule={
        pos_a = Vector3f.new(-1, 2 ,0),
        pos_b = Vector3f.new(3, 1, 0),
        radius = 2,
        info = {
            shape_type = 3
        }
    },
    Box={
        pos = Vector3f.new(0, 2 ,0),
        extent = Vector3f.new(3, 1, 2),
        rot = Vector3f.new(0, 0, 0),
        info = {
            shape_type = 5
        }
    },
    Ring={
        pos_a = Vector3f.new(-1, 3, 0),
        pos_b = Vector3f.new(1, 1 ,0),
        radius = 4,
        ring_radius = 0.5,
        info = {
            custom_shape_type = 4
        }
    },
    Triangle={
        pos = Vector3f.new(0, 2 ,0),
        extent = Vector3f.new(3, 1, 2),
        rot = Vector3f.new(0, 0, 0),
        info = {
            custom_shape_type = 3
        }
    }
}

function dummies.get()
    for _, col_data in pairs(active_dummies) do

        if (col_data.pos - data.master_player.pos):length() > config.current.draw_distance then
            goto next
        end

        table.insert(drawing.cache, col_data)

        ::next::
    end
end

function dummies.reset()
    active_dummies = {}
end

function dummies.spawn(shape_name)
    local col_data = misc.table_copy(dummy_shapes[shape_name])
    col_data.distance = 0
    col_data.sort = 0
    col_data.info.type = 'dummy'
    col_data.color = config.current.color

    local player_pos = utilities.get_player_pos()

    if player_pos then
        if shape_name == 'Sphere' or shape_name == 'Box' or shape_name == 'Triangle' then
            col_data.pos =  col_data.pos + player_pos
        else
            col_data.pos_a = col_data.pos_a + player_pos
            col_data.pos_b = col_data.pos_b + player_pos
            col_data.pos = (col_data.pos_a + col_data.pos_b) * 0.5
        end

        active_dummies[shape_name] = col_data
    end
end

function dummies.init()
    config = require("AHBD.config")
    utilities = require("AHBD.utilities")
    data = require("AHBD.data")
    misc = require("AHBD.misc")
    drawing = require("AHBD.drawing")
end

return dummies
