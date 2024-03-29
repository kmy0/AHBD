local utilities = {}

local config
local data
local misc

local scene = sdk.call_native_func(sdk.get_native_singleton("via.SceneManager"), sdk.find_type_definition("via.SceneManager"), "get_CurrentScene()")


function utilities.is_only_my_ref(obj)
    if obj:read_qword(0x8) <= 0 then return true end
    local gameobject_addr = obj:read_qword(0x10)
    if gameobject_addr == 0 then
        return true
    end
    return false
end

function utilities.get_messageman()
    if not data.messageman then
        data.messageman = sdk.get_managed_singleton("snow.gui.MessageManager")
    end
    return data.messageman
end

function utilities.get_monster_name(id)
    return utilities.get_messageman():getEnemyNameMessage(id)
end

function utilities.get_part_name(meat, em_type)
    if next(data.monsters) == nil then
        local guiman = sdk.get_managed_singleton('snow.gui.GuiManager')

        if guiman then
            local monster_list = guiman:get_refMonsterList()

            if monster_list then
                local get_message = sdk.find_type_definition("via.gui.message"):get_method("get(System.Guid)")
                local monster_data_list = monster_list._MonsterBossData._DataList

                for i=0, monster_data_list:get_Count()-1 do
                    local monster = monster_data_list:get_Item(i)
                    local em_type = monster._EmType
                    local monster_part_data = monster._PartTableData

                    for j=0, monster_part_data:get_Count()-1 do
                        local part = monster_part_data:get_Item(j)
                        local meat = part._EmPart
                        local part_type = part._Part
                        local part_name_guid = monster_list:getMonsterPartName(part_type)

                        misc.set_nested_value(data.monsters, meat, get_message(nil, part_name_guid), em_type)
                    end
                end
            end
        end
    end

    if data.monsters[em_type] then
        return data.monsters[em_type][meat]
    end
end

function utilities.get_playman()
    if not data.playman then
        data.playman = sdk.get_managed_singleton("snow.player.PlayerManager")
    end
    return data.playman
end

function utilities.get_player_pos()
    if utilities.get_master_player() then
        data.master_player.pos = utilities.get_master_player():get_Pos()
        return data.master_player.pos
    end
end

function utilities.is_master_player(obj)
    return data.master_player.obj == obj
end

function utilities.is_in_quest()
    if utilities.get_master_player() then
        return utilities.get_master_player():get_type_definition():is_a("snow.player.PlayerQuestBase")
    end
end

function utilities.get_master_player()
    if not data.master_player.obj or utilities.is_only_my_ref(data.master_player.obj) then
        if not utilities.get_playman() then return end
        data.master_player.obj = utilities.get_playman():findMasterPlayer()
        data.master_player.id = utilities.get_playman():getMasterPlayerID()
    end
    return data.master_player.obj
end

function utilities.get_component(game_object, type_name)
    local t = sdk.typeof(type_name)

    if t == nil then
        return nil
    end

    return game_object:call("getComponent(System.Type)", t)
end

function utilities.get_all_transfroms()
    return scene:call("findComponents(System.Type)", sdk.typeof("via.Transform"))
end

function utilities.get_parent_data(char_type,char_base)
    local char = {}

    if char_type == 0 then      --player

        char.type = 'player'
        char.id = char_base:getPlayerIndex()

        if char.id == data.master_player.id then
            char.master_player = true
        else
            char.servant = char_base:checkServant(char.id)
        end

    elseif char_type == 1 then      --enemy

        char.type = char_base:get_isBossEnemy() and 'bossenemy' or 'smallenemy'
        char.id = char_base:get_EnemyType()

    elseif char_type == 2 then      --otomo

        char.type = 'otomo'
        local otomo_quest_param = char_base:get_OtQuestParam()
        char.id = otomo_quest_param:get_OtomoID()
        char.servant = char_base:get_IsServantOtomo()

    elseif char_type == 5 then      --envcreature

        char.type = 'creature'
    end

    char.base = char_base
    char.distance = 0
    char.meat = {}
    return char
end

function utilities.update_hitzones(t)
    if next(t.meat) == nil then return end

    if not t.hitzones then
        t.hitzones = {}
    end

    for meat, groups in pairs(t.meat) do

        if not t.hitzones[meat] then
            t.hitzones[meat] = {}
        end

        for group, _ in pairs(groups) do

            if not t.hitzones[meat][group] then
                t.hitzones[meat][group] = {}
            end

            for i=0, 8 do
                t.hitzones[meat][group][i+1] = t.base:getMeatAdjustValue(meat, i, group)
            end
        end
    end
