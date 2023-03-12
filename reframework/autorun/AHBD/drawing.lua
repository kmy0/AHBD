local drawing = {}

local config
local utilities

local sin_cache = {}
local cos_cache = {}
local corners = {}
local prev_corners = {}
local last_corners = {}


function get_sin(angle)
    if sin_cache[angle] then
        return sin_cache[angle]
    end

    local value = math.sin(angle)
    sin_cache[angle] = value
    return value
end

function get_cos(angle)
    if cos_cache[angle] then
        return cos_cache[angle]
    end

    local value = math.cos(angle)
    cos_cache[angle] = value
    return value
end


function drawing.box(pos, extent, color, outline)
    local min = pos - extent
    local max = pos + extent
    local corners = {}

    corners[1] = Vector3f.new(min.x, min.y, min.z)
    corners[2] = Vector3f.new(max.x, min.y, min.z)
    corners[3] = Vector3f.new(max.x, max.y, min.z)
    corners[4] = Vector3f.new(min.x, max.y, min.z)
    corners[5] = Vector3f.new(min.x, max.y, max.z)
    corners[6] = Vector3f.new(min.x, min.y, max.z)
    corners[7] = Vector3f.new(max.x, min.y, max.z)
    corners[8] = Vector3f.new(max.x, max.y, max.z)

    for i, corner in ipairs(corners) do
        corners[i] = draw.world_to_screen(corner)
        if not corners[i] then
            return
        end
    end

    draw.filled_quad(
        corners[1].x, corners[1].y,
        corners[2].x, corners[2].y,
        corners[3].x, corners[3].y,
        corners[4].x, corners[4].y,
        color
    )
    draw.filled_quad(
        corners[1].x, corners[1].y,
        corners[4].x, corners[4].y,
        corners[5].x, corners[5].y,
        corners[6].x, corners[6].y,
        color
    )
    draw.filled_quad(
        corners[1].x, corners[1].y,
        corners[2].x, corners[2].y,
        corners[7].x, corners[7].y,
        corners[6].x, corners[6].y,
        color
    )
    draw.filled_quad(
        corners[2].x, corners[2].y,
        corners[3].x, corners[3].y,
        corners[8].x, corners[8].y,
        corners[7].x, corners[7].y,
        color
    )
    draw.filled_quad(
        corners[3].x, corners[3].y,
        corners[4].x, corners[4].y,
        corners[5].x, corners[5].y,
        corners[8].x, corners[8].y,
        color
    )
    draw.filled_quad(
        corners[5].x, corners[5].y,
        corners[6].x, corners[6].y,
        corners[7].x, corners[7].y,
        corners[8].x, corners[8].y,
        color
    )

    if outline then
        -- draw.outline_quad(
        --     corners[1].x, corners[1].y,
        --     corners[2].x, corners[2].y,
        --     corners[3].x, corners[3].y,
        --     corners[4].x, corners[4].y,
        --     config.outline_color
        -- )
        draw.outline_quad(
            corners[1].x, corners[1].y,
            corners[4].x, corners[4].y,
            corners[5].x, corners[5].y,
            corners[6].x, corners[6].y,
            config.outline_color
        )
        draw.outline_quad(
            corners[1].x, corners[1].y,
            corners[2].x, corners[2].y,
            corners[7].x, corners[7].y,
            corners[6].x, corners[6].y,
            config.outline_color
        )
        draw.outline_quad(
            corners[2].x, corners[2].y,
            corners[3].x, corners[3].y,
            corners[8].x, corners[8].y,
            corners[7].x, corners[7].y,
            config.outline_color
        )
        draw.outline_quad(
            corners[3].x, corners[3].y,
            corners[4].x, corners[4].y,
            corners[5].x, corners[5].y,
            corners[8].x, corners[8].y,
            config.outline_color
        )
        -- draw.outline_quad(
        --     corners[5].x, corners[5].y,
        --     corners[6].x, corners[6].y,
        --     corners[7].x, corners[7].y,
        --     corners[8].x, corners[8].y,
        --     config.outline_color
        -- )
    end
end

