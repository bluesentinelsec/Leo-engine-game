-- Default Leo Engine Lua Game Script

local time = 0
local bg_tex = nil

function leo_init()
    print("Lua: Game initialized with image bindings!")
    -- Load background texture using new leo image bindings
    bg_tex = leo_image_load("images/background_320x200.png")
    return true
end

function leo_update(dt)
    time = time + dt
    
    -- Quit after 3 seconds for demo
    if time > 3.0 then
        leo_quit()
    end
end

function leo_render()
    -- Clear to dark blue
    leo_clear_background(32, 32, 64, 255)
    -- Draw background if loaded
    if bg_tex and leo_image_is_ready(bg_tex) then
        local src_x, src_y = 0, 0
        local src_w, src_h = 320, 200
        local dest_x, dest_y = 0, 0
        -- Stretch to window height while keeping aspect ratio
        local window_w = 1920
        local window_h = 1080
        local scale_x = window_w / src_w
        local scale_y = window_h / src_h
        local scale = math.min(scale_x, scale_y)
        local draw_w = src_w * scale
        local draw_h = src_h * scale
        local offset_x = (window_w - draw_w) * 0.5
        local offset_y = (window_h - draw_h) * 0.5
        leo_draw_texture_pro(bg_tex, src_x, src_y, src_w, src_h,
            dest_x + offset_x, dest_y + offset_y, draw_w, draw_h,
            0, 0, 0,
            255, 255, 255, 255)
    end
    
end

function leo_exit()
    if bg_tex then
        leo_image_unload(bg_tex)
        bg_tex = nil
    end
    print("Lua: Game exiting!")
end
