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

function utilities.get_shape_type(collidable)
    local shape = collidable:get_TransformedShape()
    return shape:get_ShapeType()
end

function utilities.get_parent_data(char_type,char_base)
    local char = {}
    if char_type == 0 then      --player
        char.player = true
        char.id = char_base:getPlayerIndex()
        if char.id == data.master_player.id then
            char.master_player = true
        else
            char.servant = char_base:checkServant(char.id)
        end
    elseif char_type == 1 then      --enemy
        char.enemy = {
            boss=char_base:get_isBossEnemy()
        }
        char.id = char_base:get_EnemyType()
    elseif char_type == 2 then      --otomo
        char.otomo = true
        local otomo_quest_param = char_base:get_OtQuestParam()
        char.id = otomo_quest_param:get_OtomoID()
        char.servant = char_base:get_IsServantOtomo()
    elseif char_type == 5 then      --envcreature
        char.creature = true
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
                t.hitzones[meat][group][i+1] = t.base:getMeatAdjustValue(tonumber(meat), i, tonumber(group))
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
                    data.char_objects[base].enemy
                    and data.char_objects[base].enemy.boss
                    or (
                        data.char_objects[base].enemy
                        and not data.char_objects[base].enemy.boss
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

        data.to_update = misc.table_copy(data.updated)
        data.updated = {}
    end
end

function utilities.update_collidable(collidable)
    collidable.enabled = collidable.col:get_Enabled()
    if collidable.enabled then
        local shape = collidable.col:get_TransformedShape()
        if shape then
            if collidable.shape_type then
                if collidable.shape_type == 3 or collidable.shape_type == 4 then --Capsule

                    if collidable.shape_type == 4 then --ContinuousCapsule
                        shape = shape:get_Capsule()
                        collidable.pos_a = shape:get_StartPosition()
                        collidable.pos_b = shape:get_EndPosition()
                    else
                        collidable.pos_a = shape:get_PosA()
                        collidable.pos_b = shape:get_PosB()
                    end

                    collidable.radius = shape:get_Radius()
                    local center = collidable.pos_a + collidable.pos_b
                    collidable.pos = Vector3f.new(center.x / 2, center.y / 2, center.z / 2)

                elseif collidable.shape_type == 1 or collidable.shape_type == 2 then --Sphere
                    if collidable.shape_type == 2 then --ContinuousSphere
                        shape = shape:get_Sphere()
                    end

                    collidable.radius = shape:get_Radius()
                    collidable.pos = shape:get_Center()

                elseif collidable.shape_type == 5 then --Box
                    local obb = shape:get_Box()

                    collidable.pos = obb:get_Position()
                    collidable.extent = obb:get_Extent()

                end
            else
                if collidable.custom_shape_type == 1 then --Cylinder

                    collidable.pos_a = shape:get_PosA()
                    collidable.pos_b = shape:get_PosB()
                    collidable.radius = shape:get_Radius()
                    local center = collidable.pos_a + collidable.pos_b
                    collidable.pos = Vector3f.new(center.x / 2, center.y / 2, center.z / 2)

                elseif collidable.custom_shape_type == 4 then --Donut

                    collidable.pos_a = shape:get_PosA()
                    collidable.pos_b = shape:get_PosB()
                    collidable.radius = shape:get_Radius()
                    collidable.ring_radius = collidable.userdata:get_RingRadius()
                    local center = collidable.pos_a + collidable.pos_b
                    collidable.pos = Vector3f.new(center.x / 2, center.y / 2, center.z / 2)

                end
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
