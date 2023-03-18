GIZMO_FORCE = {
    COLORS = {
        X = {
            FILL = { 1.0, 0.0, 0.0, 1.0 },
            OUTLINE = { 0.5, 0.0, 0.0, 1.0 },
            HOVER_FILL = { 1.0, 0.5, 0.5, 1.0 },
            HOVER_OUTLINE = { 0.5, 0.25, 0.25, 1.0 }
        },

        Y = {
            FILL = { 0.0, 1.0, 0.0, 1.0 },
            OUTLINE = { 0.0, 0.5, 0.0, 1.0 },
            HOVER_FILL = { 0.5, 1.0, 0.5, 1.0 },
            HOVER_OUTLINE = { 0.25, 0.5, 0.25, 1.0 }
        },

        Z = {
            FILL = { 0.0, 0.0, 1.0, 1.0 },
            OUTLINE = { 0.0, 0.0, 0.5, 1.0 },
            HOVER_FILL = { 0.5, 0.5, 1.0, 1.0 },
            HOVER_OUTLINE = { 0.25, 0.25, 0.5, 1.0 }
        },

        F = {
            FILL = { 1.0, 0.33, 0.0, 1.0 },
            OUTLINE = { 0.5, 0.165, 0.0, 1.0 },
            HOVER_FILL = { 1.0, 0.66, 0.33, 1.0 },
            HOVER_OUTLINE = { 0.5, 0.33, 0.165, 1.0 },
            GUIDE = { 1.0, 0.83, 0.66, 1.0 }
        },

        FZ = {
            FILL = { 0.33, 0.33, 0.33, 1.0 },
            OUTLINE = { 0.165, 0.165, 0.165, 1.0 },
            HOVER_FILL = { 0.66, 0.66, 0.66, 1.0 },
            HOVER_OUTLINE = { 0.33, 0.33, 0.33, 1.0 },
            GUIDE = { 0.83, 0.83, 0.83, 1.0 }
        }
    },

    SEGMENT_COUNT = 32,
    RADIUS = 0.125,
    COUNT_DIV = 3,

    FILL_WIDTH = 5.0,
    OUTLINE_WIDTH = 9.0,
    CLICK_WIDTH = 20.0
}

---@param g gizmo
function gizmo_force_get_axis_at_mouse(g, mouse_x, mouse_y)
    local segments = g.segments

    local min_dist = math.huge
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

    return min_dist < GIZMO_FORCE.CLICK_WIDTH and min_axis or nil
end

---@param g gizmo
function gizmo_force_mouse_down(g, mouse_x, mouse_y)
    local axis_at_mouse = gizmo_force_get_axis_at_mouse(g, mouse_x, mouse_y)
    g.drag_axis = axis_at_mouse

    if g.drag_axis ~= nil then
        g.is_changing = true
    end

    return g.drag_axis ~= nil
end

---@param g gizmo
function gizmo_force_mouse_up(g, mouse_x, mouse_y)
    if g.drag_axis then
        g.drag_axis = nil
        g.is_changing = false
        return true
    end

    return false
end

---@param g gizmo
function gizmo_force_mouse_move(g, mouse_x, mouse_y)
    if not g.drag_axis then
        return
    end

    local current_mouse_pos = vec2(mouse_x, mouse_y)
    local center_spos = vec2(get_screen_pos(g.position.x, g.position.y, g.position.z))

    if g.drag_axis == "F" or g.drag_axis == "FZ" then
        local force_scale = g.force_render_scale or 25.0
        local force = g.force / force_scale
        if math.abs(force) < 0.01 then force = 0.01 end

        local v = g.position + g.rotation:positive_z() * force

        local start_screen_pos = vec2(get_screen_pos(g.position.x, g.position.y, g.position.z))
        local end_screen_pos = vec2(get_screen_pos(v.x, v.y, v.z))

        local mouse_delta = current_mouse_pos - g.previous_mouse_pos

        local screen_delta = end_screen_pos - start_screen_pos
        local screen_delta_length = screen_delta:length()

        local gizmo_delta = screen_delta:normalize():dot(mouse_delta) / screen_delta_length

        if g.drag_axis == "FZ" then
            g.force = gizmo_delta
            g.drag_axis = "F"
        else
            g.force = g.force * (1 + gizmo_delta)
        end

        g.change_callback()
        return
    end

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

    g.rotation = g.rotation:conjugate():rotate(angle_delta, axis):conjugate()
    g.change_callback()
end