function drawing.cylinder(start_pos, end_pos, radius, color, segments, sides, outline, outline_sides, ring)
    local dir = end_pos - start_pos
    local up = dir:cross(Vector3f.new(0, 1, 0))

    if up:length() < 0.0001 then
        up = dir:cross(Vector3f.new(1, 0, 0))
    end

    local right = dir:cross(up)
    local angle_increment = math.pi*2/segments
    local corners_cache = {}

    up:normalize()
    right:normalize()
    up = up * radius
    right = right * radius

    local function get_rotated_pos(angle)
        local cos = right * get_cos(angle)
        local sin = up * get_sin(angle)
        return draw.world_to_screen(start_pos + cos + sin), draw.world_to_screen(end_pos + cos + sin)
    end

    for i=0, segments-1 do

        if i == 0 then
            corners[1], corners[4] = get_rotated_pos(i*angle_increment)
            last_corners[1] = corners[1]
            last_corners[2] = corners[4]
        else
            corners[1] = prev_corners[1]
            corners[4] = prev_corners[2]
        end

        if i ~= segments-1 then
            corners[2], corners[3] = get_rotated_pos((i+1)*angle_increment)
            prev_corners[1] = corners[2]
            prev_corners[2] = corners[3]
        else
            corners[2] = last_corners[1]
            corners[3] = last_corners[2]
        end

        if (
            not corners[1]
            or not corners[2]
            or not corners[3]
            or not corners[4]
        ) then
            return
        end

        if ring or sides then
            corners_cache[i] = {
                corners[1],
                corners[2],
                corners[3],
                corners[4]
            }
        end

        draw.filled_quad(
            corners[1].x, corners[1].y,
            corners[2].x, corners[2].y,
            corners[3].x, corners[3].y,
            corners[4].x, corners[4].y,
            color
        )

        if outline then
            draw.outline_quad(
                corners[1].x, corners[1].y,
                corners[2].x, corners[2].y,
                corners[3].x, corners[3].y,
                corners[4].x, corners[4].y,
                config.outline_color
            )
        end
    end

    if sides then
        for i=0, segments/2-1 do
            local corners_1 = corners_cache[i]
            local corners_2 = corners_cache[segments-1 - i]

            draw.filled_quad(
                corners_1[1].x, corners_1[1].y,
                corners_1[2].x, corners_1[2].y,
                corners_2[1].x, corners_2[1].y,
                corners_2[2].x, corners_2[2].y,
                color
            )
            draw.filled_quad(
                corners_1[3].x, corners_1[3].y,
                corners_1[4].x, corners_1[4].y,
                corners_2[3].x, corners_2[3].y,
                corners_2[4].x, corners_2[4].y,
                color
            )

            if outline_sides then
                draw.outline_quad(
                    corners_1[1].x, corners_1[1].y,
                    corners_1[2].x, corners_1[2].y,
                    corners_2[1].x, corners_2[1].y,
                    corners_2[2].x, corners_2[2].y,
                    config.outline_color
                )
                draw.outline_quad(
                    corners_1[3].x, corners_1[3].y,
                    corners_1[4].x, corners_1[4].y,
                    corners_2[3].x, corners_2[3].y,
                    corners_2[4].x, corners_2[4].y,
                    config.outline_color
                )
            end
        end
    end

    return corners_cache
end

function drawing.capsule(pa, pb, r, color, segments, outline, outline_sphere)
    draw.sphere(pa, r, color, outline_sphere)
    draw.sphere(pb, r, color, outline_sphere)
    drawing.cylinder(pa, pb, r, color, segments, false, outline)
end

