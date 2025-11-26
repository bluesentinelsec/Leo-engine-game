local time_alive = 0

local function triangle_points(cx, cy, radius, angle)
    local a1 = angle
    local a2 = angle + (2 * math.pi / 3)
    local a3 = angle + (4 * math.pi / 3)
    return cx + math.cos(a1) * radius, cy + math.sin(a1) * radius,
           cx + math.cos(a2) * radius, cy + math.sin(a2) * radius,
           cx + math.cos(a3) * radius, cy + math.sin(a3) * radius
end

function leo_init()
    if leo_set_target_fps then
        leo_set_target_fps(60)
    end
    return true
end

function leo_update(dt)
    time_alive = time_alive + dt

    if leo_is_key_pressed and leo_is_key_pressed(leo_KEY_ESCAPE) then
        leo_quit()
    end
end

function leo_render()
    local screen_w = leo_get_screen_width and leo_get_screen_width() or 1280
    local screen_h = leo_get_screen_height and leo_get_screen_height() or 720
    local cx = screen_w / 2
    local cy = screen_h / 2

    leo_clear_background(16, 18, 28, 255)

    -- Filled triangle breathing in and out
    local fill_radius = 220 + math.sin(time_alive * 2.0) * 60
    local f1, f2, f3, f4, f5, f6 = triangle_points(cx, cy, fill_radius, time_alive * 1.2)
    local fill_alpha = 170 + math.floor((math.sin(time_alive * 3.1) * 0.5 + 0.5) * 80)
    leo_draw_triangle_filled(
        math.floor(f1), math.floor(f2),
        math.floor(f3), math.floor(f4),
        math.floor(f5), math.floor(f6),
        90, 200, 255, fill_alpha
    )

    -- Outline triangle counter-rotating and changing size
    local outline_radius = 140 + math.cos(time_alive * 1.4) * 50
    local o1, o2, o3, o4, o5, o6 = triangle_points(cx, cy, outline_radius, -time_alive * 1.5)
    leo_draw_triangle(
        math.floor(o1), math.floor(o2),
        math.floor(o3), math.floor(o4),
        math.floor(o5), math.floor(o6),
        255, 230, 90, 255
    )

    -- Small samples in the corner
    local base_x = 40
    local base_y = 70
    leo_draw_triangle_filled(base_x, base_y, base_x + 60, base_y, base_x + 30, base_y - 50, 120, 255, 150, 255)
    leo_draw_triangle(base_x + 90, base_y, base_x + 150, base_y, base_x + 120, base_y - 50, 255, 255, 255, 255)

    if leo_draw_text then
        leo_draw_text("Filled triangle (center, cyan)", 30, base_y + 20, 18, 200, 230, 255, 255)
        leo_draw_text("Outline triangle (center, yellow)", 30, base_y + 45, 18, 255, 230, 90, 255)
        leo_draw_text("Press ESC to quit", 30, screen_h - 36, 16, 180, 180, 180, 255)
    end
end

function leo_exit() end