---@param g gizmo
function gizmo_force_draw2d(g)

    if g.cull then
        return
    end

    local segments = g.segments

    local fw = GIZMO_FORCE.FILL_WIDTH
    local ow = GIZMO_FORCE.OUTLINE_WIDTH

    local colors_fill = {
        X = GIZMO_FORCE.COLORS.X.FILL,
        Y = GIZMO_FORCE.COLORS.Y.FILL,
        Z = GIZMO_FORCE.COLORS.Z.FILL,
        F = GIZMO_FORCE.COLORS.F.FILL,
        FZ = GIZMO_FORCE.COLORS.FZ.FILL
    }

    local colors_outline = {
        X = GIZMO_FORCE.COLORS.X.OUTLINE,
        Y = GIZMO_FORCE.COLORS.Y.OUTLINE,
        Z = GIZMO_FORCE.COLORS.Z.OUTLINE,
        F = GIZMO_FORCE.COLORS.F.OUTLINE,
        FZ = GIZMO_FORCE.COLORS.FZ.OUTLINE
    }

    local hovered_axis = g.drag_axis or gizmo_force_get_axis_at_mouse(g, MOUSE_X, MOUSE_Y)

    if hovered_axis then
        colors_fill[hovered_axis] = GIZMO_FORCE.COLORS[hovered_axis].HOVER_FILL
        colors_outline[hovered_axis] = GIZMO_FORCE.COLORS[hovered_axis].HOVER_OUTLINE
    end

    for i = 1, #segments do
        local segment = segments[i]

        if not segment.cull then
            local axis = segment.axis
            local spos_1 = segment.spos_1
            local spos_2 = segment.spos_2

            draw_fancy_line(spos_1.x, spos_1.y, spos_2.x, spos_2.y, fw, ow, nil, colors_outline[axis])
        end
    end

    for i = 1, #segments do
        local segment = segments[i]

        if not segment.cull then
            local axis = segment.axis
            local spos_1 = segment.spos_1
            local spos_2 = segment.spos_2

            draw_fancy_line(spos_1.x, spos_1.y, spos_2.x, spos_2.y, fw, ow, colors_fill[axis], nil)
        end
    end


end

---@param g gizmo
function gizmo_force_update3d(g)
    g.update_callback()
    local center_spos = vec3(get_screen_pos(g.position.x, g.position.y, g.position.z))
    local camera_pos = vec3(get_camera_info().pos)
    local dist = g.position:distance(camera_pos)

    -- Generate axis aligned points around the gizmo position
    local points = {
        X = {},
        Y = {},
        Z = {}
    }

    local segments = {}

    local force_scale = g.force_render_scale or 25.0
    --local v = g.rotation:conjugate():transform(vec3(0, 0, g.force / force_scale)) / 16.0
    local v = g.rotation:positive_z() * (g.force / force_scale) / 4.0
    local fz = g.force == 0

    if fz then
        table.insert(segments, {
            spos_1 = vec2(center_spos),
            spos_2 = vec2(center_spos),
            dist = g.position:distance(camera_pos),
            axis = "FZ",
            cull = false
        })
    else
        for i = 1, 4 do
            local a = (v * (i - 1)) + g.position
            local b = (v * i) + g.position

            local force_start_spos = vec3(get_screen_pos(a.x, a.y, a.z))
            local force_end_spos = vec3(get_screen_pos(b.x, b.y, b.z))

            local segment = {
                spos_1 = vec2(force_start_spos),
                spos_2 = vec2(force_end_spos),
                dist = a:distance(camera_pos),
                axis = fz and "FZ" or "F",
                cull = force_start_spos.z ~= 0 or force_end_spos.z ~= 0
            }

            table.insert(segments, segment)
        end
    end

    for i = 1, GIZMO_FORCE.SEGMENT_COUNT do
        local angle = (i - 1) * (math.pi * 2.0 / GIZMO_FORCE.SEGMENT_COUNT)
        local x = math.cos(angle) * GIZMO_FORCE.RADIUS * dist
        local y = math.sin(angle) * GIZMO_FORCE.RADIUS * dist

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
    tbl_bubble_sort(segments, function(a, b)
        return a.dist > b.dist
    end)

    for i = 1, #segments do
        local segment = segments[i]

        if segment.axis ~= "F" and segment.axis ~= "FZ" and i < #segments / GIZMO_FORCE.COUNT_DIV then
            segment.cull = true
        end

    end

    g.segments = segments
    g.screen_pos = points
    g.center_spos = vec2(center_spos)
end

function tbl_bubble_sort(tbl, cmp)
    local swapped = true
    local n = #tbl
    local j = 0

    while swapped do
        swapped = false
        j = j + 1

        for i = 1, n - j do
            if not cmp(tbl[i], tbl[i + 1]) then
                tbl[i], tbl[i + 1] = tbl[i + 1], tbl[i]
                swapped = true
            end
        end
    end
end