function drawing.ring(pa, pb, ra, rb, color, segments, outline, outline_sides)
    rb = rb - ra
    outer_cylinder = drawing.cylinder(pa, pb, ra, color, segments, false, outline, false, true)
    inner_cylinder = drawing.cylinder(pa, pb, rb, color, segments, false, outline, false, true)

    if outer_cylinder and inner_cylinder then
        for i=0, segments-1 do
            if i == 0 then
                j = segments / 2
            elseif i == segments / 2 then
                j = 0
            elseif  i < segments / 2 then
                j = segments / 2 + i
            else
                j = i - (segments / 2)
            end

            local corners_1 = outer_cylinder[i]
            local corners_2 = inner_cylinder[j]

            draw.filled_quad(
                corners_1[3].x, corners_1[3].y,
                corners_1[4].x, corners_1[4].y,
                corners_2[4].x, corners_2[4].y,
                corners_2[3].x, corners_2[3].y,
                color
            )
            draw.filled_quad(
                corners_1[1].x, corners_1[1].y,
                corners_1[2].x, corners_1[2].y,
                corners_2[2].x, corners_2[2].y,
                corners_2[1].x, corners_2[1].y,
                color
            )

            if outline_sides then
                draw.outline_quad(
                    corners_1[3].x, corners_1[3].y,
                    corners_1[4].x, corners_1[4].y,
                    corners_2[4].x, corners_2[4].y,
                    corners_2[3].x, corners_2[3].y,
                    config.outline_color
                )
                draw.outline_quad(
                    corners_1[1].x, corners_1[1].y,
                    corners_1[2].x, corners_1[2].y,
                    corners_2[2].x, corners_2[2].y,
                    corners_2[1].x, corners_2[1].y,
                    config.outline_color
                )
            end
        end
    end
end

function drawing.shape(collidable)
    if collidable.col:get_Enabled() then
        local shape = collidable.col:get_TransformedShape()
        if shape then
            if collidable.shape_type then
                if collidable.shape_type == 3 or collidable.shape_type == 4 then --Capsule
                    local pos_a
                    local pos_b

                    if collidable.shape_type == 4 then --ContinuousCapsule
                        shape = shape:get_Capsule()
                        pos_a = shape:get_StartPosition()
                        pos_b = shape:get_EndPosition()
                    else
                        pos_a = shape:get_PosA()
                        pos_b = shape:get_PosB()
                    end

                    if (
                        config.current.hitbox_capsule == 1
                        and collidable.type == 'hitbox'
                        or (
                            config.current.hurtbox_capsule == 1
                            and collidable.type == 'hurtbox')
                    ) then
                        draw.capsule(
                            pos_a,
                            pos_b,
                            shape:get_Radius(),
                            collidable.color,
                            true
                        )
                    else
                        drawing.capsule(
                            pos_a,
                            pos_b,
                            shape:get_Radius(),
                            collidable.color,
                            config.slider_data.capsule_segments[tostring(config.current.capsule_segments)],
                            config.current.capsule_show_outline,
                            config.current.capsule_show_outline_spheres
                        )
                    end
                elseif collidable.shape_type == 1 or collidable.shape_type == 2 then --Sphere
                    if collidable.shape_type == 2 then --ContinuousSphere
                        shape = shape:get_Sphere()
                    end
                    draw.sphere(
                        shape:get_Center(),
                        shape:get_Radius(),
                        collidable.color,
                        config.current.sphere_show_outline
                    )
                elseif collidable.shape_type == 5 then --Box
                    local obb = shape:get_Box()
                    drawing.box(
                        obb:get_Position(),
                        obb:get_Extent(),
                        collidable.color,
                        config.current.box_show_outline
                    )
                end
            else
                if collidable.custom_shape_type == 1 then --Cylinder
                    drawing.cylinder(
                        shape:get_PosA(),
                        shape:get_PosB(),
                        shape:get_Radius(),
                        collidable.color,
                        config.slider_data.cylinder_segments[tostring(config.current.cylinder_segments)],
                        true,
                        config.current.cylinder_show_outline,
                        config.current.cylinder_show_outline_sides
                    )
                elseif collidable.custom_shape_type == 4 then --Donut
                    drawing.ring(
                        shape:get_PosA(),
                        shape:get_PosB(),
                        shape:get_Radius(),
                        collidable.userdata:get_RingRadius(),
                        collidable.color,
                        config.slider_data.ring_segments[tostring(config.current.ring_segments)],
                        config.current.ring_show_outline,
                        config.current.ring_show_outline_sides
                    )
                end
            end
        end
    end
end

function drawing.init()
    config = require("AHBD.config")
    utilities = require("AHBD.utilities")
end

return drawing
