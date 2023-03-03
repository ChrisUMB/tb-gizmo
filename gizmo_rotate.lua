GIZMO_ROTATE = {
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

    SEGMENT_COUNT = 64,
    RADIUS = 0.125,
    COUNT_DIV = 3,

    FILL_WIDTH = 5.0,
    OUTLINE_WIDTH = 9.0,
    CLICK_WIDTH = 20.0
}

---@param g gizmo
function gizmo_rotate_get_axis_at_mouse(g, mouse_x, mouse_y)
    local segments = g.segments

    local min_dist
    local min_axis

    for i = 1, #segments do
        local segment = segments[i]

        if not segment.cull then
            local spos_1 = segment.spos_1
            local spos_2 = segment.spos_2

            local d = distance_to_segment(mouse_x, mouse_y, spos_1.x, spos_1.y, spos_2.x, spos_2.y)
            if min_dist == nil or d < min_dist then
                min_dist = d
                min_axis = segment.axis
            end
        end
    end

    return min_dist < GIZMO_ROTATE.CLICK_WIDTH and min_axis or nil
end

---@param g gizmo
function gizmo_rotate_mouse_down(g, mouse_x, mouse_y)
    local axis_at_mouse = gizmo_rotate_get_axis_at_mouse(g, mouse_x, mouse_y)
    g.drag_axis = axis_at_mouse

    if g.drag_axis ~= nil then
        g.is_changing = true
    end

    return g.drag_axis ~= nil
end

---@param g gizmo
function gizmo_rotate_mouse_up(g, mouse_x, mouse_y)
    if g.drag_axis then
        g.drag_axis = nil
        g.is_changing = false
        return true
    end

    return false
end

---@param g gizmo
function gizmo_rotate_mouse_move(g, mouse_x, mouse_y)
    if not g.drag_axis then
        return
    end

    local current_mouse_pos = vec2(mouse_x, mouse_y)
    local center_spos = vec2(get_screen_pos(g.position.x, g.position.y, g.position.z))

    local angle_1 = (current_mouse_pos - center_spos):angle()
    local angle_2 = (g.previous_mouse_pos - center_spos):angle()

    local angle_delta = angle_1 - angle_2

    local axis_dir = {
        X = axis.positive_x,
        Y = axis.positive_y,
        Z = axis.positive_z
    }

    local axis = axis_dir[g.drag_axis]

    local camera_pos = vec3(get_camera_info().pos)
    local camera_dir = (g.position - camera_pos):normalize()
    local that = camera_dir:dot(axis)

    if that >= 0 then
        angle_delta = -angle_delta
    end

    if g.is_local then
        axis = g.rotation:transform(axis)
    end

    g.rotation = g.rotation:rotate(angle_delta, axis)
    g.change_callback()
end

---@param g gizmo
function gizmo_rotate_draw2d(g)
    if g.cull then
        return
    end

    local segments = g.segments

    local fw = GIZMO_ROTATE.FILL_WIDTH
    local ow = GIZMO_ROTATE.OUTLINE_WIDTH

    local colors_fill = {
        X = GIZMO_ROTATE.COLORS.X.FILL,
        Y = GIZMO_ROTATE.COLORS.Y.FILL,
        Z = GIZMO_ROTATE.COLORS.Z.FILL
    }

    local colors_outline = {
        X = GIZMO_ROTATE.COLORS.X.OUTLINE,
        Y = GIZMO_ROTATE.COLORS.Y.OUTLINE,
        Z = GIZMO_ROTATE.COLORS.Z.OUTLINE
    }

    local hovered_axis = g.drag_axis or gizmo_rotate_get_axis_at_mouse(g, MOUSE_X, MOUSE_Y)

    if hovered_axis then
        colors_fill[hovered_axis] = GIZMO_ROTATE.COLORS[hovered_axis].HOVER_FILL
        colors_outline[hovered_axis] = GIZMO_ROTATE.COLORS[hovered_axis].HOVER_OUTLINE
    end

    local function check_cull(segment)
        if segment.axis == g.drag_axis then
            return segment.cull and not segment.cull_by_quota
        elseif g.drag_axis ~= nil then
            return true
        end

        return segment.cull
    end

    for i = 1, #segments do
        local segment = segments[i]

        if not check_cull(segment) and not segment.override_width then
            draw_fancy_line(
                    segment.spos_1.x, segment.spos_1.y,
                    segment.spos_2.x, segment.spos_2.y,
                    fw, ow, nil, colors_outline[segment.axis]
            )
        end
    end

    for i = 1, #segments do
        local segment = segments[i]

        if not check_cull(segment) then
            draw_fancy_line(
                    segment.spos_1.x, segment.spos_1.y,
                    segment.spos_2.x, segment.spos_2.y,
                    segment.override_width or fw, ow, colors_fill[segment.axis], nil
            )
        end
    end