end

function utilities.update_objects()
    if config.current.enabled_hurtboxes or config.current.enabled then
        for base, _ in pairs(data.to_update) do

            if utilities.is_only_my_ref(base) then
                data.to_update[base] = nil
                goto next
            end

            if data.char_objects[base] and not utilities.is_only_my_ref(base) then

                if (
                    data.char_objects[base].type == 'bossenemy'
                    or (
                        data.char_objects[base].type == 'smallenemy'
                        and not data.char_objects[base].hitzones
                    )
                ) then
                    utilities.update_hitzones(data.char_objects[base])
                end

                local pos = base:get_Pos()
                if pos then
                    if data.char_objects[base].master_player then
                        data.master_player.pos = pos
                    end

                    data.char_objects[base].distance = (data.master_player.pos - pos):length()
                    data.updated[base] = true
                    data.to_update[base] = nil
                    return
                end
            end

            ::next::
        end

        data.to_update = data.updated
        data.updated = {}
    end
end

function utilities.check_custom_shape(collidable, userdata)
    local custom_shape_type = userdata:read_byte(0xa0) --userdata._CustomShapeType
    local shape_type

    if custom_shape_type and custom_shape_type ~= 0 then
        return true, custom_shape_type
    else
        shape_type = collidable.shape:read_byte(0x20) --collidable.shape:get_ShapeType()
        return false, shape_type
    end
end

function utilities.update_collidable(collidable)
    collidable.enabled = collidable.col:read_byte(0x10) ~= 0 --collidable.col:get_Enabled()

    if collidable.enabled then
        local shape = collidable.shape

        if shape then
            if (
                collidable.info.shape_type == 3             --Capsule
                or collidable.info.shape_type == 4          --ContinuousCapsule
                or collidable.info.custom_shape_type == 1   --Cylinder
                or collidable.info.custom_shape_type == 4   --Donut
            ) then

                collidable.pos_a = Vector3f.new(shape:read_float(0x60), shape:read_float(100), shape:read_float(0x68))
                collidable.pos_b = Vector3f.new(shape:read_float(0x70), shape:read_float(0x74), shape:read_float(0x78))
                collidable.radius = shape:read_float(0x80)

                -- shape = shape:get_Capsule()
                -- collidable.pos_a = shape.p0
                -- collidable.pos_b = shape.p1
                -- collidable.radius = shape.r

                if collidable.info.custom_shape_type == 4 then
                    collidable.ring_radius = collidable.info.userdata:read_float(0x44)
                end

                collidable.pos = (collidable.pos_a + collidable.pos_b) * 0.5

            elseif (
                    collidable.info.shape_type == 1         --Sphere
                    or collidable.info.shape_type == 2      --ContinuousSphere
            ) then

                collidable.pos = Vector3f.new(shape:read_float(0x60), shape:read_float(0x64), shape:read_float(0x68))
                collidable.radius = shape:read_float(0x6c)

                -- shape = shape:get_Sphere()
                -- collidable.radius = shape.r
                -- collidable.pos = shape.pos

            elseif (
                    collidable.info.shape_type == 5             --Box
                    or collidable.info.custom_shape_type == 3   --TrianglePole
            ) then

                collidable.pos = Vector3f.new(shape:read_float(0x90), shape:read_float(0x94), shape:read_float(0x98))
                collidable.extent = Vector3f.new(shape:read_float(0xa0), shape:read_float(0xa4), shape:read_float(0xa8))
                collidable.rot = Matrix4x4f.new(
                    shape:read_float(0x60), shape:read_float(0x100), shape:read_float(0x68), shape:read_float(0x6c),
                    shape:read_float(0x70), shape:read_float(0x74), shape:read_float(0x78), shape:read_float(0x7c),
                    shape:read_float(0x80), shape:read_float(0x84), shape:read_float(0x88), shape:read_float(0x8c),
                    collidable.pos.x, collidable.pos.y, collidable.pos.z, shape:read_float(0x9c)
                )

                -- shape = shape:get_Box()
                -- collidable.pos = shape:get_Position()
                -- collidable.rot = shape:get_RotateAngle()    --euler
                -- collidable.extent = shape.extent

            end

            collidable.distance = (data.master_player.pos - collidable.pos):length()
            collidable.updated = true
        else
            collidable.updated = false
        end
    end
end

function utilities.init()
    data = require("AHBD.data")
    misc = require("AHBD.misc")
    config = require("AHBD.config")
end

return utilities
