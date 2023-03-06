dofile("gizmo/gizmo.lua")

remove_hooks("gizmo_test")

--local part = fighter.tori():get_part(PART.NAME.L_HAND)
local obj = object.get(1)
obj:set_position(vec3(0, 0, 2))

local gizmo = gizmo.new(GIZMO_TYPE.SCALE, part:get_position())
gizmo.scale = vec3(1.0)

gizmo:on_change(function()
--    local rotated = force_gizmo.rotation:conjugate():transform(vec3(0, 0, force_gizmo.force))
--    part:set_linear_velocity(rotated)
--    set_ghost(0)
--    set_ghost(2)
    obj:set_scale(gizmo.scale)
end)
--
gizmo:on_update(function()
--    if force_gizmo.is_changing then
--        return
--    end
--
--    force_gizmo.position = part:get_position()
--    --force_gizmo.force = part:get_linear_velocity()

    gizmo.position = obj:get_position()
    gizmo.scale = obj:get_scale()
end)