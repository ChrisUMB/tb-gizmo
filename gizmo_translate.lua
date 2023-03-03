GIZMO_TRANSLATE = {
    COLORS = {
        X = {
            FILL = { 1.0, 0.0, 0.0, 1.0 },
            OUTLINE = { 0.5, 0.0, 0.0, 1.0 },
            HOVER_FILL = { 1.0, 0.5, 0.5, 1.0 },
            HOVER_OUTLINE = { 0.5, 0.25, 0.25, 1.0 },
            GUIDE = { 1.0, 0.75, 0.75, 1.0 }
        },

        Y = {
            FILL = { 0.0, 1.0, 0.0, 1.0 },
            OUTLINE = { 0.0, 0.5, 0.0, 1.0 },
            HOVER_FILL = { 0.5, 1.0, 0.5, 1.0 },
            HOVER_OUTLINE = { 0.25, 0.5, 0.25, 1.0 },
            GUIDE = { 0.75, 1.0, 0.75, 1.0 }
        },

        Z = {
            FILL = { 0.0, 0.0, 1.0, 1.0 },
            OUTLINE = { 0.0, 0.0, 0.5, 1.0 },
            HOVER_FILL = { 0.5, 0.5, 1.0, 1.0 },
            HOVER_OUTLINE = { 0.25, 0.25, 0.5, 1.0 },
            GUIDE = { 0.75, 0.75, 1.0, 1.0 }
        }
    },

    FILL_WIDTH = 3.0,
    OUTLINE_WIDTH = 6.0,
    CLICK_WIDTH = 15.0,
    LINE_LENGTH = 0.125
}

---@param g gizmo
function gizmo_translate_get_axis_at_mouse(g, mouse_x, mouse_y)
    local center_spos = g.center_spos

    local camera_pos = vec3(get_camera_info().pos)
    local x_axis_distance = (g.position + axis.positive_x - camera_pos):length()
    local y_axis_distance = (g.position + axis.positive_y - camera_pos):length()
    local z_axis_distance = (g.position + axis.positive_z - camera_pos):length()

    local ow = GIZMO_TRANSLATE.CLICK_WIDTH

    local xd = distance_to_segment(mouse_x, mouse_y, center_spos.x, center_spos.y, g.x_end_spos.x, g.x_end_spos.y)
    local yd = distance_to_segment(mouse_x, mouse_y, center_spos.x, center_spos.y, g.y_end_spos.x, g.y_end_spos.y)
    local zd = distance_to_segment(mouse_x, mouse_y, center_spos.x, center_spos.y, g.z_end_spos.x, g.z_end_spos.y)

    local click_x = xd < ow and xd < yd and xd < zd
    local click_y = yd < ow and yd < xd and yd < zd
    local click_z = zd < ow and zd < xd and zd < yd

    if x_axis_distance < y_axis_distance and x_axis_distance < z_axis_distance then
        return click_x and "X" or click_y and "Y" or click_z and "Z" or nil
    elseif y_axis_distance < z_axis_distance and y_axis_distance < x_axis_distance then
        return click_y and "Y" or click_z and "Z" or click_x and "X" or nil
    else
        return click_z and "Z" or click_x and "X" or click_y and "Y" or nil
    end

    return nil
end

---@param g gizmo
function gizmo_translate_mouse_down(g, mouse_x, mouse_y)
    local axes = {
        X = g.rotation:transform(axis.positive_x),
        Y = g.rotation:transform(axis.positive_y),
        Z = g.rotation:transform(axis.positive_z)
    }

    local axis_at_mouse = gizmo_translate_get_axis_at_mouse(g, mouse_x, mouse_y)
    g.drag_direction = axes[axis_at_mouse]
    g.drag_axis = axis_at_mouse

    if g.drag_axis ~= nil then
        g.is_changing = true
    end

    return g.drag_direction ~= nil
end

---@param g gizmo
function gizmo_translate_mouse_up(g, mouse_x, mouse_y)
    if g.drag_direction or g.drag_axis then
        g.drag_direction = nil
        g.drag_axis = nil
        g.is_changing = false
        return true
    end

    return false

end

---@param g gizmo
function gizmo_translate_mouse_move(g, mouse_x, mouse_y)
    if not g.drag_direction then
        return
    end

    local end_pos = g.position + g.drag_direction

    local start_screen_pos = vec2(get_screen_pos(g.position.x, g.position.y, g.position.z))
    local end_screen_pos = vec2(get_screen_pos(end_pos.x, end_pos.y, end_pos.z))

    local current_mouse_pos = vec2(mouse_x, mouse_y)
    local mouse_delta = current_mouse_pos - g.previous_mouse_pos

    local screen_delta = end_screen_pos - start_screen_pos
    local gizmo_delta = g.drag_direction * screen_delta:normalize():dot(mouse_delta) / screen_delta:length()
    g.position = g.position + gizmo_delta

    g.change_callback()
end

