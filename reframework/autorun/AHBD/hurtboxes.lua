local hurtboxes = {}

local config
local drawing
local misc

local function get_player_hurtbox()
    if misc.get_playman() then
        if not hurtboxes.master_player then
            hurtboxes.master_player = {
                obj=misc.get_playman():findMasterPlayer(),
                boxes={}
            }
        end
        if hurtboxes.master_player.obj then
            local game_object = hurtboxes.master_player.obj:get_GameObject()
            local rscc = misc.get_component(game_object, 'snow.RSCController')
            local collidable = rscc:getCollidable(0, 0, 0)
            local data = {
                col=collidable,
                shape_type=misc.get_shape_type(collidable)
            }
            table.insert(hurtboxes.master_player.boxes, data)
        else
            hurtboxes.master_player = nil
        end
    end
end

function hurtboxes.draw_player()
    if config.default.enabled and config.default.show_player_hurtbox then
        if not hurtboxes.master_player then
            get_player_hurtbox()
        else
            if hurtboxes.master_player.boxes[1].col:get_reference_count() == 1 then
                hurtboxes.master_player = nil
            elseif hurtboxes.master_player then
                if not hurtboxes.master_player.obj:get_type_definition():is_a("snow.player.PlayerQuestBase") then
                    return
                end

                if config.default.hide_when_invulnerable and hurtboxes.master_player.obj:checkMuteki() then
                    return
                end
                hurtboxes.master_player.boxes[1].color = config.default.player_hurtbox_color
                drawing.shape(hurtboxes.master_player.boxes[1])
            end
        end
    else
        hurtboxes.master_player = nil
    end
end

sdk.hook(sdk.find_type_definition("snow.player.PlayerQuestBase"):get_method("update"),
    function(args)
        -- local obj = sdk.to_managed_object(args[2])
        -- local game_object = em:get_GameObject()
        -- local char_base = misc.get_component(game_object, 'snow.CharacterBase')
        -- print('chuj')
        -- if char_base then
        --     local char_type = char_base:getCharacterType()
        --     print(char_type)
        -- end
    end
)
sdk.hook(sdk.find_type_definition("snow.envCreature.EnvironmentCreatureBase"):get_method("update"),
    function(args)
        -- local em = sdk.to_managed_object(args[2])
        -- local game_object = em:get_GameObject()
        -- local char_base = misc.get_component(game_object, 'snow.CharacterBase')
        -- print('dupa')
        -- if char_base then
        --     local char_type = char_base:getCharacterType()
        --     print(char_type)
        -- end
    end
)
sdk.hook(sdk.find_type_definition("snow.enemy.EnemyCharacterBase"):get_method("update"),
    function(args)
        local obj = sdk.to_managed_object(args[2])
        local game_object = obj:get_GameObject()
        -- local char_base = misc.get_component(game_object, 'snow.CharacterBase')
        local char_base = misc.get_component(game_object, 'via.physics.RequestSetCollider')
        if char_base then
            group_count = char_base:get_NumRequestSetGroups()
            for i=0, group_count-1 do
                a = char_base:getRequestSetGroups(i):get_Resource() --get_NumRequestSets())
                b = a:get_type_definition():get_methods()
            end
        end
        -- print('cipa')
        -- if char_base then
        --     local char_type = char_base:getCharacterType()
        --     print(char_type)
        -- end
    end
)
cols = {}
-- EmHitDamageShapeData
-- via.physics.RequestSetCollider.getCollidableFromIndex(System.UInt32, System.UInt32, System.UInt32)
sdk.hook(sdk.find_type_definition("via.physics.RequestSetCollider"):get_method('getCollidableFromIndex(System.UInt32, System.UInt32, System.UInt32)'),
    function(args)
        print(args[3],args[4],args[5])
    end,
    function(retval)
        collidable = sdk.to_managed_object(retval)
        local col_data = {
            col=collidable,
            color=config.default.color,
            type='hurtbox'
        }
        if collidable then
            userdata = collidable:get_UserData()
            print(userdata:get_type_definition():get_name())
            col_data.shape_type = misc.get_shape_type(collidable)
            table.insert(cols, col_data)
            -- drawing.shape(col_data)
        end
        return retval
    end
)

function hurtboxes.draw_enemy()
    for _, col in pairs(cols) do
        drawing.shape(col)
    end
end

function hurtboxes.draw()
    hurtboxes.draw_player()
    hurtboxes.draw_enemy()
end

function hurtboxes.init()
    config = require("AHBD.config")
    drawing = require("AHBD.drawing")
    misc = require("AHBD.misc")
end

return hurtboxes
