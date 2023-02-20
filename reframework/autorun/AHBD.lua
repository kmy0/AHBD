local config = {
    enabled=true,
    ignore_small_monsters=false,
    ignore_big_monsters=false,
    ignore_otomo=false,
    ignore_players=false,
    ignore_undefined=false,
    color=1020343074
}
local version = '1.0'
local name = 'AHBD'
local config_path = name .. '/config.json'
local window = {
    flags=0x10120,
    pos=Vector2f.new(50, 50),
    pivot=Vector2f.new(0, 0),
    size=Vector2f.new(200, 200),
    condition=1 << 3,
    is_opened=false
}

local rsc_controllers = {}
local attacks = {}
local missing_shapes = {}


local function load_config()
    local loaded_config = json.load_file(config_path)
    if loaded_config then
        config = loaded_config
    end
end

local function save_config()
    json.dump_file(config_path, config)
end

local function draw_menu()
    imgui.set_next_window_pos(window.pos, window.condition, window.pivot)
    imgui.set_next_window_size(window.size, window.condition)

    window.is_opened = imgui.begin_window(name .. " " .. version, window.is_opened, window.flags)

    if not window.is_opened then
        imgui.end_window()
        save_config()
        return
    end

    local string_ = table.concat(missing_shapes, ", ")
    if string_ ~= '' then
        imgui.text('Missing Shape Types: ' .. string_)
    end

    _, config.enabled = imgui.checkbox('Enabled', config.enabled)
    _, config.ignore_small_monsters = imgui.checkbox('Ignore Small Monsters', config.ignore_small_monsters)
    _, config.ignore_big_monsters = imgui.checkbox('Ignore Big Monsters', config.ignore_big_monsters)
    _, config.ignore_otomo = imgui.checkbox('Ignore Otomo', config.ignore_otomo)
    _, config.ignore_players = imgui.checkbox('Ignore Players', config.ignore_players)
    _, config.ignore_undefined = imgui.checkbox('Ignore Undefined', config.ignore_undefined)
    if imgui.is_item_hovered() then
        imgui.set_tooltip('Environment creatures and stage damage. I think...')
    end
    _, config.color = imgui.color_edit('Color', config.color)
end

local function get_component(game_object, type_name)
    local t = sdk.typeof(type_name)

    if t == nil then
        return nil
    end

    return game_object:call("getComponent(System.Type)", t)
end

local function table_remove(t, fn_keep)
    local i, j, n = 1, 1, #t;
    while i <= n do
        if (fn_keep(t, i, j)) then
            local k = i
            repeat
                i = i + 1;
            until i>n or not fn_keep(t, i, j+i-k)
            --if (k ~= j) then
                table.move(t,k,i-1,j);
            --end
            j = j + i - k;
        end
        i = i + 1;
    end
    table.move(t,n+1,n+n-j+1,j);
    return t;
end

local function table_contains(list, x)
    for _, v in pairs(list) do
        if v == x then
            return true
        end
    end
    return false
end

local function draw_shape(collidable)
    if collidable:get_Enabled() then
        local shape = collidable:get_TransformedShape()
        if shape then
            local shape_type = shape:get_ShapeType()

            if shape_type == 3 then
                draw.capsule(
                    shape:get_PosA(),
                    shape:get_PosB(),
                    shape:get_Radius(),
                    config.color,
                    true
                )
            elseif shape_type == 4 then
                shape = shape:get_Capsule()
                draw.capsule(
                    shape:get_StartPosition(),
                    shape:get_EndPosition(),
                    shape:get_Radius(),
                    config.color,
                    true
                )
            elseif shape_type == 1 or shape_type == 2 then
                if shape_type == 2 then
                    shape = shape:get_Sphere()
                end
                draw.sphere(
                    shape:get_Center(),
                    shape:get_Radius(),
                    config.color,
                    true
                )
            elseif shape_type == 5 then
                local obb = shape:get_Box()
                local pos = obb:get_Position()
                local extent = obb:get_Extent()
                local min = pos - extent
                local max = pos + extent
                local c1 = draw.world_to_screen(Vector3f.new(min.x, min.y, min.z))
                local c2 = draw.world_to_screen(Vector3f.new(max.x, min.y, min.z))
                local c3 = draw.world_to_screen(Vector3f.new(max.x, max.y, min.z))
                local c4 = draw.world_to_screen(Vector3f.new(min.x, max.y, min.z))
                local c5 = draw.world_to_screen(Vector3f.new(min.x, max.y, max.z))
                local c6 = draw.world_to_screen(Vector3f.new(min.x, min.y, max.z))
                local c7 = draw.world_to_screen(Vector3f.new(max.x, min.y, max.z))
                local c8 = draw.world_to_screen(Vector3f.new(max.x, max.y, max.z))
                if c1 and c2 and c3 and c4 and c5 and c6 and c7 and c8 then
                    draw.filled_quad(c1.x, c1.y, c2.x, c2.y, c3.x, c3.y, c4.x, c4.y, config.color)
                    draw.filled_quad(c1.x, c1.y, c4.x, c4.y, c5.x, c5.y, c6.x, c6.y, config.color)
                    draw.filled_quad(c1.x, c1.y, c2.x, c2.y, c7.x, c7.y, c6.x, c6.y, config.color)
                    draw.filled_quad(c2.x, c2.y, c3.x, c3.y, c8.x, c8.y, c7.x, c7.y, config.color)
                    draw.filled_quad(c3.x, c3.y, c4.x, c4.y, c5.x, c5.y, c8.x, c8.y, config.color)
                    draw.filled_quad(c5.x, c5.y, c6.x, c6.y, c7.x, c7.y, c8.x, c8.y, config.color)
                    draw.outline_quad(c1.x, c1.y, c2.x, c2.y, c3.x, c3.y, c4.x, c4.y, 4278190080)
                    draw.outline_quad(c1.x, c1.y, c4.x, c4.y, c5.x, c5.y, c6.x, c6.y, 4278190080)
                    draw.outline_quad(c1.x, c1.y, c2.x, c2.y, c7.x, c7.y, c6.x, c6.y, 4278190080)
                    draw.outline_quad(c2.x, c2.y, c3.x, c3.y, c8.x, c8.y, c7.x, c7.y, 4278190080)
                    draw.outline_quad(c3.x, c3.y, c4.x, c4.y, c5.x, c5.y, c8.x, c8.y, 4278190080)
                    draw.outline_quad(c5.x, c5.y, c6.x, c6.y, c7.x, c7.y, c8.x, c8.y, 4278190080)
                end
            else
                if not table_contains(missing_shapes, shape_type) then
                    table.insert(missing_shapes, shape_type)
                end
            end
        end
    end
