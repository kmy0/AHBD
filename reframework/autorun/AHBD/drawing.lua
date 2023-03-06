local drawing = {}

local config
local misc

function drawing.box(pos, extent, color, outline)
    local min = pos - extent
    local max = pos + extent
    local corners = {}
    local corners_positions = {}

    corners[1] = Vector3f.new(min.x, min.y, min.z)
    corners[2] = Vector3f.new(max.x, min.y, min.z)
    corners[3] = Vector3f.new(max.x, max.y, min.z)
    corners[4] = Vector3f.new(min.x, max.y, min.z)
    corners[5] = Vector3f.new(min.x, max.y, max.z)
    corners[6] = Vector3f.new(min.x, min.y, max.z)
    corners[7] = Vector3f.new(max.x, min.y, max.z)
    corners[8] = Vector3f.new(max.x, max.y, max.z)

    local screen_corners = {}
    for i, corner in ipairs(corners) do
        local key = corner.x .. corner.y .. corner.z
        if not corners_positions[key] then
            local screen_pos = draw.world_to_screen(corner)
            if not screen_pos then
                return
            end
            corners[i] = screen_pos
            corners_positions[key] = screen_pos
        else
            corners[i] = corners_positions[key]
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
        --     config.default.outline_color
        -- )
        draw.outline_quad(
            corners[1].x, corners[1].y,
            corners[4].x, corners[4].y,
            corners[5].x, corners[5].y,
            corners[6].x, corners[6].y,
            config.default.outline_color
        )
        draw.outline_quad(
            corners[1].x, corners[1].y,
            corners[2].x, corners[2].y,
            corners[7].x, corners[7].y,
            corners[6].x, corners[6].y,
            config.default.outline_color
        )
        draw.outline_quad(
            corners[2].x, corners[2].y,
            corners[3].x, corners[3].y,
            corners[8].x, corners[8].y,
            corners[7].x, corners[7].y,
            config.default.outline_color
        )
        draw.outline_quad(
            corners[3].x, corners[3].y,
            corners[4].x, corners[4].y,
            corners[5].x, corners[5].y,
            corners[8].x, corners[8].y,
            config.default.outline_color
        )
        -- draw.outline_quad(
        --     corners[5].x, corners[5].y,
        --     corners[6].x, corners[6].y,
        --     corners[7].x, corners[7].y,
        --     corners[8].x, corners[8].y,
        --     config.default.outline_color
        -- )
    end
end

-- standard reframework draw sphere function + wireframe
function drawing.sphere(center, radius, color, outline, wireframe)
    local camera_up = misc.get_camera_up()

    if not camera_up then return end

    local screen_pos_center = draw.world_to_screen(center)

    if screen_pos_center then
        local pos_top = center + (camera_up:normalized() * radius)
        local screen_pos_top = draw.world_to_screen(pos_top)

        if screen_pos_top then
            local radius2d = (screen_pos_top - screen_pos_center):length()

            draw.filled_circle(screen_pos_center.x, screen_pos_center.y, radius2d, color, 32)

            if outline then
                draw.outline_circle(screen_pos_center.x, screen_pos_center.y, radius2d, config.default.outline_color, 32)
            end

            if wireframe then
                local segments = config.slider_data.sphere_wireframe_segments[tostring(config.default.sphere_wireframe_segments)]
                local x = screen_pos_center.x
                local y = screen_pos_center.y
                local step = math.pi * 2 / segments

                local sins = {}
                local cosins = {}

                for i = 0, segments - 1 do
                    sins[i] = math.sin(i * step)
                    cosins[i] = math.cos(i * step)
                end

                for i = 0, segments - 1 do
                    sins[i] = math.sin(i * step)
                    cosins[i] = math.cos(i * step)
                    local sin_angle1 = sins[i]

                    for j = 0, segments - 1 do
                        local cos_angle2 = cosins[j]
                        local sin_angle2 = math.sin(j * step)
                        local px = x + sin_angle1 * cos_angle2 * radius2d
                        local py = y + sin_angle2 * radius2d
                        local screen_x = px
                        local screen_y = py

                        if i > segments / 2 then
                            local prev_px = x + sins[i-1] * cos_angle2 * radius2d
                            local prev_py = y + sin_angle2 * radius2d
                            local prev_screen_x = prev_px
                            local prev_screen_y = prev_py
                            draw.line(screen_x, screen_y, prev_screen_x, prev_screen_y, config.default.outline_color)
                        end

                        if j > 0 then
                            local prev_px = x + sin_angle1 * cosins[j-1] * radius2d
                            local prev_py = y + math.sin((j-1) * step) * radius2d
                            local prev_screen_x = prev_px
                            local prev_screen_y = prev_py
                            draw.line(screen_x, screen_y, prev_screen_x, prev_screen_y, config.default.outline_color)
                        end
                    end
                end
            end
        end
    end
