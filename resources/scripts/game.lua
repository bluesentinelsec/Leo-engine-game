-- Default Leo Engine Lua Game Script

local time = 0
local bg_tex = nil

local player = {
    x = 160,
    y = 100,
    speed = 110,
    radius = 14
}

local flash_pressed = 0
local flash_released = 0
local pulse_reset = false

local function clamp(v, min_v, max_v)
    if v < min_v then
        return min_v
    elseif v > max_v then
        return max_v
    end
    return v
end

function leo_init()
    print("Lua: Game initialized with image + keyboard bindings!")
    bg_tex = leo_image_load("images/background_320x200.png")
    return true
end

function leo_update(dt)
    time = time + dt

    local move_x, move_y = 0, 0

    if leo_is_key_down(leo_KEY_LEFT) or leo_is_key_down(leo_KEY_A) then
        move_x = move_x - 1
    end
    if leo_is_key_down(leo_KEY_RIGHT) or leo_is_key_down(leo_KEY_D) then
        move_x = move_x + 1
    end
    if leo_is_key_down(leo_KEY_UP) or leo_is_key_down(leo_KEY_W) then
        move_y = move_y - 1
    end
    if leo_is_key_down(leo_KEY_DOWN) or leo_is_key_down(leo_KEY_S) then
        move_y = move_y + 1
    end

    if move_x ~= 0 or move_y ~= 0 then
        local length = math.sqrt(move_x * move_x + move_y * move_y)
        move_x = move_x / length
        move_y = move_y / length
        player.x = player.x + move_x * player.speed * dt
        player.y = player.y + move_y * player.speed * dt
    end

    local screen_w = leo_get_screen_width()
    local screen_h = leo_get_screen_height()
    player.x = clamp(player.x, player.radius, screen_w - player.radius)
    player.y = clamp(player.y, player.radius, screen_h - player.radius)

    if leo_is_key_pressed(leo_KEY_SPACE) then
        flash_pressed = 0.25
        pulse_reset = true
        print("Space pressed, resetting pulse animation")
        time = 0
    end

    if leo_is_key_released(leo_KEY_SPACE) then
        flash_released = 0.25
        print("Space released")
    end

    if flash_pressed > 0 then
        flash_pressed = flash_pressed - dt
        if flash_pressed < 0 then
            flash_pressed = 0
        end
    end

    if flash_released > 0 then
        flash_released = flash_released - dt
        if flash_released < 0 then
            flash_released = 0
        end
    end

    if leo_is_key_pressed(leo_KEY_Q) then
        print("Q pressed, quitting game")
        leo_quit()
    end

    if leo_is_exit_key_pressed() then
        leo_quit()
    end
end

local function draw_background()
    if bg_tex and leo_image_is_ready(bg_tex) then
        local src_w, src_h = leo_texture_get_size(bg_tex)
        local window_w = leo_get_screen_width()
        local window_h = leo_get_screen_height()
        local scale = math.min(window_w / src_w, window_h / src_h)
        local draw_w = src_w * scale
        local draw_h = src_h * scale
        local offset_x = (window_w - draw_w) * 0.5
        local offset_y = (window_h - draw_h) * 0.5

        leo_draw_texture_pro(
            bg_tex,
            0, 0, src_w, src_h,
            offset_x, offset_y, draw_w, draw_h,
            0, 0, 0,
            255, 255, 255, 255
        )
    end
end

local function draw_keyboard_overlay()
    local hud_x = 10
    local hud_y = 10
    leo_draw_rectangle(hud_x, hud_y, 180, 70, 20, 20, 40, 220)
    leo_draw_rectangle_lines(hud_x, hud_y, 180, 70, 200, 200, 255, 255)

    local active = {0, 220, 255, 255}
    local idle = {60, 60, 90, 255}
    local cx = hud_x + 35
    local cy = hud_y + 38

    local function draw_key(dx, dy, pressed)
        local color = pressed and active or idle
        leo_draw_rectangle(cx + dx, cy + dy, 20, 20, color[1], color[2], color[3], color[4])
        leo_draw_rectangle_lines(cx + dx, cy + dy, 20, 20, 255, 255, 255, 200)
    end

    draw_key(22, -22, leo_is_key_down(leo_KEY_UP) or leo_is_key_down(leo_KEY_W))
    draw_key(-22, 0, leo_is_key_down(leo_KEY_LEFT) or leo_is_key_down(leo_KEY_A))
    draw_key(22, 0, leo_is_key_down(leo_KEY_RIGHT) or leo_is_key_down(leo_KEY_D))
    draw_key(22, 22, leo_is_key_down(leo_KEY_DOWN) or leo_is_key_down(leo_KEY_S))

    local pressed_color = flash_pressed > 0 and {0, 255, 160, 255} or {70, 70, 110, 255}
    local released_color = flash_released > 0 and {255, 120, 0, 255} or {70, 70, 110, 255}
    leo_draw_rectangle(hud_x + 105, hud_y + 22, 65, 14, pressed_color[1], pressed_color[2], pressed_color[3], pressed_color[4])
    leo_draw_rectangle_lines(hud_x + 105, hud_y + 22, 65, 14, 255, 255, 255, 200)
    leo_draw_rectangle(hud_x + 105, hud_y + 46, 65, 14, released_color[1], released_color[2], released_color[3], released_color[4])
    leo_draw_rectangle_lines(hud_x + 105, hud_y + 46, 65, 14, 255, 255, 255, 200)
end

local function draw_animated_geometry()
    for i = 0, 12 do
        local t = time * 1.6 + i * 0.25
        local x = 40 + i * 18 + math.sin(t) * 12
        local y = 70 + math.cos(t * 0.8) * 10
        local alpha = 220 - i * 15
        leo_draw_rectangle(math.floor(x), math.floor(y), 16, 16, 255 - i * 10, 110 + i * 12, 40 + i * 8, alpha)
    end

    local px = math.floor(player.x)
    local py = math.floor(player.y)
    leo_draw_circle_filled(px, py, player.radius, 255, 210, 90, 255)
    leo_draw_triangle(px, py - player.radius - 12, px - 8, py - player.radius - 2, px + 8, py - player.radius - 2, 255, 255, 255, 220)

    leo_draw_line(20, 190, 300, 190 + math.floor(math.sin(time * 2) * 18), 0, 180, 255, 255)
    leo_draw_circle(250, 60, 22 + math.sin(time * 3) * 6, 80, 200, 255, 255)
    leo_draw_triangle_filled(270, 140, 310, 190, 220, 190, 180, 90, 200, 220)

    for i = 0, 50 do
        local x = 30 + i * 5
        local y = 210 + math.floor(math.sin(time * 4 + i * 0.32) * 6)
        local brightness = math.floor(128 + 127 * math.sin(time + i * 0.14))
        leo_draw_pixel(x, y, brightness, 255 - brightness, 200, 255)
    end
end

function leo_render()
    local pulse = math.floor(28 + (pulse_reset and 18 or 10) * math.sin(time * (pulse_reset and 3.5 or 2.0)))
    leo_clear_background(32, 32, 64 + pulse, 255)
    pulse_reset = false

    draw_background()
    draw_animated_geometry()
    draw_keyboard_overlay()
end

function leo_exit()
    if bg_tex then
        leo_image_unload(bg_tex)
        bg_tex = nil
    end
    print("Lua: Game exiting!")
end
