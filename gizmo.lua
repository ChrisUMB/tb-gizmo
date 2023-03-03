dofile("dsk/dsk.lua")
dofile("gizmo/gizmo_translate.lua")
dofile("gizmo/gizmo_rotate.lua")
dofile("gizmo/gizmo_force.lua")

remove_hooks("gizmo")

---@class GIZMO_TYPE : number
GIZMO_TYPE = {
    TRANSLATE = 1,
    ROTATE = 2,
    SCALE = 3,
    FORCE = 4 -- Rotate gizmo with an arrow pointing in the direction of the force, length representing the magnitude
}

---@type gizmo[]
local GIZMO_LIST = {}

---@class gizmo
---@field type GIZMO_TYPE The type of gizmo
---@field position vec3 The position of the gizmo
---@field rotation quat The rotation of the gizmo
---@field drag_direction vec3 The direction of the mouse drag
---@field previous_mouse_pos vec2 The previous mouse position
gizmo = {}

---@param type GIZMO_TYPE The type of gizmo
---@param position vec3|nil The position of the gizmo
---@param rotation quat|nil The rotation of the gizmo
---@param is_local boolean|nil True if the position and rotation are local to the parent, false if they are global
---@return gizmo The new gizmo
function gizmo:new(type, position, rotation, is_local)
    position = position or vec3(0, 0, 0)
    rotation = rotation or quat(0, 0, 0, 1)
    is_local = is_local or false
    local result = {
        type = type,
        position = position,
        rotation = rotation,
        is_local = is_local,

        -- Every implementation of gizmo is responsible for calling it's callbacks.
        update_callback = function()
        end,
        change_callback = function()
        end,

        -- This will be set to true when the gizmo is being dragged, again, every implementation is responsible for setting it.
        is_changing = false
    }

    setmetatable(result, self)
    self.__index = self

    table.insert(GIZMO_LIST, result)
    return result
end

---@param g gizmo
---@return boolean True if the gizmo was removed, false otherwise
function gizmo.remove(g)
    for i, v in ipairs(GIZMO_LIST) do
        if v == g then
            table.remove(GIZMO_LIST, i)
            return true
        end
    end

    return false
end

---@param change_callback fun() The callback to call when the gizmo is changed
function gizmo:on_change(change_callback)
    self.change_callback = change_callback
end

function gizmo:on_update(update_callback)
    self.update_callback = update_callback
end

local function gizmo_mouse_down(g, mouse_x, mouse_y)
    if g.cull then
        return
    end

    g.previous_mouse_pos = vec2(mouse_x, mouse_y)

    if g.type == GIZMO_TYPE.TRANSLATE then
        return gizmo_translate_mouse_down(g, mouse_x, mouse_y)
    end

    if g.type == GIZMO_TYPE.ROTATE then
        return gizmo_rotate_mouse_down(g, mouse_x, mouse_y)
    end

    if g.type == GIZMO_TYPE.FORCE then
        return gizmo_force_mouse_down(g, mouse_x, mouse_y)
    end
end

local function gizmo_mouse_up(g, mouse_x, mouse_y)
    if g.type == GIZMO_TYPE.TRANSLATE then
        return gizmo_translate_mouse_up(g, mouse_x, mouse_y)
    end

    if g.type == GIZMO_TYPE.ROTATE then
        return gizmo_rotate_mouse_up(g, mouse_x, mouse_y)
    end

    if g.type == GIZMO_TYPE.FORCE then
        return gizmo_force_mouse_up(g, mouse_x, mouse_y)
    end
end

local function gizmo_mouse_move(g, mouse_x, mouse_y)

    local s, e = pcall(function()


        if g.type == GIZMO_TYPE.TRANSLATE then
            gizmo_translate_mouse_move(g, mouse_x, mouse_y)
        end

        if g.type == GIZMO_TYPE.ROTATE then
            gizmo_rotate_mouse_move(g, mouse_x, mouse_y)
        end

        if g.type == GIZMO_TYPE.FORCE then
            gizmo_force_mouse_move(g, mouse_x, mouse_y)
        end

        g.previous_mouse_pos = vec2(mouse_x, mouse_y)

    end)

    if not s then
        println(string.format("gizmo_mouse_move: %s", e))
    end

end