---@param g gizmo
function gizmo_translate_draw2d(g)
    local center_spos = g.center_spos

    --if g.drag_axis then
    --    local c = GIZMO_TRANSLATE.COLORS[g.drag_axis].GUIDE
    --    set_color(c[1], c[2], c[3], c[4])
    --
    --    local e = g.screen_pos[g.drag_axis]
    --    local dir = (e - center_spos):normalize()
    --
    --
    --end

    if g.cull then
        return
    end

    -- Center circle if we want it
    --set_color(0.0, 0.0, 0.0, 1.0)
    --draw_disk(center_spos.x, center_spos.y, 0.0, 12.0, 32, 1, 0, 360, 0)
    --set_color(1.0, 1.0, 1.0, 1.0)
    --draw_disk(center_spos.x, center_spos.y, 0.0, 10.0, 32, 1, 0, 360, 0)

    -- Determine which axis is closest to the camera and draw that one last so it's on top
    local camera_pos = vec3(get_camera_info().pos)
    local x_axis_distance = (g.position + g.rotation:transform(axis.positive_x) - camera_pos):length()
    local y_axis_distance = (g.position + g.rotation:transform(axis.positive_y) - camera_pos):length()
    local z_axis_distance = (g.position + g.rotation:transform(axis.positive_z) - camera_pos):length()

    local fw = GIZMO_TRANSLATE.FILL_WIDTH
    local ow = GIZMO_TRANSLATE.OUTLINE_WIDTH

    local colors_fill = {
        X = GIZMO_TRANSLATE.COLORS.X.FILL,
        Y = GIZMO_TRANSLATE.COLORS.Y.FILL,
        Z = GIZMO_TRANSLATE.COLORS.Z.FILL
    }

    local colors_outline = {
        X = GIZMO_TRANSLATE.COLORS.X.OUTLINE,
        Y = GIZMO_TRANSLATE.COLORS.Y.OUTLINE,
        Z = GIZMO_TRANSLATE.COLORS.Z.OUTLINE
    }

    local hovered_axis = g.drag_axis or gizmo_translate_get_axis_at_mouse(g, MOUSE_X, MOUSE_Y)

    if hovered_axis then
        colors_fill[hovered_axis] = GIZMO_TRANSLATE.COLORS[hovered_axis].HOVER_FILL
        colors_outline[hovered_axis] = GIZMO_TRANSLATE.COLORS[hovered_axis].HOVER_OUTLINE
    end

    if x_axis_distance < y_axis_distance and x_axis_distance < z_axis_distance then
        draw_fancy_line(center_spos.x, center_spos.y, g.z_end_spos.x, g.z_end_spos.y, fw, ow, colors_fill.Z, colors_outline.Z)
        draw_fancy_line(center_spos.x, center_spos.y, g.y_end_spos.x, g.y_end_spos.y, fw, ow, colors_fill.Y, colors_outline.Y)
        draw_fancy_line(center_spos.x, center_spos.y, g.x_end_spos.x, g.x_end_spos.y, fw, ow, colors_fill.X, colors_outline.X)
    elseif y_axis_distance < z_axis_distance and y_axis_distance < x_axis_distance then
        draw_fancy_line(center_spos.x, center_spos.y, g.z_end_spos.x, g.z_end_spos.y, fw, ow, colors_fill.Z, colors_outline.Z)
        draw_fancy_line(center_spos.x, center_spos.y, g.x_end_spos.x, g.x_end_spos.y, fw, ow, colors_fill.X, colors_outline.X)
        draw_fancy_line(center_spos.x, center_spos.y, g.y_end_spos.x, g.y_end_spos.y, fw, ow, colors_fill.Y, colors_outline.Y)
    else
        draw_fancy_line(center_spos.x, center_spos.y, g.x_end_spos.x, g.x_end_spos.y, fw, ow, colors_fill.X, colors_outline.X)
        draw_fancy_line(center_spos.x, center_spos.y, g.y_end_spos.x, g.y_end_spos.y, fw, ow, colors_fill.Y, colors_outline.Y)
        draw_fancy_line(center_spos.x, center_spos.y, g.z_end_spos.x, g.z_end_spos.y, fw, ow, colors_fill.Z, colors_outline.Z)
    end
end

---@param g gizmo
function gizmo_translate_update3d(g)
    g.update_callback()
    local center_spos = vec2(get_screen_pos(g.position.x, g.position.y, g.position.z))
    local camera_pos = vec3(get_camera_info().pos)
    local dist = g.position:distance(camera_pos)

    local x_end_pos = g.position + g.rotation:transform(axis.positive_x) * GIZMO_TRANSLATE.LINE_LENGTH * dist
    local x_end_spos = vec3(get_screen_pos(x_end_pos.x, x_end_pos.y, x_end_pos.z))

    local y_end_pos = g.position + g.rotation:transform(axis.positive_y) * GIZMO_TRANSLATE.LINE_LENGTH * dist
    local y_end_spos = vec3(get_screen_pos(y_end_pos.x, y_end_pos.y, y_end_pos.z))

    local z_end_pos = g.position + g.rotation:transform(axis.positive_z) * GIZMO_TRANSLATE.LINE_LENGTH * dist
    local z_end_spos = vec3(get_screen_pos(z_end_pos.x, z_end_pos.y, z_end_pos.z))

    -- some part of the gizmo is not going to render properly, disable the whole thing
    g.cull = x_end_spos.z ~= 0 or y_end_spos.z ~= 0 or z_end_spos.z ~= 0

    set_color(1.0, 0.0, 0.0, 1.0)
    draw_sphere(g.position.x, g.position.y, g.position.z, 0.05)

    -- TODO: Refactor!
    g.x_end_spos = vec2(x_end_spos)
    g.y_end_spos = vec2(y_end_spos)
    g.z_end_spos = vec2(z_end_spos)

    g.screen_pos = {
        X = vec2(x_end_spos),
        Y = vec2(y_end_spos),
        Z = vec2(z_end_spos)
    }

    g.center_spos = center_spos
end