end

function drawing.cylinder(start_pos, end_pos, radius, color, segments, sides, outline, outline_sides)
    local dir = (end_pos - start_pos):normalized()
    local up = dir:cross(Vector3f.new(0, 1, 0)):normalized()
    local right = dir:cross(up):normalized()
    local angle_increment = math.pi*2/segments
    local corners = {}
    local corners_bank = {}
    local corners_positions = {}
    local sin = {}
    local cos = {}

    for i = 0, segments/2 do
        local angle = i*angle_increment
        cos[i] = right*radius*math.cos(angle)
        cos[segments - i] = cos[i]
        sin[i] = up*radius*math.sin(angle)
        sin[segments - i] = sin[i]
    end

    for i = 0, segments-1,2 do
        corners[1] = start_pos + cos[i] + sin[i]
        corners[2] = start_pos + cos[i+1] + sin[i+1]
        corners[3] = start_pos + cos[i+1] - sin[i+1]
        corners[4] = start_pos + cos[i] - sin[i]

        corners[5] = end_pos + cos[i] + sin[i]
        corners[6] = end_pos + cos[i+1] + sin[i+1]
        corners[7] = end_pos + cos[i+1] - sin[i+1]
        corners[8] = end_pos + cos[i] - sin[i]

        for j = 1, 8 do
            local key = corners[j].x .. corners[j].y .. corners[j].z
            if not corners_positions[key] then
                corners[j] = draw.world_to_screen(corners[j])
                corners_positions[key] = corners[j]
            else
                corners[j] = corners_positions[key]
            end
            if not corners[j] then return end
        end

        corners_bank[tostring(i)] = {
            corners[1],
            corners[2],
            corners[3],
            corners[4],
            corners[5],
            corners[6],
            corners[7],
            corners[8]
        }

        --draw top face
        draw.filled_quad(
            corners[1].x, corners[1].y,
            corners[2].x, corners[2].y,
            corners[6].x, corners[6].y,
            corners[5].x, corners[5].y,
            color
        )
        -- draw bottom face
        draw.filled_quad(
            corners[4].x, corners[4].y,
            corners[3].x, corners[3].y,
            corners[7].x, corners[7].y,
            corners[8].x, corners[8].y,
            color
        )

        if outline then
            draw.outline_quad(
                corners[1].x, corners[1].y,
                corners[2].x, corners[2].y,
                corners[6].x, corners[6].y,
                corners[5].x, corners[5].y,
                config.default.outline_color
            )
            draw.outline_quad(
                corners[4].x, corners[4].y,
                corners[3].x, corners[3].y,
                corners[7].x, corners[7].y,
                corners[8].x, corners[8].y,
                config.default.outline_color
            )
        end

        -- draw side faces
        if sides then
            draw.filled_quad(
                corners[1].x, corners[1].y,
                corners[2].x, corners[2].y,
                corners[3].x, corners[3].y,
                corners[4].x, corners[4].y,
                color
            )
            draw.filled_quad(
                corners[5].x, corners[5].y,
                corners[6].x, corners[6].y,
                corners[7].x, corners[7].y,
                corners[8].x, corners[8].y,
                color
            )

            if outline_sides then
                draw.outline_quad(
                    corners[1].x, corners[1].y,
                    corners[2].x, corners[2].y,
                    corners[3].x, corners[3].y,
                    corners[4].x, corners[4].y,
                    config.default.outline_color
                )
                draw.outline_quad(
                    corners[5].x, corners[5].y,
                    corners[6].x, corners[6].y,
                    corners[7].x, corners[7].y,
                    corners[8].x, corners[8].y,
                    config.default.outline_color
                )
            end
        end
    end
    return corners_bank
end

function drawing.capsule(pa, pb, r, color, segments, outline, outline_sphere)
    drawing.sphere(pa, r, color, outline_sphere)
    drawing.sphere(pb, r, color, outline_sphere)
    drawing.cylinder(pa, pb, r, color, segments, sides, outline)
end

