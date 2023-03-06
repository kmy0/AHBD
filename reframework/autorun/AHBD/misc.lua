local misc = {}

local playman

function misc.get_playman()
    if not misc.playman then
        misc.playman = sdk.get_managed_singleton("snow.player.PlayerManager")
    end
    return misc.playman
end

function misc.get_player_pos()
    if misc.get_playman() then
        return misc.get_playman():findMasterPlayer():get_Pos()
    end
end

function misc.get_component(game_object, type_name)
    local t = sdk.typeof(type_name)

    if t == nil then
        return nil
    end

    return game_object:call("getComponent(System.Type)", t)
end

function misc.table_remove(t, fn_keep)
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

function misc.table_contains(list, x)
    for _, v in pairs(list) do
        if v == x then
            return true
        end
    end
    return false
end

function misc.table_copy(t)
    local newtable = {}
    for k,v in pairs(t) do
        newtable[k] = v
    end
    return newtable
end

function misc.add_count(t, k)
    local count = t[k]
    if count then
        t[k] = count + 1
    else
        t[k] = 1
    end
    return t
end

function misc.join_table(t)
    local str = nil
    for k,v in pairs(t) do
        local l = k .. ' ' .. v
        if not str then
            str = l .. '\n'
        else
            str = str .. l
        end
    end
    return str
end

function misc.get_camera_up()
    local camera = sdk.get_primary_camera()
    if not camera then return end

    local camera_obj = camera:get_GameObject()
    if not camera_obj then return end

    local camera_transform = camera_obj:get_Transform()
    if not camera_transform then return end

    local camera_joints = camera_transform:get_Joints()
    if not camera_joints then return end

    local camera_joint = camera_joints:get_Item(0)
    if not camera_joint then return end

    return camera_joint:get_Rotation() * Vector3f.new(0, 1, 0)
end

function misc.get_shape_type(collidable)
    local shape = collidable:get_TransformedShape()
    return shape:get_ShapeType()
end

return misc
