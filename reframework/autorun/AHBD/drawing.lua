local drawing = {}

local config
drawing.cache = {}


local function draw_shape(collidable)
    if collidable.info.shape_type then
        if collidable.info.shape_type == 3 or collidable.info.shape_type == 4 then --Capsule

            hb_draw.capsule(
                collidable.pos_a,
                collidable.pos_b,
                collidable.radius,
                collidable.color,
                config.current.show_outline,
                config.current.outline_color
            )


        elseif collidable.info.shape_type == 1 or collidable.info.shape_type == 2 then --Sphere

            hb_draw.sphere(
                collidable.pos,
                collidable.radius,
                collidable.color,
                config.current.show_outline,
                config.current.outline_color
            )

        elseif collidable.info.shape_type == 5 then --Box

            hb_draw.box(
                collidable.pos,
                collidable.extent,
                collidable.rot,
                collidable.color,
                config.current.show_outline,
                config.current.outline_color
            )

        end
    else
        if collidable.info.custom_shape_type == 1 then --Cylinder

            hb_draw.cylinder(
                collidable.pos_a,
                collidable.pos_b,
                collidable.radius,
                collidable.color,
                config.current.show_outline,
                config.current.outline_color
            )


        elseif collidable.info.custom_shape_type == 3 then --TrianglePole

            hb_draw.triangle(
                collidable.pos,
                collidable.extent,
                collidable.rot,
                collidable.color,
                config.current.show_outline,
                config.current.outline_color
            )

        elseif collidable.info.custom_shape_type == 4 then --Donut

            hb_draw.ring(
                collidable.pos_a,
                collidable.pos_b,
                collidable.radius,
                collidable.ring_radius,
                collidable.color,
                config.current.show_outline,
                config.current.outline_color
            )

        end
    end
end

function drawing.draw()
    table.sort(
        drawing.cache,
        function(x, y)
            if x.distance > y.distance then
                return true
            elseif x.distance == y.distance then
                if x.type == 'hurtbox' and y.type == 'hitbox' then
                    return true
                elseif x.type == y.type then
                    if x.sort < y.sort then
                        return true
                    end
                end
            end
        end
    )

    if #drawing.cache > 0 then

        for i=1, #drawing.cache do
            local col = drawing.cache[i]
            col.sort = i
            draw_shape(col)
        end

        drawing.cache = {}
    else
        drawing.cache = {}
    end
end

function drawing.init()
    config = require("AHBD.config")
end

return drawing