end


load_config()


sdk.hook(
    sdk.find_type_definition('snow.hit.AttackWork'):get_method('initialize(System.Single, System.Single, System.UInt32, System.UInt32, System.Int32, snow.hit.userdata.BaseHitAttackRSData)'),
    function(args)
        if config.enabled then
            local attack_work = sdk.to_managed_object(args[2])
            local rsc_controller = attack_work:get_RSCCtrl()
            local parent = rsc_controllers[rsc_controller]

            if not parent then
                local transform = rsc_controller:getTransform()
                local game_object = transform:get_GameObject()
                local enemy_motion = get_component(game_object, 'snow.EnemyMotionFsm')
                parent = {}

                if enemy_motion then
                    em_char_base = enemy_motion:get_RefEmCharaBaseMotFsm()
                    parent.enemy = {
                        boss=em_char_base:get_isBossEnemy()
                    }
                elseif get_component(game_object, 'snow.PlayerMotionFsm') then
                    parent.player = true
                elseif get_component(game_object, 'snow.otomo.OtomoSequenceController') then
                    parent.otomo = true
                else
                    parent.undefined = true
                end
                rsc_controllers[rsc_controller] = parent
            end

            if (
                parent.player
                and not config.ignore_players
                or (
                    parent.otomo
                    and not config.ignore_otomo
                ) or (
                      parent.enemy
                      and (
                           not config.ignore_big_monsters
                           and parent.enemy.boss
                           or (
                               not config.ignore_small_monsters
                               and not parent.enemy.boss
                           )
                      )
                  ) or (
                        parent.undefined
                        and not config.ignore_undefined
                    )
            ) then
                table.insert(attacks,{
                    rsc_controller=rsc_controller,
                    attack_work=attack_work,
                    res_idx=args[5],
                    rs_id=args[6],
                })
            end
        end
    end
)

re.on_frame(
    function()
        if config.enabled then
            for _, data in pairs(attacks) do
                local phase = data.attack_work:get_Phase()

                if phase == 3 or data.attack_work:get_reference_count() == 1 then
                    data.remove = true
                    goto continue
                end

                if phase == 2 then
                    if not data.collidables then
                        data.collidables = {}
                        local col_count = data.rsc_controller:getNumCollidables(data.res_idx, data.rs_id)
                        for i=0, col_count-1 do
                            local collidable = data.rsc_controller:getCollidable(data.res_idx, data.rs_id, i)
                            table.insert(data.collidables, collidable)
                            draw_shape(collidable)
                        end
                    else
                        for _, collidable in pairs(data.collidables) do
                            draw_shape(collidable)
                        end
                    end
                end

                ::continue::
            end

            if #attacks > 0 then
                table_remove(
                    attacks,
                    function(t, i, j)
                        if t[i].remove then
                            return false
                        else
                            return true
                        end
                    end
                )
            end
        else
            attacks = {}
        end
    end
)

re.on_draw_ui(
    function()
        if imgui.button(name .. " " .. version) then
            window.is_opened = not window.is_opened
        end
    end
)

re.on_frame(
    function()
        if not reframework:is_drawing_ui() then
            window.is_opened = false
        end

        if window.is_opened then
            pcall(draw_menu)
        end
    end
)

re.on_script_reset(save_config)