local function gizmo_draw2d(g)

    local s, e = pcall(function()

        if g.type == GIZMO_TYPE.TRANSLATE then
            gizmo_translate_draw2d(g)
        end

        if g.type == GIZMO_TYPE.ROTATE then
            gizmo_rotate_draw2d(g)
        end

        if g.type == GIZMO_TYPE.FORCE then
            gizmo_force_draw2d(g)
        end

    end)

    if not s then
        println(string.format("gizmo_draw2d: %s", e))
    end
end

local function gizmo_update3d(g)
    local s, e = pcall(function()

        if g.type == GIZMO_TYPE.TRANSLATE then
            gizmo_translate_update3d(g)
        end

        if g.type == GIZMO_TYPE.ROTATE then
            gizmo_rotate_update3d(g)
        end

        if g.type == GIZMO_TYPE.FORCE then
            gizmo_force_update3d(g)
        end

    end)

    if not s then
        println(string.format("gizmo_update3d: %s", e))
    end
end

function distance_to_segment(px, py, x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    local length_squared = dx * dx + dy * dy
    if length_squared == 0 then
        return math.sqrt((px - x1) * (px - x1) + (py - y1) * (py - y1))
    end
    local t = math.max(0, math.min(1, ((px - x1) * dx + (py - y1) * dy) / length_squared))
    local projection_x, projection_y = x1 + t * dx, y1 + t * dy
    return math.sqrt((px - projection_x) * (px - projection_x) + (py - projection_y) * (py - projection_y))
end

function draw_fancy_line(start_x, start_y, end_x, end_y, fill_width, outline_width, fill_color, outline_color, capped, outline_cap)

    if capped == nil then
        capped = true
    end

    if outline_cap == nil then
        outline_cap = true
    end

    if outline_color then
        set_color(outline_color[1], outline_color[2], outline_color[3], outline_color[4])
        draw_line(start_x, start_y, end_x, end_y, outline_width)

        if capped and outline_cap then
            draw_disk(end_x, end_y, 0.0, outline_width * 0.5, 16, 1, 180, 360, 0)
            draw_disk(start_x, start_y, 0.0, outline_width * 0.5, 16, 1, 180, 360, 0)
        end
    end

    if fill_color then
        set_color(fill_color[1], fill_color[2], fill_color[3], fill_color[4])
        draw_line(start_x, start_y, end_x, end_y, fill_width)

        if capped then
            draw_disk(start_x, start_y, 0.0, fill_width * 0.5, 16, 1, 180, 360, 0)
            draw_disk(end_x, end_y, 0.0, fill_width * 0.5, 16, 1, 180, 360, 0)
        end
    end
end

add_hook("mouse_button_up", "gizmo", function(button_id, x, y)
    if button_id ~= 1 then
        return 0
    end

    for i = 1, #GIZMO_LIST do
        if gizmo_mouse_up(GIZMO_LIST[i], x, y) then
            return 1
        end
    end

    return 0
end)

add_hook("mouse_button_down", "gizmo", function(button_id, x, y)
    if button_id ~= 1 then
        return 0
    end

    for i = 1, #GIZMO_LIST do
        if gizmo_mouse_down(GIZMO_LIST[i], x, y) then
            return 1
        end
    end

    return 0
end)

add_hook("mouse_move", "gizmo", function(x, y)
    for i = 1, #GIZMO_LIST do
        gizmo_mouse_move(GIZMO_LIST[i], x, y)
    end
end)

add_hook("draw3d", "gizmo", function()
    for i = 1, #GIZMO_LIST do
        gizmo_update3d(GIZMO_LIST[i])
    end
end)

add_hook("draw2d", "gizmo", function()
    for i = 1, #GIZMO_LIST do
        gizmo_draw2d(GIZMO_LIST[i])
    end
end)

--set_camera_mode(4)
--add_hook("camera", "gizmo", function()
--    local g = GIZMO_LIST[1]
--    set_camera_lookat(g.position.x, g.position.y, g.position.z)
--end)

--[[
    kp_period = 266
--]]

KB_MODIFIERS = {
    L_SHIFT = false,
    R_SHIFT = false,

    L_CTRL = false,
    R_CTRL = false,

    L_ALT = false,
    R_ALT = false,

    SHIFT = false,
    CTRL = false,
    ALT = false,
}

add_hook("key_down", "gizmo", function(key)
    if key == 266 then
        local g = GIZMO_LIST[1]
        set_camera_mode(4)
        set_camera_lookat(g.position.x, g.position.y, g.position.z)
    end
end)