end

---@param g gizmo
function gizmo_rotate_update3d(g)
    g.update_callback()
    local center_spos = vec2(get_screen_pos(g.position.x, g.position.y, g.position.z))
    local camera_pos = vec3(get_camera_info().pos)
    local dist = g.position:distance(camera_pos)

    -- Generate axis aligned points around the gizmo position
    local points = {
        X = {},
        Y = {},
        Z = {}
    }

    local segments = {}

    for i = 1, GIZMO_ROTATE.SEGMENT_COUNT do
        local angle = (i - 1) * (math.pi * 2.0 / GIZMO_ROTATE.SEGMENT_COUNT)
        local x = math.cos(angle) * GIZMO_ROTATE.RADIUS * dist
        local y = math.sin(angle) * GIZMO_ROTATE.RADIUS * dist

        local pos_x = vec3(g.position.x, x + g.position.y, y + g.position.z)
        local pos_y = vec3(x + g.position.x, g.position.y, y + g.position.z)
        local pos_z = vec3(x + g.position.x, y + g.position.y, g.position.z)

        local spos_x = vec3(get_screen_pos(pos_x.x, pos_x.y, pos_x.z))
        local spos_y = vec3(get_screen_pos(pos_y.x, pos_y.y, pos_y.z))
        local spos_z = vec3(get_screen_pos(pos_z.x, pos_z.y, pos_z.z))

        table.insert(points.X, { pos = spos_x, dist = pos_x:distance(camera_pos) })
        table.insert(points.Y, { pos = spos_y, dist = pos_y:distance(camera_pos) })
        table.insert(points.Z, { pos = spos_z, dist = pos_z:distance(camera_pos) })
    end

    local axes = { "X", "Y", "Z" }

    for i = 1, #axes do
        local axis = axes[i]
        local axis_points = points[axis]

        for k = 1, #axis_points do
            local spos_1 = axis_points[k].pos
            local spos_2 = axis_points[(k % #axis_points) + 1].pos

            local segment = {
                spos_1 = vec2(spos_1),
                spos_2 = vec2(spos_2),
                dist = axis_points[k].dist,
                axis = axis,
                cull = spos_1.z ~= 0 or spos_2.z ~= 0
            }

            table.insert(segments, segment)
        end
    end

    -- sort segments by distance to camera
    table.sort(segments, function(a, b)
        return a.dist > b.dist
    end)

    local axis_quota = {
        X = GIZMO_ROTATE.SEGMENT_COUNT / 2,
        Y = GIZMO_ROTATE.SEGMENT_COUNT / 2,
        Z = GIZMO_ROTATE.SEGMENT_COUNT / 2
    }

    for i = #segments,1,-1 do
        local segment = segments[i]
        local axis = segment.axis

        if axis_quota[axis] > 0 then
            axis_quota[axis] = axis_quota[axis] - 1
        elseif not segment.cull then
            segment.cull = true
            segment.cull_by_quota = true
        end
    end

    -- Create a line going through the center of the gizmo on the axis of rotation
    if g.drag_axis ~= nil then
        local directions = {
            X = axis.positive_x,
            Y = axis.positive_y,
            Z = axis.positive_z
        }

        local direction = directions[g.drag_axis]
        local start_pos = g.position + direction * dist
        local end_pos = g.position - direction * dist

        local spos_start = vec3(get_screen_pos(start_pos.x, start_pos.y, start_pos.z))
        local spos_end = vec3(get_screen_pos(end_pos.x, end_pos.y, end_pos.z))

        table.insert(segments, {
            spos_1 = vec2(spos_start),
            spos_2 = vec2(spos_end),
            dist = start_pos:distance(camera_pos),
            axis = g.drag_axis,
            cull = spos_start.z ~= 0 or spos_end.z ~= 0,
            override_width = 2.0
        })
    end

    g.segments = segments
    g.screen_pos = points
    g.center_spos = center_spos


    -- Debug
    --set_color(0.5, 0.5, 0.5, 1.0)
    --
    --local m = mat4(g.rotation):to_tb_matrix()
    --draw_box_m(g.position.x, g.position.y, g.position.z, 0.25, 0.25, 0.25, m)
end