function drawing.ring(pa, pb, ra, rb, color, segments, outline, outline_sides)
    rb = rb - ra
    outer_cylinder = drawing.cylinder(pa, pb, ra, color, segments, false, outline)
    inner_cylinder = drawing.cylinder(pa, pb, rb, color, segments, false, outline)

    if outer_cylinder and inner_cylinder then
        for i,outer_walls in pairs(outer_cylinder) do
            i = tonumber(i)
            if i <= (segments - 1) / 2 then
                inner_walls = inner_cylinder[tostring(-i + (segments - 2) // 2 )]
            else
                inner_walls = inner_cylinder[tostring(-i + segments + (segments - 2) // 2)]
            end

            draw.filled_quad(
                outer_walls[3].x, outer_walls[3].y,
                outer_walls[4].x, outer_walls[4].y,
                inner_walls[2].x, inner_walls[2].y,
                inner_walls[1].x, inner_walls[1].y,
                color
            )
            draw.filled_quad(
                inner_walls[3].x, inner_walls[3].y,
                inner_walls[4].x, inner_walls[4].y,
                outer_walls[2].x, outer_walls[2].y,
                outer_walls[1].x, outer_walls[1].y,
                color
            )

            draw.filled_quad(
                outer_walls[5].x, outer_walls[5].y,
                outer_walls[6].x, outer_walls[6].y,
                inner_walls[8].x, inner_walls[8].y,
                inner_walls[7].x, inner_walls[7].y,
                color
            )

            draw.filled_quad(
                inner_walls[5].x, inner_walls[5].y,
                inner_walls[6].x, inner_walls[6].y,
                outer_walls[8].x, outer_walls[8].y,
                outer_walls[7].x, outer_walls[7].y,
                color
            )

            if outline_sides then
                draw.outline_quad(
                    outer_walls[3].x, outer_walls[3].y,
                    outer_walls[4].x, outer_walls[4].y,
                    inner_walls[2].x, inner_walls[2].y,
                    inner_walls[1].x, inner_walls[1].y,
                    config.default.outline_color
                )
                draw.outline_quad(
                    inner_walls[3].x, inner_walls[3].y,
                    inner_walls[4].x, inner_walls[4].y,
                    outer_walls[2].x, outer_walls[2].y,
                    outer_walls[1].x, outer_walls[1].y,
                    config.default.outline_color
                )
                draw.outline_quad(
                    outer_walls[5].x, outer_walls[5].y,
                    outer_walls[6].x, outer_walls[6].y,
                    inner_walls[8].x, inner_walls[8].y,
                    inner_walls[7].x, inner_walls[7].y,
                    config.default.outline_color
                )

                draw.outline_quad(
                    inner_walls[5].x, inner_walls[5].y,
                    inner_walls[6].x, inner_walls[6].y,
                    outer_walls[8].x, outer_walls[8].y,
                    outer_walls[7].x, outer_walls[7].y,
                    config.default.outline_color
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
                        config.default.hitbox_capsule == 1
                        and collidable.type == 'hitbox'
                        or (
                            config.default.hurtbox_capsule == 1
                            and collidable.type == 'hurtbox')
                    ) then
                        draw.capsule(
                            pos_a,
                            pos_b,
                            shape:get_Radius(),
                            config.default.color,
                            config.default.capsule_show_outline
                        )
                    else
                        drawing.capsule(
                            pos_a,
                            pos_b,
                            shape:get_Radius(),
                            config.default.color,
                            config.slider_data.capsule_segments[tostring(config.default.capsule_segments)],
                            config.default.capsule_show_outline,
                            config.default.capsule_show_outline_spheres
                        )
                    end
                elseif collidable.shape_type == 1 or collidable.shape_type == 2 then --Sphere
                    if collidable.shape_type == 2 then --ContinuousSphere
                        shape = shape:get_Sphere()
                    end
                    drawing.sphere(
                        shape:get_Center(),
                        shape:get_Radius(),
                        collidable.color,
                        config.default.sphere_show_outline,
                        config.default.sphere_show_wireframe
                    )
                elseif collidable.shape_type == 5 then --Box
                    local obb = shape:get_Box()
                    drawing.box(
                        obb:get_Position(),
                        obb:get_Extent(),
                        collidable.color,
                        config.default.box_show_outline
                    )
                end
            else
                if collidable.custom_shape_type == 1 then --Cylinder
                    drawing.cylinder(
                        shape:get_PosA(),
                        shape:get_PosB(),
                        shape:get_Radius(),
                        collidable.color,
                        config.slider_data.cylinder_segments[tostring(config.default.cylinder_segments)],
                        config.default.cylinder_show_outline,
                        config.default.cylinder_show_outline_sides
                    )
                elseif collidable.custom_shape_type == 4 then --Donut
                    drawing.ring(
                        shape:get_PosA(),
                        shape:get_PosB(),
                        shape:get_Radius(),
                        collidable.userdata:get_RingRadius(),
                        collidable.color,
                        config.slider_data.ring_segments[tostring(config.default.ring_segments)],
                        config.default.ring_show_outline,
                        config.default.ring_show_outline_sides
                    )
                end
            end
        end
    end
end

function drawing.init()
    config = require("AHBD.config")
    misc = require("AHBD.misc")
end

return drawing
