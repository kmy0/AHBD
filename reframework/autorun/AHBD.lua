local config = require("AHBD.config")
local config_menu = require("AHBD.config_menu")
local data = require("AHBD.data")
local utilities = require("AHBD.utilities")
local hitboxes = require("AHBD.hitboxes")
local hurtboxes = require("AHBD.hurtboxes")
local drawing = require("AHBD.drawing")
local misc = require("AHBD.misc")


data.init()
utilities.init()
config.init()
config_menu.init()
drawing.init()
hitboxes.init()
hurtboxes.init()


sdk.hook(sdk.find_type_definition("via.physics.RequestSetCollider"):get_method('getCollidableFromIndex(System.UInt32, System.UInt32, System.UInt32)'), hurtboxes.get_hurtboxes)
sdk.hook(sdk.find_type_definition('snow.hit.AttackWork'):get_method('initialize(System.Single, System.Single, System.UInt32, System.UInt32, System.Int32, snow.hit.userdata.BaseHitAttackRSData)'), hitboxes.get_attacks)


re.on_draw_ui(
    function()
        if imgui.button(config.name .. " " ..config.version) then
            config_menu.is_opened = not config_menu.is_opened
        end
    end
)

re.on_frame(
    function()
        if not reframework:is_drawing_ui() then
            config_menu.is_opened = false
        end

        if config_menu.is_opened then
            config_menu.draw()
        end

        if utilities.is_in_quest() then
            utilities.update_objects()
            hurtboxes.get()
            hitboxes.get()
            drawing.draw()
        else
            hitboxes.reset()
            hurtboxes.reset()
        end
    end
)

re.on_config_save(config.save)
