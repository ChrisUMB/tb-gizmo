dofile("gizmo/gizmo.lua")

remove_hooks("gizmo_test")

local part = fighter.tori():get_part(PART.NAME.L_HAND)

local force_gizmo = gizmo.new(GIZMO_TYPE.FORCE, part:get_position())
force_gizmo.force = 10.0

force_gizmo:on_change(function()
    local rotated = force_gizmo.rotation:conjugate():transform(vec3(0, 0, force_gizmo.force))
    part:set_linear_velocity(rotated)
    set_ghost(2)
end)

force_gizmo:on_update(function()
    if force_gizmo.is_changing then
        return
    end

    force_gizmo.position = part:get_position()
    --force_gizmo.force = part:get_linear_velocity()
end)